import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../economy/economy_v92_service.dart';
import '../progression/progression_service.dart';
import 'combat_models.dart';
import 'combat_service.dart';
import 'combat_page.dart';

/// === CONFIGURATION AVANT-MATCH SOLO V9.2 ===
/// - 21 oeuvres chargees depuis Cloudflare R2 (/catalog) + filtre Arc
/// - 6 modes de difficulte (Facile, Moyen, Difficile, Expert, Maitre, Adaptatif)
/// - Contrat Malus (Zen / Normal / Malicieux +25 % OC)
/// - Frais d'arene OC (ECO-05 : 0 OC Niv 1-5), Assurance XP (25 OC) et Puits de Confiance
/// - Coup de Pouce (+40 OC via pub) si solde insuffisant (ECO-06)
class CombatSetupPage extends StatefulWidget {
  const CombatSetupPage({super.key});

  @override
  State<CombatSetupPage> createState() => _CombatSetupPageState();
}

class _CombatSetupPageState extends State<CombatSetupPage> {
  final CombatService _combatService = CombatService();
  final EconomyV92Service _economyService = EconomyV92Service();
  final ProgressionService _progressionService = ProgressionService();
  final PageController _pageController = PageController();

  String? _workSlugChoisi;
  String? _arcChoisi;
  List<Map<String, dynamic>> _catalogue = [];
  List<String> _arcsDisponibles = [];
  bool _chargementAnimes = true;
  bool _chargementArcs = false;

  String _difficulteChoisie = 'moyen';
  String _malusChoisi = 'normal';
  bool _assuranceXp = false;
  int _puitsOc = 0;

  int _niveauJoueur = 1;
  int _divisionJoueur = 10;
  WalletV92 _wallet = const WalletV92();
  bool _lancementCombat = false;
  int _currentPage = 0;

  static const List<Map<String, String>> _difficultes = [
    {'id': 'facile', 'label': 'FACILE', 'desc': '+2 XP / +0,5 OC par reponse · Bot lent (55 %)'},
    {'id': 'moyen', 'label': 'MOYEN', 'desc': '+3 XP / +1 OC par reponse · Bot equilibre (65 %)'},
    {'id': 'difficile', 'label': 'DIFFICILE', 'desc': '+5 XP / +1,5 OC (-0,5 erreur) · Bot rapide (75 %)'},
    {'id': 'expert', 'label': 'EXPERT', 'desc': '+7 XP / +2 OC (-1 erreur) · Bot agressif (82 %)'},
    {'id': 'maitre', 'label': 'MAITRE', 'desc': '+9 XP / +2,5 OC (-1,5 erreur) · Bot Elite (90 %)'},
    {'id': 'adaptatif', 'label': 'ADAPTATIF', 'desc': 'Monte toutes les 3 bonnes reponses · Bonus palier final'},
  ];

  static const List<Map<String, String>> _malusOptions = [
    {'id': 'zen', 'label': 'ZEN', 'desc': '0 Malus visuel'},
    {'id': 'normal', 'label': 'NORMAL', 'desc': 'Malus occasionnels'},
    {'id': 'malicieux', 'label': 'MALICIEUX', 'desc': '+25 % OC si victoire (-20 XP si < 50 %)'},
  ];

  @override
  void initState() {
    super.initState();
    _chargerDonneesInitiales();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonneesInitiales() async {
    try {
      final results = await Future.wait([
        _combatService.recupererCatalogueOeuvres(),
        _progressionService.recupererProfil(),
        _economyService.recupererPortefeuille(),
      ]);
      if (!mounted) return;
      final profil = results[1] as Map<String, dynamic>?;
      setState(() {
        _catalogue = results[0] as List<Map<String, dynamic>>;
        _niveauJoueur = (profil?['niveau'] as num?)?.toInt() ?? 1;
        _divisionJoueur = (profil?['division_id'] as num?)?.toInt() ?? 10;
        _wallet = results[2] as WalletV92;
        _chargementAnimes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _chargementAnimes = false);
    }
  }

  int get _fraisEntreeOc => EconomyV92Service.fraisAreneOc(
        niveau: _niveauJoueur,
        divisionId: _divisionJoueur,
        mode: 'solo',
      );

  int get _coutTotalOc => _fraisEntreeOc + (_assuranceXp ? 25 : 0) + _puitsOc;

  Future<void> _chargerArcs() async {
    if (_workSlugChoisi == null) return;
    setState(() => _chargementArcs = true);
    try {
      final arcs = await _combatService.recupererArcsDisponibles(_workSlugChoisi!);
      if (!mounted) return;
      setState(() {
        _arcsDisponibles = arcs;
        _chargementArcs = false;
      });
    } catch (_) {
      if (mounted) setState(() => _chargementArcs = false);
    }
  }

  Future<void> _activerCoupDePouce() async {
    try {
      final res = await _economyService.reclamerCoupDePouceOc('solo');
      if (!mounted) return;
      final newOc = (res['new_oc_balance'] as num?)?.toInt() ?? (_wallet.ocBalance + 40);
      setState(() {
        _wallet = WalletV92(
          ocBalance: newOc,
          vcBonus: _wallet.vcBonus,
          vcPaid: _wallet.vcPaid,
          seasonFreeVcEarned: _wallet.seasonFreeVcEarned,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('+40 Otaku Coins recus (Coup de Pouce) !')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _lancerCombat() async {
    setState(() => _lancementCombat = true);
    try {
      // 1. Demarrer la session securisee sur Supabase `match-engine` (debite OC + anti-force-close)
      final startData = await _economyService.demarrerMatch(
        mode: 'solo',
        difficulty: _difficulteChoisie,
        malusMode: _malusChoisi,
        xpInsurance: _assuranceXp,
        confidencePotOc: _puitsOc,
      );

      final matchId = startData['match_id']?.toString();
      final opp = startData['opponent'] is Map ? startData['opponent'] as Map : const {};

      final params = CombatParams(
        mode: 'solo',
        anime: _workSlugChoisi,
        arc: _arcChoisi,
        difficulte: _difficulteChoisie,
        malusMode: _malusChoisi,
        xpInsurance: _assuranceXp,
        confidencePotOc: _puitsOc,
        matchId: matchId,
        opponentPseudo: opp['pseudo']?.toString() ?? 'A.K.I.N.A',
      );

      // 2. Tirer les 40 questions depuis Cloudflare R2 (sans bonne reponse)
      final questions = await _combatService.preparerCombat(params);
      if (!mounted) return;

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune question disponible pour ces filtres.')),
        );
        setState(() => _lancementCombat = false);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CombatPage(questions: questions, params: params)),
      );
    } on MatchStartException catch (e) {
      if (!mounted) return;
      setState(() => _lancementCombat = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          action: e.canRescueAd
              ? SnackBarAction(label: '+40 OC (PUB)', onPressed: _activerCoupDePouce)
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _lancementCombat = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de lancement : $e')),
      );
    }
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_workSlugChoisi != null) {
        _arcChoisi = null;
        _chargerArcs();
        _pageController.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
        setState(() => _currentPage = 1);
      } else {
        _arcChoisi = null;
        _pageController.animateToPage(2, duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
        setState(() => _currentPage = 2);
      }
    } else if (_currentPage == 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
      setState(() => _currentPage = 2);
    }
  }

  void _prevPage() {
    if (_currentPage == 2 && _workSlugChoisi == null) {
      _pageController.animateToPage(0, duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
      setState(() => _currentPage = 0);
    } else if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
      setState(() => _currentPage--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool soldeInsuffisant = _wallet.ocBalance < _coutTotalOc;

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec solde OC et frais d'entree
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Text('SOLO · 350 PV · 40 Q · 02:00', style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: OtakuColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF4CC9F0).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'Solde : ${_wallet.ocBalance} OC  |  Mise : $_coutTotalOc OC',
                      style: OtakuTypo.hud.copyWith(fontSize: 11, color: const Color(0xFF4CC9F0)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPageAnime(),
                  _buildPageArc(),
                  _buildPageDifficulteEtContrat(),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _prevPage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: OtakuColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: OtakuColors.border),
                      ),
                      child: Text('RETOUR', style: OtakuTypo.label),
                    ),
                  ),
                  if (_currentPage < 2)
                    GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                        decoration: BoxDecoration(
                          color: OtakuColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('SUIVANT', style: OtakuTypo.label.copyWith(color: Colors.black)),
                      ),
                    )
                  else if (soldeInsuffisant && _wallet.ocBalance < _fraisEntreeOc)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.modeEvent, foregroundColor: Colors.black),
                      onPressed: _activerCoupDePouce,
                      icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                      label: const Text('COUP DE POUCE (+40 OC)'),
                    )
                  else
                    GestureDetector(
                      onTap: (_lancementCombat || soldeInsuffisant) ? null : _lancerCombat,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: soldeInsuffisant
                                ? [Colors.grey, Colors.grey]
                                : [OtakuColors.accent, OtakuColors.accentDark],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _lancementCombat
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _coutTotalOc > 0 ? 'LANCER ($_coutTotalOc OC)' : 'LANCER (GRATUIT)',
                                style: OtakuTypo.label.copyWith(color: Colors.white),
                              ),
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

  Widget _buildPageAnime() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CHOISIS TON OEUVRE (21 UNIVERS)', style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
          const SizedBox(height: 6),
          if (_chargementAnimes)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildChipAnime(null, 'MULTI-VERSE (TOUTES)'),
                    ..._catalogue.map((w) => _buildChipAnime(
                          w['slug']?.toString(),
                          (w['title'] ?? w['slug']).toString().toUpperCase(),
                        )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChipAnime(String? slug, String label) {
    final estSelectionne = _workSlugChoisi == slug;
    return GestureDetector(
      onTap: () => setState(() => _workSlugChoisi = slug),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: estSelectionne ? OtakuColors.accent : OtakuColors.surface,
          border: Border.all(
            color: estSelectionne ? OtakuColors.accent : OtakuColors.border,
            width: estSelectionne ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: OtakuTypo.headlineSmall.copyWith(
            fontSize: 11,
            color: estSelectionne ? Colors.black : OtakuColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildPageArc() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("CHOISIS L'ARC", style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          if (_chargementArcs)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildChipArc(null, 'TOUS LES ARCS'),
                    ..._arcsDisponibles.map((arc) => _buildChipArc(arc, arc)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChipArc(String? arc, String label) {
    final estSelectionne = _arcChoisi == arc;
    return GestureDetector(
      onTap: () => setState(() => _arcChoisi = arc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: estSelectionne ? OtakuColors.accent : OtakuColors.surface,
          border: Border.all(
            color: estSelectionne ? OtakuColors.accent : OtakuColors.border,
            width: estSelectionne ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: OtakuTypo.headlineSmall.copyWith(
            fontSize: 11,
            color: estSelectionne ? Colors.black : OtakuColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildPageDifficulteEtContrat() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colonne gauche : 6 modes de difficulte
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DIFFICULTE (6 MODES)', style: OtakuTypo.headlineLarge.copyWith(fontSize: 15)),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.separated(
                    itemCount: _difficultes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final diff = _difficultes[i];
                      final sel = _difficulteChoisie == diff['id'];
                      return GestureDetector(
                        onTap: () => setState(() => _difficulteChoisie = diff['id']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? OtakuColors.accent.withValues(alpha: 0.14) : OtakuColors.surface,
                            border: Border.all(color: sel ? OtakuColors.accent : OtakuColors.border, width: sel ? 1.8 : 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                size: 18,
                                color: sel ? OtakuColors.accent : OtakuColors.textMuted,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      diff['label']!,
                                      style: OtakuTypo.headlineSmall.copyWith(
                                        fontSize: 12,
                                        color: sel ? OtakuColors.accent : OtakuColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      diff['desc']!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: OtakuTypo.bodySmall.copyWith(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Colonne droite : Contrat Malus + Options OC
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CONTRAT MALUS', style: OtakuTypo.headlineLarge.copyWith(fontSize: 15)),
                  const SizedBox(height: 6),
                  Row(
                    children: _malusOptions.map((m) {
                      final sel = _malusChoisi == m['id'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _malusChoisi = m['id']!),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: BoxDecoration(
                              color: sel ? OtakuColors.modeDuel.withValues(alpha: 0.2) : OtakuColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: sel ? OtakuColors.modeDuel : OtakuColors.border),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  m['label']!,
                                  style: OtakuTypo.label.copyWith(
                                    fontSize: 10,
                                    color: sel ? OtakuColors.modeDuel : OtakuColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _malusOptions.firstWhere((e) => e['id'] == _malusChoisi)['desc']!,
                    style: OtakuTypo.bodySmall.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 12),
                  Text('OPTIONS AVANT-MATCH', style: OtakuTypo.headlineLarge.copyWith(fontSize: 15)),
                  const SizedBox(height: 6),
                  // Assurance XP (25 OC)
                  SwitchListTile.adaptive(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    tileColor: OtakuColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: OtakuColors.border),
                    ),
                    title: Text('Assurance XP (25 OC)', style: OtakuTypo.headlineSmall.copyWith(fontSize: 11)),
                    subtitle: Text('Divise par 2 la perte XP si defaite', style: OtakuTypo.bodySmall.copyWith(fontSize: 10)),
                    value: _assuranceXp,
                    onChanged: _niveauJoueur >= 6 ? (v) => setState(() => _assuranceXp = v) : null,
                  ),
                  const SizedBox(height: 8),
                  // Puits de Confiance (0 / 15 / 30 OC)
                  Text('Puits de Confiance (x2 si victoire solide)', style: OtakuTypo.bodySmall.copyWith(fontSize: 10)),
                  const SizedBox(height: 4),
                  Row(
                    children: [0, 15, 30].map((v) {
                      final sel = _puitsOc == v;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _puitsOc = v),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: sel ? OtakuColors.accent.withValues(alpha: 0.2) : OtakuColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: sel ? OtakuColors.accent : OtakuColors.border),
                            ),
                            child: Text(
                              v == 0 ? 'AUCUN' : '$v OC',
                              style: OtakuTypo.label.copyWith(
                                fontSize: 10,
                                color: sel ? OtakuColors.accent : OtakuColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
