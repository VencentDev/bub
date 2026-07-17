import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/generated/models/home_dashboard_response.dart';
import '../../api/generated/models/home_moment_reaction_request.dart';
import '../../api/generated/models/home_mood_request.dart';
import '../../api/generated/models/home_today_moment_request.dart';
import '../../core/dio_provider.dart';

class HomeDashboardController extends AsyncNotifier<HomeDashboardResponse> {
  @override
  Future<HomeDashboardResponse> build() {
    return ref.read(restClientProvider).fallback.getHomeDashboard();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> putTodayMoment(String photoUrl, DateTime date) async {
    final localDate = _dateOnly(date);
    state = await AsyncValue.guard(() async {
      await ref
          .read(restClientProvider)
          .fallback
          .putTodayMoment(
            body: HomeTodayMomentRequest(
              photoUrl: photoUrl,
              localDate: localDate,
            ),
          );
      return ref.read(restClientProvider).fallback.getHomeDashboard();
    });
  }

  Future<void> reactToTodayMoment(String momentId) async {
    state = await AsyncValue.guard(() async {
      await ref
          .read(restClientProvider)
          .fallback
          .reactToTodayMoment(
            momentId: momentId,
            body: const HomeMomentReactionRequest(reaction: '❤️'),
          );
      return ref.read(restClientProvider).fallback.getHomeDashboard();
    });
  }

  Future<void> putMood(String mood) async {
    final trimmedMood = mood.trim();
    if (trimmedMood.isEmpty || trimmedMood.length > 20) {
      return;
    }

    state = await AsyncValue.guard(() async {
      await ref
          .read(restClientProvider)
          .fallback
          .putMood(body: HomeMoodRequest(mood: trimmedMood));
      return ref.read(restClientProvider).fallback.getHomeDashboard();
    });
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

final homeDashboardProvider =
    AsyncNotifierProvider<HomeDashboardController, HomeDashboardResponse>(
      HomeDashboardController.new,
    );
