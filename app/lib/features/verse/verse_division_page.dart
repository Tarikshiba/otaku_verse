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
  String _status = "Recherche d'un joueur de ton rang...";
  bool _found = false;

  @override
  void initState() {
    super.initState();
    _lancerRecherche();
  }

  Future<void> _lancerRecherche() async {
    try {
      final matchId = await _matchmaking.chercherMatchClasse();
      if (!mounted) return;
      setState(() {
        _status = "Adversaire trouvé ! (Match: $matchId)";
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
    return Scaffold(
      backgroundColor: OtakuColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _found ? Icons.check_circle_rounded : Icons.military_tech_rounded, 
              size: 80, 
              color: _found ? Colors.greenAccent : OtakuColors.modeDivision
            ),
            const SizedBox(height: 20),
            Text(
              _found ? "MATCH TROUVÉ" : "RECHERCHE D'ADVERSAIRE...", 
              style: OtakuTypo.headlineLarge
            ),
            const SizedBox(height: 10),
            Text(_status, style: OtakuTypo.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 40),
            if (!_found)
              const CircularProgressIndicator(color: OtakuColors.modeDivision),
          ],
        ),
      ),
    );
  }
}
