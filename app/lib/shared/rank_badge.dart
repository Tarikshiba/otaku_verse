import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../features/economy/economy_v92_service.dart';

/// === BADGE DE RANG OFFICIEL PERMANENT (ECO-04 / UI-05) ===
/// Affiche toujours le rang merite par l'XP (et la Division en mode classe)
/// dans un cartouche dedie, totalement separe des cadres d'avatar achetes.
class OfficialRankBadge extends StatelessWidget {
  final int niveau;
  final int? divisionId;
  final bool compact;

  const OfficialRankBadge({
    super.key,
    required this.niveau,
    this.divisionId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final titre = EconomyV92Service.titreRangOfficiel(niveau);
    final couleur = EconomyV92Service.couleurBadgeRang(niveau);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: couleur.withValues(alpha: 0.65), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, size: compact ? 11 : 13, color: couleur),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              divisionId != null ? 'Nv.$niveau · $titre · D$divisionId' : 'Nv.$niveau · $titre',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OtakuTypo.label.copyWith(
                fontSize: compact ? 9 : 10,
                color: couleur,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// === CONTENEUR D'AVATAR / GOODIES NON COUPE (TICKET UI-01) ===
/// Garantit BoxFit.contain + Alignment.topCenter + padding superieur >= 12 px
/// pour ne jamais couper le haut du crane, les cornes ou les armes d'un skin.
class SafeAvatarBox extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final double topPadding;
  final double borderRadius;
  final Color borderColor;

  const SafeAvatarBox({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.topPadding = 12,
    this.borderRadius = 16,
    this.borderColor = OtakuColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.only(top: topPadding, left: 6, right: 6, bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            borderColor.withValues(alpha: 0.14),
            OtakuColors.surface,
          ],
        ),
        border: Border.all(color: borderColor.withValues(alpha: 0.55), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular((borderRadius - 4).clamp(4, 30)),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          errorBuilder: (_, _, _) => Icon(
            Icons.person_rounded,
            size: 48,
            color: borderColor.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
