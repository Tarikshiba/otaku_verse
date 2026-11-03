import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'matchmaking_service.dart';

/// Service de la V3 : gère les Saisons (8 semaines), les Événements temporaires,
/// les Tournois (phase de groupes 10 duels + Top 8) et les Missions longue durée (Carrière).
class VerseV3Service {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://otaku-verse-6e05e-default-rtdb.europe-west1.firebasedatabase.app',
  );
  final SupabaseClient _supabase = Supabase.instance.client;
  final MatchmakingService _matchmaking = MatchmakingService();

  /// Récupère le pseudo du joueur connecté depuis Supabase
  Future<String> _recupererPseudo() async {
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
  // 10.1 SAISONS (8 semaines, classement dédié, paliers, soft reset -2 div max)
  // ===========================================================================

  /// Récupère les informations de la Saison active et le classement saisonnier
  Future<Map<String, dynamic>> recupererDonneesSaison() async {
    final userId = _supabase.auth.currentUser!.id;
    final pseudo = await _recupererPseudo();
    final statsDiv = await _matchmaking.recupererStatsDivision();

    List<Map<String, dynamic>> classement = [];
    List<int> paliersReclames = [];

    try {
      // Synchroniser le score saisonnier du joueur avec ses points actuels
      await _db.ref('saisons/saison_1/classement/$userId').update({
        'id': userId,
        'pseudo': pseudo,
        'points': statsDiv['points'] ?? 0,
        'division': statsDiv['division'] ?? 10,
      });

      final snap = await _db.ref('saisons/saison_1/classement').get();
      if (snap.exists && snap.value is Map) {
        final map = Map<String, dynamic>.from(snap.value as Map);
        for (final entry in map.entries) {
          if (entry.value is Map) {
            classement.add(Map<String, dynamic>.from(entry.value as Map));
          }
        }
        classement.sort((a, b) => ((b['points'] ?? 0) as int).compareTo((a['points'] ?? 0) as int));
      }

      final palierSnap = await _db.ref('saisons/saison_1/recompenses/$userId').get();
      if (palierSnap.exists && palierSnap.value is List) {
        paliersReclames = (palierSnap.value as List).whereType<int>().toList();
      }
    } catch (_) {}

    if (classement.isEmpty) {
      classement.add({
        'id': userId,
        'pseudo': pseudo,
        'points': statsDiv['points'] ?? 0,
        'division': statsDiv['division'] ?? 10,
      });
    }

    final int monRang = classement.indexWhere((e) => e['id'] == userId) + 1;

    return {
      'id': 'saison_1',
      'titre': "SAISON 1 : L'ÈRE DES PIRATES",
      'themeAnime': 'One Piece',
      'semaineActuelle': 3,
      'semainesTotales': 8,
      'joursRestants': 35,
      'mesPoints': statsDiv['points'] ?? 0,
      'maDivision': statsDiv['division'] ?? 10,
      'monRang': monRang > 0 ? monRang : 1,
      'classement': classement.take(20).toList(),
      'paliersReclames': paliersReclames,
    };
  }

  /// Réclame la récompense d'un palier de saison et crédite l'XP dans Supabase
  Future<void> reclamerPalierSaison(int palier, int xpBonus) async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      final snap = await _db.ref('saisons/saison_1/recompenses/$userId').get();
      List<int> actuels = [];
      if (snap.exists && snap.value is List) {
        actuels = (snap.value as List).whereType<int>().toList();
      }
      if (!actuels.contains(palier)) {
        actuels.add(palier);
        await _db.ref('saisons/saison_1/recompenses/$userId').set(actuels);
      }

      final profil = await _supabase.from('profiles').select('xp_totale').eq('id', userId).maybeSingle();
      if (profil != null) {
        final int xp = (profil['xp_totale'] ?? 0) + xpBonus;
        await _supabase.from('profiles').update({'xp_totale': xp}).eq('id', userId);
      }
    } catch (_) {}
  }

  /// Applique la règle du Soft Reset de fin de saison (protection : recul max de 2 divisions)
  static int calculerDivisionApresSoftReset(int divisionActuelle) {
    return (divisionActuelle + 2).clamp(1, 10);
  }

  // ===========================================================================
  // 10.2 ÉVÉNEMENTS TEMPORAIRES (3 à 7 jours, thème anime, classement dédié)
  // ===========================================================================

  /// Retourne la liste des événements temporaires de la saison et leur classement
  Future<List<Map<String, dynamic>>> recupererEvenements() async {
    final userId = _supabase.auth.currentUser!.id;
    List<Map<String, dynamic>> classementOp = [];
    int mesPointsEvent = 0;

    try {
      final snap = await _db.ref('evenements/event_op_east_blue/classement').get();
      if (snap.exists && snap.value is Map) {
        final map = Map<String, dynamic>.from(snap.value as Map);
        for (final e in map.entries) {
          if (e.value is Map) {
            final row = Map<String, dynamic>.from(e.value as Map);
            classementOp.add(row);
            if (row['id'] == userId) {
              mesPointsEvent = row['points'] ?? 0;
            }
          }
        }
        classementOp.sort((a, b) => ((b['points'] ?? 0) as int).compareTo((a['points'] ?? 0) as int));
      }
    } catch (_) {}

    return [
      {
        'id': 'event_op_east_blue',
        'titre': 'SEMAINE ONE PIECE : EAST BLUE',
        'anime': 'One Piece',
        'duree': '5 jours restants',
        'statut': 'EN COURS',
        'recompense': 'Titre Édition Limitée : Roi d\'East Blue + 250 XP',
        'mesPoints': mesPointsEvent,
        'classement': classementOp.take(10).toList(),
      },
      {
        'id': 'event_naruto_chunin',
        'titre': 'SEMAINE NARUTO : EXAMEN CHUNIN',
        'anime': 'naruto',
        'duree': '4 jours restants',
        'statut': 'EN COURS',
        'recompense': 'Badge Édition Limitée : Volonté du Feu + 250 XP',
        'mesPoints': 0,
        'classement': const [],
      },
      {
        'id': 'event_communautaire',
        'titre': 'DÉFI COMMUNAUTAIRE MULTI-VERSE',
        'anime': 'Tous',
        'duree': '3 jours restants',
        'statut': 'EN COURS',
        'recompense': 'Avatar Édition Limitée : Prodige du Verse + 300 XP',
        'mesPoints': 0,
        'classement': const [],
      },
    ];
  }

  /// Enregistre une participation à un événement temporaire et lance un match thématique
  Future<String> participerEvenement(String eventId, String anime) async {
    final userId = _supabase.auth.currentUser!.id;
    final pseudo = await _recupererPseudo();

    try {
      final ref = _db.ref('evenements/$eventId/classement/$userId');
      final snap = await ref.get();
      int pts = 30;
      int participations = 1;
      if (snap.exists && snap.value is Map) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        pts = (data['points'] ?? 0) + 30;
        participations = (data['participations'] ?? 0) + 1;
      }
      await ref.set({
        'id': userId,
        'pseudo': pseudo,
        'points': pts,
        'participations': participations,
      });

      // Comptabiliser le nombre total d'événements rejoints pour les missions de carrière
      final carriereRef = _db.ref('carriere/$userId/evenements_participes');
      final cSnap = await carriereRef.get();
      final int nb = (cSnap.value is int ? cSnap.value as int : 0) + 1;
      await carriereRef.set(nb);
    } catch (_) {}

    // Lance un match Verse contre A.K.I.N.A sur le thème de l'événement
    return _matchmaking.chercherMatchClasse();
  }

  // ===========================================================================
  // 10.3 TOURNOIS (Phase de groupes sur 10 duels + Finale Top 8 élimination)
  // ===========================================================================

  /// Récupère l'état du Tournoi Mensuel (phase de groupes 10 duels + arbre Top 8)
  Future<Map<String, dynamic>> recupererTournoi() async {
    final userId = _supabase.auth.currentUser!.id;
    bool inscrit = false;
    int duelsJoues = 0;
    int scoreCumule = 0;
    List<Map<String, dynamic>> classementGroupe = [];

    try {
      final snap = await _db.ref('tournois/tournoi_mensuel/participants').get();
      if (snap.exists && snap.value is Map) {
        final map = Map<String, dynamic>.from(snap.value as Map);
        for (final e in map.entries) {
          if (e.value is Map) {
            final row = Map<String, dynamic>.from(e.value as Map);
            classementGroupe.add(row);
            if (row['id'] == userId) {
              inscrit = true;
              duelsJoues = row['duelsJoues'] ?? 0;
              scoreCumule = row['scoreCumule'] ?? 0;
            }
          }
        }
        classementGroupe.sort((a, b) => ((b['scoreCumule'] ?? 0) as int).compareTo((a['scoreCumule'] ?? 0) as int));
      }
    } catch (_) {}

    // Génère le tableau Top 8 à partir des meilleurs joueurs inscrits (complété par des bots qualifiés)
    final List<String> qualif = classementGroupe.map((e) => (e['pseudo'] ?? 'Joueur').toString()).toList();
    const bots = ['Shanks_SN', 'Itachi_221', 'Luffy_Gear5', 'Zoro_K', 'Gojo_S', 'Pain_Akatsuki', 'Ace_Fire', 'Minato_4'];
    for (final b in bots) {
      if (qualif.length < 8 && !qualif.contains(b)) qualif.add(b);
    }

    return {
      'titre': 'TOURNOI MENSUEL DU VERSE',
      'duree': 'Durée : 7 jours (Phase de groupes + Finale Top 8)',
      'recompense': 'Titre Champion du Verse + 500 Verse Coins + Badge Champion',
      'inscrit': inscrit,
      'duelsJoues': duelsJoues,
      'duelsMax': 10,
      'scoreCumule': scoreCumule,
      'classementGroupe': classementGroupe,
      'top8': qualif.take(8).toList(),
    };
  }

  /// Inscrit le joueur au Tournoi Mensuel
  Future<void> inscrireAuTournoi() async {
    final userId = _supabase.auth.currentUser!.id;
    final pseudo = await _recupererPseudo();
    await _db.ref('tournois/tournoi_mensuel/participants/$userId').set({
      'id': userId,
      'pseudo': pseudo,
      'duelsJoues': 0,
      'scoreCumule': 0,
      'updatedAt': ServerValue.timestamp,
    });
  }

  /// Lance un duel comptant pour les 10 matchs de poule du Tournoi
  Future<String> jouerDuelTournoi() async {
    final userId = _supabase.auth.currentUser!.id;
    final pseudo = await _recupererPseudo();
    try {
      final ref = _db.ref('tournois/tournoi_mensuel/participants/$userId');
      final snap = await ref.get();
      int duels = 0;
      int score = 0;
      if (snap.exists && snap.value is Map) {
        final d = Map<String, dynamic>.from(snap.value as Map);
        duels = d['duelsJoues'] ?? 0;
        score = d['scoreCumule'] ?? 0;
      }
      if (duels < 10) {
        await ref.set({
          'id': userId,
          'pseudo': pseudo,
          'duelsJoues': duels + 1,
          'scoreCumule': score + 100,
          'updatedAt': ServerValue.timestamp,
        });
      }
    } catch (_) {}
    return _matchmaking.chercherMatchClasse();
  }

  // ===========================================================================
  // 10.4 MISSIONS LONGUE DURÉE (Objectifs de carrière Roadmap 10.4)
  // ===========================================================================

  /// Récupère l'avancement réel des 5 missions longue durée de la Roadmap
  Future<List<Map<String, dynamic>>> recupererMissionsCarriere() async {
    final userId = _supabase.auth.currentUser!.id;
    final statsDiv = await _matchmaking.recupererStatsDivision();

    int combatsJoues = 0;
    int combatsGagnes = 0;
    try {
      final profil = await _supabase
          .from('profiles')
          .select('combats_joues, combats_gagnes')
          .eq('id', userId)
          .maybeSingle();
      if (profil != null) {
        combatsJoues = profil['combats_joues'] ?? 0;
        combatsGagnes = profil['combats_gagnes'] ?? 0;
      }
    } catch (_) {}

    int duelsVerse = (statsDiv['victoires'] as int? ?? 0) + (statsDiv['defaites'] as int? ?? 0);
    if (combatsJoues > duelsVerse) duelsVerse = combatsJoues;
    final int divisionActuelle = statsDiv['division'] as int? ?? 10;
    final int questionsReussies = combatsGagnes * 8 + combatsJoues * 3;

    int eventsParticipes = 0;
    List<String> missionsReclamees = [];
    try {
      final evSnap = await _db.ref('carriere/$userId/evenements_participes').get();
      if (evSnap.exists && evSnap.value is int) {
        eventsParticipes = evSnap.value as int;
      }
      final recSnap = await _db.ref('carriere/$userId/reclamees').get();
      if (recSnap.exists && recSnap.value is List) {
        missionsReclamees = (recSnap.value as List).map((e) => e.toString()).toList();
      }
    } catch (_) {}

    final int progressionDiv5 = divisionActuelle <= 5 ? 5 : (10 - divisionActuelle).clamp(0, 5);

    return [
      {
        'id': 'carriere_100_duels',
        'mission': 'Jouer 100 duels Verse',
        'recompense': 'Titre "Guerrier du Verse" + 500 XP',
        'xp': 500,
        'actuel': duelsVerse.clamp(0, 100),
        'cible': 100,
        'reclamee': missionsReclamees.contains('carriere_100_duels'),
      },
      {
        'id': 'carriere_div_5',
        'mission': 'Atteindre Division 5',
        'recompense': 'Badge "Montée en Puissance" + 400 XP',
        'xp': 400,
        'actuel': progressionDiv5,
        'cible': 5,
        'reclamee': missionsReclamees.contains('carriere_div_5'),
      },
      {
        'id': 'carriere_3_events',
        'mission': 'Participer à 3 événements',
        'recompense': 'Avatar exclusif + 300 XP',
        'xp': 300,
        'actuel': eventsParticipes.clamp(0, 3),
        'cible': 3,
        'reclamee': missionsReclamees.contains('carriere_3_events'),
      },
      {
        'id': 'carriere_top_100',
        'mission': 'Finir une saison Top 100',
        'recompense': 'Titre de saison "Élite S1" + 500 XP',
        'xp': 500,
        'actuel': (statsDiv['points'] as int? ?? 0) > 0 ? 1 : 0,
        'cible': 1,
        'reclamee': missionsReclamees.contains('carriere_top_100'),
      },
      {
        'id': 'carriere_5000_questions',
        'mission': 'Réussir 5 000 questions',
        'recompense': 'Badge "Encyclopédie Vivante" + 1 000 XP',
        'xp': 1000,
        'actuel': questionsReussies.clamp(0, 5000),
        'cible': 5000,
        'reclamee': missionsReclamees.contains('carriere_5000_questions'),
      },
    ];
  }

  /// Réclame la récompense d'une mission de carrière accomplie
  Future<void> reclamerMissionCarriere(String missionId, int xpBonus) async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      final ref = _db.ref('carriere/$userId/reclamees');
      final snap = await ref.get();
      List<String> list = [];
      if (snap.exists && snap.value is List) {
        list = (snap.value as List).map((e) => e.toString()).toList();
      }
      if (!list.contains(missionId)) {
        list.add(missionId);
        await ref.set(list);
      }

      final profil = await _supabase.from('profiles').select('xp_totale').eq('id', userId).maybeSingle();
      if (profil != null) {
        final int xp = (profil['xp_totale'] ?? 0) + xpBonus;
        await _supabase.from('profiles').update({'xp_totale': xp}).eq('id', userId);
      }
    } catch (_) {}
  }
}
