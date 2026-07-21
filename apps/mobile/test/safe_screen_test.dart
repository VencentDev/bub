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

  testWidgets('unlocked state renders Safe gallery', (tester) async {
    await tester.pumpWidget(
      _safeApp(
        const SafeStatus(tethered: true, pinConfigured: true),
        session: const SafeSession(unlocked: true, pin: '1234'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safe-gallery-grid')), findsOneWidget);
    expect(find.byKey(const Key('safe-unlocked-state')), findsOneWidget);
  });

  testWidgets('Safe gallery renders newest items in backend order', (
    tester,
  ) async {
    await tester.pumpWidget(
      _safeApp(
        const SafeStatus(tethered: true, pinConfigured: true),
        session: const SafeSession(unlocked: true, pin: '1234'),
        media: const [
          SafeMediaItem(
            id: 'new',
            mediaType: SafeMediaType.image,
            url: 'https://example.com/new.jpg',
            createdAt: '2026-07-21T01:00:00Z',
          ),
          SafeMediaItem(
            id: 'old',
            mediaType: SafeMediaType.video,
            url: 'https://example.com/old.mp4',
            createdAt: '2026-07-20T01:00:00Z',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safe-gallery-item-new')), findsOneWidget);
    expect(find.byKey(const Key('safe-gallery-item-old')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('safe-gallery-item-new'))).dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const Key('safe-gallery-item-old'))).dy,
      ),
    );
  });

  testWidgets('tapping a Safe gallery item opens viewer', (tester) async {
    await tester.pumpWidget(
      _safeApp(
        const SafeStatus(tethered: true, pinConfigured: true),
        session: const SafeSession(unlocked: true, pin: '1234'),
        media: const [
          SafeMediaItem(
            id: 'photo',
            mediaType: SafeMediaType.image,
            url: 'https://example.com/photo.jpg',
            createdAt: '2026-07-21T01:00:00Z',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('safe-gallery-item-photo')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safe-media-viewer')), findsOneWidget);
  });

  testWidgets('Safe delete confirmation cancel keeps item', (tester) async {
    await tester.pumpWidget(
      _safeApp(
        const SafeStatus(tethered: true, pinConfigured: true),
        session: const SafeSession(unlocked: true, pin: '1234'),
        media: const [
          SafeMediaItem(
            id: 'keep',
            mediaType: SafeMediaType.image,
            url: 'https://example.com/keep.jpg',
            createdAt: '2026-07-21T01:00:00Z',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('safe-gallery-item-keep')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('safe-delete-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safe-delete-confirm')), findsOneWidget);

    await tester.tap(find.byKey(const Key('safe-delete-cancel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safe-gallery-item-keep')), findsOneWidget);
  });

  testWidgets('Safe delete confirm removes item after API success', (
    tester,
  ) async {
    final controller = _FakeSafeController(
      const SafeStatus(tethered: true, pinConfigured: true),
      media: const [
        SafeMediaItem(
          id: 'delete-me',
          mediaType: SafeMediaType.image,
          url: 'https://example.com/delete.jpg',
          createdAt: '2026-07-21T01:00:00Z',
        ),
      ],
    );
    await tester.pumpWidget(
      _safeAppWithController(
        controller,
        session: const SafeSession(unlocked: true, pin: '1234'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('safe-gallery-item-delete-me')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('safe-delete-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('safe-delete-confirm')));
    await tester.pumpAndSettle();

    expect(controller.deletedIds, ['delete-me']);
    expect(find.byKey(const Key('safe-gallery-item-delete-me')), findsNothing);
  });

  testWidgets('Safe delete failure keeps item and shows error', (tester) async {
    await tester.pumpWidget(
      _safeApp(
        const SafeStatus(tethered: true, pinConfigured: true),
        session: const SafeSession(unlocked: true, pin: '1234'),
        deleteSucceeds: false,
        media: const [
          SafeMediaItem(
            id: 'still-here',
            mediaType: SafeMediaType.image,
            url: 'https://example.com/still.jpg',
            createdAt: '2026-07-21T01:00:00Z',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('safe-gallery-item-still-here')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('safe-delete-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('safe-delete-confirm')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('safe-gallery-item-still-here')),
      findsOneWidget,
    );
    expect(find.text("Couldn't delete that Safe item."), findsOneWidget);
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

Widget _safeApp(
  SafeStatus status, {
  bool unlockSucceeds = true,
  bool deleteSucceeds = true,
  SafeSession session = const SafeSession(unlocked: false),
  List<SafeMediaItem> media = const [],
}) {
  return _safeAppWithController(
    _FakeSafeController(
      status,
      unlockSucceeds: unlockSucceeds,
      deleteSucceeds: deleteSucceeds,
      media: media,
    ),
    session: session,
  );
}

Widget _safeAppWithController(
  _FakeSafeController controller, {
  SafeSession session = const SafeSession(unlocked: false),
}) {
  return ProviderScope(
    overrides: [
      safeSessionProvider.overrideWith(
        () => _FakeSafeSessionController(session),
      ),
      safeControllerProvider.overrideWith(() => controller),
    ],
    child: const MaterialApp(home: SafeScreen()),
  );
}

class _FakeSafeController extends SafeController {
  _FakeSafeController(
    this.initialStatus, {
    this.unlockSucceeds = true,
    this.deleteSucceeds = true,
    List<SafeMediaItem> media = const [],
  }) : _media = [...media];

  final SafeStatus initialStatus;
  final bool unlockSucceeds;
  final bool deleteSucceeds;
  final List<String> deletedIds = [];
  final List<SafeMediaItem> _media;

  @override
  Future<SafeStatus> build() async => initialStatus;

  @override
  Future<void> unlock(String pin) async {
    if (!unlockSucceeds) {
      throw StateError('Invalid Safe PIN');
    }
    ref.read(safeSessionProvider.notifier).unlock(pin);
  }

  @override
  Future<void> setupPin(String pin) async {
    ref.read(safeSessionProvider.notifier).unlock(pin);
    state = const AsyncData(SafeStatus(tethered: true, pinConfigured: true));
  }

  @override
  Future<List<SafeMediaItem>> listMedia(String pin) async => [..._media];

  @override
  Future<void> deleteMedia(String mediaId, String pin) async {
    if (!deleteSucceeds) {
      throw StateError('Delete failed');
    }
    deletedIds.add(mediaId);
    _media.removeWhere((item) => item.id == mediaId);
  }
}

class _FakeSafeSessionController extends SafeSessionController {
  _FakeSafeSessionController(this.initialSession);

  final SafeSession initialSession;

  @override
  SafeSession build() => initialSession;
}
