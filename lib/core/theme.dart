import 'package:flutter/material.dart';

/// Palette « supercar néon » : fond quasi noir, rouge et cyan électriques.
class Neon {
  Neon._();

  static const Color bg = Color(0xFF06070C);
  static const Color panel = Color(0xFF0E1018);
  static const Color panelHi = Color(0xFF171A27);
  static const Color red = Color(0xFFFF1F4B);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color amber = Color(0xFFFFB020);
  static const Color text = Color(0xFFE9ECF5);
  static const Color textDim = Color(0xFF7C8396);

  /// Même couleur avec une opacité de 0.0 à 1.0.
  /// (withAlpha marche sur toutes les versions de Flutter, contrairement à
  /// withOpacity / withValues dont l'API a changé récemment.)
  static Color fade(Color c, double opacity) {
    final double o = opacity < 0 ? 0.0 : (opacity > 1 ? 1.0 : opacity);
    return c.withAlpha((o * 255).round());
  }

  /// Halo lumineux néon (à mettre dans BoxDecoration.boxShadow).
  static List<BoxShadow> glow(Color c, {double strength = 1}) => <BoxShadow>[
        BoxShadow(color: fade(c, 0.55), blurRadius: 16 * strength),
        BoxShadow(
          color: fade(c, 0.25),
          blurRadius: 40 * strength,
          spreadRadius: 2 * strength,
        ),
      ];
}

/// Police d'affichage. Si Orbitron n'est pas ajoutée au projet, Flutter
/// retombe sur la police par défaut : le rendu reste correct.
const String kDisplayFont = 'Orbitron';

TextStyle displayStyle({
  double size = 18,
  Color color = Neon.text,
  FontWeight weight = FontWeight.w800,
  double spacing = 2,
}) {
  return TextStyle(
    fontFamily: kDisplayFont,
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: spacing,
  );
}

/// Valeur bornée entre [lo] et [hi] (évite les surprises de num.clamp).
double clampD(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Neon.bg,
    colorScheme: const ColorScheme.dark(
      primary: Neon.cyan,
      secondary: Neon.red,
      surface: Neon.panel,
      error: Neon.red,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Neon.cyan : Neon.textDim,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Neon.fade(Neon.cyan, 0.30)
            : Neon.panelHi,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Neon.cyan
            : const Color(0xFF2A2F42),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Neon.panelHi,
      contentTextStyle: TextStyle(color: Neon.text),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
