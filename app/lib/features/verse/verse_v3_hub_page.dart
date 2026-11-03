import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'verse_v3_service.dart';
import 'verse_combat_page.dart';

/// Hub complet de la V3 : regroupe Saisons (10.1), Événements temporaires (10.2),
/// Tournois (10.3) et Missions longue durée / Carrière (10.4).
class VerseV3HubPage extends StatefulWidget {
  final int initialTab;
  const VerseV3HubPage({super.key, this.initialTab = 0});

  @override
  State<VerseV3HubPage> createState() => _VerseV3HubPageState();
}

class _VerseV3HubPageState extends State<VerseV3HubPage> with SingleTickerProviderStateMixin {
  final VerseV3Service _service = VerseV3Service();
  late TabController _tabController;

  bool _loading = true;
  Map<String, dynamic>? _saisonData;
  List<Map<String, dynamic>> _evenements = [];
  Map<String, dynamic>? _tournoiData;
  List<Map<String, dynamic>> _missionsCarriere = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    _chargerTout();
  }

  Future<void> _chargerTout() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.recupererDonneesSaison(),
        _service.recupererEvenements(),
        _service.recupererTournoi(),
        _service.recupererMissionsCarriere(),
      ]);
      if (!mounted) return;
      setState(() {
        _saisonData = results[0] as Map<String, dynamic>;
        _evenements = results[1] as List<Map<String, dynamic>>;
        _tournoiData = results[2] as Map<String, dynamic>;
        _missionsCarriere = results[3] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      appBar: AppBar(
        backgroundColor: OtakuColors.surface,
        elevation: 0,
        title: Text("SAISONS, ÉVÉNEMENTS & TOURNOIS", style: OtakuTypo.headlineSmall.copyWith(fontSize: 15)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: OtakuColors.modeEvent,
          labelColor: OtakuColors.modeEvent,
          unselectedLabelColor: OtakuColors.textMuted,
          labelStyle: OtakuTypo.label.copyWith(fontSize: 11),
          tabs: const [
            Tab(text: "SAISON 1"),
            Tab(text: "ÉVÉNEMENTS"),
            Tab(text: "TOURNOIS"),
            Tab(text: "CARRIÈRE"),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: OtakuColors.modeEvent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSaisonTab(),
                _buildEvenementsTab(),
                _buildTournoiTab(),
                _buildCarriereTab(),
              ],
            ),
    );
  }

  // ===========================================================================
  // ONGLET 1 : SAISONS (8 semaines, classement saisonnier, paliers, soft reset)
  // ===========================================================================
  Widget _buildSaisonTab() {
    final s = _saisonData ?? {};
    final int mesPoints = s['mesPoints'] ?? 0;
    final int maDiv = s['maDivision'] ?? 10;
    final int divReset = VerseV3Service.calculerDivisionApresSoftReset(maDiv);
    final List<dynamic> classement = s['classement'] ?? [];
    final List<int> paliersReclames = (s['paliersReclames'] as List<int>?) ?? [];

    final paliers = [
      {'palier': 1, 'seuil': 50, 'xp': 100, 'label': 'Palier 1 (50 PTS) : +100 XP'},
      {'palier': 2, 'seuil': 150, 'xp': 200, 'label': 'Palier 2 (150 PTS) : +200 XP & Badge Pirate'},
      {'palier': 3, 'seuil': 300, 'xp': 350, 'label': 'Palier 3 (300 PTS) : +350 XP & Cadre Grand Line'},
      {'palier': 4, 'seuil': 600, 'xp': 500, 'label': 'Palier 4 (600 PTS) : +500 XP & Titre Supernova'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: OtakuColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: OtakuColors.modeEvent.withOpacity(0.5)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/events/event_one_piece.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          OtakuColors.background.withValues(alpha: 0.92),
                          OtakuColors.background.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['titre'] ?? "SAISON 1 : L'ÈRE DES PIRATES",
                              style: OtakuTypo.headlineSmall.copyWith(color: OtakuColors.modeEvent),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Thème : ${s['themeAnime'] ?? 'One Piece'} | Durée : 8 semaines (${s['joursRestants'] ?? 35} j restants)",
                              style: OtakuTypo.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Fin de saison : Soft Reset protégé (Division $maDiv -> Division $divReset max)",
                              style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: OtakuColors.background.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text("RANG #${s['monRang'] ?? 1}", style: OtakuTypo.headlineSmall.copyWith(color: Colors.amber)),
                            Text("$mesPoints PTS", style: OtakuTypo.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text("PALIERS DE SAISON", style: OtakuTypo.headlineSmall.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          ...paliers.map((p) {
            final int numPalier = p['palier'] as int;
            final int seuil = p['seuil'] as int;
            final int xp = p['xp'] as int;
            final bool debloque = mesPoints >= seuil;
            final bool reclame = paliersReclames.contains(numPalier);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: OtakuColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: debloque ? OtakuColors.modeEvent : OtakuColors.glassBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(p['label'] as String, style: OtakuTypo.bodySmall)),
                  if (reclame)
                    const Text("RÉCLAMÉ", style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold))
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: debloque ? OtakuColors.modeEvent : Colors.grey[800],
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: debloque
                          ? () async {
                              await _service.reclamerPalierSaison(numPalier, xp);
                              await _chargerTout();
                            }
                          : null,
                      child: Text(debloque ? "RÉCLAMER" : "$mesPoints/$seuil PTS", style: const TextStyle(fontSize: 11)),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Text("CLASSEMENT SAISONNIER", style: OtakuTypo.headlineSmall.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          ...List.generate(classement.length, (i) {
            final row = classement[i] as Map;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: OtakuColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("#${i + 1}  ${row['pseudo'] ?? 'Joueur'}", style: OtakuTypo.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                  Text("Div. ${row['division'] ?? 10}  |  ${row['points'] ?? 0} PTS", style: OtakuTypo.bodySmall),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // ONGLET 2 : ÉVÉNEMENTS TEMPORAIRES (3 à 7 jours, thème anime, récompenses)
  // ===========================================================================
  Widget _buildEvenementsTab() {
    const bannieres = [
      'assets/images/events/event_one_piece.png',
      'assets/images/events/event_naruto.png',
      'assets/images/events/event_multiverse.png',
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _evenements.length,
      itemBuilder: (context, index) {
        final ev = _evenements[index];
        final String imgAsset = bannieres[index % bannieres.length];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: OtakuColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OtakuColors.modeEvent.withOpacity(0.5)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  imgAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        OtakuColors.background.withValues(alpha: 0.92),
                        OtakuColors.background.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ev['titre'] ?? '', style: OtakuTypo.headlineSmall.copyWith(color: OtakuColors.modeEvent)),
                          const SizedBox(height: 4),
                          Text("Anime : ${ev['anime']}  |  ${ev['duree']}", style: OtakuTypo.bodySmall),
                          const SizedBox(height: 4),
                          Text("Récompense : ${ev['recompense']}", style: OtakuTypo.bodySmall.copyWith(color: Colors.amber, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.modeEvent),
                      onPressed: () async {
                        setState(() => _loading = true);
                        try {
                          final matchId = await _service.participerEvenement(ev['id'] as String, ev['anime'] as String);
                          if (!mounted) return;
                          setState(() => _loading = false);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => VerseCombatPage(matchId: matchId)),
                          );
                        } catch (_) {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                      child: const Text("PARTICIPER"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // ONGLET 3 : TOURNOIS (Phase de groupes 10 duels + Finale Top 8)
  // ===========================================================================
  Widget _buildTournoiTab() {
    final t = _tournoiData ?? {};
    final bool inscrit = t['inscrit'] == true;
    final int duelsJoues = t['duelsJoues'] ?? 0;
    final int scoreCumule = t['scoreCumule'] ?? 0;
    final List<dynamic> top8 = t['top8'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: OtakuColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: OtakuColors.accent.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['titre'] ?? 'TOURNOI MENSUEL DU VERSE', style: OtakuTypo.headlineSmall.copyWith(color: OtakuColors.accent)),
                      const SizedBox(height: 4),
                      Text(t['duree'] ?? '', style: OtakuTypo.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        "Phase de groupes : $duelsJoues / 10 duels joués  |  Score cumulé : $scoreCumule PTS",
                        style: OtakuTypo.bodySmall.copyWith(color: Colors.greenAccent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (!inscrit)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.accent),
                    onPressed: () async {
                      await _service.inscrireAuTournoi();
                      await _chargerTout();
                    },
                    child: const Text("S'INSCRIRE"),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                    onPressed: duelsJoues < 10
                        ? () async {
                            setState(() => _loading = true);
                            try {
                              final matchId = await _service.jouerDuelTournoi();
                              if (!mounted) return;
                              setState(() => _loading = false);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => VerseCombatPage(matchId: matchId)),
                              );
                            } catch (_) {
                              if (mounted) setState(() => _loading = false);
                            }
                          }
                        : null,
                    child: Text(duelsJoues < 10 ? "JOUER DUEL (${duelsJoues + 1}/10)" : "10/10 TERMINÉS"),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text("ARBRE FINALE TOP 8 (ÉLIMINATION DIRECTE)", style: OtakuTypo.headlineSmall.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(4, (i) {
              final String j1 = top8.length > i * 2 ? top8[i * 2].toString() : 'Qualifié ${i * 2 + 1}';
              final String j2 = top8.length > i * 2 + 1 ? top8[i * 2 + 1].toString() : 'Qualifié ${i * 2 + 2}';
              return Container(
                width: 200,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: OtakuColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: OtakuColors.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("QUART DE FINALE #${i + 1}", style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.accent)),
                    const SizedBox(height: 6),
                    Text(j1, style: OtakuTypo.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                    const Text("VS", style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                    Text(j2, style: OtakuTypo.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ONGLET 4 : MISSIONS LONGUE DURÉE / CARRIÈRE (Section 10.4 Roadmap)
  // ===========================================================================
  Widget _buildCarriereTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _missionsCarriere.length,
      itemBuilder: (context, index) {
        final m = _missionsCarriere[index];
        final int actuel = m['actuel'] as int? ?? 0;
        final int cible = m['cible'] as int? ?? 1;
        final bool terminee = actuel >= cible;
        final bool reclamee = m['reclamee'] == true;
        final double ratio = (actuel / cible).clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: OtakuColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: terminee ? Colors.greenAccent.withOpacity(0.5) : OtakuColors.glassBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['mission'] as String, style: OtakuTypo.headlineSmall.copyWith(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(m['recompense'] as String, style: OtakuTypo.bodySmall.copyWith(color: Colors.amber, fontSize: 11)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: OtakuColors.background,
                      color: OtakuColors.accent,
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              if (reclamee)
                const Text("OBTENU", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12))
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: terminee ? Colors.green[700] : Colors.grey[800],
                  ),
                  onPressed: terminee
                      ? () async {
                          await _service.reclamerMissionCarriere(m['id'] as String, m['xp'] as int);
                          await _chargerTout();
                        }
                      : null,
                  child: Text(terminee ? "RÉCLAMER" : "$actuel / $cible", style: const TextStyle(fontSize: 11)),
                ),
            ],
          ),
        );
      },
    );
  }
}
