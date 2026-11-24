import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../shared/rank_badge.dart';
import '../core/feature_flags_service.dart';
import '../economy/economy_v92_service.dart';
import '../tutorial/tutorial_service.dart';
import '../verse/verse_division_page.dart';
import 'classement_service.dart';
import 'profil_public_page.dart';

/// === ECRAN CLASSEMENTS V9.2 (TESTS 10, 26, 27) ===
/// - Mode `initialSection: 'xp'` (depuis le Profil) : Classement General XP
///   (Mondial / National / Amis) — ZERO bandeau cagnotte ni recompense !
/// - Mode `initialSection: 'competitif'` (depuis la rubrique Classements de l'Accueil) :
///   Hub competitif style eFootball : Division en priorite (Division actuelle, points,
///   rang, 10 Divisions visibles, bandeau cagnotte dynamique, acces rapide Jouer > Division)
///   + onglets Guildes, Battle Royale et Tournois prets par palier.
class ClassementScreen extends StatefulWidget {
  final String initialSection; // 'xp' ou 'competitif'
  const ClassementScreen({super.key, this.initialSection = 'xp'});

  @override
  State<ClassementScreen> createState() => _ClassementScreenState();
}

class _ClassementScreenState extends State<ClassementScreen> {
  final _service = ClassementService();
  final _economyService = EconomyV92Service();
  final _flagsService = FeatureFlagsService();

  late String _section; // 'xp' ou 'competitif'
  // Pour 'xp' : 0 = Mondial, 1 = National, 2 = Amis
  int _xpTab = 0;
  // Pour 'competitif' : 0 = Division, 1 = 10 Divisions, 2 = Guildes, 3 = Battle Royale, 4 = Tournois
  int _compTab = 0;

  List<Map<String, dynamic>> _classement = [];
  Map<String, dynamic>? _cagnotte;
  Map<String, dynamic>? _monProfilDiv;
  bool _chargement = true;
  int _maPosition = 0;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
    // Enregistre la visite reelle pour l'etape 5 du Parcours d'Initiation Phase B
    TutorialService().marquerVisiteEtape(5);
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      await _flagsService.chargerFlags();
      if (_section == 'xp') {
        List<Map<String, dynamic>> data;
        int pos = 0;
        switch (_xpTab) {
          case 0:
            data = await _service.classementMondial();
            pos = await _service.maPositionMondiale();
            break;
          case 1:
            data = await _service.classementNational();
            break;
          default:
            data = await _service.classementAmis();
        }
        if (mounted) {
          setState(() {
            _classement = data;
            _maPosition = pos;
            _cagnotte = null; // Regle absolue Test 26 : jamais de cagnotte sur le classement XP
            _chargement = false;
          });
        }
      } else {
        final results = await Future.wait([
          _service.classementDivision(),
          _service.maPositionDivision(),
          _service.monProfilDivision(),
          _economyService.recupererBandeauCagnotte(mode: 'division'),
        ]);
        if (mounted) {
          setState(() {
            _classement = results[0] as List<Map<String, dynamic>>;
            _maPosition = results[1] as int;
            _monProfilDiv = results[2] as Map<String, dynamic>?;
            _cagnotte = results[3] as Map<String, dynamic>?;
            _chargement = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool estCompetitif = _section == 'competitif';

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === HEADER ===
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: OtakuColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: OtakuColors.border),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: OtakuColors.textPrimary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      estCompetitif ? 'CLASSEMENTS COMPÉTITIFS' : 'CLASSEMENT GÉNÉRAL XP',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OtakuTypo.headlineLarge.copyWith(fontSize: 18),
                    ),
                  ),
                  // Bascule rapide entre Classements Competitifs et General XP
                  GestureDetector(
                    onTap: () {
                      setState(() => _section = estCompetitif ? 'xp' : 'competitif');
                      _charger();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: OtakuColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: OtakuColors.border),
                      ),
                      child: Text(
                        estCompetitif ? 'Voir Classement XP' : 'Voir Divisions',
                        style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.accent),
                      ),
                    ),
                  ),
                  if (_maPosition > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: OtakuColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Toi : #$_maPosition',
                        style: OtakuTypo.hud.copyWith(fontSize: 12, color: OtakuColors.accent),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              if (estCompetitif) _buildTabsCompetitifs() else _buildTabsXp(),
              const SizedBox(height: 10),

              // Contenu principal
              Expanded(
                child: _chargement
                    ? const Center(child: CircularProgressIndicator(color: OtakuColors.accent))
                    : (estCompetitif ? _buildContenuCompetitif() : _buildListeJoueurs(isDivision: false)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabsXp() {
    return Row(
      children: [
        _buildTabChip('Mondial', _xpTab == 0, Icons.public_rounded, () {
          setState(() => _xpTab = 0);
          _charger();
        }),
        const SizedBox(width: 8),
        _buildTabChip('National', _xpTab == 1, Icons.flag_rounded, () {
          setState(() => _xpTab = 1);
          _charger();
        }),
        const SizedBox(width: 8),
        _buildTabChip('Amis', _xpTab == 2, Icons.people_rounded, () {
          setState(() => _xpTab = 2);
          _charger();
        }),
        const Spacer(),
        Text(
          'Classement de prestige (0 récompense VC)',
          style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildTabsCompetitifs() {
    final guildesOpen = _flagsService.estOuvert('mode_guildes');
    final brOpen = _flagsService.estOuvert('mode_battle_royale');
    final tournoisOpen = _flagsService.estOuvert('mode_events_tournois');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTabChip('Division (Top)', _compTab == 0, Icons.military_tech_rounded, () {
            setState(() => _compTab = 0);
          }),
          const SizedBox(width: 8),
          _buildTabChip('Les 10 Divisions', _compTab == 1, Icons.stairs_rounded, () {
            setState(() => _compTab = 1);
          }),
          const SizedBox(width: 8),
          _buildTabChip('Guildes', _compTab == 2, guildesOpen ? Icons.shield_rounded : Icons.lock_rounded, () {
            setState(() => _compTab = 2);
          }, locked: !guildesOpen),
          const SizedBox(width: 8),
          _buildTabChip('Battle Royale', _compTab == 3, brOpen ? Icons.whatshot_rounded : Icons.lock_rounded, () {
            setState(() => _compTab = 3);
          }, locked: !brOpen),
          const SizedBox(width: 8),
          _buildTabChip('Tournois', _compTab == 4, tournoisOpen ? Icons.emoji_events_rounded : Icons.lock_rounded, () {
            setState(() => _compTab = 4);
          }, locked: !tournoisOpen),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, bool actif, IconData icon, VoidCallback onTap, {bool locked = false}) {
    final color = locked ? OtakuColors.modeEvent : OtakuColors.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: actif ? color.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: actif ? color.withValues(alpha: 0.65) : OtakuColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: actif ? color : (locked ? OtakuColors.modeEvent : OtakuColors.textMuted)),
            const SizedBox(width: 6),
            Text(
              label,
              style: OtakuTypo.label.copyWith(
                fontSize: 11,
                color: actif ? color : OtakuColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenuCompetitif() {
    if (_compTab == 1) {
      return _buildVue10Divisions();
    }
    if (_compTab == 2 || _compTab == 3 || _compTab == 4) {
      final titles = {2: 'CLASSEMENT GUILDES', 3: 'CLASSEMENT BATTLE ROYALE', 4: 'CLASSEMENT TOURNOIS'};
      final flagKeys = {2: 'mode_guildes', 3: 'mode_battle_royale', 4: 'mode_events_tournois'};
      final label = _flagsService.labelLancement(flagKeys[_compTab]!);
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: OtakuColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: OtakuColors.modeEvent.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock_rounded, size: 38, color: OtakuColors.modeEvent),
              const SizedBox(height: 10),
              Text(titles[_compTab]!, style: OtakuTypo.headlineSmall.copyWith(color: OtakuColors.modeEvent)),
              const SizedBox(height: 6),
              Text(
                '$label — Ce classement compétitif à récompenses VC ouvrira automatiquement avec son palier dédié.',
                textAlign: TextAlign.center,
                style: OtakuTypo.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    // Onglet 0 : Classement Division (Priorite Palier 1)
    final int mesPts = (_monProfilDiv?['pts_division'] as num?)?.toInt() ?? 0;
    final int maDiv = EconomyV92Service.calculerDivision(mesPts);
    final String nomDiv = EconomyV92Service.nomDivision(maDiv);

    return Column(
      children: [
        // Carte Ma Division + acces rapide vers Jouer > Division (style eFootball)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: OtakuColors.modeDivision.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: OtakuColors.modeDivision.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              const Icon(Icons.military_tech_rounded, color: OtakuColors.modeDivision, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TA DIVISION : D$maDiv · $nomDiv ($mesPts pts)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OtakuTypo.headlineSmall.copyWith(fontSize: 12, color: Colors.white),
                    ),
                    Text(
                      'Position mondiale : ${_maPosition > 0 ? "#$_maPosition" : "Non classé"} · 10 matchs requis pour la cagnotte saisonnière',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: OtakuColors.modeDivision,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VerseDivisionPage()),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('JOUER > DIVISION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Bandeau Cagnotte Dynamique (EXCLUSIVEMENT sur les classements competitifs §6.5)
        if (_cagnotte != null) ...[
          _buildBandeauCagnotte(_cagnotte!),
          const SizedBox(height: 8),
        ],

        Expanded(child: _buildListeJoueurs(isDivision: true)),
      ],
    );
  }

  /// Affiche les 10 Divisions officielles (seuils 0 a 1 900+ pts et frais OC) — Test 27
  Widget _buildVue10Divisions() {
    final int mesPts = (_monProfilDiv?['pts_division'] as num?)?.toInt() ?? 0;
    final int maDiv = EconomyV92Service.calculerDivision(mesPts);

    return ListView.separated(
      itemCount: EconomyV92Service.divisionsOfficielles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final d = EconomyV92Service.divisionsOfficielles[i];
        final int divId = d['id'] as int;
        final bool estActuelle = divId == maDiv;
        final String plage = d['max'] == null ? '${d['min']}+ pts' : '${d['min']} – ${d['max']} pts';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: estActuelle ? OtakuColors.modeDivision.withValues(alpha: 0.18) : OtakuColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: estActuelle ? OtakuColors.modeDivision : OtakuColors.border,
              width: estActuelle ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (estActuelle ? OtakuColors.modeDivision : OtakuColors.accent).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'D$divId',
                  style: OtakuTypo.hud.copyWith(
                    fontSize: 13,
                    color: estActuelle ? OtakuColors.modeDivision : OtakuColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Division $divId : ${d['nom']}',
                          style: OtakuTypo.headlineSmall.copyWith(fontSize: 13),
                        ),
                        if (estActuelle) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: OtakuColors.modeDivision,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text('TOI ($mesPts pts)', style: OtakuTypo.label.copyWith(fontSize: 8, color: Colors.white)),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Seuil : $plage  ·  Frais d\'arène (dès Niv. 6) : ${d['frais']} OC',
                      style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                plage,
                style: OtakuTypo.hud.copyWith(fontSize: 11, color: Colors.amber),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBandeauCagnotte(Map<String, dynamic> pot) {
    final int qualif = (pot['qualified_players'] as num?)?.toInt() ?? 0;
    final int top1 = (pot['top1_vc'] as num?)?.toInt() ?? 25;
    final int top2 = (pot['top2_vc'] as num?)?.toInt() ?? 15;
    final int top3 = (pot['top3_vc'] as num?)?.toInt() ?? 10;
    final int? nextThreshold = (pot['next_threshold'] as num?)?.toInt();
    final int? nextTop1 = (pot['next_top1_vc'] as num?)?.toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: OtakuColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Participants qualifiés : $qualif  |  1er = $top1 VC · 2e = $top2 VC · 3e = $top3 VC',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OtakuTypo.headlineSmall.copyWith(fontSize: 11, color: Colors.amber),
                ),
                const SizedBox(height: 2),
                Text(
                  nextThreshold != null && nextTop1 != null
                      ? 'La cagnotte Division monte à $nextTop1 VC dès $nextThreshold participants qualifiés !'
                      : 'Palier maximal 50+ actif : récompenses pleines débloquées !',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OtakuTypo.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Share.share(
              'Rejoins-moi sur Otaku Verse pour faire monter la cagnotte du classement Division !',
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Text(
                'INVITER',
                style: OtakuTypo.label.copyWith(fontSize: 9, color: Colors.amber),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<int> _calculerPositions(bool isDivision) {
    final positions = <int>[];
    final key = isDivision ? 'pts_division' : 'xp_totale';
    for (int i = 0; i < _classement.length; i++) {
      if (i == 0) {
        positions.add(1);
      } else {
        final cur = (_classement[i][key] as num?)?.toInt() ?? 0;
        final prev = (_classement[i - 1][key] as num?)?.toInt() ?? 0;
        positions.add(cur == prev ? positions[i - 1] : i + 1);
      }
    }
    return positions;
  }

  Widget _buildListeJoueurs({required bool isDivision}) {
    if (_classement.isEmpty) {
      return Center(
        child: Text('Aucun joueur trouvé', style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted)),
      );
    }

    final myId = _service.monId;
    final positions = _calculerPositions(isDivision);

    return ListView.separated(
      itemCount: _classement.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, index) {
        final joueur = _classement[index];
        final position = positions[index];
        final estMoi = joueur['id'] == myId;
        final int niveau = (joueur['niveau'] as num?)?.toInt() ?? 1;
        final int ptsDiv = (joueur['pts_division'] as num?)?.toInt() ?? 0;
        final int divId = EconomyV92Service.calculerDivision(ptsDiv);
        final String skinKey = joueur['equipped_skin_key']?.toString() ?? 'skin_kio';

        return GestureDetector(
          onTap: estMoi
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilPublicPage(
                        userId: joueur['id'],
                        pseudo: joueur['pseudo'] ?? '???',
                        niveau: niveau,
                        rang: EconomyV92Service.titreRangOfficiel(niveau),
                      ),
                    ),
                  ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: estMoi
                  ? OtakuColors.accent.withValues(alpha: 0.12)
                  : OtakuColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: estMoi
                    ? OtakuColors.accent.withValues(alpha: 0.5)
                    : OtakuColors.border.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    _positionText(position),
                    style: OtakuTypo.hud.copyWith(
                      fontSize: position <= 3 ? 16 : 13,
                      color: _positionColor(position),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Vrai avatar du joueur dans le classement (Test 10)
                SafeAvatarBox(
                  assetPath: 'assets/images/skins/$skinKey.png',
                  width: 36,
                  height: 36,
                  topPadding: 3,
                  borderRadius: 10,
                  borderColor: estMoi ? OtakuColors.accent : OtakuColors.border,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estMoi ? '${joueur['pseudo']} (toi)' : joueur['pseudo'] ?? '???',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OtakuTypo.headlineSmall.copyWith(
                          fontSize: 13,
                          color: estMoi ? OtakuColors.accent : OtakuColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      OfficialRankBadge(
                        niveau: niveau,
                        divisionId: isDivision ? divId : null,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isDivision ? '$ptsDiv PTS' : '${joueur['xp_totale'] ?? 0} XP',
                      style: OtakuTypo.hud.copyWith(
                        fontSize: 12,
                        color: isDivision ? OtakuColors.modeDivision : OtakuColors.accent,
                      ),
                    ),
                    Text(
                      isDivision
                          ? 'D$divId · ${joueur['ko_wins_season'] ?? 0} K.O.'
                          : '${joueur['combats_gagnes'] ?? 0} V',
                      style: OtakuTypo.bodySmall.copyWith(fontSize: 9, color: OtakuColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _positionText(int pos) {
    if (pos == 1) return '1er';
    if (pos == 2) return '2e';
    if (pos == 3) return '3e';
    return '#$pos';
  }

  Color _positionColor(int pos) {
    if (pos == 1) return const Color(0xFFFFD700);
    if (pos == 2) return const Color(0xFFC0C0C0);
    if (pos == 3) return const Color(0xFFCD7F32);
    return OtakuColors.textMuted;
  }
}
