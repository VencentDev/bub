import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../core/env.dart';

/// Starter screen: switches between Google sign-in and the authenticated Bub shell.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    if (auth case AsyncData(value: final user) when user != null) {
      return _BubHome(onLogout: controller.logout);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bub')),
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

class _BubHome extends StatelessWidget {
  const _BubHome({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bub'),
        actions: [TextButton(onPressed: onLogout, child: const Text('Logout'))],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You're not tethered yet ❤️",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text(
                'Pairing, chat, Bubs, moments, and Safe will build from the product stories.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
