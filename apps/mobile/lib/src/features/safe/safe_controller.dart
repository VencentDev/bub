import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_provider.dart';

class SafeStatus {
  const SafeStatus({required this.tethered, required this.pinConfigured});

  factory SafeStatus.fromJson(Map<String, dynamic> json) {
    return SafeStatus(
      tethered: json['tethered'] == true,
      pinConfigured: json['pinConfigured'] == true,
    );
  }

  final bool tethered;
  final bool pinConfigured;
}

class SafeSession {
  const SafeSession({required this.unlocked});

  final bool unlocked;
}

class SafeSessionController extends Notifier<SafeSession> {
  @override
  SafeSession build() => const SafeSession(unlocked: false);

  void unlock() {
    state = const SafeSession(unlocked: true);
  }

  void lock() {
    state = const SafeSession(unlocked: false);
  }
}

class SafeController extends AsyncNotifier<SafeStatus> {
  @override
  Future<SafeStatus> build() async {
    final response = await ref
        .read(dioProvider)
        .get<Map<String, dynamic>>('/api/v1/safe/status');
    return SafeStatus.fromJson(response.data ?? const {});
  }

  Future<void> setupPin(String pin) async {
    final response = await ref
        .read(dioProvider)
        .post<Map<String, dynamic>>('/api/v1/safe/pin', data: {'pin': pin});
    ref.read(safeSessionProvider.notifier).unlock();
    state = AsyncData(SafeStatus.fromJson(response.data ?? const {}));
  }

  Future<void> unlock(String pin) async {
    try {
      final response = await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>(
            '/api/v1/safe/unlock',
            data: {'pin': pin},
          );
      final unlocked = response.data?['unlocked'] == true;
      if (!unlocked) {
        throw StateError('Safe did not unlock');
      }
      ref.read(safeSessionProvider.notifier).unlock();
    } on DioException {
      rethrow;
    }
  }
}

final safeSessionProvider =
    NotifierProvider<SafeSessionController, SafeSession>(
      SafeSessionController.new,
    );

final safeControllerProvider =
    AsyncNotifierProvider<SafeController, SafeStatus>(SafeController.new);
