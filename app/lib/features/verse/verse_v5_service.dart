import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../quiz/quiz_service.dart';
import '../skins/monetisation_v4_service.dart';

/// Service de la V5 (Expansion) :
/// 1. Battle Royale Quiz (10 joueurs, élimination progressive jusqu'au dernier survivant)
/// 2. Système de Guildes / Clans (création, adhésion, mur de clan et Classement Mondial)
class VerseV5Service {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://otaku-verse-6e05e-default-rtdb.europe-west1.firebasedatabase.app',
  );
  final SupabaseClient _supabase = Supabase.instance.client;
  final QuizService _quizService = QuizService();
  final MonetisationV4Service _v4Service = MonetisationV4Service();

  Future<String> recupererPseudo() async {
    final user = _supabase.auth.currentUser!;
    try {
      final p = await _supabase.from('profiles').select('pseudo').eq('id', user.id).maybeSingle();
      if (p != null && p['pseudo'] != null && (p['pseudo'] as String).isNotEmpty) {
        return p['pseudo'] as String;
      }
    } catch (_) {}
    return (user.email ?? 'Joueur').split('@').first;
  }

  // ===========================================================================
  // 1. BATTLE ROYALE QUIZ (10 JOUEURS — SURVIE)
  // ===========================================================================

  /// Crée ou rejoint un salon Battle Royale à 10 joueurs (complété par des bots survivants)
  Future<Map<String, dynamic>> creerOuRejoindreBattleRoyale({String? codeSalon}) async {
    final userId = _supabase.auth.currentUser!.id;
    final pseudo = await recupererPseudo();

    // Si un code à 6 chiffres est fourni par un ami (ex: Heat), on rejoint ce salon
    if (codeSalon != null && codeSalon.trim().length == 6) {
      final String lobbyId = 'br_${codeSalon.trim()}';
      final ref = _db.ref('battle_royale/$lobbyId');
      final snap = await ref.get();
      if (!snap.exists || snap.value is! Map) {
        throw Exception("Salon Battle Royale introuvable.");
      }
      await ref.child('joueurs/$userId').set({
        'id': userId,
        'pseudo': pseudo,
        'pv': 100,
        'elimine': false,
        'score': 0,
        'isBot': false,
      });
      return {'lobbyId': lobbyId, 'code': codeSalon.trim()};
    }

    // Sinon on crée un nouveau salon Battle Royale de 10 joueurs
    final String code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    final String lobbyId = 'br_$code';
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

    final Map<String, dynamic> joueurs = {
      userId: {
        'id': userId,
        'pseudo': pseudo,
        'pv': 100,
        'elimine': false,
        'score': 0,
        'isBot': false,
      },
    };

    const botsNoms = [
      'Kaido_BR',
      'Madara_U',
      'Sukuna_20',
      'Aizen_S',
      'Meruem_K',
      'Eren_Titan',
      'Broly_Z',
      'Levi_Ack',
      'Katakuri_M',
    ];

    for (int i = 0; i < botsNoms.length; i++) {
      final botId = 'bot_br_$i';
      joueurs[botId] = {
        'id': botId,
        'pseudo': botsNoms[i],
        'pv': 100,
        'elimine': false,
        'score': 0,
        'isBot': true,
      };
    }

    await _db.ref('battle_royale/$lobbyId').set({
      'status': 'playing',
      'code': code,
      'currentQuestionIndex': 0,
      'questions': questionsMap,
      'joueurs': joueurs,
      'createdAt': ServerValue.timestamp,
    });

    return {'lobbyId': lobbyId, 'code': code};
  }

  /// Attribue les récompenses de fin de Battle Royale (XP + Verse Coins selon le rang final)
  Future<Map<String, int>> attribuerRecompensesBattleRoyale(int rangFinal, int bonnesReponses) async {
    final userId = _supabase.auth.currentUser!.id;
    int xpGagne = 20 + (bonnesReponses * 10);
    int coinsGagnes = 10;

    if (rangFinal == 1) {
      xpGagne += 80;
      coinsGagnes = 50;
    } else if (rangFinal <= 3) {
      xpGagne += 40;
      coinsGagnes = 25;
    }

    try {
      await _v4Service.acheterPackCoins(coinsGagnes);
      final prof = await _supabase.from('profiles').select('xp_totale').eq('id', userId).maybeSingle();
      if (prof != null) {
        final int xp = (prof['xp_totale'] ?? 0) + xpGagne;
        await _supabase.from('profiles').update({'xp_totale': xp}).eq('id', userId);
      }
    } catch (_) {}

    return {'xp': xpGagne, 'coins': coinsGagnes};
  }

  // ===========================================================================
  // 2. SYSTÈME DE GUILDES / CLANS & CLASSEMENT MONDIAL
  // ===========================================================================

  /// Récupère toutes les guildes classées au niveau mondial ainsi que la guilde du joueur
  Future<Map<String, dynamic>> recupererDonneesGuildes() async {
    final userId = _supabase.auth.currentUser!.id;
    List<Map<String, dynamic>> toutesGuildes = [];
    Map<String, dynamic>? maGuilde;

    try {
      final snap = await _db.ref('guildes').get();
      if (snap.exists && snap.value is Map) {
        final map = Map<String, dynamic>.from(snap.value as Map);
        for (final entry in map.entries) {
          if (entry.value is Map) {
            final g = Map<String, dynamic>.from(entry.value as Map);
            g['id'] = entry.key;
            final Map membres = (g['membres'] is Map) ? Map.from(g['membres'] as Map) : {};
            g['nbMembres'] = membres.length;
            toutesGuildes.add(g);
            if (membres.containsKey(userId)) {
              maGuilde = g;
            }
          }
        }
        toutesGuildes.sort((a, b) => ((b['pointsTotaux'] ?? 0) as int).compareTo((a['pointsTotaux'] ?? 0) as int));
      }
    } catch (_) {}

    return {
      'maGuilde': maGuilde,
      'classementMondial': toutesGuildes,
    };
  }

  /// Crée une nouvelle Guilde / Clan et place son créateur comme Chef
  Future<void> creerGuilde({
    required String nom,
    required String tag,
    required String devise,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final pseudo = await recupererPseudo();
    final String cleanNom = nom.trim();
    final String cleanTag = tag.trim().toUpperCase();

    if (cleanNom.length < 3 || cleanTag.length < 2 || cleanTag.length > 4) {
      throw Exception("Nom (min 3 car.) et Tag (2 à 4 lettres) requis.");
    }

    final String guildeId = 'guilde_${DateTime.now().millisecondsSinceEpoch}';
    await _db.ref('guildes/$guildeId').set({
      'id': guildeId,
      'nom': cleanNom,
      'tag': cleanTag,
      'devise': devise.trim().isEmpty ? 'Unis dans le Verse !' : devise.trim(),
      'chefId': userId,
      'chefPseudo': pseudo,
      'pointsTotaux': 100,
      'membres': {
        userId: {
          'id': userId,
          'pseudo': pseudo,
          'role': 'Chef',
          'contribution': 100,
        },
      },
      'messages': [
        {
          'auteur': 'Système',
          'texte': 'La guilde [$cleanTag] $cleanNom vient d\'être fondée par $pseudo !',
        }
      ],
      'createdAt': ServerValue.timestamp,
    });
  }

  /// Rejoint une Guilde existante
  Future<void> rejoindreGuilde(String guildeId) async {
    final userId = _supabase.auth.currentUser!.id;
    final pseudo = await recupererPseudo();

    await _db.ref('guildes/$guildeId/membres/$userId').set({
      'id': userId,
      'pseudo': pseudo,
      'role': 'Membre',
      'contribution': 50,
    });

    final ptsSnap = await _db.ref('guildes/$guildeId/pointsTotaux').get();
    final int pts = (ptsSnap.value is int ? ptsSnap.value as int : 0) + 50;
    await _db.ref('guildes/$guildeId/pointsTotaux').set(pts);
  }

  /// Quitte la Guilde actuelle
  Future<void> quitterGuilde(String guildeId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _db.ref('guildes/$guildeId/membres/$userId').remove();
  }

  /// Publie un message dans le salon de discussion de la Guilde
  Future<void> envoyerMessageGuilde(String guildeId, String texte) async {
    final clean = texte.trim();
    if (clean.isEmpty) return;
    final pseudo = await recupererPseudo();

    final ref = _db.ref('guildes/$guildeId/messages');
    final snap = await ref.get();
    List<Map<String, dynamic>> msgs = [];
    if (snap.exists && snap.value is List) {
      for (final item in (snap.value as List)) {
        if (item is Map) msgs.add(Map<String, dynamic>.from(item));
      }
    }
    msgs.add({'auteur': pseudo, 'texte': clean});
    if (msgs.length > 25) {
      msgs = msgs.sublist(msgs.length - 25);
    }
    await ref.set(msgs);
  }
}
