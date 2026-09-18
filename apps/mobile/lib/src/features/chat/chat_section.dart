import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../api/generated/models/chat_attachment_response.dart';
import '../../api/generated/models/chat_attachment_response_type.dart';
import '../../api/generated/models/chat_message_response.dart';
import '../../api/generated/models/chat_message_response_delivery_state.dart';
import '../../api/generated/models/chat_message_response_type.dart';
import '../../api/generated/models/chat_presence_response.dart';
import '../../api/generated/models/chat_presence_response_status.dart';
import '../../api/generated/models/chat_reaction_summary_response.dart';
import '../../api/generated/models/chat_send_message_request_type.dart';
import '../../api/generated/models/chat_thread_response.dart';
import '../../features/bub/bub_heart_burst.dart';
import '../../features/bub/bub_send_controller.dart';
import '../../features/safe/safe_controller.dart';
import '../../features/safe/safe_screen.dart';
import '../../core/async_state_widgets.dart';
import '../../features/tether_onboarding/tether_onboarding_screens.dart';
import '../../theme/bub_colors.dart';
import '../../widgets/bub_dialog_sheet.dart';
import 'chat_controller.dart';
import 'chat_media_picker.dart';

final chatPresenceClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

bool shouldShowLastSeen(DateTime? lastSeenAt, DateTime now) {
  if (lastSeenAt == null) {
    return false;
  }
  return now.difference(lastSeenAt) <= const Duration(hours: 24);
}

class ChatSection extends ConsumerStatefulWidget {
  const ChatSection({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends ConsumerState<ChatSection> {
  final _composer = TextEditingController();
  final _composerFocus = FocusNode();
  ChatMessageResponse? _replyTo;
  final _safeNotices = <_LocalChatNotice>[];
  final _pendingBubNotices = <_LocalChatNotice>[];
  var _stagedMedia = const <File>[];
  var _stagedMediaIds = const <String>{};
  var _pendingTextMessages = const <_PendingTextMessage>[];
  var _pendingMediaMessages = const <_PendingMediaMessage>[];
  var _sendToSafe = false;
  var _inlineMedia = const <ChatMediaItem>[];
  var _showInlineMediaPicker = false;
  var _inlineMediaExpanded = false;
  var _inlineMediaLoading = false;
  var _composerHasText = false;
  var _showEmojiPicker = false;
  var _bubTapCount = 0;
  var _bubBurstTrigger = 0;
  var _sendingTapBub = false;
  String? _safeUploadError;
  var _pendingTextSequence = 0;
  var _pendingMediaSequence = 0;
  var _pendingBubSequence = 0;
  DateTime? _lastBubTapAt;
  ChatThreadResponse? _lastThread;

  @override
  void initState() {
    super.initState();
    _composer.addListener(_handleComposerChanged);
    _composerFocus.addListener(_handleComposerFocusChanged);
  }

  @override
  void dispose() {
    _composer.removeListener(_handleComposerChanged);
    _composerFocus.removeListener(_handleComposerFocusChanged);
    _composer.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  void _handleComposerChanged() {
    final hasText = _composer.text.trim().isNotEmpty;
    if (hasText != _composerHasText) {
      final keepFocus = _composerFocus.hasFocus;
      setState(() => _composerHasText = hasText);
      if (keepFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _composerFocus.requestFocus();
          }
        });
      }
    }
  }

  void _handleComposerFocusChanged() {
    if (!_composerFocus.hasFocus) {
      return;
    }
    if (!_showInlineMediaPicker && !_showEmojiPicker) {
      return;
    }
    setState(() {
      _showInlineMediaPicker = false;
      _inlineMediaExpanded = false;
      _showEmojiPicker = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(chatThreadProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _handleBack(),
      child: thread.when(
        loading: () {
          final lastThread = _lastThread;
          if (lastThread != null) {
            return _buildLoadedThread(lastThread);
          }
          return const BubLoadingState(
            key: Key('chat-loading'),
            label: 'Loading chat',
          );
        },
        error: (_, _) => BubErrorState(
          key: const Key('chat-error-state'),
          title: 'Chat could not load',
          onRetry: () => ref.read(chatThreadProvider.notifier).refresh(),
          retryLabel: 'Retry',
          retryKey: const Key('chat-retry-button'),
        ),
        data: _buildLoadedThread,
      ),
    );
  }

  Widget _buildLoadedThread(ChatThreadResponse data) {
    _lastThread = data;
    if (data.hasActiveTether != true) {
      return const _UntetheredChatEmptyState();
    }
    final messages = data.messages ?? const [];
    final visiblePendingText = _visiblePendingTextMessages(
      _pendingTextMessages,
      messages,
    );
    final visiblePendingMedia = _visiblePendingMediaMessages(
      _pendingMediaMessages,
      messages,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          key: const Key('chat-bub-tap-zone'),
          behavior: HitTestBehavior.translucent,
          onTap: _handleBubTap,
          child: Column(
            children: [
              _ChatHeader(
                thread: data,
                onBack: widget.onBack,
                quickImages: _quickImages(messages),
                onSaveNickname: _savePartnerNickname,
                presenceNow: ref.watch(chatPresenceClockProvider)(),
              ),
              Expanded(
                child: RepaintBoundary(
                  child: DecoratedBox(
                    key: const Key('chat-canvas-wash'),
                    decoration: BoxDecoration(
                      gradient: BubColors.chatCanvasGradient(
                        Theme.of(context).brightness,
                      ),
                    ),
                    child: _MessageList(
                      messages: messages,
                      localNotices: [..._safeNotices, ..._pendingBubNotices],
                      pendingTextMessages: visiblePendingText,
                      pendingMediaMessages: visiblePendingMedia,
                      hasMoreBefore: data.hasMoreBefore == true,
                      onLoadOlder: () =>
                          ref.read(chatThreadProvider.notifier).loadOlder(),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ChatComposer(
                      controller: _composer,
                      focusNode: _composerFocus,
                      replyTo: _replyTo,
                      inlineMedia: _inlineMedia,
                      sendToSafe: _sendToSafe,
                      showInlineMediaPicker: _showInlineMediaPicker,
                      inlineMediaExpanded: _inlineMediaExpanded,
                      inlineMediaLoading: _inlineMediaLoading,
                      maxInlineMediaGridHeight: math.max(
                        96.0,
                        MediaQuery.sizeOf(context).height -
                            MediaQuery.viewInsetsOf(context).bottom -
                            280,
                      ),
                      stagedMedia: _stagedMedia,
                      stagedMediaIds: _stagedMediaIds,
                      canSend: _composerHasText || _stagedMedia.isNotEmpty,
                      onCancelReply: () => setState(() => _replyTo = null),
                      onSend: _sendComposer,
                      onAttachment: _toggleInlineMediaPicker,
                      onSendToSafeChanged: _setSendToSafe,
                      onInlineMediaSelected: _toggleInlineMediaSelection,
                      onToggleInlineMediaExpanded: () => setState(
                        () => _inlineMediaExpanded = !_inlineMediaExpanded,
                      ),
                      onRemoveStagedMedia: _removeStagedMedia,
                      onQuickReaction: _sendQuickReaction,
                      onToggleEmojiPicker: _toggleEmojiPicker,
                    ),
                    if (_showEmojiPicker)
                      RepaintBoundary(
                        child: SizedBox(
                          key: const Key('chat-emoji-picker'),
                          height: 248,
                          child: EmojiPicker(
                            textEditingController: _composer,
                            config: const Config(height: 248),
                          ),
                        ),
                      ),
                    if (_safeUploadError != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          _safeUploadError!,
                          key: const Key('chat-safe-upload-error'),
                          style: const TextStyle(
                            color: BubColors.coral,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: BubHeartBurst(
            trigger: _bubBurstTrigger,
            heartKey: const Key('chat-bub-heart-burst-heart'),
          ),
        ),
      ],
    );
  }

  void _handleBack() {
    if (_showInlineMediaPicker) {
      setState(() {
        _showInlineMediaPicker = false;
        _inlineMediaExpanded = false;
      });
      return;
    }
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
      return;
    }
    if (_composerFocus.hasFocus) {
      _composerFocus.unfocus();
      return;
    }
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  List<ChatAttachmentResponse> _quickImages(
    List<ChatMessageResponse> messages,
  ) {
    return [
      for (final message in messages)
        for (final attachment in message.attachments ?? const [])
          if (attachment.type == ChatAttachmentResponseType.image) attachment,
    ];
  }

  Future<void> _savePartnerNickname(String nickname) {
    return ref
        .read(chatThreadProvider.notifier)
        .updatePartnerNickname(nickname);
  }

  void _handleBubTap() {
    final now = DateTime.now();
    final lastTap = _lastBubTapAt;
    _lastBubTapAt = now;
    if (lastTap == null ||
        now.difference(lastTap) > const Duration(milliseconds: 700)) {
      _bubTapCount = 1;
      return;
    }
    _bubTapCount += 1;
    if (_bubTapCount < 3) {
      return;
    }
    _bubTapCount = 0;
    _sendTapBub();
  }

  Future<void> _sendTapBub() async {
    if (_sendingTapBub) {
      return;
    }
    final pendingNotice = _LocalChatNotice(
      id: 'pending-bub-${_pendingBubSequence++}',
      label: 'You bubbed ${_lastThread?.partnerDisplayName ?? 'them'}',
    );
    setState(() {
      _sendingTapBub = true;
      _bubBurstTrigger += 1;
      _pendingBubNotices.add(pendingNotice);
    });
    try {
      await ref.read(bubSendControllerProvider.notifier).sendBub();
      await ref.read(chatThreadProvider.notifier).refresh();
      if (mounted) {
        final messages =
            ref.read(chatThreadProvider).asData?.value.messages ?? const [];
        _pruneResolvedLocalNotices(messages);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bub couldn't send. Please try again.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sendingTapBub = false;
          _pendingBubNotices.removeWhere(
            (notice) => notice.id == pendingNotice.id,
          );
        });
      }
    }
  }

  Future<void> _sendComposer() async {
    final text = _composer.text.trim();
    final hasMedia = _stagedMedia.isNotEmpty;
    if (!hasMedia && text.isEmpty) {
      return;
    }
    if (hasMedia) {
      if (text.isNotEmpty) {
        _composer.clear();
        setState(() => _showEmojiPicker = false);
      }
      await _sendStagedMedia();
      if (text.isNotEmpty && mounted) {
        await _sendTextBody(text);
      }
      return;
    }
    await _sendTextBody(text);
  }

  Future<void> _sendTextBody(String text) async {
    if (text.isEmpty) {
      return;
    }
    _composer.clear();
    setState(() => _showEmojiPicker = false);
    final replyId = _replyTo?.id;
    final pendingMessage = _PendingTextMessage(
      id: 'pending-text-${_pendingTextSequence++}',
      body: text,
      createdAt: DateTime.now(),
    );
    setState(() {
      _replyTo = null;
      _pendingTextMessages = [..._pendingTextMessages, pendingMessage];
    });
    try {
      await ref
          .read(chatThreadProvider.notifier)
          .sendMessage(
            type: ChatSendMessageRequestType.text,
            body: text,
            replyToMessageId: replyId,
          );
    } finally {
      if (mounted) {
        setState(() {
          _pendingTextMessages = [
            for (final message in _pendingTextMessages)
              if (message.id != pendingMessage.id) message,
          ];
        });
      }
    }
  }

  static List<_PendingTextMessage> _visiblePendingTextMessages(
    List<_PendingTextMessage> pending,
    List<ChatMessageResponse> messages,
  ) {
    final claimed = <String>{};
    final visible = <_PendingTextMessage>[];
    for (final pendingMessage in pending) {
      final match = _matchingServerText(pendingMessage, messages, claimed);
      if (match == null) {
        visible.add(pendingMessage);
        continue;
      }
      final matchId = match.id;
      if (matchId != null) {
        claimed.add(matchId);
      }
    }
    return visible;
  }

  static List<_PendingMediaMessage> _visiblePendingMediaMessages(
    List<_PendingMediaMessage> pending,
    List<ChatMessageResponse> messages,
  ) {
    final claimed = <String>{};
    final visible = <_PendingMediaMessage>[];
    for (final pendingMessage in pending) {
      final match = _matchingServerMedia(pendingMessage, messages, claimed);
      if (match == null) {
        visible.add(pendingMessage);
        continue;
      }
      final matchId = match.id;
      if (matchId != null) {
        claimed.add(matchId);
      }
    }
    return visible;
  }

  static ChatMessageResponse? _matchingServerText(
    _PendingTextMessage pending,
    List<ChatMessageResponse> messages,
    Set<String> claimed,
  ) {
    for (final message in messages) {
      final id = message.id;
      final createdAt = message.createdAt;
      if (id == null ||
          claimed.contains(id) ||
          message.viewerMessage != true ||
          message.type != ChatMessageResponseType.text ||
          message.body != pending.body ||
          createdAt == null) {
        continue;
      }
      if (createdAt.difference(pending.createdAt).abs() >
          const Duration(minutes: 2)) {
        continue;
      }
      return message;
    }
    return null;
  }

  static ChatMessageResponse? _matchingServerMedia(
    _PendingMediaMessage pending,
    List<ChatMessageResponse> messages,
    Set<String> claimed,
  ) {
    for (final message in messages) {
      final id = message.id;
      final createdAt = message.createdAt;
      final attachmentCount = message.attachments?.length ?? 0;
      if (id == null ||
          claimed.contains(id) ||
          message.viewerMessage != true ||
          message.type != ChatMessageResponseType.media ||
          attachmentCount != pending.files.length ||
          createdAt == null) {
        continue;
      }
      if (createdAt.difference(pending.createdAt).abs() >
          const Duration(minutes: 2)) {
        continue;
      }
      return message;
    }
    return null;
  }

  Future<void> _toggleInlineMediaPicker() async {
    setState(() => _showEmojiPicker = false);
    if (_showInlineMediaPicker) {
      setState(() => _showInlineMediaPicker = false);
      return;
    }

    final hasCachedMedia = _inlineMedia.isNotEmpty;
    setState(() {
      _showInlineMediaPicker = true;
      _inlineMediaExpanded = false;
      _inlineMediaLoading = !hasCachedMedia;
    });
    // Dismiss keyboard after the drawer is painted so both don't animate hard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _composerFocus.hasFocus) {
        _composerFocus.unfocus();
      }
    });
    if (hasCachedMedia) {
      return;
    }

    final picker = ref.read(chatMediaPickerProvider);
    final media = await picker.recentMedia();
    if (!mounted) {
      return;
    }
    setState(() {
      _inlineMedia = media;
      _inlineMediaLoading = false;
    });
  }

  void _toggleEmojiPicker() {
    final opening = !_showEmojiPicker;
    setState(() {
      _showEmojiPicker = opening;
      if (opening) {
        _showInlineMediaPicker = false;
        _inlineMediaExpanded = false;
      }
    });
    if (opening) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _composerFocus.hasFocus) {
          _composerFocus.unfocus();
        }
      });
    }
  }

  void _addSafeNotice(int count) {
    setState(() {
      _safeNotices.add(
        _LocalChatNotice(
          id: 'safe-${DateTime.now().microsecondsSinceEpoch}',
          label: _safeNoticeLabel(count),
          safeItemCount: count,
        ),
      );
    });
  }

  void _pruneResolvedLocalNotices(List<ChatMessageResponse> messages) {
    final nextSafe = [
      for (final notice in _safeNotices)
        if (!_localNoticeCoveredByServer(notice, messages)) notice,
    ];
    final nextBub = [
      for (final notice in _pendingBubNotices)
        if (!_localNoticeCoveredByServer(notice, messages)) notice,
    ];
    if (nextSafe.length == _safeNotices.length &&
        nextBub.length == _pendingBubNotices.length) {
      return;
    }
    setState(() {
      _safeNotices
        ..clear()
        ..addAll(nextSafe);
      _pendingBubNotices
        ..clear()
        ..addAll(nextBub);
    });
  }

  static bool _localNoticeCoveredByServer(
    _LocalChatNotice notice,
    List<ChatMessageResponse> messages, {
    DateTime? now,
  }) {
    final cutoff = (now ?? DateTime.now()).subtract(
      const Duration(seconds: 45),
    );
    if (notice.id.startsWith('pending-bub-')) {
      return messages.any((message) {
        final createdAt = message.createdAt?.toLocal();
        return message.type == ChatMessageResponseType.bub &&
            message.viewerMessage == true &&
            createdAt != null &&
            !createdAt.isBefore(cutoff);
      });
    }
    if (notice.safeItemCount != null) {
      return messages.any((message) {
        final createdAt = message.createdAt?.toLocal();
        final sameCopy =
            message.body == notice.label ||
            message.safeItemCount == notice.safeItemCount;
        return message.type == ChatMessageResponseType.safeNotice &&
            sameCopy &&
            createdAt != null &&
            !createdAt.isBefore(cutoff);
      });
    }
    return false;
  }

  void _removeStagedMedia(int index) {
    if (index < 0 || index >= _stagedMedia.length) {
      return;
    }
    setState(() {
      _stagedMedia = [
        for (final (fileIndex, file) in _stagedMedia.indexed)
          if (fileIndex != index) file,
      ];
      _stagedMediaIds = {
        for (final (fileIndex, id) in _stagedMediaIds.indexed)
          if (fileIndex != index) id,
      };
    });
  }

  void _setSendToSafe(bool value) {
    setState(() => _sendToSafe = value);
  }

  Future<void> _toggleInlineMediaSelection(ChatMediaItem item) async {
    final selected = _stagedMediaIds.contains(item.id);
    setState(() {
      if (selected) {
        _stagedMedia = [
          for (final (index, file) in _stagedMedia.indexed)
            if (_stagedMediaIds.elementAt(index) != item.id) file,
        ];
        _stagedMediaIds = {
          for (final id in _stagedMediaIds)
            if (id != item.id) id,
        };
      }
    });
    if (selected) {
      return;
    }
    final file = await item.resolveFile();
    if (!mounted || file == null) {
      return;
    }
    setState(() {
      _stagedMedia = [..._stagedMedia, file];
      _stagedMediaIds = {..._stagedMediaIds, item.id};
    });
  }

  Future<void> _sendStagedMedia() async {
    final files = _stagedMedia;
    final toSafe = _sendToSafe;
    if (files.isEmpty) {
      return;
    }
    setState(() {
      _stagedMedia = const [];
      _stagedMediaIds = const {};
      _showInlineMediaPicker = false;
      _inlineMediaExpanded = false;
    });
    if (toSafe) {
      await _sendSafeMedia(files);
      return;
    }
    final replyId = _replyTo?.id;
    final pendingMessage = _PendingMediaMessage(
      id: 'pending-media-${_pendingMediaSequence++}',
      files: files,
      createdAt: DateTime.now(),
    );
    setState(() {
      _replyTo = null;
      _pendingMediaMessages = [..._pendingMediaMessages, pendingMessage];
    });
    try {
      await ref
          .read(chatThreadProvider.notifier)
          .uploadMedia(files: files, replyToMessageId: replyId);
    } finally {
      if (mounted) {
        setState(() {
          _pendingMediaMessages = [
            for (final message in _pendingMediaMessages)
              if (message.id != pendingMessage.id) message,
          ];
        });
      }
    }
  }

  Future<void> _sendQuickReaction() async {
    setState(() => _showEmojiPicker = false);
    final replyId = _replyTo?.id;
    setState(() => _replyTo = null);
    await ref
        .read(chatThreadProvider.notifier)
        .sendMessage(
          type: ChatSendMessageRequestType.emoji,
          body: '❤️',
          replyToMessageId: replyId,
        );
  }

  void _setReply(ChatMessageResponse message) {
    setState(() => _replyTo = message);
  }

  Future<void> _sendSafeMedia(List<File> files) async {
    final pin = await _safePinForUpload();
    if (!mounted) {
      return;
    }
    if (pin == null) {
      setState(() {
        _stagedMedia = files;
        _stagedMediaIds = {for (final file in files) file.path};
        _sendToSafe = true;
      });
      return;
    }
    setState(() => _safeUploadError = null);
    try {
      final result = await ref
          .read(safeControllerProvider.notifier)
          .uploadMedia(files, pin);
      final count = result.notice?.safeItemCount ?? result.items.length;
      _addSafeNotice(count == 0 ? files.length : count);
      await ref.read(chatThreadProvider.notifier).refresh();
      if (mounted) {
        final messages =
            ref.read(chatThreadProvider).asData?.value.messages ?? const [];
        _pruneResolvedLocalNotices(messages);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _safeUploadError = "Couldn't add that to Safe.");
      }
    }
  }

  Future<String?> _safePinForUpload() async {
    final session = ref.read(safeSessionProvider);
    final existingPin = session.unlocked ? session.pin : null;
    if (existingPin != null && existingPin.isNotEmpty) {
      return existingPin;
    }
    final status = await ref.read(safeControllerProvider.future);
    if (!mounted) {
      return null;
    }
    if (status.pinConfigured) {
      return _showSafePinDialog(
        setup: false,
        onSubmit: (pin) =>
            ref.read(safeControllerProvider.notifier).unlock(pin),
      );
    }
    return _showSafePinDialog(
      setup: true,
      onSubmit: (pin) =>
          ref.read(safeControllerProvider.notifier).setupPin(pin),
    );
  }

  Future<String?> _showSafePinDialog({
    required bool setup,
    required Future<void> Function(String pin) onSubmit,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      barrierDismissible: false,
      builder: (_) => _ChatSafePinDialog(setup: setup, onSubmit: onSubmit),
    );
  }
}

class _ChatSafePinDialog extends StatefulWidget {
  const _ChatSafePinDialog({required this.setup, required this.onSubmit});

  final bool setup;
  final Future<void> Function(String pin) onSubmit;

  @override
  State<_ChatSafePinDialog> createState() => _ChatSafePinDialogState();
}

class _ChatSafePinDialogState extends State<_ChatSafePinDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;
  var _submitting = false;

  bool get _canSubmit {
    if (_submitting || !RegExp(r'^\d{4,6}$').hasMatch(_pinController.text)) {
      return false;
    }
    return !widget.setup ||
        RegExp(r'^\d{4,6}$').hasMatch(_confirmController.text);
  }

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_onChanged);
    _confirmController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _pinController.removeListener(_onChanged);
    _confirmController.removeListener(_onChanged);
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softTextColor = isDark
        ? BubColors.textSecondaryDark
        : BubColors.textSecondaryLight;
    final inputFill = isDark
        ? BubColors.darkSurface
        : BubColors.purple.withValues(alpha: 0.04);

    return BubDialogSheet(
      key: Key(widget.setup ? 'safe-setup-dialog' : 'safe-unlock-dialog'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BubDialogHeader(
            icon: widget.setup
                ? Icons.lock_outline_rounded
                : Icons.lock_open_rounded,
            title: widget.setup ? 'Set a PIN for your Safe' : 'Unlock Safe',
            subtitle: widget.setup
                ? 'Your PIN is private to you.'
                : 'Enter your private PIN to add this to Safe.',
            onClose: _submitting ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 12),
          _ChatSafePinField(
            fieldKey: const Key('safe-pin-entry'),
            controller: _pinController,
            label: 'PIN',
            icon: Icons.lock_rounded,
            inputFill: inputFill,
            softTextColor: softTextColor,
          ),
          if (widget.setup) ...[
            const SizedBox(height: 10),
            _ChatSafePinField(
              fieldKey: const Key('safe-pin-confirm-entry'),
              controller: _confirmController,
              label: 'Confirm PIN',
              icon: Icons.verified_user_outlined,
              inputFill: inputFill,
              softTextColor: softTextColor,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              key: const Key('safe-pin-error'),
              style: const TextStyle(
                color: BubColors.coral,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 12),
          BubDialogActions(
            onCancel: () => Navigator.of(context).pop(),
            confirmKey: const Key('safe-pin-submit'),
            confirmLabel: widget.setup ? 'Set PIN' : 'Unlock',
            enabled: _canSubmit,
            busy: _submitting,
            onConfirm: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final pin = _pinController.text;
    if (widget.setup && pin != _confirmController.text) {
      setState(() => _error = 'PINs do not match');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(pin);
      if (mounted) {
        Navigator.of(context).pop(pin);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = widget.setup
              ? "Couldn't set your Safe PIN"
              : 'Invalid Safe PIN';
        });
      }
    }
  }

  void _onChanged() {
    if (!mounted) {
      return;
    }
    setState(() => _error = null);
  }
}

class _ChatSafePinField extends StatelessWidget {
  const _ChatSafePinField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.icon,
    required this.inputFill,
    required this.softTextColor,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color inputFill;
  final Color softTextColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? BubColors.white : BubColors.textPrimaryLight;

    return TextField(
      key: fieldKey,
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 4,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: softTextColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: BubColors.purple.withValues(alpha: 0.70),
        ),
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: BubColors.purple.withValues(alpha: 0.14),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: BubColors.purple.withValues(alpha: 0.14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BubColors.purple, width: 1.4),
        ),
      ),
    );
  }
}

class _LocalChatNotice {
  const _LocalChatNotice({
    required this.id,
    required this.label,
    this.safeItemCount,
  });

  final String id;
  final String label;
  final int? safeItemCount;
}

class _UntetheredChatEmptyState extends StatelessWidget {
  const _UntetheredChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 132),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/onboarding/tether.png',
              key: const Key('chat-empty-image'),
              width: 210,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            const Text(
              'Tether someone to start your conversation',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('chat-start-tether-button'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EnterTetherScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.favorite_rounded),
              label: const Text('Start tethering'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.thread,
    required this.onBack,
    required this.quickImages,
    required this.onSaveNickname,
    required this.presenceNow,
  });

  final ChatThreadResponse thread;
  final VoidCallback? onBack;
  final List<ChatAttachmentResponse> quickImages;
  final Future<void> Function(String nickname) onSaveNickname;
  final DateTime presenceNow;

  @override
  Widget build(BuildContext context) {
    final partner = thread.partnerDisplayName?.trim();
    final typing = thread.state?.partnerTyping == true;
    final presence = thread.state?.partnerPresence;
    final status = _presenceText(presence, presenceNow);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      key: const Key('chat-fullscreen-header'),
      color: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      BubColors.darkSurface,
                      BubColors.chatCanvasDarkTop.withValues(alpha: 0.92),
                    ]
                  : [
                      BubColors.white,
                      BubColors.chatCanvasLightTop.withValues(alpha: 0.96),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: BubColors.purple.withValues(alpha: isDark ? 0.22 : 0.10),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 8, 8),
            child: Row(
              children: [
                IconButton(
                  key: const Key('chat-back-button'),
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: InkWell(
                    key: const Key('chat-header-partner-tap'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showNicknameDialog(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: BubColors.purple.withValues(
                                alpha: isDark ? 0.24 : 0.10,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: BubColors.purple.withValues(
                                  alpha: isDark ? 0.28 : 0.14,
                                ),
                              ),
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: BubColors.purple,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  partner == null || partner.isEmpty
                                      ? 'Your Bub'
                                      : partner,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark
                                        ? BubColors.white
                                        : BubColors.textPrimaryLight,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (status != null)
                                  Text(
                                    status,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? BubColors.textSecondaryDark
                                          : BubColors.textSecondaryLight,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (typing)
                                  const Text(
                                    'Typing...',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: BubColors.pink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<_ChatHeaderMenuAction>(
                  key: const Key('chat-header-more-button'),
                  tooltip: 'Chat options',
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: BubColors.purple.withValues(
                        alpha: isDark ? 0.24 : 0.12,
                      ),
                    ),
                  ),
                  color: isDark ? BubColors.darkDialog : BubColors.white,
                  onSelected: (action) {
                    switch (action) {
                      case _ChatHeaderMenuAction.nicknames:
                        _showNicknameDialog(context);
                      case _ChatHeaderMenuAction.images:
                        _openQuickImagesPage(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      key: Key('chat-menu-nicknames'),
                      value: _ChatHeaderMenuAction.nicknames,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.badge_outlined),
                        title: Text('Nicknames'),
                      ),
                    ),
                    PopupMenuItem(
                      key: const Key('chat-menu-images'),
                      value: _ChatHeaderMenuAction.images,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.photo_library_outlined),
                        title: const Text('Images'),
                        subtitle: Text('${quickImages.length} sent'),
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _presenceText(ChatPresenceResponse? presence, DateTime now) {
    if (presence?.status == ChatPresenceResponseStatus.online) {
      return 'Online';
    }
    final lastSeen = presence?.lastSeenAt;
    if (lastSeen != null && shouldShowLastSeen(lastSeen, now)) {
      return 'Last seen ${_timeLabel(lastSeen)}';
    }
    return null;
  }

  String _timeLabel(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _showNicknameDialog(BuildContext context) async {
    final controller = TextEditingController(text: thread.partnerDisplayName);
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (dialogContext) =>
          _NicknameDialog(controller: controller, onSave: onSaveNickname),
    );
  }

  void _openQuickImagesPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _QuickImagesPage(images: quickImages),
      ),
    );
  }
}

enum _ChatHeaderMenuAction { nicknames, images }

class _NicknameDialog extends StatelessWidget {
  const _NicknameDialog({required this.controller, required this.onSave});

  final TextEditingController controller;
  final Future<void> Function(String nickname) onSave;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? BubColors.white : BubColors.textPrimaryLight;
    final softTextColor = isDark
        ? BubColors.textSecondaryDark
        : BubColors.textSecondaryLight;
    final inputFill = isDark
        ? BubColors.darkSurface
        : BubColors.purple.withValues(alpha: 0.04);

    return BubDialogSheet(
      key: const Key('chat-nickname-dialog'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BubDialogHeader(
            icon: Icons.favorite_border_rounded,
            title: 'Nickname',
            subtitle: 'Shown only in your chat.',
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('chat-nickname-field'),
            controller: controller,
            autofocus: true,
            maxLength: 80,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Partner nickname',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              prefixIcon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: BubColors.purple.withValues(alpha: 0.70),
              ),
              counterStyle: TextStyle(color: softTextColor, fontSize: 11),
              filled: true,
              fillColor: inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: BubColors.purple.withValues(alpha: 0.14),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: BubColors.purple.withValues(alpha: 0.14),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: BubColors.purple,
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          BubDialogActions(
            onCancel: () => Navigator.pop(context),
            confirmKey: const Key('chat-nickname-save'),
            confirmLabel: 'Save',
            onConfirm: () async {
              await onSave(controller.text);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MessageList extends ConsumerWidget {
  const _MessageList({
    required this.messages,
    required this.localNotices,
    required this.pendingTextMessages,
    required this.pendingMediaMessages,
    required this.hasMoreBefore,
    required this.onLoadOlder,
  });

  final List<ChatMessageResponse> messages;
  final List<_LocalChatNotice> localNotices;
  final List<_PendingTextMessage> pendingTextMessages;
  final List<_PendingMediaMessage> pendingMediaMessages;
  final bool hasMoreBefore;
  final VoidCallback onLoadOlder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestOutgoingStatusMessageId = _latestOutgoingStatusMessageId();
    final visibleLocalNotices = [
      for (final notice in localNotices)
        if (!_ChatSectionState._localNoticeCoveredByServer(notice, messages))
          notice,
    ];
    final items = [
      for (final message in messages) _ChatTimelineItem.message(message),
      for (final notice in visibleLocalNotices)
        _ChatTimelineItem.notice(notice),
      for (final pendingText in pendingTextMessages)
        _ChatTimelineItem.pendingText(pendingText),
      for (final pendingMedia in pendingMediaMessages)
        _ChatTimelineItem.pendingMedia(pendingMedia),
    ];
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (hasMoreBefore &&
            metrics.axis == Axis.vertical &&
            (metrics.pixels <= metrics.minScrollExtent + 160 ||
                metrics.pixels >= metrics.maxScrollExtent - 160)) {
          onLoadOlder();
        }
        return false;
      },
      child: ListView.separated(
        key: const Key('chat-message-list'),
        reverse: true,
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        itemBuilder: (context, index) {
          final chronologicalIndex = items.length - 1 - index;
          final item = items[chronologicalIndex];
          final notice = item.notice;
          if (notice != null) {
            return _LocalChatNoticeDivider(notice: notice);
          }
          final pendingMedia = item.pendingMedia;
          if (pendingMedia != null) {
            return _MessageBubble(
              message: pendingMedia.toMessageResponse(),
              showDeliveryState: false,
              showSendingState: true,
              onReply: () {},
            );
          }
          final pendingText = item.pendingText;
          if (pendingText != null) {
            return _MessageBubble(
              message: pendingText.toMessageResponse(),
              showDeliveryState: false,
              showSendingState: true,
              onReply: () {},
            );
          }
          final message = item.message!;
          if (message.type == ChatMessageResponseType.bub) {
            return _LocalChatNoticeDivider(
              notice: _LocalChatNotice(
                id: 'bub-${message.id ?? chronologicalIndex}',
                label: message.body ?? 'Bub',
              ),
            );
          }
          if (message.type == ChatMessageResponseType.safeNotice) {
            final count = message.safeItemCount ?? 1;
            return _LocalChatNoticeDivider(
              notice: _LocalChatNotice(
                id: message.id ?? 'safe-notice-$chronologicalIndex',
                label: message.body ?? _safeNoticeLabel(count),
                safeItemCount: count,
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasTimeGapBefore(chronologicalIndex))
                _TimeDivider(message: message),
              _MessageBubble(
                message: message,
                showDeliveryState: message.id == latestOutgoingStatusMessageId,
                onReply: () => context
                    .findAncestorStateOfType<_ChatSectionState>()
                    ?._setReply(message),
              ),
            ],
          );
        },
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemCount: items.length,
      ),
    );
  }

  String? _latestOutgoingStatusMessageId() {
    if (messages.isEmpty) {
      return null;
    }
    final latest = messages.last;
    if (latest.viewerMessage == true && latest.deliveryState != null) {
      return latest.id;
    }
    return null;
  }

  bool _hasTimeGapBefore(int chronologicalIndex) {
    if (chronologicalIndex <= 0) {
      return false;
    }
    final previous = messages[chronologicalIndex - 1].createdAt;
    final current = messages[chronologicalIndex].createdAt;
    if (previous == null || current == null) {
      return false;
    }
    return current.difference(previous) >= const Duration(minutes: 5);
  }
}

class _ChatTimelineItem {
  const _ChatTimelineItem.message(this.message)
    : notice = null,
      pendingText = null,
      pendingMedia = null;

  const _ChatTimelineItem.notice(this.notice)
    : message = null,
      pendingText = null,
      pendingMedia = null;

  const _ChatTimelineItem.pendingText(this.pendingText)
    : message = null,
      notice = null,
      pendingMedia = null;

  const _ChatTimelineItem.pendingMedia(this.pendingMedia)
    : message = null,
      notice = null,
      pendingText = null;

  final ChatMessageResponse? message;
  final _LocalChatNotice? notice;
  final _PendingTextMessage? pendingText;
  final _PendingMediaMessage? pendingMedia;
}

class _PendingTextMessage {
  const _PendingTextMessage({
    required this.id,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String body;
  final DateTime createdAt;

  ChatMessageResponse toMessageResponse() {
    return ChatMessageResponse(
      id: id,
      viewerMessage: true,
      type: ChatMessageResponseType.text,
      body: body,
      createdAt: createdAt,
    );
  }
}

class _PendingMediaMessage {
  const _PendingMediaMessage({
    required this.id,
    required this.files,
    required this.createdAt,
  });

  final String id;
  final List<File> files;
  final DateTime createdAt;

  ChatMessageResponse toMessageResponse() {
    return ChatMessageResponse(
      id: id,
      viewerMessage: true,
      type: ChatMessageResponseType.media,
      createdAt: createdAt,
      attachments: [
        for (final (index, file) in files.indexed)
          ChatAttachmentResponse(
            id: '$id-$index',
            type: _isVideoPath(file.path)
                ? ChatAttachmentResponseType.video
                : ChatAttachmentResponseType.image,
            url: file.path,
          ),
      ],
    );
  }
}

class _LocalChatNoticeDivider extends StatelessWidget {
  const _LocalChatNoticeDivider({required this.notice});

  final _LocalChatNotice notice;

  @override
  Widget build(BuildContext context) {
    if (notice.safeItemCount != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: InkWell(
            key: Key('chat-safe-notice-${notice.id}'),
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const SafeScreen())),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/illustrations/bears/safe-box.png',
                    key: const Key('chat-safe-notice-image'),
                    width: 64,
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notice.label,
                    key: const Key('chat-safe-notice-count'),
                    style: const TextStyle(
                      color: BubColors.textSecondaryLight,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        key: Key('chat-safe-notice-${notice.id}'),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: BubColors.pink.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              notice.label,
              style: const TextStyle(
                color: BubColors.textSecondaryLight,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _safeNoticeLabel(int count) {
  return count == 1 ? '1 file added to Safe' : '$count files added to Safe';
}

class _PendingMediaUploadBubble extends StatefulWidget {
  const _PendingMediaUploadBubble({required this.files});

  final List<File> files;

  @override
  State<_PendingMediaUploadBubble> createState() =>
      _PendingMediaUploadBubbleState();
}

class _PendingMediaUploadBubbleState extends State<_PendingMediaUploadBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.48, end: 0.88).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: DecoratedBox(
          key: const Key('chat-pending-media-upload'),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BubColors.pink.withValues(alpha: 0.30)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (index, file) in widget.files.take(3).indexed) ...[
                  if (index > 0) const SizedBox(width: 5),
                  _PendingMediaUploadTile(file: file),
                ],
                const SizedBox(width: 8),
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingMediaUploadTile extends StatelessWidget {
  const _PendingMediaUploadTile({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    final isVideo = _isVideoPath(file.path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: SizedBox.square(
        dimension: 58,
        child: ColoredBox(
          color: BubColors.deepPurple.withValues(alpha: 0.10),
          child: isVideo
              ? const Icon(
                  Icons.play_circle_fill_rounded,
                  color: BubColors.pink,
                )
              : Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.photo_rounded, color: BubColors.pink),
                ),
        ),
      ),
    );
  }
}

bool _isVideoPath(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.m4v') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.mkv');
}

class _MessageBubble extends ConsumerStatefulWidget {
  const _MessageBubble({
    required this.message,
    required this.showDeliveryState,
    this.showSendingState = false,
    required this.onReply,
  });

  final ChatMessageResponse message;
  final bool showDeliveryState;
  final bool showSendingState;
  final VoidCallback onReply;

  @override
  ConsumerState<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<_MessageBubble> {
  static const _replyTriggerDistance = 56.0;
  var _dragOffset = 0.0;
  var _dragDistance = 0.0;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final mine = message.viewerMessage == true;
    final deleted = message.deletedForEveryone == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bareMessage =
        !deleted &&
        (message.type == ChatMessageResponseType.emoji ||
            message.type == ChatMessageResponseType.media);
    final bubbleColor = mine
        ? BubColors.myBubble
        : (isDark ? BubColors.partnerBubbleDark : BubColors.partnerBubbleLight);
    final textColor = deleted
        ? BubColors.textSecondaryLight
        : mine && !bareMessage
        ? BubColors.white
        : null;
    final reactions = deleted
        ? const <ChatReactionSummaryResponse>[]
        : message.reactions ?? const <ChatReactionSummaryResponse>[];
    final hasReply = message.reply != null;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        key: Key('chat-message-row-${message.id ?? 'unknown'}'),
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _showActions(context, ref),
        onHorizontalDragUpdate: (details) => _handleDragUpdate(details, mine),
        onHorizontalDragEnd: (_) => _finishDrag(),
        onHorizontalDragCancel: _resetDrag,
        child: Stack(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          children: [
            if (_dragDistance > 8)
              Padding(
                padding: EdgeInsets.only(
                  left: mine ? 0 : 10,
                  right: mine ? 10 : 0,
                ),
                child: Opacity(
                  opacity: (_dragDistance / _replyTriggerDistance).clamp(0, 1),
                  child: CircleAvatar(
                    key: Key(
                      'chat-swipe-reply-icon-${message.id ?? 'unknown'}',
                    ),
                    radius: 15,
                    backgroundColor: BubColors.pink.withValues(alpha: 0.12),
                    foregroundColor: BubColors.pink,
                    child: const Icon(Icons.reply_rounded, size: 17),
                  ),
                ),
              ),
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Column(
                crossAxisAlignment: mine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 310),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: reactions.isEmpty ? 0 : 12,
                      ),
                      child: Column(
                        crossAxisAlignment: mine
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasReply)
                            Padding(
                              padding: EdgeInsets.only(
                                left: mine ? 0 : 8,
                                right: mine ? 8 : 0,
                              ),
                              child: _ReplyOverlapPreview(
                                message: message,
                                mine: mine,
                              ),
                            ),
                          Transform.translate(
                            offset: hasReply
                                ? const Offset(0, -1)
                                : Offset.zero,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                DecoratedBox(
                                  key: Key(
                                    'chat-message-bubble-${message.id ?? 'unknown'}',
                                  ),
                                  decoration: BoxDecoration(
                                    color: bareMessage || deleted
                                        ? Colors.transparent
                                        : bubbleColor,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: Radius.circular(
                                        mine ? 20 : 6,
                                      ),
                                      bottomRight: Radius.circular(
                                        mine ? 6 : 20,
                                      ),
                                    ),
                                    border: deleted
                                        ? Border.all(
                                            color: BubColors.textSecondaryLight
                                                .withValues(alpha: 0.34),
                                          )
                                        : (!mine && !isDark
                                              ? Border.all(
                                                  color: BubColors.purple
                                                      .withValues(alpha: 0.10),
                                                )
                                              : null),
                                  ),
                                  child: Padding(
                                    padding: bareMessage
                                        ? EdgeInsets.zero
                                        : const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                    child: _MessageBody(
                                      message: message,
                                      textColor: textColor,
                                      onOpenMedia: (attachments, index) =>
                                          _openMediaViewer(
                                            context,
                                            attachments,
                                            index,
                                          ),
                                    ),
                                  ),
                                ),
                                if (reactions.isNotEmpty)
                                  Positioned(
                                    right: mine ? 7 : null,
                                    left: mine ? null : 7,
                                    bottom: -10,
                                    child: _MessageReactionBadge(
                                      messageId: message.id,
                                      reactions: reactions,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.showSendingState)
                    Padding(
                      key: Key(
                        'chat-sending-indicator-${message.id ?? 'unknown'}',
                      ),
                      padding: const EdgeInsets.only(top: 2, right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox.square(
                            dimension: 10,
                            child: CircularProgressIndicator(strokeWidth: 1.6),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Sending',
                            style: TextStyle(
                              color: BubColors.textSecondaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (widget.showDeliveryState)
                    Padding(
                      key: Key(
                        'chat-delivery-checks-${message.id ?? 'unknown'}',
                      ),
                      padding: const EdgeInsets.only(top: 2, right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            message.deliveryState ==
                                    ChatMessageResponseDeliveryState.seen
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 15,
                            color: BubColors.textSecondaryLight,
                          ),
                          if (message.createdAt != null) ...[
                            const SizedBox(width: 3),
                            Text(
                              _deliveryTimeLabel(message),
                              style: const TextStyle(
                                color: BubColors.textSecondaryLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDragUpdate(DragUpdateDetails details, bool mine) {
    final nextDistance = _dragDistance + (details.delta.dx * (mine ? -1 : 1));
    setState(() {
      _dragDistance = nextDistance.clamp(0, 72).toDouble();
      _dragOffset = _dragDistance * (mine ? -1 : 1);
    });
  }

  void _finishDrag() {
    final shouldReply = _dragDistance >= _replyTriggerDistance;
    _resetDrag();
    if (shouldReply) {
      widget.onReply();
    }
  }

  void _resetDrag() {
    if (_dragDistance == 0 && _dragOffset == 0) {
      return;
    }
    setState(() {
      _dragDistance = 0;
      _dragOffset = 0;
    });
  }

  String _deliveryTimeLabel(ChatMessageResponse message) {
    final createdAt = message.createdAt?.toLocal();
    if (createdAt == null) {
      return '';
    }
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _openMediaViewer(
    BuildContext context,
    List<ChatAttachmentResponse> attachments,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _MediaViewerPage(
          attachments: attachments,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final message = widget.message;
    final id = message.id;
    if (id == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                key: const Key('chat-message-action-sheet'),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: BubColors.deepPurple.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        key: const Key('chat-reaction-row'),
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        children: [
                          for (final reaction in const [
                            '❤️',
                            '😂',
                            '🥺',
                            '😭',
                            '🔥',
                          ])
                            InkWell(
                              onTap: () async {
                                Navigator.of(sheetContext).pop();
                                await ref
                                    .read(chatThreadProvider.notifier)
                                    .reactToMessage(id, reaction);
                              },
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(7),
                                child: Text(
                                  reaction,
                                  style: const TextStyle(fontSize: 27),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      _MessageActionTile(
                        icon: Icons.reply_rounded,
                        label: 'Reply',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          widget.onReply();
                        },
                      ),
                      _MessageActionTile(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete for me',
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          await ref
                              .read(chatThreadProvider.notifier)
                              .deleteForMe(id);
                        },
                      ),
                      if (message.deletableForEveryone == true)
                        _MessageActionTile(
                          icon: Icons.delete_forever_rounded,
                          label: 'Delete for everyone',
                          destructive: true,
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            await ref
                                .read(chatThreadProvider.notifier)
                                .deleteForEveryone(id);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplyOverlapPreview extends StatelessWidget {
  const _ReplyOverlapPreview({required this.message, required this.mine});

  final ChatMessageResponse message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final reply = message.reply!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 248),
      child: DecoratedBox(
        key: Key('chat-reply-overlap-${message.id ?? 'unknown'}'),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: BubColors.pink.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: BubColors.deepPurple.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  reply.deletedForEveryone == true
                      ? 'Original message was deleted'
                      : reply.snippet ?? 'Reply',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: BubColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.message,
    required this.textColor,
    required this.onOpenMedia,
  });

  final ChatMessageResponse message;
  final Color? textColor;
  final void Function(
    List<ChatAttachmentResponse> attachments,
    int initialIndex,
  )
  onOpenMedia;

  @override
  Widget build(BuildContext context) {
    if (message.deletedForEveryone == true) {
      return Text(
        'This message was deleted',
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    if (message.type == ChatMessageResponseType.media) {
      return _MessageMediaContent(
        messageId: message.id,
        attachments: message.attachments ?? const [],
        onOpenMedia: onOpenMedia,
      );
    }
    return Text(
      message.type == ChatMessageResponseType.gif ? 'GIF' : message.body ?? '',
      style: TextStyle(
        color: textColor,
        fontSize: message.type == ChatMessageResponseType.emoji ? 30 : 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _MessageMediaContent extends StatelessWidget {
  const _MessageMediaContent({
    required this.messageId,
    required this.attachments,
    required this.onOpenMedia,
  });

  final String? messageId;
  final List<ChatAttachmentResponse> attachments;
  final void Function(
    List<ChatAttachmentResponse> attachments,
    int initialIndex,
  )
  onOpenMedia;

  @override
  Widget build(BuildContext context) {
    final images = attachments
        .where(
          (attachment) => attachment.type == ChatAttachmentResponseType.image,
        )
        .toList();
    final videos = attachments
        .where(
          (attachment) => attachment.type == ChatAttachmentResponseType.video,
        )
        .toList();
    if (images.isEmpty && videos.isEmpty) {
      return const Text(
        'Media',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty)
          _ImageStackPreview(
            messageId: messageId,
            images: images,
            onTap: () => onOpenMedia(images, 0),
          ),
        for (final (index, video) in videos.indexed) ...[
          if (images.isNotEmpty || index > 0) const SizedBox(height: 6),
          _VideoAttachmentTile(
            key: Key('chat-video-attachment-${video.id ?? index}'),
            attachment: video,
            onTap: () => onOpenMedia([video], 0),
          ),
        ],
      ],
    );
  }
}

class _ImageStackPreview extends StatelessWidget {
  const _ImageStackPreview({
    required this.messageId,
    required this.images,
    required this.onTap,
  });

  final String? messageId;
  final List<ChatAttachmentResponse> images;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final topImage = images.first;
    return GestureDetector(
      key: Key('chat-image-stack-${messageId ?? 'unknown'}'),
      onTap: onTap,
      child: SizedBox(
        width: 206,
        height: images.length == 1 ? 150 : 164,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (images.length > 2)
              Positioned(
                top: 12,
                left: 16,
                child: _ImagePreviewCard(
                  url: images[2].url,
                  opacity: 0.46,
                  rotationTurns: 0.025,
                ),
              ),
            if (images.length > 1)
              Positioned(
                top: 6,
                left: 8,
                child: _ImagePreviewCard(
                  url: images[1].url,
                  opacity: 0.62,
                  rotationTurns: -0.018,
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              child: _ImagePreviewCard(url: topImage.url),
            ),
            if (images.length > 1)
              Positioned(
                right: 8,
                bottom: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.56),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    child: Text(
                      '+${images.length - 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  const _ImagePreviewCard({
    required this.url,
    this.opacity = 1,
    this.rotationTurns = 0,
  });

  final String? url;
  final double opacity;
  final double rotationTurns;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    final colorScheme = Theme.of(context).colorScheme;
    return Transform.rotate(
      angle: rotationTurns,
      child: Opacity(
        opacity: opacity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ColoredBox(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
            child: _previewImage(imageUrl),
          ),
        ),
      ),
    );
  }

  Widget _previewImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const SizedBox(
        width: 198,
        height: 150,
        child: Icon(Icons.photo_rounded),
      );
    }
    if (_isNetworkMediaUrl(imageUrl)) {
      return Image.network(
        imageUrl,
        width: 198,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.photo_rounded),
      );
    }
    return Image.file(
      File(imageUrl),
      width: 198,
      height: 150,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(Icons.photo_rounded),
    );
  }
}

bool _isNetworkMediaUrl(String url) {
  final lower = url.toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

class _VideoAttachmentTile extends StatelessWidget {
  const _VideoAttachmentTile({
    super.key,
    required this.attachment,
    required this.onTap,
  });

  final ChatAttachmentResponse attachment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 206,
        height: 92,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: const Center(
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            foregroundColor: BubColors.pink,
            child: Icon(Icons.play_arrow_rounded, size: 30),
          ),
        ),
      ),
    );
  }
}

class _QuickImagesPage extends StatelessWidget {
  const _QuickImagesPage({required this.images});

  final List<ChatAttachmentResponse> images;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: const Key('chat-quick-images-page'),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? BubColors.pink.withValues(alpha: 0.36)
                        : BubColors.deepPurple.withValues(alpha: 0.10),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('chat-quick-images-back-button'),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Images',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          Text(
                            '${images.length} shared in this tether',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: images.isEmpty
                  ? const Center(
                      child: Icon(Icons.photo_library_outlined, size: 40),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.86,
                          ),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final image = images[index];
                        return _QuickImageTile(
                          key: Key('chat-quick-image-${image.id ?? index}'),
                          image: image,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _MediaViewerPage(
                                attachments: images,
                                initialIndex: index,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickImageTile extends StatelessWidget {
  const _QuickImageTile({super.key, required this.image, required this.onTap});

  final ChatAttachmentResponse image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = image.url;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: url == null || url.isEmpty
              ? const Center(child: Icon(Icons.photo_outlined))
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Center(child: Icon(Icons.photo_outlined)),
                ),
        ),
      ),
    );
  }
}

class _MediaViewerPage extends StatefulWidget {
  const _MediaViewerPage({
    required this.attachments,
    required this.initialIndex,
  });

  final List<ChatAttachmentResponse> attachments;
  final int initialIndex;

  @override
  State<_MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<_MediaViewerPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('chat-media-viewer'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.attachments.length,
        itemBuilder: (context, index) {
          final attachment = widget.attachments[index];
          if (attachment.type == ChatAttachmentResponseType.video) {
            return _VideoViewer(attachment: attachment);
          }
          final url = attachment.url;
          if (url == null || url.isEmpty) {
            return const Center(
              child: Icon(Icons.broken_image_rounded, color: Colors.white),
            );
          }
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image_rounded, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VideoViewer extends StatefulWidget {
  const _VideoViewer({required this.attachment});

  final ChatAttachmentResponse attachment;

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  VideoPlayerController? _controller;
  Future<void>? _initialize;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void didUpdateWidget(_VideoViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.url != widget.attachment.url) {
      _controller?.dispose();
      _loadVideo();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _loadVideo() {
    final url = widget.attachment.url;
    if (url == null || url.isEmpty) {
      _controller = null;
      _initialize = null;
      return;
    }
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;
    _initialize = controller.initialize().then((_) {
      controller.play();
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final initialize = _initialize;
    if (controller == null || initialize == null) {
      return const Center(
        child: Icon(Icons.videocam_off_rounded, color: Colors.white, size: 54),
      );
    }
    return FutureBuilder<void>(
      future: initialize,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            key: Key('chat-video-loading'),
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (snapshot.hasError || !controller.value.isInitialized) {
          return const Center(
            key: Key('chat-video-error'),
            child: Text(
              'Video could not load',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }
        return Center(
          child: GestureDetector(
            key: const Key('chat-video-player'),
            onTap: () {
              setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
                if (!controller.value.isPlaying)
                  const CircleAvatar(
                    radius: 31,
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.play_arrow_rounded, size: 42),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageActionTile extends StatelessWidget {
  const _MessageActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageReactionBadge extends StatelessWidget {
  const _MessageReactionBadge({
    required this.messageId,
    required this.reactions,
  });

  final String? messageId;
  final List<ChatReactionSummaryResponse> reactions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: Key('chat-message-reactions-${messageId ?? 'unknown'}'),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: BubColors.deepPurple.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final reaction in reactions)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Text(
                  '${reaction.reaction ?? ''} ${reaction.count ?? 0}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeDivider extends StatelessWidget {
  const _TimeDivider({required this.message});

  final ChatMessageResponse message;

  @override
  Widget build(BuildContext context) {
    final createdAt = message.createdAt;
    if (createdAt == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      key: Key('chat-time-divider-${message.id ?? 'unknown'}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _TimeDividerLine(
            key: Key(
              'chat-time-divider-leading-line-${message.id ?? 'unknown'}',
            ),
          ),
          const SizedBox(width: 7),
          DecoratedBox(
            decoration: BoxDecoration(
              color: BubColors.deepPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Text(
                _timeLabel(createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: BubColors.textSecondaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          _TimeDividerLine(
            key: Key(
              'chat-time-divider-trailing-line-${message.id ?? 'unknown'}',
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TimeDividerLine extends StatelessWidget {
  const _TimeDividerLine({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 42,
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark
            ? BubColors.pink.withValues(alpha: 0.44)
            : BubColors.deepPurple.withValues(alpha: 0.14),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.replyTo,
    required this.inlineMedia,
    required this.sendToSafe,
    required this.showInlineMediaPicker,
    required this.inlineMediaExpanded,
    required this.inlineMediaLoading,
    required this.maxInlineMediaGridHeight,
    required this.stagedMedia,
    required this.stagedMediaIds,
    required this.canSend,
    required this.onCancelReply,
    required this.onSend,
    required this.onAttachment,
    required this.onSendToSafeChanged,
    required this.onInlineMediaSelected,
    required this.onToggleInlineMediaExpanded,
    required this.onRemoveStagedMedia,
    required this.onQuickReaction,
    required this.onToggleEmojiPicker,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ChatMessageResponse? replyTo;
  final List<ChatMediaItem> inlineMedia;
  final bool sendToSafe;
  final bool showInlineMediaPicker;
  final bool inlineMediaExpanded;
  final bool inlineMediaLoading;
  final double maxInlineMediaGridHeight;
  final List<File> stagedMedia;
  final Set<String> stagedMediaIds;
  final bool canSend;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;
  final VoidCallback onAttachment;
  final ValueChanged<bool> onSendToSafeChanged;
  final ValueChanged<ChatMediaItem> onInlineMediaSelected;
  final VoidCallback onToggleInlineMediaExpanded;
  final ValueChanged<int> onRemoveStagedMedia;
  final VoidCallback onQuickReaction;
  final VoidCallback onToggleEmojiPicker;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark
              ? BubColors.darkCard.withValues(alpha: 0.96)
              : BubColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: BubColors.purple.withValues(alpha: isDark ? 0.28 : 0.14),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (replyTo != null)
                Container(
                  key: const Key('chat-reply-preview'),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: BubColors.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          replyTo!.body ?? 'Replying to message',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onCancelReply,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  _ComposerActionSlot(
                    visible: true,
                    child: IconButton(
                      key: const Key('chat-emoji-button'),
                      onPressed: onToggleEmojiPicker,
                      icon: const Icon(Icons.emoji_emotions_outlined),
                    ),
                  ),
                  _ComposerActionSlot(
                    visible: true,
                    child: IconButton(
                      key: const Key('chat-attachment-button'),
                      onPressed: onAttachment,
                      icon: const Icon(Icons.attach_file_rounded),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      key: const Key('chat-composer-field'),
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Say something cute…',
                        hintStyle: TextStyle(
                          color: isDark
                              ? BubColors.textHintDark
                              : BubColors.textHintLight,
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  _ComposerActionSlot(
                    visible: true,
                    child: canSend
                        ? IconButton(
                            key: const Key('chat-send-button'),
                            onPressed: onSend,
                            style: IconButton.styleFrom(
                              backgroundColor: BubColors.purple,
                              foregroundColor: BubColors.white,
                              disabledBackgroundColor: BubColors.purple
                                  .withValues(alpha: 0.42),
                            ),
                            icon: const Icon(Icons.send_rounded),
                          )
                        : IconButton(
                            key: const Key('chat-quick-reaction-button'),
                            onPressed: onQuickReaction,
                            icon: const Text(
                              '❤️',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                  ),
                ],
              ),
              if (showInlineMediaPicker) ...[
                const SizedBox(height: 7),
                _InlineMediaPicker(
                  items: inlineMedia,
                  sendToSafe: sendToSafe,
                  selectedItemIds: stagedMediaIds,
                  expanded: inlineMediaExpanded,
                  loading: inlineMediaLoading,
                  maxGridHeight: maxInlineMediaGridHeight,
                  onSendToSafeChanged: onSendToSafeChanged,
                  onSelected: onInlineMediaSelected,
                  onToggleExpanded: onToggleInlineMediaExpanded,
                ),
              ],
              if (stagedMedia.isNotEmpty) ...[
                const SizedBox(height: 7),
                _StagedMediaTray(
                  files: stagedMedia,
                  onRemove: onRemoveStagedMedia,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineMediaPicker extends StatelessWidget {
  const _InlineMediaPicker({
    required this.items,
    required this.sendToSafe,
    required this.selectedItemIds,
    required this.expanded,
    required this.loading,
    required this.maxGridHeight,
    required this.onSendToSafeChanged,
    required this.onSelected,
    required this.onToggleExpanded,
  });

  final List<ChatMediaItem> items;
  final bool sendToSafe;
  final Set<String> selectedItemIds;
  final bool expanded;
  final bool loading;
  final double maxGridHeight;
  final ValueChanged<bool> onSendToSafeChanged;
  final ValueChanged<ChatMediaItem> onSelected;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softText = isDark
        ? BubColors.textSecondaryDark
        : BubColors.textSecondaryLight;
    final gridHeight = _gridHeightFor(context);
    return DecoratedBox(
      key: const Key('chat-inline-media-picker'),
      decoration: BoxDecoration(
        color: isDark
            ? BubColors.darkCard.withValues(alpha: 0.92)
            : BubColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BubColors.purple.withValues(alpha: isDark ? 0.28 : 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 18,
                  color: BubColors.purple.withValues(alpha: 0.78),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recents',
                    style: TextStyle(
                      color: isDark
                          ? BubColors.white
                          : BubColors.textPrimaryLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _SafeUploadToggle(
                  value: sendToSafe,
                  onChanged: onSendToSafeChanged,
                ),
                if (!loading && items.isNotEmpty)
                  IconButton(
                    key: const Key('chat-inline-media-expand-button'),
                    visualDensity: VisualDensity.compact,
                    tooltip: expanded ? 'Collapse gallery' : 'Expand gallery',
                    onPressed: onToggleExpanded,
                    icon: Icon(
                      expanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      color: softText,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              key: const Key('chat-inline-media-grid-frame'),
              height: gridHeight,
              child: loading
                  ? const Center(
                      key: Key('chat-inline-media-loading'),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: BubColors.purple,
                        ),
                      ),
                    )
                  : items.isEmpty
                  ? Center(
                      key: const Key('chat-inline-media-empty'),
                      child: Text(
                        'No photos yet',
                        style: TextStyle(
                          color: softText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : GridView.builder(
                      key: const Key('chat-inline-media-grid'),
                      padding: EdgeInsets.zero,
                      cacheExtent: 240,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 5,
                            crossAxisSpacing: 5,
                          ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final selected = selectedItemIds.contains(item.id);
                        return _InlineMediaItem(
                          key: Key('chat-inline-media-item-${item.id}'),
                          item: item,
                          selected: selected,
                          onTap: () => onSelected(item),
                        );
                      },
                      itemCount: items.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _gridHeightFor(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final desiredHeight = expanded ? mediaQuery.size.height * 0.54 : 220.0;
    final upperBound = math.max(96.0, maxGridHeight);
    final lowerBound = math.min(120.0, upperBound);
    return desiredHeight.clamp(lowerBound, upperBound).toDouble();
  }
}

class _SafeUploadToggle extends StatelessWidget {
  const _SafeUploadToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('chat-inline-media-safe-toggle'),
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: value
                ? BubColors.purple
                : BubColors.purple.withValues(alpha: isDark ? 0.16 : 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: BubColors.purple.withValues(
                alpha: value ? 0.0 : (isDark ? 0.28 : 0.14),
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 14,
                color: value
                    ? BubColors.white
                    : BubColors.purple.withValues(alpha: 0.86),
              ),
              const SizedBox(width: 5),
              Text(
                'Safe',
                style: TextStyle(
                  color: value
                      ? BubColors.white
                      : (isDark
                            ? BubColors.textSecondaryDark
                            : BubColors.textSecondaryLight),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineMediaItem extends StatelessWidget {
  const _InlineMediaItem({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ChatMediaItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ColoredBox(
                  color: BubColors.purple.withValues(alpha: 0.06),
                  child: _InlineMediaThumbnail(item: item),
                ),
              ),
            ),
            if (item.isVideo)
              const Positioned(
                left: 6,
                bottom: 6,
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: BubColors.white,
                  size: 22,
                ),
              ),
            if (selected)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BubColors.purple.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BubColors.purple, width: 2),
                  ),
                ),
              ),
            if (selected)
              const Positioned(
                top: 6,
                right: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BubColors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: BubColors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineMediaThumbnail extends StatefulWidget {
  const _InlineMediaThumbnail({required this.item});

  final ChatMediaItem item;

  @override
  State<_InlineMediaThumbnail> createState() => _InlineMediaThumbnailState();
}

class _InlineMediaThumbnailState extends State<_InlineMediaThumbnail> {
  static final Map<String, Uint8List> _cache = {};
  late Future<Object?> _thumbnail;

  @override
  void initState() {
    super.initState();
    _thumbnail = _load();
  }

  @override
  void didUpdateWidget(_InlineMediaThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _thumbnail = _load();
    }
  }

  Future<Object?> _load() async {
    final cached = _cache[widget.item.id];
    if (cached != null) {
      return cached;
    }
    final bytes = await widget.item.loadThumbnail();
    if (bytes != null) {
      _cache[widget.item.id] = bytes;
    }
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _thumbnail,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes is Uint8List) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
          );
        }
        final file = widget.item.file;
        if (file != null) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
            errorBuilder: (_, _, _) =>
                const Center(child: Icon(Icons.photo_rounded)),
          );
        }
        return const Center(
          child: SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: BubColors.purple,
            ),
          ),
        );
      },
    );
  }
}

class _StagedMediaTray extends StatelessWidget {
  const _StagedMediaTray({required this.files, required this.onRemove});

  final List<File> files;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('chat-staged-media-tray'),
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
        itemBuilder: (context, index) {
          final file = files[index];
          return _StagedMediaPreview(
            key: Key('chat-staged-media-$index'),
            file: file,
            index: index,
            onRemove: onRemove,
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: files.length,
      ),
    );
  }
}

class _StagedMediaPreview extends StatelessWidget {
  const _StagedMediaPreview({
    super.key,
    required this.file,
    required this.index,
    required this.onRemove,
  });

  final File file;
  final int index;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isVideo = _isVideoPath(file.path);
    return SizedBox(
      width: 66,
      height: 66,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: isVideo
                    ? const Center(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          color: BubColors.pink,
                          size: 30,
                        ),
                      )
                    : Image.file(
                        file,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Center(child: Icon(Icons.photo_rounded)),
                      ),
              ),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: InkWell(
              key: Key('chat-staged-media-remove-$index'),
              onTap: () => onRemove(index),
              borderRadius: BorderRadius.circular(999),
              child: const CircleAvatar(
                radius: 11,
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                child: Icon(Icons.close_rounded, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isVideoPath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv');
  }
}

class _ComposerActionSlot extends StatelessWidget {
  const _ComposerActionSlot({required this.visible, this.child});

  final bool visible;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 40,
      child: IgnorePointer(
        ignoring: !visible,
        child: Opacity(
          opacity: visible ? 1 : 0,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
