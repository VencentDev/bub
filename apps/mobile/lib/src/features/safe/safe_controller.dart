import 'dart:io';

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

enum SafeMediaType {
  image,
  video;

  static SafeMediaType fromJson(String? value) {
    return switch (value?.toUpperCase()) {
      'VIDEO' => SafeMediaType.video,
      _ => SafeMediaType.image,
    };
  }

  String get apiValue => name.toUpperCase();
}

class SafeMediaItem {
  const SafeMediaItem({
    required this.id,
    required this.mediaType,
    required this.url,
    required this.createdAt,
    this.contentType,
    this.sizeBytes,
    this.originalFilename,
  });

  factory SafeMediaItem.fromJson(Map<String, dynamic> json) {
    return SafeMediaItem(
      id: json['id'] as String? ?? '',
      mediaType: SafeMediaType.fromJson(json['mediaType'] as String?),
      url: json['url'] as String? ?? '',
      contentType: json['contentType'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      originalFilename: json['originalFilename'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  final String id;
  final SafeMediaType mediaType;
  final String url;
  final String? contentType;
  final int? sizeBytes;
  final String? originalFilename;
  final String createdAt;
}

class SafeChatNotice {
  const SafeChatNotice({required this.id, required this.safeItemCount});

  factory SafeChatNotice.fromJson(Map<String, dynamic> json) {
    return SafeChatNotice(
      id: json['id'] as String? ?? '',
      safeItemCount: json['safeItemCount'] as int? ?? 0,
    );
  }

  final String id;
  final int safeItemCount;
}

class SafeMediaUploadResult {
  const SafeMediaUploadResult({required this.items, required this.notice});

  factory SafeMediaUploadResult.fromJson(Map<String, dynamic> json) {
    return SafeMediaUploadResult(
      items: [
        for (final item in (json['items'] as List? ?? const []))
          if (item is Map<String, dynamic>) SafeMediaItem.fromJson(item),
      ],
      notice: json['notice'] is Map<String, dynamic>
          ? SafeChatNotice.fromJson(json['notice'] as Map<String, dynamic>)
          : null,
    );
  }

  final List<SafeMediaItem> items;
  final SafeChatNotice? notice;
}

class SafeSession {
  const SafeSession({required this.unlocked, this.pin});

  final bool unlocked;
  final String? pin;
}

class SafeSessionController extends Notifier<SafeSession> {
  @override
  SafeSession build() => const SafeSession(unlocked: false);

  void unlock(String pin) {
    state = SafeSession(unlocked: true, pin: pin);
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
    ref.read(safeSessionProvider.notifier).unlock(pin);
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
      ref.read(safeSessionProvider.notifier).unlock(pin);
    } on DioException {
      rethrow;
    }
  }

  Future<List<SafeMediaItem>> listMedia(String pin) async {
    final response = await ref
        .read(dioProvider)
        .get<Map<String, dynamic>>(
          '/api/v1/safe/media',
          options: Options(headers: {'X-Bub-Safe-Pin': pin}),
        );
    return [
      for (final item in (response.data?['items'] as List? ?? const []))
        if (item is Map<String, dynamic>) SafeMediaItem.fromJson(item),
    ];
  }

  Future<SafeMediaUploadResult> uploadMedia(
    List<File> files,
    String pin,
  ) async {
    if (files.isEmpty) {
      return const SafeMediaUploadResult(items: [], notice: null);
    }
    final formData = FormData.fromMap({
      'files': [
        for (final file in files) await MultipartFile.fromFile(file.path),
      ],
    });
    final response = await ref
        .read(dioProvider)
        .post<Map<String, dynamic>>(
          '/api/v1/safe/media',
          data: formData,
          options: Options(headers: {'X-Bub-Safe-Pin': pin}),
        );
    return SafeMediaUploadResult.fromJson(response.data ?? const {});
  }

  Future<void> deleteMedia(String mediaId, String pin) async {
    await ref
        .read(dioProvider)
        .delete<Map<String, dynamic>>(
          '/api/v1/safe/media/$mediaId',
          options: Options(headers: {'X-Bub-Safe-Pin': pin}),
        );
  }
}

final safeSessionProvider =
    NotifierProvider<SafeSessionController, SafeSession>(
      SafeSessionController.new,
    );

final safeControllerProvider =
    AsyncNotifierProvider<SafeController, SafeStatus>(SafeController.new);
