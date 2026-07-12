import 'package:supabase_flutter/supabase_flutter.dart';
import '../progression/progression_service.dart';

/// === SERVICE DE RECOMPENSES ===
/// Gere les defis quotidiens, la connexion quotidienne et les badges.

class RewardsService {
  final _supabase = Supabase.instance.client;

  // --- RECOMPENSE DE CONNEXION ---
  static const int xpConnexionQuotidienne = 15;

  /// Verifie si la connexion quotidienne a deja ete reclamee aujourd'hui.
  Future<bool> connexionDejaPrise() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final aujourdHui = DateTime.now().toIso8601String().substring(0, 10);
    final existant = await _supabase
        .from('daily_login')
        .select()
        .eq('user_id', userId)
        .eq('date', aujourdHui)
        .maybeSingle();

    return existant != null;
  }

  /// Verifie si le joueur a deja recu sa recompense de connexion aujourd'hui.
  /// Si non, lui donne +15 XP et enregistre la date.
  /// Retourne true si la recompense vient d'etre donnee, false si deja recue.
  Future<bool> reclamerConnexionQuotidienne() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final aujourdHui = DateTime.now().toIso8601String().substring(0, 10);

    // Verifier si deja reclamee aujourd'hui
    final existant = await _supabase
        .from('daily_login')
        .select()
        .eq('user_id', userId)
        .eq('date', aujourdHui)
        .maybeSingle();

    if (existant != null) return false; // Deja recue

    // Enregistrer la connexion
    await _supabase.from('daily_login').insert({
      'user_id': userId,
      'date': aujourdHui,
    });

    // Donner l'XP
    final progressionService = ProgressionService();
    await progressionService.mettreAJourApresComabat(
      xpGagne: xpConnexionQuotidienne,
      victoire: false, // Pas un combat
    );

    return true;
  }

  /// Nombre de jours consecutifs de connexion
  Future<int> serieConnexion() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final reponse = await _supabase
        .from('daily_login')
        .select('date')
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(30);

    if ((reponse as List).isEmpty) return 0;

    int serie = 0;
    var dateCourante = DateTime.now();

    for (final row in reponse) {
      final dateLogin = DateTime.parse(row['date']);
      final diff = dateCourante.difference(dateLogin).inDays;

      if (diff <= 1) {
        serie++;
        dateCourante = dateLogin;
      } else {
        break;
      }
    }

    return serie;
  }

  // --- DEFIS QUOTIDIENS ---

  /// Liste des defis possibles (on en tire 3 par jour)
  static final List<Map<String, dynamic>> _defisDisponibles = [
    {'id': 'gagner_1', 'description': 'Gagner 1 combat', 'objectif': 1, 'type': 'victoires'},
    {'id': 'gagner_3', 'description': 'Gagner 3 combats', 'objectif': 3, 'type': 'victoires'},
    {'id': 'reponses_10', 'description': 'Obtenir 10 bonnes reponses', 'objectif': 10, 'type': 'bonnes_reponses'},
    {'id': 'reponses_15', 'description': 'Obtenir 15 bonnes reponses', 'objectif': 15, 'type': 'bonnes_reponses'},
    {'id': 'combats_3', 'description': 'Jouer 3 combats', 'objectif': 3, 'type': 'combats'},
    {'id': 'ko_1', 'description': 'Gagner un combat par K.O.', 'objectif': 1, 'type': 'ko'},
  ];

  /// XP donnee par defi complete
  static const int xpDefiComplete = 30;

  /// Recupere les defis du jour pour ce joueur.
  /// Les cree si ils n'existent pas encore pour aujourd'hui.
  Future<List<Map<String, dynamic>>> recupererDefisQuotidiens() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final aujourdHui = DateTime.now().toIso8601String().substring(0, 10);

    // Chercher les defis d'aujourd'hui
    final existants = await _supabase
        .from('daily_challenges')
        .select()
        .eq('user_id', userId)
        .eq('date', aujourdHui);

    if ((existants as List).isNotEmpty) return List<Map<String, dynamic>>.from(existants);

    // Generer 3 defis aleatoires pour aujourd'hui
    final defisChoisis = List<Map<String, dynamic>>.from(_defisDisponibles)..shuffle();
    final troisDefis = defisChoisis.take(3).toList();

    final inserts = troisDefis.map((defi) => {
      'user_id': userId,
      'date': aujourdHui,
      'defi_id': defi['id'],
      'description': defi['description'],
      'objectif': defi['objectif'],
      'type': defi['type'],
      'progres': 0,
      'complete': false,
    }).toList();

    await _supabase.from('daily_challenges').insert(inserts);

    return inserts;
  }

  /// Met a jour la progression d'un defi apres un combat.
  /// [victoire], [ko], [bonnesReponses] : resultats du combat
  Future<void> mettreAJourDefis({
    required bool victoire,
    required bool ko,
    required int bonnesReponses,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final aujourdHui = DateTime.now().toIso8601String().substring(0, 10);

    final defis = await _supabase
        .from('daily_challenges')
        .select()
        .eq('user_id', userId)
        .eq('date', aujourdHui)
        .eq('complete', false);

    for (final defi in (defis as List)) {
      int nouveauProgres = defi['progres'] as int;

      switch (defi['type']) {
        case 'victoires':
          if (victoire) nouveauProgres++;
        case 'bonnes_reponses':
          nouveauProgres += bonnesReponses;
        case 'combats':
          nouveauProgres++;
        case 'ko':
          if (ko) nouveauProgres++;
      }

      final objectif = defi['objectif'] as int;
      final complete = nouveauProgres >= objectif;

      await _supabase.from('daily_challenges').update({
        'progres': nouveauProgres,
        'complete': complete,
      }).eq('id', defi['id']);

      // Si le defi vient d'etre complete, donner l'XP bonus
      if (complete && !(defi['complete'] as bool)) {
        final progressionService = ProgressionService();
        await progressionService.mettreAJourApresComabat(
          xpGagne: xpDefiComplete,
          victoire: false,
        );
      }
    }
  }

  // --- BADGES ---

  /// Liste des badges de base (V1)
  static final List<Map<String, String>> badgesDisponibles = [
    {'id': 'premier_pas', 'nom': 'Premier Pas', 'description': 'Terminer son premier combat'},
    {'id': 'sans_egratignure', 'nom': 'Sans Egratignure', 'description': 'Gagner un combat sans prendre de degats'},
    {'id': 'fidele_7', 'nom': 'Fidele', 'description': 'Se connecter 7 jours de suite'},
    {'id': 'chasseur_100', 'nom': 'Chasseur de Connaissances', 'description': '100 bonnes reponses au total'},
    {'id': 'niveau_10', 'nom': 'Montee en Grade', 'description': 'Atteindre le niveau 10'},
    {'id': 'ko_eclair', 'nom': 'K.O. Eclair', 'description': 'Gagner par K.O. avant la 5e question'},
  ];

  /// Recupere les badges debloques par le joueur
  Future<List<String>> recupererBadges() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final reponse = await _supabase
        .from('badges')
        .select('badge_id')
        .eq('user_id', userId);

    return (reponse as List).map((row) => row['badge_id'] as String).toList();
  }

  /// Verifie et attribue les badges apres un combat.
  /// Retourne la liste des nouveaux badges debloques.
  Future<List<String>> verifierBadges({
    required bool victoire,
    required bool ko,
    required bool sansDegat,
    required int questionKO, // A quelle question le K.O. a eu lieu (0 si pas de K.O.)
    required int bonnesReponsesTotales, // Total historique
    required int niveau,
    required int serieJours,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final badgesActuels = await recupererBadges();
    final nouveauxBadges = <String>[];

    // Premier Pas : premier combat termine
    if (!badgesActuels.contains('premier_pas')) {
      nouveauxBadges.add('premier_pas');
    }

    // Sans Egratignure : gagner sans degats
    if (victoire && sansDegat && !badgesActuels.contains('sans_egratignure')) {
      nouveauxBadges.add('sans_egratignure');
    }

    // Fidele : 7 jours consecutifs
    if (serieJours >= 7 && !badgesActuels.contains('fidele_7')) {
      nouveauxBadges.add('fidele_7');
    }

    // Chasseur de Connaissances : 100 bonnes reponses
    if (bonnesReponsesTotales >= 100 && !badgesActuels.contains('chasseur_100')) {
      nouveauxBadges.add('chasseur_100');
    }

    // Montee en Grade : niveau 10
    if (niveau >= 10 && !badgesActuels.contains('niveau_10')) {
      nouveauxBadges.add('niveau_10');
    }

    // K.O. Eclair : K.O. avant la 5e question
    if (ko && questionKO < 5 && !badgesActuels.contains('ko_eclair')) {
      nouveauxBadges.add('ko_eclair');
    }

    // Inserer les nouveaux badges
    if (nouveauxBadges.isNotEmpty) {
      final inserts = nouveauxBadges.map((badgeId) => {
        'user_id': userId,
        'badge_id': badgeId,
      }).toList();
      await _supabase.from('badges').insert(inserts);
    }

    return nouveauxBadges;
  }
}
