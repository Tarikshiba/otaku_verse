import 'dart:math';
import '../quiz/quiz_service.dart';
import 'combat_models.dart';

/// === SERVICE DE COMBAT ===
/// Gere toute la logique d'un combat : recuperation des questions,
/// validation des reponses via Edge Function (cote serveur),
/// fallback local si pas de reseau.

class CombatService {
  final QuizService _quizService = QuizService();
  final Random _random = Random();

  /// Recupere les questions pour un combat selon les parametres choisis.
  Future<List<Question>> preparerCombat(CombatParams params) async {
    return await _quizService.recupererQuestions(
      nombre: CombatState.questionsMax,
      anime: params.anime,
      arc: params.arc,
      difficulte: params.difficulte == 'adaptatif' ? null : params.difficulte,
    );
  }

  /// Valide la reponse via l'Edge Function (cote serveur).
  /// Le serveur verifie la bonne reponse, simule le bot, calcule les degats.
  /// En cas d'erreur reseau, on fallback sur la validation locale.
  Future<ResultatTour> jouerTourServeur({
    required CombatState etat,
    required String questionId,
    required String? reponseJoueur,
    required String difficulte,
  }) async {
    // Si le joueur n'a pas repondu (timeout), on envoie une reponse vide
    final reponse = reponseJoueur ?? '';

    try {
      final validation = await _quizService.validerReponse(
        questionId: questionId,
        reponse: reponse,
        comboJoueur: etat.comboJoueur,
        comboBot: etat.comboBot,
        difficulte: difficulte,
      );

      // Mettre a jour l'etat avec les valeurs du serveur
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
      );
    } catch (_) {
      // Fallback local si le serveur est injoignable
      return _jouerTourLocal(
        etat: etat,
        reponseJoueur: reponseJoueur,
        questionId: questionId,
        difficulte: difficulte,
      );
    }
  }

  /// Fallback : validation locale (utilisee si pas de reseau)
  ResultatTour _jouerTourLocal({
    required CombatState etat,
    required String? reponseJoueur,
    required String questionId,
    required String difficulte,
  }) {
    // En local, on ne peut pas valider sans la bonne reponse
    // Ce fallback ne sera utilise qu'en cas d'erreur reseau
    // Le joueur est considere comme ayant rate (securite)
    final joueurCorrect = false;
    final botCorrect = botRepond(difficulte: difficulte);

    return _calculerTour(etat: etat, joueurCorrect: joueurCorrect, botCorrect: botCorrect);
  }

  /// Simule la reponse du bot pour ce tour (utilise en fallback local).
  bool botRepond({required String difficulte}) {
    final double probaReussite;
    switch (difficulte) {
      case 'facile':
        probaReussite = 0.3;
      case 'moyen':
        probaReussite = 0.5;
      case 'difficile':
        probaReussite = 0.7;
      case 'expert':
        probaReussite = 0.85;
      default:
        probaReussite = 0.5;
    }
    return _random.nextDouble() < probaReussite;
  }

  /// Calcule les degats et met a jour l'etat (logique commune)
  ResultatTour _calculerTour({
    required CombatState etat,
    required bool joueurCorrect,
    required bool botCorrect,
  }) {
    bool comboJoueurDeclenche = false;
    int degatsInfliges = 0;

    if (joueurCorrect) {
      etat.comboJoueur++;
      if (etat.comboJoueur >= CombatState.seuilCombo) {
        comboJoueurDeclenche = true;
        degatsInfliges = CombatState.degatsSpeciaux;
        etat.comboJoueur = 0;
      } else {
        degatsInfliges = CombatState.degatsNormaux;
      }
    } else {
      etat.comboJoueur = 0;
    }

    bool comboBotDeclenche = false;
    int degatsSubis = 0;

    if (botCorrect) {
      etat.comboBot++;
      if (etat.comboBot >= CombatState.seuilCombo) {
        comboBotDeclenche = true;
        degatsSubis = CombatState.degatsSpeciaux;
        etat.comboBot = 0;
      } else {
        degatsSubis = CombatState.degatsNormaux;
      }
    } else {
      etat.comboBot = 0;
    }

    etat.pvBot = (etat.pvBot - degatsInfliges).clamp(0, CombatState.pvDepart);
    etat.pvJoueur = (etat.pvJoueur - degatsSubis).clamp(0, CombatState.pvDepart);

    return ResultatTour(
      joueurCorrect: joueurCorrect,
      botCorrect: botCorrect,
      degatsInfliges: degatsInfliges,
      degatsSubis: degatsSubis,
      comboJoueurDeclenche: comboJoueurDeclenche,
      comboBotDeclenche: comboBotDeclenche,
    );
  }

  /// Retourne la liste des animes disponibles dans la base de questions.
  Future<List<String>> recupererAnimesDisponibles() async {
    final supabase = _quizService.supabaseClient;
    final reponse = await supabase
        .from('questions')
        .select('anime')
        .eq('statut', 'actif');

    final animes = (reponse as List)
        .map((row) => (row['anime'] as String).toLowerCase())
        .toSet()
        .toList();
    animes.sort();
    return animes;
  }

  /// Retourne la liste des arcs pour un anime.
  Future<List<String>> recupererArcsDisponibles(String anime) async {
    final supabase = _quizService.supabaseClient;
    final reponse = await supabase
        .from('questions')
        .select('arc')
        .ilike('anime', anime)
        .eq('statut', 'actif');

    final arcs = (reponse as List)
        .map((row) => row['arc'] as String?)
        .where((arc) => arc != null && arc.isNotEmpty)
        .map((arc) => arc!)
        .toSet()
        .toList();
    arcs.sort();
    return arcs;
  }
}
