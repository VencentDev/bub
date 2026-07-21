import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Safe could not load',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.invalidate(safeControllerProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
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
      child: Center(
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
    final title = widget.pinConfigured ? 'Unlock Safe' : 'Create Safe PIN';
    final subtitle = widget.pinConfigured
        ? 'Enter your Safe PIN to view private memories.'
        : 'Choose a 4 to 6 digit PIN for this shared vault.';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 150),
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
          FilledButton.icon(
            key: const Key('safe-pin-submit'),
            onPressed: _canSubmit ? _submit : null,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_open_rounded),
            label: Text(title),
          ),
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
                        IconButton(
                          tooltip: 'Lock Safe',
                          onPressed: () =>
                              ref.read(safeSessionProvider.notifier).lock(),
                          icon: const Icon(Icons.lock_rounded),
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
      return const Center(child: CircularProgressIndicator());
    }
    if (error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 132),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Safe gallery could not load',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _reload, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Stack(
        children: [
          SafeGalleryGrid(items: _items, onOpen: (_) {}),
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 132),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/illustrations/bears/safe-box.png',
                    width: 130,
                    height: 130,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Nothing in Safe yet',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
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
