import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/bub_colors.dart';
import 'settings_controller.dart';
import 'settings_store.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.paired});

  final bool paired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? BubColors.textPrimaryDark
        : BubColors.textPrimaryLight;
    final mutedColor = isDark
        ? BubColors.textSecondaryDark
        : BubColors.textSecondaryLight;

    return ListView(
      key: const Key('settings-screen'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 136),
      children: [
        Text(
          'Settings',
          style: TextStyle(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Personalize Bub and manage your account.',
          style: TextStyle(
            color: mutedColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 20),
        _SettingsSection(
          title: 'Appearance',
          children: [
            _SettingsRow(
              key: Key('settings-theme-row'),
              icon: Icons.dark_mode_rounded,
              title: 'Theme',
              trailing: _SettingsMenu<BubSettingsThemeMode>(
                value: settings.value?.themeMode ?? BubSettingsThemeMode.system,
                values: BubSettingsThemeMode.values,
                label: _themeModeLabel,
                onSelected: (value) => ref
                    .read(settingsControllerProvider.notifier)
                    .setThemeMode(value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SettingsSection(
          title: 'Language',
          children: [
            _SettingsRow(
              key: Key('settings-language-row'),
              icon: Icons.language_rounded,
              title: 'Language',
              trailing: _SettingsMenu<String>(
                value: settings.value?.language ?? 'en',
                values: const ['en'],
                label: _languageLabel,
                onSelected: (value) => ref
                    .read(settingsControllerProvider.notifier)
                    .setLanguage(value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SettingsSection(
          key: const Key('settings-tether-section'),
          title: 'Tether',
          children: [
            _SettingsRow(
              icon: Icons.favorite_rounded,
              title: 'Remove tether',
              value: paired ? 'Available' : 'Not tethered',
              destructive: paired,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _SettingsSection(
          key: Key('settings-account-section'),
          title: 'Account',
          children: [
            _SettingsRow(
              icon: Icons.logout_rounded,
              title: 'Logout',
              value: 'End session',
            ),
          ],
        ),
      ],
    );
  }

  static String _themeModeLabel(BubSettingsThemeMode value) {
    return switch (value) {
      BubSettingsThemeMode.system => 'System',
      BubSettingsThemeMode.light => 'Light',
      BubSettingsThemeMode.dark => 'Dark',
    };
  }

  static String _languageLabel(String value) {
    return switch (value) {
      'en' => 'English',
      _ => value,
    };
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? BubColors.textSecondaryDark
        : BubColors.textSecondaryLight;
    final backgroundColor = isDark
        ? BubColors.darkCard.withValues(alpha: 0.88)
        : BubColors.white.withValues(alpha: 0.92);
    final borderColor = isDark
        ? BubColors.white.withValues(alpha: 0.08)
        : BubColors.deepPurple.withValues(alpha: 0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: BubColors.deepPurple.withValues(
                  alpha: isDark ? 0.12 : 0.08,
                ),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = destructive ? BubColors.coral : BubColors.purple;
    final textColor = isDark
        ? BubColors.textPrimaryDark
        : BubColors.textPrimaryLight;
    final valueColor = isDark
        ? BubColors.textSecondaryDark
        : BubColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: destructive ? BubColors.coral : textColor,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (trailing case final trailing?)
            trailing
          else
            Flexible(
              child: Text(
                value ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsMenu<T> extends StatelessWidget {
  const _SettingsMenu({
    required this.value,
    required this.values,
    required this.label,
    required this.onSelected,
  });

  final T value;
  final List<T> values;
  final String Function(T value) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(16),
      items: [
        for (final item in values)
          DropdownMenuItem<T>(value: item, child: Text(label(item))),
      ],
      onChanged: (value) {
        if (value != null) {
          onSelected(value);
        }
      },
    );
  }
}
