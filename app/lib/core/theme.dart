import 'package:flutter/material.dart';

/// === PALETTE DE COULEURS OTAKU VERSE ===
/// Fond quasi-noir, accent violet electrique unique, texte blanc/gris.
class OtakuColors {
  // Fond principal (quasi-noir, pas du pur noir pour eviter la fatigue oculaire)
  static const Color background = Color(0xFF0A0A0A);

  // Fond des cartes / conteneurs secondaires
  static const Color surface = Color(0xFF141414);

  // Bordure subtile sur les cartes
  static const Color border = Color(0xFF2A2A2A);

  // Accent principal — violet electrique
  static const Color accent = Color(0xFF7B2FF7);

  // Variante plus claire de l'accent (pour hover, splash)
  static const Color accentLight = Color(0xFF9B5FF9);

  // Variante plus sombre (pour fonds teintes)
  static const Color accentDark = Color(0xFF4A0FA0);

  // Texte principal
  static const Color textPrimary = Color(0xFFFFFFFF);

  // Texte secondaire (descriptions, sous-titres)
  static const Color textSecondary = Color(0xFFB0B0B0);

  // Texte desactive / placeholder
  static const Color textMuted = Color(0xFF666666);

  // Succes (bonne reponse)
  static const Color success = Color(0xFF00E676);

  // Erreur (mauvaise reponse)
  static const Color error = Color(0xFFFF1744);

  // Avertissement
  static const Color warning = Color(0xFFFFA726);
}

/// === TYPOGRAPHIE ===
/// Titres : gras, espacement large, impact.
/// Corps : sobre, lisible.
class OtakuTypo {
  // Titre principal (ecran d'accueil, nom de l'app)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: OtakuColors.textPrimary,
    letterSpacing: 6,
  );

  // Titre de section (JOUER, PROFIL, etc.)
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: OtakuColors.textPrimary,
    letterSpacing: 2,
  );

  // Sous-titre / nom d'anime
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: OtakuColors.textPrimary,
    letterSpacing: 1,
  );

  // Corps de texte (questions, descriptions)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: OtakuColors.textPrimary,
    height: 1.5,
  );

  // Texte secondaire (sous-titres, infos)
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: OtakuColors.textSecondary,
  );

  // Labels (boutons, badges, tags)
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: OtakuColors.textPrimary,
    letterSpacing: 1.5,
  );

  // Onomatopees / feedback fort (PARFAIT!, K.O., LEVEL UP!)
  static const TextStyle impact = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: OtakuColors.accent,
    letterSpacing: 3,
  );
}

/// === THEME FLUTTER GLOBAL ===
/// A passer dans MaterialApp(theme: otakuTheme)
final ThemeData otakuTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: OtakuColors.background,
  colorScheme: const ColorScheme.dark(
    primary: OtakuColors.accent,
    secondary: OtakuColors.accentLight,
    surface: OtakuColors.surface,
    error: OtakuColors.error,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: OtakuColors.textPrimary,
    onError: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: OtakuColors.background,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: OtakuTypo.headlineLarge,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: OtakuColors.accent,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: OtakuTypo.label,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: OtakuColors.accent,
      side: const BorderSide(color: OtakuColors.accent, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: OtakuTypo.label,
    ),
  ),
  cardTheme: CardThemeData(
    color: OtakuColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: const BorderSide(color: OtakuColors.border, width: 1),
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: OtakuColors.accent,
    linearTrackColor: OtakuColors.border,
  ),
);
