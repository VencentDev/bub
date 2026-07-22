import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/features/home/home_screen.dart';
import 'src/features/settings/settings_controller.dart';
import 'src/features/settings/settings_store.dart';
import 'src/theme/bub_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(isOptional: true);
  runApp(const ProviderScope(child: MobileApp()));
}

class MobileApp extends ConsumerWidget {
  const MobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).value;

    return MaterialApp(
      title: 'Bub',
      theme: BubTheme.light,
      darkTheme: BubTheme.dark,
      themeMode: switch (settings?.themeMode ?? BubSettingsThemeMode.system) {
        BubSettingsThemeMode.system => ThemeMode.system,
        BubSettingsThemeMode.light => ThemeMode.light,
        BubSettingsThemeMode.dark => ThemeMode.dark,
      },
      home: const HomeScreen(),
    );
  }
}
