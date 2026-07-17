import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/generated/models/chat_message_response.dart';
import '../../api/generated/models/chat_message_response_delivery_state.dart';
import '../../api/generated/models/chat_message_response_type.dart';
import '../../api/generated/models/chat_presence_response.dart';
import '../../api/generated/models/chat_presence_response_status.dart';
import '../../api/generated/models/chat_send_message_request_type.dart';
import '../../api/generated/models/chat_thread_response.dart';
import '../../features/tether_onboarding/tether_onboarding_screens.dart';
import '../../theme/bub_colors.dart';
import 'chat_controller.dart';

class ChatSection extends ConsumerStatefulWidget {
  const ChatSection({super.key});

  @override
  ConsumerState<ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends ConsumerState<ChatSection> {
  final _composer = TextEditingController();
  ChatMessageResponse? _replyTo;

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(chatThreadProvider);
    return thread.when(
      loading: () => const Center(
        child: Padding(
          key: Key('chat-loading'),
          padding: EdgeInsets.only(bottom: 132),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 132),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chat could not load',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('chat-retry-button'),
                onPressed: () =>
                    ref.read(chatThreadProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        if (data.hasActiveTether != true) {
          return const _UntetheredChatEmptyState();
        }
        return Column(
          children: [
            _ChatHeader(thread: data),
            Expanded(child: _MessageList(messages: data.messages ?? const [])),
            _ChatComposer(
              controller: _composer,
              replyTo: _replyTo,
              onCancelReply: () => setState(() => _replyTo = null),
              onSend: _sendText,
              onSendEmoji: () => _sendEmoji('❤️'),
              onSendGif: _sendGif,
            ),
            const SizedBox(height: 112),
          ],
        );
      },
    );
  }

  Future<void> _sendText() async {
    final text = _composer.text.trim();
    if (text.isEmpty) {
      return;
    }
    _composer.clear();
    final replyId = _replyTo?.id;
    setState(() => _replyTo = null);
    await ref
        .read(chatThreadProvider.notifier)
        .sendMessage(
          type: ChatSendMessageRequestType.text,
          body: text,
          replyToMessageId: replyId,
        );
  }

  Future<void> _sendEmoji(String emoji) async {
    final replyId = _replyTo?.id;
    setState(() => _replyTo = null);
    await ref
        .read(chatThreadProvider.notifier)
        .sendMessage(
          type: ChatSendMessageRequestType.emoji,
          body: emoji,
          replyToMessageId: replyId,
        );
  }

  Future<void> _sendGif() async {
    final url = await showDialog<String>(
      context: context,
      builder: (context) => const _GifUrlDialog(),
    );
    if (url == null || url.trim().isEmpty) {
      return;
    }
    final replyId = _replyTo?.id;
    setState(() => _replyTo = null);
    await ref
        .read(chatThreadProvider.notifier)
        .sendMessage(
          type: ChatSendMessageRequestType.gif,
          gifUrl: url,
          gifProviderId: url,
          replyToMessageId: replyId,
        );
  }

  void _setReply(ChatMessageResponse message) {
    setState(() => _replyTo = message);
  }
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
  const _ChatHeader({required this.thread});

  final ChatThreadResponse thread;

  @override
  Widget build(BuildContext context) {
    final partner = thread.partnerDisplayName?.trim();
    final typing = thread.state?.partnerTyping == true;
    final presence = thread.state?.partnerPresence;
    final status = _presenceText(presence);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: BubColors.pink.withValues(alpha: 0.16),
            foregroundColor: BubColors.pink,
            child: const Icon(Icons.favorite_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner == null || partner.isEmpty ? 'Your Bub' : partner,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  status,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (typing)
                  const Text(
                    'Typing...',
                    style: TextStyle(
                      color: BubColors.pink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _presenceText(ChatPresenceResponse? presence) {
    if (presence?.status == ChatPresenceResponseStatus.online) {
      return 'Online';
    }
    final lastSeen = presence?.lastSeenAt;
    if (lastSeen != null) {
      return 'Last seen ${_timeLabel(lastSeen)}';
    }
    return 'Offline';
  }

  String _timeLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _MessageList extends ConsumerWidget {
  const _MessageList({required this.messages});

  final List<ChatMessageResponse> messages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return _MessageBubble(
          message: message,
          onReply: () => context
              .findAncestorStateOfType<_ChatSectionState>()
              ?._setReply(message),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemCount: messages.length,
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({required this.message, required this.onReply});

  final ChatMessageResponse message;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = message.viewerMessage == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = mine
        ? BubColors.myBubble
        : (isDark ? BubColors.partnerBubbleDark : BubColors.partnerBubbleLight);
    final textColor = mine ? BubColors.white : null;

    return Align(
      key: Key('chat-message-row-${message.id ?? 'unknown'}'),
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 310),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!mine)
              IconButton(
                key: Key('chat-message-actions-${message.id ?? 'unknown'}'),
                onPressed: () => _showActions(context, ref),
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            Flexible(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.reply != null) ...[
                        Text(
                          message.reply!.snippet ?? 'Reply',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: mine
                                ? BubColors.white.withValues(alpha: 0.78)
                                : BubColors.textSecondaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        _messageText(message),
                        style: TextStyle(
                          color: textColor,
                          fontSize:
                              message.type == ChatMessageResponseType.emoji
                              ? 30
                              : 16,
                          fontStyle: message.deletedForEveryone == true
                              ? FontStyle.italic
                              : FontStyle.normal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((message.reactions ?? const []).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (final reaction in message.reactions!)
                              Text(
                                '${reaction.reaction ?? ''} ${reaction.count ?? 0}',
                                style: TextStyle(color: textColor),
                              ),
                          ],
                        ),
                      ],
                      if (mine && message.deliveryState != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _deliveryText(message.deliveryState),
                          style: TextStyle(
                            color: BubColors.white.withValues(alpha: 0.72),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (mine)
              IconButton(
                key: Key('chat-message-actions-${message.id ?? 'unknown'}'),
                onPressed: () => _showActions(context, ref),
                icon: const Icon(Icons.more_horiz_rounded),
              ),
          ],
        ),
      ),
    );
  }

  String _messageText(ChatMessageResponse message) {
    if (message.deletedForEveryone == true) {
      return 'This message was deleted';
    }
    if (message.type == ChatMessageResponseType.gif) {
      return 'GIF';
    }
    return message.body ?? '';
  }

  String _deliveryText(ChatMessageResponseDeliveryState? state) {
    return switch (state) {
      ChatMessageResponseDeliveryState.seen => 'Seen',
      ChatMessageResponseDeliveryState.delivered => 'Delivered',
      _ => 'Sent',
    };
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final id = message.id;
    if (id == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.reply_rounded),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onReply();
                  },
                ),
                if (message.editable == true)
                  ListTile(
                    leading: const Icon(Icons.edit_rounded),
                    title: const Text('Edit'),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      final body = await showDialog<String>(
                        context: context,
                        builder: (_) => _EditMessageDialog(body: message.body),
                      );
                      if (body != null) {
                        await ref
                            .read(chatThreadProvider.notifier)
                            .editMessage(id, body);
                      }
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Delete for me'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await ref.read(chatThreadProvider.notifier).deleteForMe(id);
                  },
                ),
                if (message.deletableForEveryone == true)
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded),
                    title: const Text('Delete for everyone'),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await ref
                          .read(chatThreadProvider.notifier)
                          .deleteForEveryone(id);
                    },
                  ),
                const Divider(),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final reaction in const ['❤️', '😂', '🥺', '😭', '🔥'])
                      ActionChip(
                        label: Text(reaction),
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await ref
                              .read(chatThreadProvider.notifier)
                              .reactToMessage(id, reaction);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.replyTo,
    required this.onCancelReply,
    required this.onSend,
    required this.onSendEmoji,
    required this.onSendGif,
  });

  final TextEditingController controller;
  final ChatMessageResponse? replyTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;
  final VoidCallback onSendEmoji;
  final VoidCallback onSendGif;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: BubColors.deepPurple.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
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
                    color: BubColors.pink.withValues(alpha: 0.10),
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
                  IconButton(
                    key: const Key('chat-emoji-button'),
                    onPressed: onSendEmoji,
                    icon: const Icon(Icons.favorite_rounded),
                  ),
                  IconButton(
                    key: const Key('chat-gif-button'),
                    onPressed: onSendGif,
                    icon: const Icon(Icons.gif_box_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      key: const Key('chat-composer-field'),
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  IconButton.filled(
                    key: const Key('chat-send-button'),
                    onPressed: onSend,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditMessageDialog extends StatefulWidget {
  const _EditMessageDialog({this.body});

  final String? body;

  @override
  State<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<_EditMessageDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.body);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit message'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 1,
        maxLines: 4,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _GifUrlDialog extends StatefulWidget {
  const _GifUrlDialog();

  @override
  State<_GifUrlDialog> createState() => _GifUrlDialogState();
}

class _GifUrlDialogState extends State<_GifUrlDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send GIF'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'GIF URL'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Send'),
        ),
      ],
    );
  }
}
