import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dio_provider.dart';
import '../home/home_dashboard_controller.dart';

class BubSendController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendBub() async {
    if (state.isLoading) {
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(restClientProvider).bubController.sendBub();
      await ref.read(homeDashboardProvider.notifier).refresh();
    });

    if (state case AsyncError(:final error, :final stackTrace)) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

final bubSendControllerProvider =
    AsyncNotifierProvider<BubSendController, void>(BubSendController.new);
