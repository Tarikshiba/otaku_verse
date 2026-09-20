import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/theme.dart';

class VerseCombatPage extends StatefulWidget {
  final String matchId;
  const VerseCombatPage({super.key, required this.matchId});

  @override
  State<VerseCombatPage> createState() => _VerseCombatPageState();
}

class _VerseCombatPageState extends State<VerseCombatPage> {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app, 
      databaseURL: 'https://otaku-verse-6e05e-default-rtdb.europe-west1.firebasedatabase.app'
  );
  
  Map<dynamic, dynamic>? _matchData;

  @override
  void initState() {
    super.initState();
    _db.ref('matches/${widget.matchId}').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _matchData = event.snapshot.value as Map<dynamic, dynamic>;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_matchData == null) {
      return const Scaffold(
        backgroundColor: OtakuColors.background,
        body: Center(child: CircularProgressIndicator(color: OtakuColors.accent)),
      );
    }

    final player1 = _matchData!['player1'] ?? {};
    final player2 = _matchData!['player2'] ?? {};

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // BARRES DE VIE (TEMPS RÉEL)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPlayerAvatar(player1['pseudo'] ?? 'Joueur 1', player1['pv'] ?? 100, isMe: true),
                  const Text('VS', style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                  _buildPlayerAvatar(player2['pseudo'] ?? 'Adversaire', player2['pv'] ?? 100, isMe: false),
                ],
              ),
            ),
            
            const Spacer(),
            Text("L'ARÈNE DU VERSE", style: OtakuTypo.headlineLarge),
            const SizedBox(height: 10),
            Text("(Interface en cours de construction)", style: OtakuTypo.bodySmall),
            const Spacer(),
            
            // BOUTON QUITTER (Temporaire)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(context),
                child: const Text('QUITTER LE MATCH'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar(String pseudo, int pv, {required bool isMe}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: isMe ? OtakuColors.accent : Colors.redAccent,
          child: Icon(Icons.person, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        Text(pseudo, style: OtakuTypo.headlineSmall.copyWith(fontSize: 14)),
        const SizedBox(height: 4),
        Container(
          width: 100,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
            widthFactor: (pv / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: isMe ? OtakuColors.modeSolo : Colors.redAccent,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('$pv PV', style: OtakuTypo.label.copyWith(color: isMe ? OtakuColors.modeSolo : Colors.redAccent)),
      ],
    );
  }
}
