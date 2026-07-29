import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// === PALETTE DE COULEURS OTAKU VERSE — DA V2.1 ===
class OtakuColors {
  // Fond absolu
  static const Color background = Color(0xFF0A0A0F);

  // Fond cartes / conteneurs
  static const Color surface = Color(0xFF141419);

  // Bordure subtile
  static const Color border = Color(0xFF2A2A35);

  // Violet signature (Solo, marque, XP)
  static const Color accent = Color(0xFF7B2FF7);

  // Violet glow (halos, reflets)
  static const Color accentGlow = Color(0xFFA970FF);

  // Variante sombre
  static const Color accentDark = Color(0xFF4A0FA0);

  // Couleurs par mode de jeu
  static const Color modeSolo = Color(0xFF7B2FF7);
  static const Color modeDivision = Color(0xFFF72F4E);
  static const Color modeCoop = Color(0xFF2F8FF7);
  static const Color modeDuel = Color(0xFFFF7A2F);
  static const Color modeEvent = Color(0xFFF7B32F);

  // PV
  static const Color pvHaut = Color(0xFF2ECC71);
  static const Color pvMoyen = Color(0xFFF7B32F);
  static const Color pvCritique = Color(0xFFFF2E4D);

  // Combo
  static const Color combo2 = Color(0xFFA970FF);
  static const Color combo3 = Color(0xFFFFD23F);

  // Resultats
  static const Color victoire = Color(0xFF3FFFB0);
  static const Color defaite = Color(0xFFFF2E5C);

  // Texte
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF666666);

  // Legacy (retrocompatibilite avec le code existant)
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFFF2E5C);
  static const Color warning = Color(0xFFF7B32F);
  static const Color accentLight = Color(0xFFA970FF);

  // Liquid Glass
  static const Color glassBackground = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color glassBorder = Color(0x24FFFFFF); // rgba(255,255,255,0.14)
  static const Color glassShadow = Color(0x73000000); // rgba(0,0,0,0.45)
}

/// === TYPOGRAPHIE — DA V2.1 ===
/// Anton/Bebas Neue : titres impact
/// Bangers : onomatopees
/// Manrope : UI courante
/// Space Grotesk : chiffres/HUD
class OtakuTypo {
  // Titre principal (ecran d'accueil, nom de l'app) — Anton
  static TextStyle displayLarge = GoogleFonts.anton(
    fontSize: 32,
    color: OtakuColors.textPrimary,
    letterSpacing: 4,
  );

  // Titre de section — Bebas Neue
  static TextStyle headlineLarge = GoogleFonts.bebasNeue(
    fontSize: 24,
    color: OtakuColors.textPrimary,
    letterSpacing: 2,
  );

  // Sous-titre — Manrope bold
  static TextStyle headlineSmall = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: OtakuColors.textPrimary,
    letterSpacing: 0.5,
  );

  // Corps de texte — Manrope
  static TextStyle bodyLarge = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: OtakuColors.textPrimary,
    height: 1.5,
  );

  // Texte secondaire — Manrope
  static TextStyle bodySmall = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: OtakuColors.textSecondary,
  );

  // Labels (boutons, badges, tags) — Manrope bold
  static TextStyle label = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: OtakuColors.textPrimary,
    letterSpacing: 1.2,
  );

  // Onomatopees / feedback fort — Bangers
  static TextStyle impact = GoogleFonts.bangers(
    fontSize: 28,
    color: OtakuColors.accent,
    letterSpacing: 3,
  );

  // Chiffres HUD (PV, XP, timer) — Space Grotesk
  static TextStyle hud = GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: OtakuColors.textPrimary,
  );

  // Tab bar label — Manrope
  static TextStyle tabLabel = GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: OtakuColors.textSecondary,
  );
}

/// === WIDGET LIQUID GLASS REUTILISABLE ===
/// Surface en verre floute avec bordure subtile et ombre.
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final Color? tintColor; // null = verre neutre, sinon teinte par mode
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const LiquidGlass({
    super.key,
    required this.child,
    this.tintColor,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = tintColor != null
        ? tintColor!.withValues(alpha: 0.18)
        : OtakuColors.glassBackground;
    final borderColor = tintColor != null
        ? tintColor!.withValues(alpha: 0.35)
        : OtakuColors.glassBorder;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: OtakuColors.glassShadow,
            blurRadius: 32,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: tintColor != null ? 20 : 24,
            sigmaY: tintColor != null ? 20 : 24,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// === THEME FLUTTER GLOBAL ===
final ThemeData otakuTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: OtakuColors.background,
  colorScheme: const ColorScheme.dark(
    primary: OtakuColors.accent,
    secondary: OtakuColors.accentGlow,
    surface: OtakuColors.surface,
    error: OtakuColors.error,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: OtakuColors.textPrimary,
    onError: Colors.white,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: OtakuColors.background,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: OtakuTypo.headlineLarge,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: OtakuColors.accent,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: OtakuTypo.label,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: OtakuColors.accent,
      side: const BorderSide(color: OtakuColors.accent, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: OtakuTypo.label,
    ),
  ),
  cardTheme: CardThemeData(
    color: OtakuColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: OtakuColors.border, width: 1),
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: OtakuColors.accent,
    linearTrackColor: OtakuColors.border,
  ),
);
