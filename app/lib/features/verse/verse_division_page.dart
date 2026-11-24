import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../shared/rank_badge.dart';
import '../combat/combat_models.dart';
import '../combat/combat_page.dart';
import '../combat/combat_service.dart';
import '../core/feature_flags_service.dart';
import '../economy/economy_v92_service.dart';
import '../progression/progression_service.dart';
import '../social/classement_screen.dart';
import 'matchmaking_service.dart';
import 'verse_combat_page.dart';

/// === MODE DIVISION V9.2 (LAUNCH-02 : AI_ONLY SEMAINE 1 -> HYBRID_5S SEMAINE 3) ===
/// Lit `division_matchmaking_mode` depuis `app_feature_flags`.
/// En `AI_ONLY` : zero WebSocket, adversaire IA calibre sur la Division,
/// barème 100 % officiel (350 PV / 40 Q mix 10/25/30/25/10 %) et vrai Classement Mondial.
class VerseDivisionPage extends StatefulWidget {
  const VerseDivisionPage({super.key});

  @override
  State<VerseDivisionPage> createState() => _VerseDivisionPageState();
}

class _VerseDivisionPageState extends State<VerseDivisionPage> {
  final MatchmakingService _matchmaking = MatchmakingService();
  final EconomyV92Service _economyService = EconomyV92Service();
  final ProgressionService _progressionService = ProgressionService();
  final CombatService _combatService = CombatService();
  final FeatureFlagsService _flagsService = FeatureFlagsService();

  String _status = 'Chargement de ta Division...';
  bool _chargement = true;
  bool _rechercheEnCours = false;
  bool _peutCoupDePouce = false;

  int _niveau = 1;
  int _divisionId = 10;
  int _ptsDivision = 0;
  WalletV92 _wallet = const WalletV92();
  String _modeMatchmaking = 'AI_ONLY';

  @override
  void initState() {
    super.initState();
    _chargerInfosDivision();
  }

  Future<void> _chargerInfosDivision() async {
    try {
      await _flagsService.chargerFlags();
      final results = await Future.wait([
        _progressionService.recupererProfil(),
        _economyService.recupererPortefeuille(),
      ]);
      if (!mounted) return;
      final p = results[0] as Map<String, dynamic>?;
      final w = results[1] as WalletV92;
      final pts = (p?['pts_division'] as num?)?.toInt() ?? 0;
      final div = EconomyV92Service.calculerDivision(pts);
      setState(() {
        _niveau = (p?['niveau'] as num?)?.toInt() ?? 1;
        _ptsDivision = pts;
        _divisionId = div;
        _wallet = w;
        _modeMatchmaking = _flagsService.modeMatchmakingDivision;
        _chargement = false;
        _status = 'Pret a entrer en Division $div (${EconomyV92Service.nomDivision(div)})';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _chargement = false;
          _status = 'Erreur de chargement du profil.';
        });
      }
    }
  }

  /// Arbitrage officiel ECO-05 : en Mode Division des Niv 6, la Division prevaut
  int get _fraisEntreeOc => EconomyV92Service.fraisAreneOc(
        niveau: _niveau,
        divisionId: _divisionId,
        mode: 'division',
      );

  Future<void> _lancerMatchDivision() async {
    setState(() {
      _rechercheEnCours = true;
      _peutCoupDePouce = false;
      _status = "Recherche d'un adversaire de Division $_divisionId...";
    });

    // Mode Palier 1 : AI_ONLY (0 WebSocket, Bot IA calibre + bareme Division officiel)
    if (_modeMatchmaking == 'AI_ONLY') {
      try {
        final startData = await _economyService.demarrerMatch(
          mode: 'division',
          difficulty: 'moyen',
          malusMode: 'normal',
        );
        final matchId = startData['match_id']?.toString();
        final opp = startData['opponent'] is Map ? startData['opponent'] as Map : const {};
        final oppPseudo = opp['pseudo']?.toString() ?? 'A.K.I.N.A';
        final oppLevel = (opp['level'] as num?)?.toInt() ?? _niveau;

        final params = CombatParams(
          mode: 'division',
          difficulte: opp['tier']?.toString() ?? 'moyen',
          malusMode: 'normal',
          matchId: matchId,
          opponentPseudo: oppPseudo,
          opponentLevel: oppLevel,
          opponentDivisionId: _divisionId,
        );

        // Tirage officiel 40 questions (mix 10/25/30/25/10 %) depuis Cloudflare R2
        final questions = await _combatService.preparerCombat(params);
        await Future.delayed(const Duration(milliseconds: 350));

        if (!mounted) return;
        if (questions.isEmpty) {
          setState(() {
            _rechercheEnCours = false;
            _status = 'Impossible de charger les questions. Réessaie.';
          });
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CombatPage(questions: questions, params: params)),
        );
      } on MatchStartException catch (e) {
        if (!mounted) return;
        setState(() {
          _rechercheEnCours = false;
          _peutCoupDePouce = e.canRescueAd;
          _status = e.message;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _rechercheEnCours = false;
          _status = 'Connexion impossible pour le moment. Vérifie ton réseau et réessaie.';
        });
      }
      return;
    }

    // Mode Palier 3+ : HYBRID_5S / PVP_PRIORITY_8S (matchmaking temps reel)
    try {
      final matchId = await _matchmaking.chercherMatchClasse();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => VerseCombatPage(matchId: matchId)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rechercheEnCours = false;
        _status = 'Erreur de connexion au matchmaking.';
      });
    }
  }

  Future<void> _reclamerCoupDePouce() async {
    try {
      await _economyService.reclamerCoupDePouceOc('division');
      await _chargerInfosDivision();
      setState(() => _peutCoupDePouce = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  void dispose() {
    if (_rechercheEnCours && _modeMatchmaking != 'AI_ONLY') {
      _matchmaking.annulerRecherche();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nomDiv = EconomyV92Service.nomDivision(_divisionId);
    final bool manqueOc = _wallet.ocBalance < _fraisEntreeOc;

    return Scaffold(
      backgroundColor: OtakuColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('MODE DIVISION · SAISON 1', style: OtakuTypo.headlineSmall),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: _chargement
              ? const CircularProgressIndicator(color: OtakuColors.modeDivision)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: OtakuColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: OtakuColors.modeDivision.withValues(alpha: 0.55)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'DIVISION $_divisionId : ${nomDiv.toUpperCase()}',
                              style: OtakuTypo.headlineSmall.copyWith(color: OtakuColors.modeDivision),
                            ),
                            const SizedBox(height: 6),
                            OfficialRankBadge(niveau: _niveau, divisionId: _divisionId),
                            const SizedBox(height: 6),
                            Text(
                              '$_ptsDivision PTS  |  Solde : ${_wallet.ocBalance} OC  |  Frais : $_fraisEntreeOc OC',
                              style: OtakuTypo.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(_status, style: OtakuTypo.bodySmall, textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      if (_rechercheEnCours)
                        const CircularProgressIndicator(color: OtakuColors.modeDivision)
                      else if (manqueOc || _peutCoupDePouce)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OtakuColors.modeEvent,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _reclamerCoupDePouce,
                          icon: const Icon(Icons.play_circle_outline_rounded),
                          label: const Text('COUP DE POUCE (+40 OC · PUB)'),
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OtakuColors.modeDivision,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          ),
                          onPressed: _lancerMatchDivision,
                          icon: const Icon(Icons.military_tech_rounded),
                          label: Text(
                            _fraisEntreeOc > 0
                                ? 'LANCER UN DUEL CLASSÉ ($_fraisEntreeOc OC)'
                                : 'LANCER UN DUEL CLASSÉ (GRATUIT)',
                          ),
                        ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber,
                          side: BorderSide(color: Colors.amber.withValues(alpha: 0.6)),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ClassementScreen(initialSection: 'competitif')),
                        ),
                        icon: const Icon(Icons.leaderboard_rounded, size: 16),
                        label: const Text('CLASSEMENT DIVISION & 10 PALIERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
