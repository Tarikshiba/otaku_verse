import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../quiz/quiz_service.dart';

class MatchmakingService {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://otaku-verse-6e05e-default-rtdb.europe-west1.firebasedatabase.app');
  final _supabase = Supabase.instance.client;
  final QuizService _quizService = QuizService();

  /// Calcule le numero de division (10 a 1) selon les points PvP (bareme ROADMAP 9.2)
  static int calculerDivision(int points) {
    if (points >= 4000) return 1;
    if (points >= 3250) return 2;
    if (points >= 2500) return 3;
    if (points >= 1850) return 4;
    if (points >= 1300) return 5;
    if (points >= 850) return 6;
    if (points >= 500) return 7;
    if (points >= 250) return 8;
    if (points >= 100) return 9;
    return 10;
  }

  /// Retourne le titre officiel associe a la division
  static String nomDivision(int division) {
    switch (division) {
      case 1:
        return 'Légende du Verse';
      case 2:
        return 'Hokage';
      case 3:
        return 'Yonko';
      case 4:
        return 'Amiral';
      case 5:
        return 'Vice-Amiral';
      case 6:
        return 'Capitaine';
      case 7:
        return 'Jonin';
      case 8:
        return 'Chunin';
      case 9:
        return 'Genin';
      default:
        return 'Académie';
    }
  }

  /// Recupere les statistiques PvP (Division, points, XP PvP) du joueur connecte
  Future<Map<String, dynamic>> recupererStatsDivision() async {
    final userId = _supabase.auth.currentUser!.id;
    final snap = await _db.ref('divisions/$userId').get();
    if (snap.exists && snap.value is Map) {
      final data = Map<String, dynamic>.from(snap.value as Map);
      final int points = data['points'] ?? 0;
      final int div = calculerDivision(points);
      return {
        'points': points,
        'division': div,
        'nomDivision': nomDivision(div),
        'xpPvp': data['xpPvp'] ?? 0,
        'victoires': data['victoires'] ?? 0,
        'defaites': data['defaites'] ?? 0,
      };
    }
    return {
      'points': 0,
      'division': 10,
      'nomDivision': nomDivision(10),
      'xpPvp': 0,
      'victoires': 0,
      'defaites': 0,
    };
  }

  /// Met a jour les points de division et l'XP PvP a la fin d'un match classe
  Future<Map<String, dynamic>> mettreAJourDivisionApresMatch({
    required int deltaPoints,
    required int xpGagne,
    required String resultat,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final statsActuelles = await recupererStatsDivision();
    final int anciensPoints = statsActuelles['points'] as int;
    final int nouveauxPoints = (anciensPoints + deltaPoints).clamp(0, 999999);
    final int nouvelleDivision = calculerDivision(nouveauxPoints);
    final int nouvelXpPvp = (statsActuelles['xpPvp'] as int) + xpGagne;
    final int victoires = (statsActuelles['victoires'] as int) + (resultat == 'victoire' ? 1 : 0);
    final int defaites = (statsActuelles['defaites'] as int) + (resultat == 'defaite' || resultat == 'abandon' ? 1 : 0);

    final updated = {
      'points': nouveauxPoints,
      'division': nouvelleDivision,
      'nomDivision': nomDivision(nouvelleDivision),
      'xpPvp': nouvelXpPvp,
      'victoires': victoires,
      'defaites': defaites,
      'updatedAt': ServerValue.timestamp,
    };

    await _db.ref('divisions/$userId').set(updated);
    return updated;
  }

  /// Recupere le vrai pseudo du joueur depuis Supabase (ou extrait de l'email en secours)
  Future<String> _recupererPseudo() async {
    final user = _supabase.auth.currentUser!;
    try {
      final profil = await _supabase
          .from('profiles')
          .select('pseudo')
          .eq('id', user.id)
          .maybeSingle();
      if (profil != null && profil['pseudo'] != null && (profil['pseudo'] as String).isNotEmpty) {
        return profil['pseudo'] as String;
      }
    } catch (_) {}
    final userEmail = user.email ?? 'Joueur';
    return userEmail.split('@')[0];
  }

  /// Cherche un adversaire dans la file d'attente globale par division (±2 divisions)
  /// Retourne le matchId quand la partie est trouvee (ou creee avec un bot)
  Future<String> chercherMatchClasse() async {
    final user = _supabase.auth.currentUser!;
    final userId = user.id;
    final pseudo = await _recupererPseudo();
    final stats = await recupererStatsDivision();
    final int maDivision = stats['division'] as int;
    final int mesPoints = stats['points'] as int;

    // 1. Verifier s'il y a deja un joueur en attente dans la file globale
    final queueSnap = await _db.ref('matchmaking/queue').get();
    if (queueSnap.exists && queueSnap.value is Map) {
      final queueMap = Map<dynamic, dynamic>.from(queueSnap.value as Map);
      String? adversaireId;
      Map<dynamic, dynamic>? adversaireData;

      for (final entry in queueMap.entries) {
        final String candId = entry.key.toString();
        if (candId == userId || entry.value is! Map) continue;
        final cand = Map<dynamic, dynamic>.from(entry.value as Map);
        if (cand['status'] == 'searching' && cand['mode'] == 'division') {
          final int candDiv = cand['division'] ?? 10;
          // Appairage si l'ecart est de ±2 divisions maximum
          if ((candDiv - maDivision).abs() <= 2) {
            adversaireId = candId;
            adversaireData = cand;
            break;
          }
        }
      }

      // Si un adversaire humain compatible attend deja, on cree le match immediatement
      if (adversaireId != null && adversaireData != null) {
        final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';
        final matchRef = _db.ref('matches/$matchId');

        final questionsList = await _quizService.recupererQuestions(nombre: 10);
        final questionsMap = questionsList.map((q) => {
          'id': q.id,
          'question': q.question,
          'choixA': q.choixA,
          'choixB': q.choixB,
          'choixC': q.choixC,
          'choixD': q.choixD,
          if (q.imageUrl != null) 'imageUrl': q.imageUrl,
        }).toList();

        await matchRef.set({
          'status': 'starting',
          'mode': 'division',
          'questions': questionsMap,
          'currentQuestionIndex': 0,
          'player1': {
            'id': adversaireId,
            'pseudo': adversaireData['pseudo'] ?? 'Joueur 1',
            'division': adversaireData['division'] ?? 10,
            'pv': 100,
            'combo': 0,
            'ready': true,
          },
          'player2': {
            'id': userId,
            'pseudo': pseudo,
            'division': maDivision,
            'pv': 100,
            'combo': 0,
            'ready': true,
          },
          'createdAt': ServerValue.timestamp,
        });

        // Prevenir le joueur 1 qui attendait dans la file
        await _db.ref('matchmaking/queue/$adversaireId').update({
          'status': 'matched',
          'matchId': matchId,
        });

        return matchId;
      }
    }

    final queueRef = _db.ref('matchmaking/queue/$userId');

    // 2. Sinon, inscription dans la file d'attente globale
    await queueRef.set({
      'id': userId,
      'mode': 'division',
      'pseudo': pseudo,
      'division': maDivision,
      'points': mesPoints,
      'status': 'searching',
      'timestamp': ServerValue.timestamp,
    });

    final completer = Completer<String>();
    StreamSubscription? sub;
    Timer? timeoutTimer;

    // 3. Ecoute des changements (quand un autre joueur nous rejoint et renseigne matchId)
    sub = queueRef.onValue.listen((event) {
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        final data = event.snapshot.value as Map;
        if (data['matchId'] != null) {
          final matchId = data['matchId'] as String;
          if (!completer.isCompleted) {
            completer.complete(matchId);
          }
        }
      }
    });

    // 4. Fallback Bot adaptatif apres 10 secondes si aucun joueur humain n'est disponible
    timeoutTimer = Timer(const Duration(seconds: 10), () async {
      if (!completer.isCompleted) {
        await queueRef.remove();
        
        final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';
        final matchRef = _db.ref('matches/$matchId');
        
        final questionsList = await _quizService.recupererQuestions(nombre: 10);
        final questionsMap = questionsList.map((q) => {
          'id': q.id,
          'question': q.question,
          'choixA': q.choixA,
          'choixB': q.choixB,
          'choixC': q.choixC,
          'choixD': q.choixD,
          if (q.imageUrl != null) 'imageUrl': q.imageUrl,
        }).toList();

        await matchRef.set({
          'status': 'starting',
          'mode': 'division',
          'questions': questionsMap,
          'currentQuestionIndex': 0,
          'player1': {
            'id': userId,
            'pseudo': pseudo,
            'division': maDivision,
            'pv': 100,
            'combo': 0,
            'ready': true,
          },
          'player2': {
            'id': 'bot_123',
            'pseudo': 'A.K.I.N.A (Bot)',
            'division': maDivision,
            'pv': 100,
            'combo': 0,
            'ready': true,
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

  /// Crée un salon amical privé et génère un code à 6 chiffres
  Future<Map<String, dynamic>> creerSalonAmical() async {
    final user = _supabase.auth.currentUser!;
    final userId = user.id;
    final pseudo = await _recupererPseudo();

    // Génération du code à 6 chiffres
    final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    final matchId = 'amical_$code';
    final matchRef = _db.ref('matches/$matchId');

    // Recuperer 10 questions aleatoires (pour l'instant, force One Piece)
    final questionsList = await _quizService.recupererQuestions(nombre: 10, anime: 'One Piece');
    final questionsMap = questionsList.map((q) => {
      'id': q.id,
      'question': q.question,
      'choixA': q.choixA,
      'choixB': q.choixB,
      'choixC': q.choixC,
      'choixD': q.choixD,
      if (q.imageUrl != null) 'imageUrl': q.imageUrl,
    }).toList();

    await matchRef.set({
      'status': 'waiting', // En attente du joueur 2
      'mode': 'amical',
      'code': code,
      'questions': questionsMap,
      'currentQuestionIndex': 0,
      'player1': {
        'id': userId,
        'pseudo': pseudo,
        'pv': 100,
        'combo': 0,
        'ready': false,
      },
      'createdAt': ServerValue.timestamp,
    });

    return {'matchId': matchId, 'code': code};
  }

  /// Rejoint un salon amical privé avec un code à 6 chiffres
  Future<String?> rejoindreSalonAmical(String code) async {
    final user = _supabase.auth.currentUser!;
    final userId = user.id;
    final pseudo = await _recupererPseudo();

    final matchId = 'amical_$code';
    final matchRef = _db.ref('matches/$matchId');
    final snapshot = await matchRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      if (data['status'] == 'waiting' && data['player2'] == null) {
        // Le joueur 2 rejoint la partie
        await matchRef.update({
          'status': 'starting',
          'player2': {
            'id': userId,
            'pseudo': pseudo,
            'pv': 100,
            'combo': 0,
            'ready': false,
          }
        });
        return matchId;
      } else {
        throw Exception("Salon plein ou déjà lancé.");
      }
    } else {
      throw Exception("Code invalide ou salon introuvable.");
    }
  }
}
