import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../core/feature_flags_service.dart';

/// === SELECTEUR DE MODES PLEIN ECRAN STYLE FREE FIRE (PHASE A3) ===
/// - Fond immersif `modes_selector_bg.webp`
/// - 2 onglets : MODES OFFICIELS / COMMUNAUTE
/// - Onglet Officiels : 2 grandes cartes verticales phares (DIVISION, SOLO) a gauche
///   + grille 2x2 des 4 autres modes (.webp) a droite
/// - Onglet Communaute : Salons Live JKLM & Donjons Otaku Forge (.webp)
/// - Retourne le code du mode choisi (ou null si annule). Pour un mode verrouille,
///   appelle `onLockedTap` afin d'ouvrir directement le modal "M'alerter".
class ModeSelectorPage extends StatefulWidget {
  final String modeActif;
  final FeatureFlagsService flagsService;
  final Future<void> Function(String titreMode, String flagKey) onLockedTap;

  const ModeSelectorPage({
    super.key,
    required this.modeActif,
    required this.flagsService,
    required this.onLockedTap,
  });

  @override
  State<ModeSelectorPage> createState() => _ModeSelectorPageState();
}

class _ModeSelectorPageState extends State<ModeSelectorPage> {
  int _tab = 0; // 0 = MODES OFFICIELS, 1 = COMMUNAUTE

  void _handleSelect({
    required String code,
    required String titre,
    required String flagKey,
  }) {
    if (widget.flagsService.estOuvert(flagKey)) {
      Navigator.pop(context, code);
    } else {
      widget.onLockedTap(titre, flagKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond immersif dedie au selecteur de modes
          Image.asset(
            'assets/images/backgrounds/modes_selector_bg.webp',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: OtakuColors.background),
          ),
          // Voile sombre pour un contraste net sur toutes les cartes
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                children: [
                  // === TOP BAR : Retour + Titre + 2 Onglets ===
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: LiquidGlass(
                          padding: const EdgeInsets.all(8),
                          borderRadius: 12,
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'CHOISIR UN MODE',
                        style: OtakuTypo.headlineLarge.copyWith(fontSize: 18, letterSpacing: 1.2),
                      ),
                      const Spacer(),
                      _buildTabPill('MODES OFFICIELS', 0, Icons.military_tech_rounded),
                      const SizedBox(width: 8),
                      _buildTabPill('COMMUNAUTÉ', 1, Icons.groups_rounded),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // === CONTENU PRINCIPAL ===
                  Expanded(
                    child: _tab == 0 ? _buildOfficielsGrid() : _buildCommunauteGrid(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(String label, int index, IconData icon) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? OtakuColors.accent.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? OtakuColors.accent : Colors.white.withValues(alpha: 0.18),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? OtakuColors.accent : OtakuColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: OtakuTypo.label.copyWith(
                fontSize: 10,
                color: active ? Colors.white : OtakuColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Onglet 0 : 2 grandes cartes verticales phares a gauche + grille 2x2 a droite
  Widget _buildOfficielsGrid() {
    return Row(
      children: [
        // Gauche (flex 5) : DIVISION & SOLO en grand format vertical
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  code: 'DIVISION',
                  titre: 'DIVISION',
                  sousTitre: 'Classement Mondial · 10 Paliers',
                  badge: 'CLASSÉ',
                  assetPath: 'assets/images/modes/mode_division_tall.webp',
                  flagKey: 'mode_division',
                  accent: OtakuColors.modeDivision,
                  tall: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildModeCard(
                  code: 'SOLO',
                  titre: 'SOLO',
                  sousTitre: 'Duel 350 PV · 21 Œuvres',
                  badge: '0 OC NIV. 1-5',
                  assetPath: 'assets/images/modes/mode_solo_tall.webp',
                  flagKey: 'mode_solo',
                  accent: OtakuColors.modeSolo,
                  tall: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Droite (flex 6) : 4 modes en grille 2x2 propre et scrollable
        Expanded(
          flex: 6,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildModeCard(
                        code: 'DUEL',
                        titre: 'DUEL 1v1',
                        sousTitre: 'Défie un ami en direct',
                        assetPath: 'assets/images/modes/mode_duel_card.webp',
                        flagKey: 'mode_duel_ami',
                        accent: OtakuColors.modeDuel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModeCard(
                        code: 'COOP',
                        titre: 'COOP 2v2 / BOSS',
                        sousTitre: 'Duo 2vIA & Raids',
                        assetPath: 'assets/images/modes/mode_coop_card.webp',
                        flagKey: 'mode_coop',
                        accent: OtakuColors.modeCoop,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildModeCard(
                        code: 'BATTLE_ROYALE',
                        titre: 'BATTLE ROYALE',
                        sousTitre: 'Survie 10 joueurs',
                        assetPath: 'assets/images/modes/mode_br_card.webp',
                        flagKey: 'mode_battle_royale',
                        accent: Colors.deepOrangeAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModeCard(
                        code: 'EVENTS',
                        titre: 'SAISONS & TOURNOIS',
                        sousTitre: 'Événements spéciaux',
                        assetPath: 'assets/images/modes/mode_events_card.webp',
                        flagKey: 'mode_events_tournois',
                        accent: OtakuColors.modeEvent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Onglet 1 : Modes Communaute (Salons Live & Donjons Otaku Forge)
  Widget _buildCommunauteGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildModeCard(
            code: 'SALONS_LIVE',
            titre: 'SALONS LIVE JKLM',
            sousTitre: 'Parties privées et soirées entre amis',
            badge: 'GRATUIT VIP · 150 VC',
            assetPath: 'assets/images/modes/mode_salon_live_card.webp',
            flagKey: 'mode_salon_live',
            accent: const Color(0xFFFF4D9D),
            tall: true,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildModeCard(
            code: 'DONJONS',
            titre: 'DONJONS OTAKU FORGE',
            sousTitre: 'Crée et affronte des donjons communautaires',
            badge: 'GRATUIT VIP · 100 VC',
            assetPath: 'assets/images/modes/mode_donjon_card.webp',
            flagKey: 'mode_donjons',
            accent: const Color(0xFFFF8A00),
            tall: true,
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required String code,
    required String titre,
    required String sousTitre,
    required String assetPath,
    required String flagKey,
    required Color accent,
    String? badge,
    bool tall = false,
  }) {
    final bool ouvert = widget.flagsService.estOuvert(flagKey);
    final String launchLabel = widget.flagsService.labelLancement(flagKey);
    final bool selected = widget.modeActif == code && ouvert;

    return GestureDetector(
      onTap: () => _handleSelect(code: code, titre: titre, flagKey: flagKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: OtakuColors.surface,
          border: Border.all(
            color: selected
                ? accent
                : (ouvert ? accent.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.16)),
            width: selected ? 2.4 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.42),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Artwork plein cadre
            Opacity(
              opacity: ouvert ? 1.0 : 0.42,
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: OtakuColors.surface),
              ),
            ),

            // Degrade bas pour la lisibilite du titre
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.45, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.90),
                  ],
                ),
              ),
            ),

            // Badge haut-gauche + Etat selectionne / verrouille haut-droite
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  if (badge != null && ouvert)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (!ouvert)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: OtakuColors.modeEvent.withValues(alpha: 0.8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded, size: 11, color: OtakuColors.modeEvent),
                          const SizedBox(width: 4),
                          Text(
                            'BIENTÔT',
                            style: OtakuTypo.label.copyWith(fontSize: 8.5, color: OtakuColors.modeEvent),
                          ),
                        ],
                      ),
                    )
                  else if (selected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, size: 12, color: Colors.black),
                          SizedBox(width: 3),
                          Text('ACTIF', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.black)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Titre + sous-titre en bas
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OtakuTypo.headlineLarge.copyWith(
                      fontSize: tall ? 18 : 14,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ouvert ? sousTitre : launchLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OtakuTypo.bodySmall.copyWith(
                      fontSize: tall ? 10.5 : 9.5,
                      color: ouvert ? Colors.white70 : OtakuColors.modeEvent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
