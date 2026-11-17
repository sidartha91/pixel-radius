import 'package:flutter/material.dart';

/// Palette officielle Pixel Radius (AAI Studio).
class PixelColors {
  PixelColors._();

  // Thème sombre — Cyber-Soul
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color amber = Color(0xFFE5A93C);
  static const Color neonPink = Color(0xFFFF007F);

  // Thème clair — Vinyle Vintage
  static const Color lightBackground = Color(0xFFF5F2EB);
  static const Color lightSurface = Color(0xFFEAE5D9);
  static const Color ink = Color(0xFF000000);
  static const Color terracotta = Color(0xFFC86446);

  // Feedback (communs aux deux thèmes)
  static const Color correct = Color(0xFF00FF66);
  static const Color partial = Color(0xFFFF9500);
  static const Color wrong = Color(0xFFFF3B3B);

  // Focus TV / manette / clavier
  static const Color focusRing = Color(0xFFE5A93C);
  static const double focusRingWidth = 2.5;
  static const double focusScale = 1.03;
}

/// Extension de thème : expose les couleurs métier à tous les widgets.
@immutable
class PixelPalette extends ThemeExtension<PixelPalette> {
  const PixelPalette({
    required this.background,
    required this.surface,
    required this.accent,
    required this.secondary,
    required this.onSurface,
    required this.muted,
  });

  final Color background;
  final Color surface;
  final Color accent;
  final Color secondary;
  final Color onSurface;
  final Color muted;

  static const PixelPalette dark = PixelPalette(
    background: PixelColors.darkBackground,
    surface: PixelColors.darkSurface,
    accent: PixelColors.amber,
    secondary: PixelColors.neonPink,
    onSurface: Color(0xFFF2EDE4),
    muted: Color(0xFF8A8478),
  );

  static const PixelPalette light = PixelPalette(
    background: PixelColors.lightBackground,
    surface: PixelColors.lightSurface,
    accent: PixelColors.ink,
    secondary: PixelColors.terracotta,
    onSurface: Color(0xFF111111),
    muted: Color(0xFF6E665A),
  );

  static PixelPalette of(BuildContext context) =>
      Theme.of(context).extension<PixelPalette>() ?? dark;

  @override
  PixelPalette copyWith({
    Color? background,
    Color? surface,
    Color? accent,
    Color? secondary,
    Color? onSurface,
    Color? muted,
  }) {
    return PixelPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      accent: accent ?? this.accent,
      secondary: secondary ?? this.secondary,
      onSurface: onSurface ?? this.onSurface,
      muted: muted ?? this.muted,
    );
  }

  @override
  PixelPalette lerp(ThemeExtension<PixelPalette>? other, double t) {
    if (other is! PixelPalette) return this;
    return PixelPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(Brightness.dark, PixelPalette.dark);
  static ThemeData get light => _build(Brightness.light, PixelPalette.light);

  static ThemeData _build(Brightness brightness, PixelPalette p) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: brightness == Brightness.dark ? PixelColors.darkBackground : PixelColors.lightBackground,
      secondary: p.secondary,
      onSecondary: Colors.white,
      error: PixelColors.wrong,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.onSurface,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      splashFactory: InkSparkle.splashFactory,
      focusColor: PixelColors.focusRing.withValues(alpha: 0.18),
      extensions: <ThemeExtension<dynamic>>[p],
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: p.onSurface,
        displayColor: p.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      iconTheme: IconThemeData(color: p.onSurface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surface,
        contentTextStyle: TextStyle(color: p.onSurface),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(backgroundColor: p.surface),
    );
  }
}
