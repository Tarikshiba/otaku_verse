import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'matchmaking_service.dart';
import 'verse_combat_page.dart';

class VerseDivisionPage extends StatefulWidget {
  const VerseDivisionPage({super.key});

  @override
  State<VerseDivisionPage> createState() => _VerseDivisionPageState();
}

class _VerseDivisionPageState extends State<VerseDivisionPage> {
  final MatchmakingService _matchmaking = MatchmakingService();
  String _status = "Chargement de ton rang PvP...";
  bool _found = false;
  Map<String, dynamic>? _statsDivision;

  @override
  void initState() {
    super.initState();
    _initialiserEtChercher();
  }

  Future<void> _initialiserEtChercher() async {
    try {
      final stats = await _matchmaking.recupererStatsDivision();
      if (!mounted) return;
      final int secondesCooldown = stats['secondesCooldown'] as int? ?? 0;
      if (secondesCooldown > 0) {
        final int mins = (secondesCooldown / 60).ceil();
        setState(() {
          _statsDivision = stats;
          _found = true; // Masque le loader
          _status = "Pénalité d'abandon active : réessaie dans $mins min.";
        });
        return;
      }
      setState(() {
        _statsDivision = stats;
        _status = "Recherche d'un adversaire (Division ${stats['division']} ±2)...";
      });
      await _lancerRecherche();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = "Erreur de connexion...";
      });
    }
  }

  Future<void> _lancerRecherche() async {
    try {
      final matchId = await _matchmaking.chercherMatchClasse();
      if (!mounted) return;
      setState(() {
        _status = "Adversaire trouvé ! Entrée dans l'arène...";
        _found = true;
      });
      
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => VerseCombatPage(matchId: matchId)),
        );
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = "Erreur de connexion...";
      });
    }
  }

  @override
  void dispose() {
    if (!_found) {
      _matchmaking.annulerRecherche();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int div = _statsDivision?['division'] ?? 10;
    final String nomDiv = _statsDivision?['nomDivision'] ?? 'Académie';
    final int points = _statsDivision?['points'] ?? 0;
    final int xpPvp = _statsDivision?['xpPvp'] ?? 0;

    return Scaffold(
      backgroundColor: OtakuColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: OtakuColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: OtakuColors.modeDivision.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "DIVISION $div : ${nomDiv.toUpperCase()}",
                        style: OtakuTypo.headlineSmall.copyWith(color: OtakuColors.modeDivision),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$points PTS  |  $xpPvp XP PVP",
                        style: OtakuTypo.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Icon(
                  _found ? Icons.check_circle_rounded : Icons.military_tech_rounded,
                  size: 64,
                  color: _found ? Colors.greenAccent : OtakuColors.modeDivision,
                ),
                const SizedBox(height: 12),
                Text(
                  _found ? "MATCH TROUVÉ" : "RECHERCHE D'ADVERSAIRE...",
                  style: OtakuTypo.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(_status, style: OtakuTypo.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                if (!_found)
                  const CircularProgressIndicator(color: OtakuColors.modeDivision),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
