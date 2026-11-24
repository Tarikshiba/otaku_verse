import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/rank_badge.dart';
import '../../shared/skin_3d_viewer.dart';
import '../progression/progression_service.dart';
import '../skins/boutique_screen.dart';
import '../skins/skin_model.dart';
import '../skins/skin_service.dart';
import '../social/classement_screen.dart';
import '../tutorial/tutorial_service.dart';
import 'guide_jeu_page.dart';
import 'parametres_page.dart';
import 'verse_analytics_page.dart';

/// === ECRAN PROFIL 3 COLONNES STYLE FREE FIRE (PHASE A4 & A5) ===
/// - Fond immersif `profil_podium_bg.webp`
/// - Colonne gauche : onglets verticaux (Apercu, Collection, Classement, Analytics, Guide, Parametres)
/// - Colonne centrale : personnage en grand sur podium 3D .glb interactif 360° + changer de skin
/// - Colonne droite : fiche joueur aeree avec avatar encadre, vraie medaille de rang PNG et stats
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProgressionService _progressionService = ProgressionService();
  final SkinService _skinService = SkinService();

  Map<String, dynamic>? _profil;
  bool _chargement = true;
  int _ongletActif = 0; // 0 = Apercu, 1 = Collection
  List<Skin> _mesSkins = [];
  List<String> _mesCadres = [];
  String? _cadreEquipe;
  Skin _skinActif = SkinService.catalogueOfficiel.first;

  @override
  void initState() {
    super.initState();
    TutorialService().marquerVisiteEtape(5);
    _chargerTout();
  }

  Future<void> _chargerTout() async {
    try {
      await _progressionService.creerProfilSiAbsent();
      final results = await Future.wait([
        _progressionService.recupererProfil(),
        _skinService.tousLesSkins(),
      ]);
      final profil = results[0] as Map<String, dynamic>?;
      final allSkins = results[1] as List<Skin>;
      final isVip = profil?['is_vip'] == true;
      final cadres = await _skinService.cadresPossedes(isVip: isVip);
      final cadreActif = await _skinService.recupererCadreEquipe(isVip: isVip);

      if (!mounted) return;
      final possedes = allSkins.where((s) => s.owned).toList();
      final equipe = possedes.where((s) => s.equipped).firstOrNull ?? SkinService.catalogueOfficiel.first;
      setState(() {
        _profil = profil;
        _mesSkins = possedes;
        _skinActif = equipe;
        _mesCadres = cadres;
        _cadreEquipe = cadreActif;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _equiperSkin(Skin skin) async {
    await _skinService.equiper(skin.id);
    await _chargerTout();
  }

  Future<void> _changerSkinSuivant() async {
    if (_mesSkins.length <= 1) return;
    final idx = _mesSkins.indexWhere((s) => s.id == _skinActif.id);
    final next = _mesSkins[(idx + 1) % _mesSkins.length];
    await _equiperSkin(next);
  }

  Future<void> _equiperCadre(String? frameId) async {
    await _skinService.equiperCadre(frameId);
    if (mounted) setState(() => _cadreEquipe = frameId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/backgrounds/profil_podium_bg.webp',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: OtakuColors.background),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),
          SafeArea(
            child: _chargement
                ? const Center(child: CircularProgressIndicator(color: OtakuColors.accent))
                : _buildContenu3Colonnes(),
          ),
        ],
      ),
    );
  }

  Widget _buildContenu3Colonnes() {
    final xpTotale = (_profil?['xp_totale'] as num?)?.toInt() ?? 0;
    final niveau = (_profil?['niveau'] as num?)?.toInt() ?? 1;
    final divisionId = (_profil?['division_id'] as num?)?.toInt();
    final activeTitle = _profil?['active_title']?.toString();
    final combatsJoues = (_profil?['combats_joues'] as num?)?.toInt() ?? 0;
    final combatsGagnes = (_profil?['combats_gagnes'] as num?)?.toInt() ?? 0;
    final pseudo = _profil?['pseudo']?.toString() ?? 'Joueur';
    final country = _profil?['country']?.toString();
    final isVip = _profil?['is_vip'] == true;

    final xpDansNiveau = ProgressionService.xpDansNiveauActuel(xpTotale);
    final xpPourProchain = ProgressionService.xpRequise(niveau);
    final progressionXp = xpPourProchain > 0 ? (xpDansNiveau / xpPourProchain).clamp(0.0, 1.0) : 0.0;
    final tauxVictoire = combatsJoues > 0 ? ((combatsGagnes / combatsJoues) * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 14, 12),
      child: Column(
        children: [
          // === TOP BAR ===
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: LiquidGlass(
                  padding: const EdgeInsets.all(8),
                  borderRadius: 10,
                  child: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Text('PROFIL DU COMBATTANT', style: OtakuTypo.headlineLarge.copyWith(fontSize: 17)),
              const Spacer(),
              if (activeTitle != null && activeTitle.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: OtakuColors.modeEvent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: OtakuColors.modeEvent.withValues(alpha: 0.7)),
                  ),
                  child: Text(
                    activeTitle,
                    style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.modeEvent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // === DISPOSITION 3 COLONNES FREE FIRE ===
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. COLONNE GAUCHE : Navigation verticale
                SizedBox(
                  width: 138,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildNavItem('Aperçu', Icons.badge_rounded, selected: _ongletActif == 0, onTap: () => setState(() => _ongletActif = 0)),
                        const SizedBox(height: 6),
                        _buildNavItem('Collection (${_mesSkins.length})', Icons.checkroom_rounded, selected: _ongletActif == 1, onTap: () => setState(() => _ongletActif = 1)),
                        const SizedBox(height: 6),
                        _buildNavItem('Classement', Icons.leaderboard_rounded, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassementScreen(initialSection: 'xp')));
                        }),
                        const SizedBox(height: 6),
                        _buildNavItem(
                          'Verse Analytics',
                          isVip ? Icons.insights_rounded : Icons.lock_rounded,
                          accent: const Color(0xFFFFD700),
                          onTap: _ouvrirVerseAnalyticsVip,
                        ),
                        const SizedBox(height: 6),
                        _buildNavItem('Guide du jeu', Icons.menu_book_rounded, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const GuideJeuPage()));
                        }),
                        const SizedBox(height: 6),
                        _buildNavItem('Paramètres', Icons.settings_rounded, onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ParametresPage(
                                profil: _profil,
                                onProfilChange: _chargerTout,
                              ),
                            ),
                          );
                          _chargerTout();
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 2. COLONNE CENTRALE : Personnage 3D en grand sur podium
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      Expanded(
                        child: OtakuSkin3DViewer(
                          imageKey: _skinActif.imageKey,
                          accentColor: _skinActif.accentColor,
                          characterName: _skinActif.name,
                          characterSubtitle: _skinActif.powerName.isNotEmpty ? 'Pouvoir : ${_skinActif.powerName}' : _skinActif.role,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_mesSkins.length > 1)
                        GestureDetector(
                          onTap: _changerSkinSuivant,
                          child: LiquidGlass(
                            tintColor: _skinActif.accentColor,
                            borderRadius: 12,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.swap_horiz_rounded, size: 16, color: _skinActif.accentColor),
                                const SizedBox(width: 6),
                                Text(
                                  'SKIN SUIVANT',
                                  style: OtakuTypo.label.copyWith(fontSize: 10, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // 3. COLONNE DROITE : Fiche Joueur OU Collection interactive
                Expanded(
                  flex: 6,
                  child: _ongletActif == 0
                      ? _buildApercuFiche(
                          pseudo: pseudo,
                          niveau: niveau,
                          divisionId: divisionId,
                          country: country,
                          xpTotale: xpTotale,
                          xpDansNiveau: xpDansNiveau,
                          xpPourProchain: xpPourProchain,
                          progressionXp: progressionXp,
                          combatsJoues: combatsJoues,
                          combatsGagnes: combatsGagnes,
                          tauxVictoire: tauxVictoire,
                        )
                      : _buildCollectionPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    String label,
    IconData icon, {
    bool selected = false,
    Color accent = OtakuColors.accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.24) : Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : Colors.white.withValues(alpha: 0.14),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: selected ? accent : (accent == OtakuColors.accent ? Colors.white70 : accent)),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OtakuTypo.headlineSmall.copyWith(
                  fontSize: 10.5,
                  color: selected ? Colors.white : OtakuColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApercuFiche({
    required String pseudo,
    required int niveau,
    required int? divisionId,
    required String? country,
    required int xpTotale,
    required int xpDansNiveau,
    required int xpPourProchain,
    required double progressionXp,
    required int combatsJoues,
    required int combatsGagnes,
    required int tauxVictoire,
  }) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Carte Identite + Avatar encadre + Vrai Badge de Rang PNG
          LiquidGlass(
            tintColor: _skinActif.accentColor,
            borderRadius: 16,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SafeAvatarBox(
                  assetPath: 'assets/images/skins/${_skinActif.imageKey}.png',
                  frameId: _cadreEquipe,
                  width: 62,
                  height: 62,
                  topPadding: 4,
                  borderRadius: 14,
                  borderColor: _skinActif.accentColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '@$pseudo',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: OtakuTypo.headlineLarge.copyWith(fontSize: 16),
                            ),
                          ),
                          if (country != null && country.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: OtakuColors.border),
                                color: Colors.black.withValues(alpha: 0.35),
                              ),
                              child: Text(country, style: OtakuTypo.label.copyWith(fontSize: 8.5, color: Colors.white70)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      OfficialRankBadge(
                        niveau: niveau,
                        divisionId: divisionId,
                        prominent: true,
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: progressionXp,
                                minHeight: 6,
                                backgroundColor: OtakuColors.border,
                                valueColor: AlwaysStoppedAnimation(_skinActif.accentColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$xpDansNiveau / $xpPourProchain XP',
                            style: OtakuTypo.hud.copyWith(fontSize: 9, color: OtakuColors.modeEvent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 4 Stats en ligne
          Row(
            children: [
              Expanded(child: _buildStatCard('XP TOTALE', '$xpTotale', OtakuColors.accent, Icons.bolt_rounded)),
              const SizedBox(width: 6),
              Expanded(child: _buildStatCard('COMBATS', '$combatsJoues', OtakuColors.modeDuel, Icons.sports_mma_rounded)),
              const SizedBox(width: 6),
              Expanded(child: _buildStatCard('VICTOIRES', '$combatsGagnes', OtakuColors.victoire, Icons.emoji_events_rounded)),
              const SizedBox(width: 6),
              Expanded(child: _buildStatCard('TAUX', '$tauxVictoire%', OtakuColors.pvMoyen, Icons.pie_chart_rounded)),
            ],
          ),
          const SizedBox(height: 10),

          // Fiche du personnage actif (lore + pouvoir)
          LiquidGlass(
            borderRadius: 14,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 15, color: _skinActif.accentColor),
                    const SizedBox(width: 6),
                    Text(
                      '${_skinActif.name.toUpperCase()} · ${_skinActif.role}',
                      style: OtakuTypo.headlineSmall.copyWith(fontSize: 11.5, color: _skinActif.accentColor),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  _skinActif.description,
                  style: OtakuTypo.bodySmall.copyWith(fontSize: 10.5, color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionPanel() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('MES PERSONNAGES (${_mesSkins.length})', style: OtakuTypo.headlineSmall.copyWith(fontSize: 12)),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const BoutiqueScreen(showBack: true, initialTab: 0)));
                  _chargerTout();
                },
                child: Text('BOUTIQUE >', style: OtakuTypo.label.copyWith(fontSize: 9.5, color: OtakuColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _mesSkins.map((skin) {
              final active = skin.id == _skinActif.id;
              return GestureDetector(
                onTap: () => _equiperSkin(skin),
                child: Container(
                  width: 96,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.52),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? skin.accentColor : OtakuColors.border,
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      SafeAvatarBox(
                        assetPath: 'assets/images/skins/${skin.imageKey}.png',
                        width: 64,
                        height: 64,
                        topPadding: 4,
                        borderRadius: 10,
                        borderColor: skin.accentColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        skin.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OtakuTypo.headlineSmall.copyWith(fontSize: 10),
                      ),
                      Text(
                        active ? 'ÉQUIPÉ' : 'ÉQUIPER',
                        style: OtakuTypo.label.copyWith(
                          fontSize: 7.5,
                          color: active ? OtakuColors.pvHaut : OtakuColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text('MES CADRES D\'AVATAR (${_mesCadres.length})', style: OtakuTypo.headlineSmall.copyWith(fontSize: 12)),
          const SizedBox(height: 6),
          if (_mesCadres.isEmpty)
            Text(
              'Aucun cadre cosmétique débloqué. Découvre les 4 cadres dans la Boutique !',
              style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _mesCadres.map((frameId) {
                final active = _cadreEquipe == frameId;
                return GestureDetector(
                  onTap: () => _equiperCadre(active ? null : frameId),
                  child: Container(
                    width: 82,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? const Color(0xFFFFD700) : OtakuColors.border, width: active ? 2 : 1),
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/frames/$frameId.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(Icons.filter_frames_rounded, color: Colors.amber, size: 36),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          active ? 'ACTIF' : 'METTRE',
                          style: OtakuTypo.label.copyWith(fontSize: 8, color: active ? const Color(0xFFFFD700) : Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _ouvrirVerseAnalyticsVip() async {
    final bool isVip = _profil?['is_vip'] == true;
    if (!isVip) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: OtakuColors.surface,
          title: Text('VERSE ANALYTICS (7 STATS PRO)', style: OtakuTypo.headlineSmall.copyWith(color: const Color(0xFFFFD700))),
          content: Text(
            'Exclusif aux abonnés VIP : Radar 5 axes, réussite par difficulté, chrono moyen & ratio Haya!!, résistance aux Malus, courbe des 50 derniers matchs, carnet d\'erreurs révisable et comparateur Head-to-Head.',
            style: OtakuTypo.bodySmall,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BoutiqueScreen(showBack: true, initialTab: 3)));
              },
              child: const Text('VOIR L\'OFFRE VIP', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VerseAnalyticsPage()),
    );
  }

  Widget _buildStatCard(String label, String valeur, Color couleur, IconData icon) {
    return LiquidGlass(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: couleur.withValues(alpha: 0.85)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(valeur, style: OtakuTypo.hud.copyWith(fontSize: 17, color: couleur)),
          ),
          const SizedBox(height: 2),
          Text(label, style: OtakuTypo.label.copyWith(fontSize: 7, color: OtakuColors.textMuted)),
        ],
      ),
    );
  }
}
