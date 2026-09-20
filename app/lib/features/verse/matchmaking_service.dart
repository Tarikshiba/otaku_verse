import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchmakingService {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://otaku-verse-6e05e-default-rtdb.europe-west1.firebasedatabase.app');
  final _supabase = Supabase.instance.client;

  /// Cherche un adversaire pour un duel (Verse V2)
  /// Retourne le matchId quand la partie est trouvee (ou creee avec un bot)
  Future<String> chercherMatchClasse() async {
    final user = _supabase.auth.currentUser!;
    final userId = user.id;
    final userEmail = user.email ?? 'Joueur';
    final pseudo = userEmail.split('@')[0]; // En attendant d'avoir le profil complet

    final queueRef = _db.ref('matchmaking/queue/$userId');

    // 1. Inscription dans la file d'attente
    await queueRef.set({
      'mode': 'division',
      'pseudo': pseudo,
      'status': 'searching',
      'timestamp': ServerValue.timestamp,
    });

    final completer = Completer<String>();
    StreamSubscription? sub;
    Timer? timeoutTimer;

    // 2. Ecoute des changements (si une Edge Function ou un autre joueur nous match)
    sub = queueRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map;
        if (data['matchId'] != null) {
          final matchId = data['matchId'] as String;
          if (!completer.isCompleted) {
            completer.complete(matchId);
          }
        }
      }
    });

    // 3. Fallback Bot apres 5 secondes pour tester facilement
    timeoutTimer = Timer(const Duration(seconds: 5), () async {
      if (!completer.isCompleted) {
        // On annule la file d'attente
        await queueRef.remove();
        
        // On cree un match artificiel avec un Bot
        final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';
        final matchRef = _db.ref('matches/$matchId');
        
        await matchRef.set({
          'status': 'starting',
          'mode': 'division',
          'player1': {
            'id': userId,
            'pseudo': pseudo,
            'pv': 100,
            'combo': 0,
            'ready': false,
          },
          'player2': {
            'id': 'bot_123',
            'pseudo': 'A.K.I.N.A (Bot)',
            'pv': 100,
            'combo': 0,
            'ready': true, // Le bot est toujours pret
            'isBot': true,
          },
          'createdAt': ServerValue.timestamp,
        });

        completer.complete(matchId);
      }
    });

    // Nettoyage quand le future se termine
    final matchId = await completer.future;
    sub?.cancel();
    timeoutTimer.cancel();
    await queueRef.remove(); // On se retire de la file d'attente
    
    return matchId;
  }

  /// Annule la recherche en cours
  Future<void> annulerRecherche() async {
    final userId = _supabase.auth.currentUser!.id;
    await _db.ref('matchmaking/queue/$userId').remove();
  }
}
