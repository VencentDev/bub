import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../api/generated/models/tether_accept_request.dart';
import '../../api/generated/models/tether_invitation_response.dart';
import '../../auth/auth_controller.dart';
import '../../core/dio_provider.dart';
import '../../theme/bub_colors.dart';

class EnterTetherScreen extends ConsumerStatefulWidget {
  const EnterTetherScreen({super.key});

  @override
  ConsumerState<EnterTetherScreen> createState() => _EnterTetherScreenState();
}

class _EnterTetherScreenState extends ConsumerState<EnterTetherScreen> {
  final _controller = TextEditingController();
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _OnboardingScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
        children: [
          const _WelcomeHeader(),
          const SizedBox(height: 4),
          Text(
            'Who are you tethering with?',
            key: Key('tether-prompt'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Image.asset(
              'assets/illustrations/bears/bear4.png',
              key: const Key('enter-tether-bear'),
              height: _enterBearHeight(context),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('tether-code-field'),
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'BUB-7KQ2-XH19',
              errorText: _error,
              suffixIcon: IconButton(
                tooltip: 'Submit tether code',
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                onPressed: _submitting ? null : _acceptCode,
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('qr-scanner-button'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TetherScannerScreen(),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Scan QR code'),
          ),
          const SizedBox(height: 14),
          const _OrDivider(),
          const SizedBox(height: 14),
          _GradientButton(
            label: 'Generate new tether',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GenerateTetherScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('skip-tether-button'),
            onPressed: () async {
              await ref
                  .read(authControllerProvider.notifier)
                  .skipTetherOnboarding();
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptCode() async {
    final code = _controller.text.trim().toUpperCase();
    if (!RegExp(r'^BUB-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(code)) {
      setState(() => _error = 'Enter a code like BUB-7KQ2-XH19');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final status = await ref
          .read(restClientProvider)
          .fallback
          .acceptTether(body: TetherAcceptRequest(code: code));
      await ref
          .read(authControllerProvider.notifier)
          .applyAcceptedTether(status);
      if (mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const AllSetScreen()));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'That tether code could not be used');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

String? parseTetherCodeFromQrPayload(String payload) {
  final value = payload.trim().toUpperCase();
  final codePattern = RegExp(r'^BUB-[A-Z0-9]{4}-[A-Z0-9]{4}$');
  if (codePattern.hasMatch(value)) {
    return value;
  }

  final uri = Uri.tryParse(payload);
  final code = uri?.queryParameters['code']?.trim().toUpperCase();
  if (code == null || !codePattern.hasMatch(code)) {
    return null;
  }
  return code;
}

class GenerateTetherScreen extends ConsumerWidget {
  const GenerateTetherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitation = ref.watch(tetherInvitationProvider);
    final theme = Theme.of(context);

    return _OnboardingScaffold(
      bottom: _GradientButton(
        key: const Key('done-generate-tether-button'),
        label: 'DONE',
        onPressed: () async {
          await ref
              .read(authControllerProvider.notifier)
              .completeTetherOnboarding();
          if (!context.mounted) {
            return;
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const AllSetScreen()),
          );
        },
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    key: const Key('back-from-generate-tether-button'),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Share your tether code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textTheme.displayMedium?.color,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Send this code to your person so they can Bub with you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            invitation.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Could not generate a tether code.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('retry-generate-tether-button'),
                    onPressed: () => ref.invalidate(tetherInvitationProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
              data: (invite) => _InviteQr(invite: invite),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class AllSetScreen extends ConsumerWidget {
  const AllSetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return _OnboardingScaffold(
      bottom: _GradientButton(
        key: const Key('go-to-bub-button'),
        label: 'Go to Bub',
        onPressed: () {
          ref
              .read(authControllerProvider.notifier)
              .refreshTetherStatus(markComplete: true);
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 42, 24, 24),
        child: Column(
          children: [
            Text(
              'All set',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textTheme.displayMedium?.color,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You're almost there",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 17,
              ),
            ),
            const Spacer(),
            Image.asset(
              'assets/illustrations/bears/bear2.png',
              key: const Key('all-set-bear'),
              height: _bearHeight(context),
              fit: BoxFit.contain,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

typedef TetherScannerPreviewBuilder =
    Widget Function(
      BuildContext context,
      Rect scanWindow,
      ValueChanged<String> onPayloadDetected,
    );

final tetherScannerPreviewProvider = Provider<TetherScannerPreviewBuilder>(
  (ref) =>
      (context, scanWindow, onPayloadDetected) => _MobileTetherScannerView(
        scanWindow: scanWindow,
        onPayloadDetected: onPayloadDetected,
      ),
);

class TetherScannerScreen extends ConsumerStatefulWidget {
  const TetherScannerScreen({super.key});

  @override
  ConsumerState<TetherScannerScreen> createState() =>
      _TetherScannerScreenState();
}

class _TetherScannerScreenState extends ConsumerState<TetherScannerScreen> {
  var _accepting = false;
  String? _error;

  Future<void> _handlePayload(String payload) async {
    if (_accepting) {
      return;
    }

    final code = parseTetherCodeFromQrPayload(payload);
    if (code == null) {
      setState(() => _error = 'Scan a Bub tether QR code');
      return;
    }

    setState(() {
      _accepting = true;
      _error = null;
    });
    try {
      final status = await ref
          .read(restClientProvider)
          .fallback
          .acceptTether(body: TetherAcceptRequest(code: code));
      await ref
          .read(authControllerProvider.notifier)
          .applyAcceptedTether(status);
      if (mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const AllSetScreen()),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _accepting = false;
          _error = 'That tether QR could not be used';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final guideSize = (constraints.maxWidth - 64)
                .clamp(220.0, 300.0)
                .toDouble();
            final scanWindow = Rect.fromCenter(
              center: Offset(
                constraints.maxWidth / 2,
                (constraints.maxHeight - 124) / 2,
              ),
              width: guideSize,
              height: guideSize,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                ref.watch(tetherScannerPreviewProvider)(
                  context,
                  scanWindow,
                  _handlePayload,
                ),
                CustomPaint(
                  key: const Key('tether-scanner-guide'),
                  painter: _ScannerGuidePainter(scanWindow),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: scanWindow.bottom + 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _accepting
                            ? 'Connecting your tether...'
                            : 'Place the QR inside the frame',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: BubColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFFB4B4),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: OutlinedButton.icon(
                      key: const Key('scanner-back-button'),
                      onPressed: _accepting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Go back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BubColors.white,
                        side: const BorderSide(color: BubColors.white),
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MobileTetherScannerView extends StatefulWidget {
  const _MobileTetherScannerView({
    required this.scanWindow,
    required this.onPayloadDetected,
  });

  final Rect scanWindow;
  final ValueChanged<String> onPayloadDetected;

  @override
  State<_MobileTetherScannerView> createState() =>
      _MobileTetherScannerViewState();
}

class _MobileTetherScannerViewState extends State<_MobileTetherScannerView> {
  late final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      fit: BoxFit.cover,
      scanWindow: widget.scanWindow,
      placeholderBuilder: (context, child) => const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: BubColors.white)),
      ),
      errorBuilder: (context, error, child) => const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Camera permission is needed to scan tether QR codes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: BubColors.white),
            ),
          ),
        ),
      ),
      onDetect: (capture) {
        if (capture.barcodes.isEmpty) {
          return;
        }
        final payload = capture.barcodes.first.rawValue;
        if (payload != null) {
          widget.onPayloadDetected(payload);
        }
      },
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await _controller.dispose();
  }
}

class _ScannerGuidePainter extends CustomPainter {
  const _ScannerGuidePainter(this.window);

  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    final cutout = Path()
      ..addRRect(RRect.fromRectAndRadius(window, const Radius.circular(24)));
    final shaded = Path.combine(PathOperation.difference, overlay, cutout);

    canvas.drawPath(
      shaded,
      Paint()..color = Colors.black.withValues(alpha: 0.58),
    );

    final faintFrame = Paint()
      ..color = BubColors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(window, const Radius.circular(24)),
      faintFrame,
    );

    final cornerPaint = Paint()
      ..color = BubColors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const corner = 42.0;
    canvas.drawLine(
      window.topLeft,
      window.topLeft + const Offset(corner, 0),
      cornerPaint,
    );
    canvas.drawLine(
      window.topLeft,
      window.topLeft + const Offset(0, corner),
      cornerPaint,
    );
    canvas.drawLine(
      window.topRight,
      window.topRight + const Offset(-corner, 0),
      cornerPaint,
    );
    canvas.drawLine(
      window.topRight,
      window.topRight + const Offset(0, corner),
      cornerPaint,
    );
    canvas.drawLine(
      window.bottomLeft,
      window.bottomLeft + const Offset(corner, 0),
      cornerPaint,
    );
    canvas.drawLine(
      window.bottomLeft,
      window.bottomLeft + const Offset(0, -corner),
      cornerPaint,
    );
    canvas.drawLine(
      window.bottomRight,
      window.bottomRight + const Offset(-corner, 0),
      cornerPaint,
    );
    canvas.drawLine(
      window.bottomRight,
      window.bottomRight + const Offset(0, -corner),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerGuidePainter oldDelegate) =>
      oldDelegate.window != window;
}

final tetherInvitationProvider =
    FutureProvider.autoDispose<TetherInvitationResponse>(
      (ref) => ref.read(restClientProvider).fallback.createTetherInvitation(),
    );

class _InviteQr extends StatelessWidget {
  const _InviteQr({required this.invite});

  final TetherInvitationResponse invite;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: BubColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BubColors.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: QrImageView(
              key: const Key('tether-qr-code'),
              data: invite.qrPayload,
              size: 220,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              backgroundColor: BubColors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _TetherCodeContainer(code: invite.code),
      ],
    );
  }
}

double _bearHeight(BuildContext context) =>
    MediaQuery.sizeOf(context).height * 0.5;

double _enterBearHeight(BuildContext context) =>
    (MediaQuery.sizeOf(context).height * 0.48).clamp(280.0, 340.0).toDouble();

class _TetherCodeContainer extends StatelessWidget {
  const _TetherCodeContainer({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      key: const Key('tether-code-container'),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              code,
              key: const Key('generated-tether-code'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textTheme.titleMedium?.color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const Key('copy-tether-code-button'),
              tooltip: 'Copy tether code',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tether code copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Welcome to Bub',
          key: const Key('welcome-title'),
          style: TextStyle(
            color: theme.textTheme.displayMedium?.color,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.favorite_rounded, color: BubColors.purple, size: 20),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: theme.hintColor)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _OnboardingScaffold extends StatelessWidget {
  const _OnboardingScaffold({required this.child, this.bottom});

  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: child),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: bottom!,
            ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: BubColors.bubButtonGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
