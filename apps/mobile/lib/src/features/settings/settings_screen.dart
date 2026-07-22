import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/bub_colors.dart';
import 'settings_controller.dart';
import 'settings_store.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    super.key,
    required this.paired,
    required this.onLogout,
    required this.onRemoveTether,
  });

  final bool paired;
  final VoidCallback onLogout;
  final Future<void> Function() onRemoveTether;

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
          key: const Key('settings-safe-section'),
          title: 'Safe',
          children: const [
            _SettingsRow(
              actionKey: Key('settings-safe-pin-recovery-button'),
              icon: Icons.lock_reset_rounded,
              title: 'Forgot Safe PIN',
              value:
                  'PIN recovery will be available after secure email is configured.',
              enabled: false,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SettingsSection(
          key: const Key('settings-tether-section'),
          title: 'Tether',
          children: [
            _SettingsRow(
              actionKey: const Key('settings-remove-tether-button'),
              icon: Icons.favorite_rounded,
              title: 'Remove tether',
              value: paired ? 'Available' : 'Not tethered',
              destructive: paired,
              enabled: paired,
              onTap: paired ? () => _confirmRemoveTether(context) : null,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SettingsSection(
          key: const Key('settings-account-section'),
          title: 'Account',
          children: [
            _SettingsRow(
              actionKey: const Key('settings-logout-button'),
              icon: Icons.logout_rounded,
              title: 'Logout',
              value: 'End session',
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to get back to Bub.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      onLogout();
    }
  }

  Future<void> _confirmRemoveTether(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove tether?'),
        content: const Text(
          'This permanently deletes your chat conversation, images and media, Shared Safe, shared moments, Bub history, Bub streak, "Been tethered" history, and other couple history for this tether. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove tether'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onRemoveTether();
    }
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
    this.enabled = true,
    this.actionKey,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final bool destructive;
  final bool enabled;
  final Key? actionKey;
  final VoidCallback? onTap;

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

    return InkWell(
      key: actionKey,
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: enabled ? 0.12 : 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: enabled ? accent : valueColor, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: enabled
                      ? destructive
                            ? BubColors.coral
                            : textColor
                      : valueColor,
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
