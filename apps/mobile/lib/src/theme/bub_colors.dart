import 'package:flutter/material.dart';

class BubColors {
  const BubColors._();

  static const purple = Color(0xFF7C3AED);
  static const deepPurple = Color(0xFF4C1D95);
  static const violet = Color(0xFFA78BFA);
  static const pink = Color(0xFFFF5EA8);
  static const coral = Color(0xFFFF7A9E);

  static const darkScaffold = Color(0xFF100A1F);
  static const darkSurface = Color(0xFF18102A);
  static const darkCard = Color(0xFF221638);
  static const darkDialog = Color(0xFF2B1D46);

  static const lightScaffold = white;
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFCFAFF);
  static const lightDialog = Color(0xFFFFFFFF);

  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFFC8C5D8);
  static const textHintDark = Color(0xFF8B89A5);

  static const textPrimaryLight = Color(0xFF211638);
  static const textSecondaryLight = Color(0xFF655A7C);
  static const textHintLight = Color(0xFF9C91B5);

  static const heart = pink;
  static const notification = Color(0xFFFF4F9A);
  static const success = Color(0xFF66D28F);
  static const warning = Color(0xFFFFC56E);
  static const divider = Color(0xFFE7DDF7);
  static const disabled = Color(0xFF6A687E);

  static const myBubble = purple;
  static const partnerBubbleDark = Color(0xFF2C2142);
  static const partnerBubbleLight = Color(0xFFF6EEFF);

  static const chatCanvasLightTop = Color(0xFFF7F1FF);
  static const chatCanvasLightBottom = Color(0xFFFFFBFE);
  static const chatCanvasDarkTop = Color(0xFF161022);
  static const chatCanvasDarkBottom = Color(0xFF100A1F);

  static const safeBackground = deepPurple;
  static const doodleYellow = Color(0xFFFFD56A);
  static const doodleGreen = Color(0xFF73D98D);
  static const doodleBlue = Color(0xFF53B8FF);
  static const doodleLavender = Color(0xFFC79DFF);
  static const white = Color(0xFFFFFFFF);

  /// Soft sandy halo behind the home hero bears (sampled from Alan iOS).
  static const heroHalo = Color(0xFFFCEBD7);
  static const heroHaloDark = Color(0xFF3A2E28);

  static const bubGradient = LinearGradient(colors: [deepPurple, purple, pink]);

  static const loginButtonGradient = LinearGradient(
    colors: [purple, deepPurple, pink],
  );

  static const bubButtonGradient = LinearGradient(
    colors: [purple, deepPurple, pink],
  );

  static const chatBubbleGradient = LinearGradient(
    colors: [deepPurple, purple, pink],
  );

  static LinearGradient homeTodayMomentGradient(Brightness brightness) {
    return brightness == Brightness.dark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              deepPurple.withValues(alpha: 0.96),
              darkCard,
              pink.withValues(alpha: 0.36),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [partnerBubbleLight, white, pink.withValues(alpha: 0.12)],
          );
  }

  static LinearGradient homePartnerGradient(Brightness brightness) {
    return brightness == Brightness.dark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkCard, Color(0xFF201C3A), Color(0xFF172637)],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [white, Color(0xFFF7F2FF), Color(0xFFEFF8FF)],
          );
  }

  static LinearGradient homeLatestBubGradient(Brightness brightness) {
    return brightness == Brightness.dark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkSurface, Color(0xFF20273B), Color(0xFF2B1D46)],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [white, Color(0xFFFFF3F8), Color(0xFFF5F0FF)],
          );
  }

  static LinearGradient homeMoodGradient(Brightness brightness) {
    return brightness == Brightness.dark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkCard, Color(0xFF2A1D3B), Color(0xFF3A1E3E)],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [white, Color(0xFFFFF2F8), Color(0xFFF4ECFF)],
          );
  }

  static LinearGradient chatCanvasGradient(Brightness brightness) {
    return brightness == Brightness.dark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [chatCanvasDarkTop, chatCanvasDarkBottom],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [chatCanvasLightTop, chatCanvasLightBottom],
          );
  }
}
