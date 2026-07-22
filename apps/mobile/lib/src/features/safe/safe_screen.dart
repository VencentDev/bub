import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/async_state_widgets.dart';
import '../../l10n/app_strings.dart';
import '../../theme/bub_colors.dart';
import 'safe_controller.dart';
import 'widgets/safe_delete_confirmation.dart';
import 'widgets/safe_gallery_grid.dart';
import 'widgets/safe_media_viewer.dart';

class SafeScreen extends ConsumerWidget {
  const SafeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(safeControllerProvider);
    final session = ref.watch(safeSessionProvider);

    return Scaffold(
      key: const Key('safe-screen'),
      body: status.when(
        loading: () => const BubLoadingState(
          key: Key('safe-loading'),
          label: 'Loading Safe',
        ),
        error: (_, _) => SafeArea(
          child: BubErrorState(
            key: const Key('safe-error-state'),
            title: 'Safe could not load',
            onRetry: () => ref.invalidate(safeControllerProvider),
            retryKey: const Key('safe-retry-button'),
          ),
        ),
        data: (value) {
          if (!value.tethered) {
            return const _SafeLockedState(
              title: 'Tether to unlock Safe',
              subtitle:
                  'Safe becomes available after you tether with your person.',
            );
          }
          if (session.unlocked) {
            return const _SafeUnlockedState();
          }
          if (!value.pinConfigured) {
            return const _SafeFirstTimeSetupState();
          }
          return _SafePinFlow(pinConfigured: value.pinConfigured);
        },
      ),
    );
  }
}

class _SafeLockedState extends StatelessWidget {
  const _SafeLockedState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 132),
              child: Column(
                key: const Key('safe-locked-state'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/illustrations/bears/safe-box.png',
                    key: const Key('safe-box-image'),
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _SafeContextBackButton(),
        ],
      ),
    );
  }
}

class _SafeFirstTimeSetupState extends ConsumerWidget {
  const _SafeFirstTimeSetupState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 132),
              child: Column(
                key: const Key('safe-first-time-setup'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/illustrations/bears/safe-box.png',
                    key: const Key('safe-box-image'),
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    strings.setUpSafe,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.createSafePinSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const Key('safe-setup-open'),
                    onPressed: () => _showSetupDialog(context, ref),
                    icon: const Icon(Icons.add_moderator_rounded),
                    label: Text(strings.setPin),
                  ),
                ],
              ),
            ),
          ),
          const _SafeContextBackButton(),
        ],
      ),
    );
  }

  Future<void> _showSetupDialog(BuildContext context, WidgetRef ref) async {
    final pin = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (_) => const _SafeSetupPinDialog(),
    );
    if (pin == null || !context.mounted) {
      return;
    }
    try {
      await ref.read(safeControllerProvider.notifier).setupPin(pin);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't set your Safe PIN.")),
        );
      }
    }
  }
}

class _SafeSetupPinDialog extends StatefulWidget {
  const _SafeSetupPinDialog();

  @override
  State<_SafeSetupPinDialog> createState() => _SafeSetupPinDialogState();
}

class _SafeSetupPinDialogState extends State<_SafeSetupPinDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  bool get _canSubmit {
    return RegExp(r'^\d{4,6}$').hasMatch(_pinController.text) &&
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
    final panelColor = (isDark ? BubColors.darkDialog : BubColors.white)
        .withValues(alpha: isDark ? 0.74 : 0.70);
    final textColor = isDark ? BubColors.white : BubColors.textPrimaryLight;
    final softTextColor = isDark
        ? BubColors.textSecondaryDark
        : BubColors.textSecondaryLight;
    final inputFill = (isDark ? BubColors.darkSurface : BubColors.white)
        .withValues(alpha: isDark ? 0.58 : 0.72);

    return Dialog(
      key: const Key('safe-setup-dialog'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -26,
            right: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    BubColors.pink.withValues(alpha: isDark ? 0.42 : 0.25),
                    BubColors.pink.withValues(alpha: 0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(width: 126, height: 126),
            ),
          ),
          Positioned(
            bottom: -28,
            left: -10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    BubColors.violet.withValues(alpha: isDark ? 0.34 : 0.23),
                    BubColors.violet.withValues(alpha: 0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(width: 118, height: 118),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: panelColor,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            BubColors.white.withValues(alpha: 0.10),
                            BubColors.darkDialog.withValues(alpha: 0.70),
                            BubColors.pink.withValues(alpha: 0.12),
                          ]
                        : [
                            BubColors.white.withValues(alpha: 0.78),
                            const Color(0xFFFFF4FA).withValues(alpha: 0.64),
                            const Color(0xFFF5EEFF).withValues(alpha: 0.72),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: BubColors.white.withValues(
                      alpha: isDark ? 0.14 : 0.72,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BubColors.deepPurple.withValues(
                        alpha: isDark ? 0.42 : 0.16,
                      ),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: BubColors.pink.withValues(
                        alpha: isDark ? 0.18 : 0.12,
                      ),
                      blurRadius: 36,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: BubColors.bubGradient,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: BubColors.pink.withValues(alpha: 0.28),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_moderator_rounded,
                              color: BubColors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Set a PIN for your Safe',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Your PIN is private to you.',
                                  style: TextStyle(
                                    color: softTextColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Close',
                            icon: const Icon(Icons.close_rounded),
                            color: softTextColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _SafePinField(
                        fieldKey: const Key('safe-pin-entry'),
                        controller: _pinController,
                        label: 'PIN',
                        icon: Icons.lock_rounded,
                        inputFill: inputFill,
                        softTextColor: softTextColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _SafePinField(
                        fieldKey: const Key('safe-pin-confirm-entry'),
                        controller: _confirmController,
                        label: 'Confirm PIN',
                        icon: Icons.verified_user_rounded,
                        inputFill: inputFill,
                        softTextColor: softTextColor,
                        isDark: isDark,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          key: const Key('safe-pin-error'),
                          style: const TextStyle(
                            color: BubColors.coral,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: softTextColor,
                                side: BorderSide(
                                  color: BubColors.white.withValues(
                                    alpha: isDark ? 0.12 : 0.58,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _canSubmit
                                    ? null
                                    : BubColors.white.withValues(
                                        alpha: isDark ? 0.10 : 0.54,
                                      ),
                                gradient: _canSubmit
                                    ? BubColors.bubGradient
                                    : null,
                                borderRadius: BorderRadius.circular(18),
                                border: _canSubmit
                                    ? null
                                    : Border.all(
                                        color: BubColors.pink.withValues(
                                          alpha: isDark ? 0.16 : 0.22,
                                        ),
                                      ),
                                boxShadow: [
                                  BoxShadow(
                                    color: BubColors.pink.withValues(
                                      alpha: _canSubmit ? 0.28 : 0.08,
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: FilledButton(
                                key: const Key('safe-pin-submit'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                  disabledBackgroundColor: Colors.transparent,
                                  disabledForegroundColor: softTextColor
                                      .withValues(alpha: 0.72),
                                ),
                                onPressed: _canSubmit ? _submit : null,
                                child: const Text('Set PIN'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final pin = _pinController.text;
    if (pin != _confirmController.text) {
      setState(() => _error = 'PINs do not match');
      return;
    }
    Navigator.of(context).pop(pin);
  }

  void _onChanged() {
    setState(() => _error = null);
  }
}

class _SafePinField extends StatelessWidget {
  const _SafePinField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.icon,
    required this.inputFill,
    required this.softTextColor,
    required this.isDark,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color inputFill;
  final Color softTextColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: BubColors.pink.withValues(alpha: 0.78)),
        fillColor: inputFill,
        filled: true,
        labelStyle: TextStyle(color: softTextColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: BubColors.white.withValues(alpha: isDark ? 0.10 : 0.62),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: BubColors.white.withValues(alpha: isDark ? 0.10 : 0.62),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: BubColors.pink, width: 1.5),
        ),
      ),
    );
  }
}

class _SafePinFlow extends ConsumerStatefulWidget {
  const _SafePinFlow({required this.pinConfigured});

  final bool pinConfigured;

  @override
  ConsumerState<_SafePinFlow> createState() => _SafePinFlowState();
}

class _SafePinFlowState extends ConsumerState<_SafePinFlow> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  var _submitting = false;
  String? _error;

  bool get _validPin => RegExp(r'^\d{4,6}$').hasMatch(_pinController.text);

  bool get _canSubmit {
    if (_submitting || !_validPin) {
      return false;
    }
    return widget.pinConfigured ||
        RegExp(r'^\d{4,6}$').hasMatch(_confirmController.text);
  }

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_onPinChanged);
    _confirmController.addListener(_onPinChanged);
  }

  @override
  void dispose() {
    _pinController.removeListener(_onPinChanged);
    _confirmController.removeListener(_onPinChanged);
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final title = widget.pinConfigured
        ? strings.unlockSafe
        : strings.createSafePin;
    final subtitle = widget.pinConfigured
        ? strings.safeUnlockSubtitle
        : strings.safeCreatePinSubtitle;
    final canPop = Navigator.canPop(context);

    return SafeArea(
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(24, canPop ? 72 : 24, 24, 150),
            children: [
              Column(
                key: const Key('safe-locked-state'),
                children: [
                  Image.asset(
                    'assets/illustrations/bears/safe-box.png',
                    key: const Key('safe-box-image'),
                    width: 142,
                    height: 142,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                key: const Key('safe-pin-entry'),
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: 'PIN',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  errorText: _error == null ? null : '',
                ),
              ),
              if (!widget.pinConfigured) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const Key('safe-pin-confirm-entry'),
                  controller: _confirmController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Confirm PIN',
                    prefixIcon: Icon(Icons.verified_user_rounded),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  key: const Key('safe-pin-error'),
                  style: const TextStyle(
                    color: BubColors.coral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _canSubmit
                      ? null
                      : BubColors.white.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.10
                              : 0.54,
                        ),
                  gradient: _canSubmit ? BubColors.bubGradient : null,
                  borderRadius: BorderRadius.circular(18),
                  border: _canSubmit
                      ? null
                      : Border.all(
                          color: BubColors.pink.withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
                                ? 0.16
                                : 0.22,
                          ),
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: BubColors.pink.withValues(
                        alpha: _canSubmit ? 0.28 : 0.08,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  key: const Key('safe-pin-submit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: Theme.of(
                      context,
                    ).hintColor.withValues(alpha: 0.72),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _canSubmit ? _submit : null,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open_rounded),
                  label: Text(title),
                ),
              ),
            ],
          ),
          const _SafeContextBackButton(),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final pin = _pinController.text;
    if (!widget.pinConfigured && pin != _confirmController.text) {
      setState(() => _error = 'PINs do not match');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (widget.pinConfigured) {
        await ref.read(safeControllerProvider.notifier).unlock(pin);
      } else {
        await ref.read(safeControllerProvider.notifier).setupPin(pin);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Invalid Safe PIN');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _onPinChanged() {
    if (!mounted) {
      return;
    }
    setState(() => _error = null);
  }
}

class _SafeUnlockedState extends ConsumerStatefulWidget {
  const _SafeUnlockedState();

  @override
  ConsumerState<_SafeUnlockedState> createState() => _SafeUnlockedStateState();
}

class _SafeContextBackButton extends StatelessWidget {
  const _SafeContextBackButton({this.inline = false});

  final bool inline;

  @override
  Widget build(BuildContext context) {
    if (!Navigator.canPop(context)) {
      return const SizedBox.shrink();
    }

    final button = IconButton(
      key: const Key('safe-back-button'),
      tooltip: 'Back',
      onPressed: () => Navigator.maybePop(context),
      icon: const Icon(Icons.arrow_back_rounded),
      style: IconButton.styleFrom(
        backgroundColor: BubColors.white.withValues(alpha: 0.72),
        foregroundColor: BubColors.textPrimaryLight,
        shadowColor: BubColors.pink.withValues(alpha: 0.18),
        elevation: 8,
        fixedSize: const Size.square(42),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );

    if (inline) {
      return Padding(padding: const EdgeInsets.only(right: 8), child: button);
    }

    return Positioned(top: 12, left: 12, child: button);
  }
}

class _SafeUnlockedStateState extends ConsumerState<_SafeUnlockedState> {
  late Future<List<SafeMediaItem>> _mediaFuture;
  var _items = const <SafeMediaItem>[];
  int? _selectedIndex;
  String? _deleteError;
  var _deleting = false;

  @override
  void initState() {
    super.initState();
    _mediaFuture = _loadMedia();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<SafeMediaItem>>(
        future: _mediaFuture,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState != ConnectionState.done;
          final error = snapshot.hasError;
          return Stack(
            key: const Key('safe-unlocked-state'),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: Row(
                      children: [
                        const _SafeContextBackButton(inline: true),
                        const Icon(Icons.lock_open_rounded, size: 28),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Safe',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          key: const Key('safe-lock-toggle'),
                          onPressed: () =>
                              ref.read(safeSessionProvider.notifier).lock(),
                          icon: const Icon(Icons.lock_open_rounded, size: 18),
                          label: const Text('Unlocked'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BubColors.pink,
                            side: BorderSide(
                              color: BubColors.pink.withValues(alpha: 0.34),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_deleteError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        _deleteError!,
                        style: const TextStyle(
                          color: BubColors.coral,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  Expanded(
                    child: _buildBody(loading: loading, error: error),
                  ),
                ],
              ),
              if (_selectedIndex != null && _items.isNotEmpty)
                SafeMediaViewer(
                  items: _items,
                  initialIndex: _selectedIndex!.clamp(0, _items.length - 1),
                  deleting: _deleting,
                  onClose: () => setState(() => _selectedIndex = null),
                  onDelete: _confirmAndDeleteSelected,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody({required bool loading, required bool error}) {
    if (loading) {
      return const BubLoadingState(
        key: Key('safe-gallery-loading'),
        label: 'Loading Safe gallery',
      );
    }
    if (error) {
      return BubErrorState(
        key: const Key('safe-gallery-error'),
        title: 'Safe gallery could not load',
        onRetry: _reload,
        retryKey: const Key('safe-gallery-retry-button'),
      );
    }
    if (_items.isEmpty) {
      return Stack(
        children: [
          SafeGalleryGrid(items: _items, onOpen: (_) {}),
          BubEmptyState(
            key: const Key('safe-gallery-empty'),
            title: 'Nothing in Safe yet',
            image: Image.asset(
              'assets/illustrations/bears/safe-box.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
            ),
          ),
        ],
      );
    }
    return SafeGalleryGrid(
      items: _items,
      onOpen: (index) {
        setState(() {
          _selectedIndex = index;
          _deleteError = null;
        });
      },
    );
  }

  Future<List<SafeMediaItem>> _loadMedia() async {
    final pin = ref.read(safeSessionProvider).pin;
    if (pin == null || pin.isEmpty) {
      return const [];
    }
    final items = await ref
        .read(safeControllerProvider.notifier)
        .listMedia(pin);
    if (mounted) {
      setState(() => _items = items);
    } else {
      _items = items;
    }
    return items;
  }

  void _reload() {
    setState(() {
      _deleteError = null;
      _mediaFuture = _loadMedia();
    });
  }

  Future<void> _confirmAndDeleteSelected(int index) async {
    final item = _items[index];
    final confirmed = await showSafeDeleteConfirmation(context);
    if (confirmed != true || !mounted) {
      return;
    }
    final pin = ref.read(safeSessionProvider).pin;
    if (pin == null || pin.isEmpty) {
      ref.read(safeSessionProvider.notifier).lock();
      return;
    }
    setState(() {
      _deleting = true;
      _deleteError = null;
    });
    try {
      await ref.read(safeControllerProvider.notifier).deleteMedia(item.id, pin);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = [
          for (final current in _items)
            if (current.id != item.id) current,
        ];
        _selectedIndex = null;
        _mediaFuture = Future.value(_items);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _deleteError = "Couldn't delete that Safe item.");
      }
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }
}
