import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../core/env.dart';
import '../todos/todos_screen.dart';

/// Starter screen: switches between Google sign-in and the authenticated todo app.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    if (auth case AsyncData(value: final user) when user != null) {
      return TodosScreen(user: user, onLogout: controller.logout);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('app_mobile')),
      body: Center(
        child: switch (auth) {
          AsyncLoading() => const CircularProgressIndicator(),
          AsyncError(:final error) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sign-in failed:\n$error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: controller.login,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
          _ => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: Env.isGoogleConfigured ? controller.login : null,
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
              ),
              if (!Env.isGoogleConfigured)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Set GOOGLE_CLIENT_ID in .env and restart the app.',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        },
      ),
    );
  }
}
