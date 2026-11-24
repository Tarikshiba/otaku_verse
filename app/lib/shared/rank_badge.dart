import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../features/economy/economy_v92_service.dart';

/// === BADGE DE RANG OFFICIEL PERMANENT (ECO-04 / UI-05 / PHASE A5) ===
/// Affiche toujours le rang merite par l'XP (avec la vraie medaille PNG du rang)
/// dans un cartouche dedie, totalement separe des cadres d'avatar achetes.
class OfficialRankBadge extends StatelessWidget {
  final int niveau;
  final int? divisionId;
  final bool compact;
  final bool prominent;

  const OfficialRankBadge({
    super.key,
    required this.niveau,
    this.divisionId,
    this.compact = false,
    this.prominent = false,
  });

  /// Chemin officiel de l'embleme PNG selon la tranche de niveau (OTAKU_VERSE_PERSONNAGES.md)
  static String assetPourNiveau(int niveau) {
    if (niveau <= 5) return 'assets/images/ranks/rank_1_bronze.png';
    if (niveau <= 15) return 'assets/images/ranks/rank_2_acier.png';
    if (niveau <= 30) return 'assets/images/ranks/rank_3_argent.png';
    if (niveau <= 50) return 'assets/images/ranks/rank_4_or.png';
    if (niveau <= 75) return 'assets/images/ranks/rank_5_platine.png';
    return 'assets/images/ranks/rank_6_legende.png';
  }

  @override
  Widget build(BuildContext context) {
    final titre = EconomyV92Service.titreRangOfficiel(niveau);
    final couleur = EconomyV92Service.couleurBadgeRang(niveau);
    final double iconSize = prominent ? 20 : (compact ? 14 : 16);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: prominent ? 10 : (compact ? 6 : 8),
        vertical: prominent ? 5 : (compact ? 2 : 4),
      ),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: prominent ? 0.24 : 0.16),
        borderRadius: BorderRadius.circular(prominent ? 10 : 8),
        border: Border.all(
          color: couleur.withValues(alpha: prominent ? 0.95 : 0.65),
          width: prominent ? 1.5 : 1,
        ),
        boxShadow: prominent
            ? [
                BoxShadow(
                  color: couleur.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            assetPourNiveau(niveau),
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.shield_rounded,
              size: iconSize - 2,
              color: couleur,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              divisionId != null ? 'Nv.$niveau · $titre · D$divisionId' : 'Nv.$niveau · $titre',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OtakuTypo.label.copyWith(
                fontSize: prominent ? 11 : (compact ? 9 : 10),
                color: couleur,
                letterSpacing: 0.4,
                fontWeight: prominent ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// === CONTENEUR D'AVATAR / GOODIES NON COUPE + CADRE COSMETIQUE (UI-01 & PHASE A5) ===
/// Garantit BoxFit.contain + Alignment.topCenter + padding superieur >= 12 px
/// pour ne jamais couper le haut du crane, les cornes ou les armes d'un skin.
/// Si `frameId` est fourni (ex: cadre_neon_shonen, cadre_vip_or_violet), superpose le cadre PNG transparent.
class SafeAvatarBox extends StatelessWidget {
  final String assetPath;
  final String? frameId;
  final double? width;
  final double? height;
  final double topPadding;
  final double borderRadius;
  final Color borderColor;

  const SafeAvatarBox({
    super.key,
    required this.assetPath,
    this.frameId,
    this.width,
    this.height,
    this.topPadding = 12,
    this.borderRadius = 16,
    this.borderColor = OtakuColors.accent,
  });

  static const Set<String> validFrames = {
    'cadre_neon_shonen',
    'cadre_flamme_astral',
    'cadre_eclipse_or',
    'cadre_vip_or_violet',
  };

  @override
  Widget build(BuildContext context) {
    final bool hasFrame = frameId != null && validFrames.contains(frameId);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          Container(
            margin: EdgeInsets.all(hasFrame ? 3 : 0),
            padding: EdgeInsets.only(top: topPadding, left: 6, right: 6, bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  borderColor.withValues(alpha: 0.16),
                  OtakuColors.surface,
                ],
              ),
              border: hasFrame
                  ? null
                  : Border.all(color: borderColor.withValues(alpha: 0.55), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular((borderRadius - 4).clamp(4, 30)),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) => Icon(
                  Icons.person_rounded,
                  size: 40,
                  color: borderColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          if (hasFrame)
            IgnorePointer(
              child: Image.asset(
                'assets/images/frames/$frameId.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}
