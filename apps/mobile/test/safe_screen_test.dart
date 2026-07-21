import 'package:bub/src/features/safe/safe_controller.dart';
import 'package:bub/src/features/safe/safe_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('untethered Safe state stays unavailable', (tester) async {
    await tester.pumpWidget(
      _safeApp(const SafeStatus(tethered: false, pinConfigured: false)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safe-screen')), findsOneWidget);
    expect(find.byKey(const Key('safe-locked-state')), findsOneWidget);
    expect(find.text('Tether to unlock Safe'), findsOneWidget);
    expect(find.byKey(const Key('safe-pin-entry')), findsNothing);
  });

  testWidgets('configured PIN status shows locked unlock flow', (tester) async {
    await tester.pumpWidget(
      _safeApp(const SafeStatus(tethered: true, pinConfigured: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safe-locked-state')), findsOneWidget);
    expect(find.byKey(const Key('safe-pin-entry')), findsOneWidget);
    expect(find.text('Unlock Safe'), findsWidgets);
  });

  testWidgets('invalid PIN length keeps submit disabled', (tester) async {
    await tester.pumpWidget(
      _safeApp(const SafeStatus(tethered: true, pinConfigured: true)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('safe-pin-entry')), '123');
    await tester.pump();

    final submit = tester.widget<FilledButton>(
      find.byKey(const Key('safe-pin-submit')),
    );
    expect(submit.onPressed, isNull);
  });

  testWidgets('wrong PIN shows an error', (tester) async {
    await tester.pumpWidget(
      _safeApp(
        const SafeStatus(tethered: true, pinConfigured: true),
        unlockSucceeds: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('safe-pin-entry')), '9999');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('safe-pin-submit')))
          .onPressed,
      isNotNull,
    );
    await tester.ensureVisible(find.byKey(const Key('safe-pin-submit')));
    await tester.tap(find.byKey(const Key('safe-pin-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safe-pin-error')), findsOneWidget);
  });

  testWidgets('correct PIN unlocks Safe for the session', (tester) async {
    await tester.pumpWidget(
      _safeApp(const SafeStatus(tethered: true, pinConfigured: true)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('safe-pin-entry')), '1234');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('safe-pin-submit')))
          .onPressed,
      isNotNull,
    );
    await tester.ensureVisible(find.byKey(const Key('safe-pin-submit')));
    await tester.tap(find.byKey(const Key('safe-pin-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safe-unlocked-state')), findsOneWidget);
    expect(find.byKey(const Key('safe-pin-entry')), findsNothing);
  });

  testWidgets('no PIN status shows setup flow and handles mismatch', (
    tester,
  ) async {
    await tester.pumpWidget(
      _safeApp(const SafeStatus(tethered: true, pinConfigured: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create Safe PIN'), findsWidgets);

    await tester.enterText(find.byKey(const Key('safe-pin-entry')), '1234');
    await tester.enterText(
      find.byKey(const Key('safe-pin-confirm-entry')),
      '5678',
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('safe-pin-submit')))
          .onPressed,
      isNotNull,
    );
    await tester.ensureVisible(find.byKey(const Key('safe-pin-submit')));
    await tester.tap(find.byKey(const Key('safe-pin-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safe-pin-error')), findsOneWidget);
  });
}

Widget _safeApp(SafeStatus status, {bool unlockSucceeds = true}) {
  return ProviderScope(
    overrides: [
      safeControllerProvider.overrideWith(
        () => _FakeSafeController(status, unlockSucceeds: unlockSucceeds),
      ),
    ],
    child: const MaterialApp(home: SafeScreen()),
  );
}

class _FakeSafeController extends SafeController {
  _FakeSafeController(this.initialStatus, {required this.unlockSucceeds});

  final SafeStatus initialStatus;
  final bool unlockSucceeds;

  @override
  Future<SafeStatus> build() async => initialStatus;

  @override
  Future<void> unlock(String pin) async {
    if (!unlockSucceeds) {
      throw StateError('Invalid Safe PIN');
    }
    ref.read(safeSessionProvider.notifier).unlock();
  }

  @override
  Future<void> setupPin(String pin) async {
    ref.read(safeSessionProvider.notifier).unlock();
    state = const AsyncData(SafeStatus(tethered: true, pinConfigured: true));
  }
}
