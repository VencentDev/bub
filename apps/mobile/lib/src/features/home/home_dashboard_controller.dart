import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/generated/models/home_dashboard_response.dart';
import '../../api/generated/models/home_moment_reaction_request.dart';
import '../../api/generated/models/home_mood_request.dart';
import '../../api/generated/models/home_today_moment_request.dart';
import '../../core/dio_provider.dart';

final momentImagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

final momentUploadInProgressProvider = NotifierProvider<_BusyFlag, bool>(
  _BusyFlag.new,
);

class _BusyFlag extends Notifier<bool> {
  @override
  bool build() => false;

  void setBusy(bool value) => state = value;
}

class HomeDashboardController extends AsyncNotifier<HomeDashboardResponse> {
  @override
  Future<HomeDashboardResponse> build() {
    return ref.read(restClientProvider).homeController.getHomeDashboard();
  }

  Future<void> refresh({bool preserveCurrent = false}) async {
    final previous = state.asData?.value;
    if (!preserveCurrent) {
      state = const AsyncLoading();
    }
    final next = await AsyncValue.guard(build);
    if (preserveCurrent && previous != null && next.hasError) {
      state = AsyncData(previous);
      return;
    }
    state = next;
  }

  Future<void> putTodayMoment(String photoUrl, DateTime date) async {
    final localDate = _dateOnly(date);
    final previous = state.asData?.value;
    try {
      await ref
          .read(restClientProvider)
          .homeController
          .putTodayMoment(
            body: HomeTodayMomentRequest(
              photoUrl: photoUrl,
              localDate: DateTime.parse(localDate),
            ),
          );
      state = AsyncData(
        await ref.read(restClientProvider).homeController.getHomeDashboard(),
      );
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> captureTodayMoment() async {
    final image = await ref
        .read(momentImagePickerProvider)
        .pickImage(
          source: ImageSource.camera,
          imageQuality: 86,
          maxWidth: 1600,
          preferredCameraDevice: CameraDevice.rear,
        );
    if (image == null) {
      return;
    }

    final previous = state.asData?.value;
    ref.read(momentUploadInProgressProvider.notifier).setBusy(true);
    try {
      await _uploadMomentPhoto(image.path);
      state = AsyncData(
        await ref.read(restClientProvider).homeController.getHomeDashboard(),
      );
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      ref.read(momentUploadInProgressProvider.notifier).setBusy(false);
    }
  }

  Future<void> _uploadMomentPhoto(String imagePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imagePath,
        filename: _fileName(imagePath),
      ),
    });
    final response = await ref
        .read(dioProvider)
        .post<Map<String, dynamic>>(
          '/api/v1/home/today-moment/photo',
          data: formData,
        );
    final photoUrl = response.data?['photoUrl'] as String?;
    if (photoUrl == null || photoUrl.trim().isEmpty) {
      throw StateError('Moment upload did not return a photo URL');
    }
  }

  Future<void> reactToTodayMoment(String momentId) async {
    final previous = state.asData?.value;
    try {
      await ref
          .read(restClientProvider)
          .homeController
          .reactToTodayMoment(
            momentId: momentId,
            body: const HomeMomentReactionRequest(reaction: '❤️'),
          );
      state = AsyncData(
        await ref.read(restClientProvider).homeController.getHomeDashboard(),
      );
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> putMood(String mood) async {
    final trimmedMood = mood.trim();
    if (trimmedMood.isEmpty || trimmedMood.length > 20) {
      return;
    }

    final previous = state.asData?.value;
    try {
      await ref
          .read(restClientProvider)
          .homeController
          .putMood(body: HomeMoodRequest(mood: trimmedMood));
      state = AsyncData(
        await ref.read(restClientProvider).homeController.getHomeDashboard(),
      );
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _fileName(String path) {
    final name = path.split('/').last.trim();
    return name.isEmpty ? 'moment.jpg' : name;
  }
}

final homeDashboardProvider =
    AsyncNotifierProvider<HomeDashboardController, HomeDashboardResponse>(
      HomeDashboardController.new,
    );
