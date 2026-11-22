import '../economy/economy_v92_service.dart';
import '../quiz/quiz_service.dart';
import 'combat_models.dart';

/// === SERVICE DE COMBAT V9.2 ===
/// Recupere les 40 questions depuis Cloudflare R2 (1,25 M questions)
/// et valide chaque reponse cote serveur via l'Edge Function `match-engine`.
class CombatService {
  final QuizService _quizService = QuizService();
  final EconomyV92Service _economyService = EconomyV92Service();

  /// Prepare un lot de 40 questions (mix progressif en Division ou niveau choisi en Solo).
  Future<List<Question>> preparerCombat(CombatParams params) async {
    return await _quizService.tirerLotR2(
      mode: params.mode,
      workSlug: params.anime,
      arcName: params.arc,
      difficulty: params.difficulte,
      count: CombatState.questionsMax,
    );
  }

  /// Valide la reponse via `match-engine` (V9.2 : 350 PV, Auto-Faute -5 PV, Haya!!, Combo x3, 0 PV simultane).
  Future<ResultatTour> jouerTourV92({
    required CombatState etat,
    required String? matchId,
    required Question question,
    required String? reponseJoueur,
    required int responseTimeMs,
    required String difficulte,
  }) async {
    final bool isTimeout = reponseJoueur == null || reponseJoueur.isEmpty;
    final String answer = reponseJoueur ?? '';

    // Si on a un matchId cree par `match-engine`, on passe par le moteur officiel V9.2
    if (matchId != null && matchId.isNotEmpty) {
      final data = await _economyService.soumettreReponse(
        matchId: matchId,
        questionId: question.id,
        answer: answer,
        responseTimeMs: responseTimeMs,
        isTimeout: isTimeout,
        workSlug: question.workSlug,
        difficultyLevel: question.difficultyLevel,
      );

      etat.pvJoueur = (data['player1_hp'] as num?)?.toInt() ?? etat.pvJoueur;
      etat.pvBot = (data['player2_hp'] as num?)?.toInt() ?? etat.pvBot;
      etat.comboJoueur = (data['player1_combo'] as num?)?.toInt() ?? 0;
      etat.comboBot = (data['player2_combo'] as num?)?.toInt() ?? 0;

      return ResultatTour(
        joueurCorrect: data['joueur_correct'] == true,
        botCorrect: data['bot_correct'] == true,
        degatsInfliges: (data['degats_infliges'] as num?)?.toInt() ?? 0,
        degatsSubis: (data['degats_subis'] as num?)?.toInt() ?? 0,
        comboJoueurDeclenche: data['combo_joueur_declenche'] == true,
        comboBotDeclenche: data['combo_bot_declenche'] == true,
        bonneReponse: data['bonne_reponse']?.toString() ?? '',
        explication: data['explication']?.toString(),
        hayaTriggered: data['haya_triggered'] == true,
        clashWinner: data['clash_winner']?.toString(),
        suddenDeathTriggered: data['sudden_death_triggered'] == true,
        canSecondChance: data['can_second_chance'] == true,
        matchFinished: data['match_finished'] == true,
        remainingGlobalMs: (data['remaining_global_ms'] as num?)?.toInt(),
        summary: data['summary'] is Map ? Map<String, dynamic>.from(data['summary']) : null,
      );
    }

    // Repli securise sur l'ancienne Edge Function si aucun matchId serveur
    final validation = await _quizService.validerReponse(
      questionId: question.id,
      reponse: answer,
      comboJoueur: etat.comboJoueur,
      comboBot: etat.comboBot,
      difficulte: difficulte,
    );

    etat.comboJoueur = validation.nouveauComboJoueur;
    etat.comboBot = validation.nouveauComboBot;
    etat.pvBot = (etat.pvBot - validation.degatsInfliges).clamp(0, CombatState.pvDepart);
    etat.pvJoueur = (etat.pvJoueur - validation.degatsSubis).clamp(0, CombatState.pvDepart);

    return ResultatTour(
      joueurCorrect: validation.joueurCorrect,
      botCorrect: validation.botCorrect,
      degatsInfliges: validation.degatsInfliges,
      degatsSubis: validation.degatsSubis,
      comboJoueurDeclenche: validation.comboJoueurDeclenche,
      comboBotDeclenche: validation.comboBotDeclenche,
      bonneReponse: validation.bonneReponse,
    );
  }

  /// Retourne la liste complete des oeuvres (21 oeuvres depuis R2, ou repli Supabase).
  /// Chaque entree contient : slug, title, total_questions, arcs.
  Future<List<Map<String, dynamic>>> recupererCatalogueOeuvres() async {
    final works = await _quizService.recupererCatalogueR2();
    if (works.isNotEmpty) return works;

    // Repli sur Supabase si R2 indisponible
    final supabase = _quizService.supabaseClient;
    final reponse = await supabase.from('questions').select('anime').eq('statut', 'actif');
    final animes = (reponse as List)
        .map((row) => (row['anime'] as String).toLowerCase())
        .toSet()
        .toList()
      ..sort();
    return animes
        .map((a) => {
              'slug': a.replaceAll(' ', '_'),
              'title': a.toUpperCase(),
              'arcs': <String>[],
            })
        .toList();
  }

  /// Retourne uniquement les noms/slugs d'animes (retrocompatibilite avec les autres ecrans).
  Future<List<String>> recupererAnimesDisponibles() async {
    final works = await recupererCatalogueOeuvres();
    return works.map((w) => (w['title'] ?? w['slug']).toString()).toList();
  }

  /// Retourne les arcs d'une oeuvre (depuis le catalogue R2 ou Supabase).
  Future<List<String>> recupererArcsDisponibles(String animeOrSlug) async {
    final works = await _quizService.recupererCatalogueR2();
    final needle = animeOrSlug.toLowerCase();
    for (final w in works) {
      if (w['slug'].toString().toLowerCase() == needle ||
          w['title'].toString().toLowerCase() == needle) {
        final arcs = (w['arcs'] as List?)?.map((e) => e.toString()).toList() ?? [];
        if (arcs.isNotEmpty) return arcs;
      }
    }

    final supabase = _quizService.supabaseClient;
    final reponse = await supabase
        .from('questions')
        .select('arc')
        .ilike('anime', animeOrSlug.replaceAll('_', ' '))
        .eq('statut', 'actif');

    final arcs = (reponse as List)
        .map((row) => row['arc'] as String?)
        .where((arc) => arc != null && arc.isNotEmpty)
        .map((arc) => arc!)
        .toSet()
        .toList()
      ..sort();
    return arcs;
  }
}
