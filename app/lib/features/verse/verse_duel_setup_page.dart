import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/theme.dart';
import 'matchmaking_service.dart';
import 'verse_combat_page.dart';

class VerseDuelSetupPage extends StatefulWidget {
  const VerseDuelSetupPage({super.key});

  @override
  State<VerseDuelSetupPage> createState() => _VerseDuelSetupPageState();
}

class _VerseDuelSetupPageState extends State<VerseDuelSetupPage> {
  final MatchmakingService _matchmakingService = MatchmakingService();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  void _creerSalon() async {
    setState(() => _isLoading = true);
    try {
      final data = await _matchmakingService.creerSalonAmical();
      final String matchId = data['matchId'];
      final String code = data['code'];
      
      setState(() => _isLoading = false);
      _afficherLobbyAttente(matchId, code);
    } catch (e) {
      setState(() => _isLoading = false);
      _afficherErreur(e.toString());
    }
  }

  void _rejoindreSalon() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length != 6) {
      _afficherErreur("Code invalide. Entrez 6 chiffres.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final matchId = await _matchmakingService.rejoindreSalonAmical(code);
      setState(() => _isLoading = false);
      
      if (matchId != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => VerseCombatPage(matchId: matchId)),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _afficherErreur(e.toString());
    }
  }

  void _afficherLobbyAttente(String matchId, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LobbyDialog(matchId: matchId, code: code),
    );
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("CRÉER UN SALON", style: OtakuTypo.headlineSmall),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_alt_rounded, size: 80, color: OtakuColors.modeDuel),
              const SizedBox(height: 20),
              Text("GÉNÉRER UN CODE", style: OtakuTypo.headlineLarge),
              const SizedBox(height: 10),
              Text("Paramètre les règles de ton duel amical.", style: OtakuTypo.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator(color: OtakuColors.modeDuel)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.modeDuel),
                      onPressed: _creerSalon,
                      child: const Text("CRÉER LE SALON"),
                    ),
              const SizedBox(height: 30),
              Text("OU", style: OtakuTypo.bodySmall),
              const SizedBox(height: 30),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: "ENTRER LE CODE (6 CHIFFRES)",
                  filled: true,
                  fillColor: OtakuColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: "",
                ),
                textAlign: TextAlign.center,
                style: OtakuTypo.headlineSmall,
              ),
              const SizedBox(height: 10),
              _isLoading
                  ? const SizedBox.shrink()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                      onPressed: _rejoindreSalon,
                      child: const Text("REJOINDRE"),
                    ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LobbyDialog extends StatefulWidget {
  final String matchId;
  final String code;

  const _LobbyDialog({required this.matchId, required this.code});

  @override
  State<_LobbyDialog> createState() => _LobbyDialogState();
}

class _LobbyDialogState extends State<_LobbyDialog> {
  late StreamSubscription _matchSubscription;
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app, 
      databaseURL: 'https://otaku-verse-6e05e-default-rtdb.europe-west1.firebasedatabase.app'
  );

  @override
  void initState() {
    super.initState();
    _ecouterStatusMatch();
  }

  void _ecouterStatusMatch() {
    final ref = _db.ref('matches/${widget.matchId}/status');
    _matchSubscription = ref.onValue.listen((event) {
      if (event.snapshot.value == 'starting') {
        if (mounted) {
          Navigator.of(context).pop(); // Ferme la modale
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => VerseCombatPage(matchId: widget.matchId)),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _matchSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: OtakuColors.surface,
      title: Text("SALON CRÉÉ", style: OtakuTypo.headlineSmall, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Donne ce code à ton adversaire :", style: OtakuTypo.bodySmall),
          const SizedBox(height: 20),
          Text(widget.code, style: OtakuTypo.headlineLarge.copyWith(color: OtakuColors.modeDuel, letterSpacing: 8)),
          const SizedBox(height: 30),
          const CircularProgressIndicator(color: OtakuColors.accent),
          const SizedBox(height: 20),
          Text("En attente du joueur 2...", style: OtakuTypo.bodySmall),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Optionnel : supprimer le match dans Firebase
            Navigator.of(context).pop();
          },
          child: const Text("ANNULER", style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }
}
