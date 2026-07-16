import 'package:flutter/material.dart';

import 'bub_colors.dart';

class BubTheme {
  const BubTheme._();

  static ThemeData get light => _theme(
    brightness: Brightness.light,
    scaffold: BubColors.lightScaffold,
    surface: BubColors.lightSurface,
    card: BubColors.lightCard,
    dialog: BubColors.lightDialog,
    textPrimary: BubColors.textPrimaryLight,
    textSecondary: BubColors.textSecondaryLight,
    textHint: BubColors.textHintLight,
    bottomNavBackground: BubColors.lightSurface,
    divider: BubColors.divider,
  );

  static ThemeData get dark => _theme(
    brightness: Brightness.dark,
    scaffold: BubColors.darkScaffold,
    surface: BubColors.darkSurface,
    card: BubColors.darkCard,
    dialog: BubColors.darkDialog,
    textPrimary: BubColors.textPrimaryDark,
    textSecondary: BubColors.textSecondaryDark,
    textHint: BubColors.textHintDark,
    bottomNavBackground: BubColors.darkSurface,
    divider: BubColors.darkCard,
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color card,
    required Color dialog,
    required Color textPrimary,
    required Color textSecondary,
    required Color textHint,
    required Color bottomNavBackground,
    required Color divider,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: BubColors.purple,
      brightness: brightness,
      primary: BubColors.purple,
      secondary: BubColors.pink,
      tertiary: BubColors.violet,
      surface: surface,
      error: BubColors.notification,
    );

    final textTheme = ThemeData(
      brightness: brightness,
      useMaterial3: true,
    ).textTheme.apply(bodyColor: textPrimary, displayColor: textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      cardColor: card,
      dialogTheme: DialogThemeData(backgroundColor: dialog),
      dividerColor: divider,
      disabledColor: BubColors.disabled,
      hintColor: textHint,
      textTheme: textTheme.copyWith(
        bodyMedium: textTheme.bodyMedium?.copyWith(color: textSecondary),
        bodySmall: textTheme.bodySmall?.copyWith(color: textHint),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: scaffold,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bottomNavBackground,
        selectedItemColor: BubColors.purple,
        unselectedItemColor: textHint,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BubColors.purple,
          foregroundColor: BubColors.white,
          disabledBackgroundColor: BubColors.disabled,
          disabledForegroundColor: textHint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: BubColors.purple),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: TextStyle(color: textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BubColors.purple, width: 1.5),
        ),
      ),
    );
  }
}
