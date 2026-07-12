import 'dart:math';
import '../quiz/quiz_service.dart';
import 'combat_models.dart';

/// === SERVICE DE COMBAT ===
/// Gere toute la logique d'un combat : recuperation des questions,
/// simulation du bot, calcul des degats, gestion des combos.

class CombatService {
  final QuizService _quizService = QuizService();
  final Random _random = Random();

  /// Recupere les questions pour un combat selon les parametres choisis.
  Future<List<Question>> preparerCombat(CombatParams params) async {
    return await _quizService.recupererQuestions(
      nombre: CombatState.questionsMax,
      anime: params.anime,
      difficulte: params.difficulte == 'adaptatif' ? null : params.difficulte,
    );
  }

  /// Simule la reponse du bot pour ce tour.
  /// Retourne true si le bot a "bien repondu", selon sa difficulte.
  bool botRepond({required String difficulte}) {
    // Probabilite que le bot reponde correctement selon la difficulte choisie
    final double probaReussite;
    switch (difficulte) {
      case 'facile':
        probaReussite = 0.3; // Le bot se trompe souvent
      case 'moyen':
        probaReussite = 0.5; // 50/50
      case 'difficile':
        probaReussite = 0.7; // Le bot est bon
      case 'expert':
        probaReussite = 0.85; // Le bot est tres fort
      default: // adaptatif — par defaut moyen
        probaReussite = 0.5;
    }
    return _random.nextDouble() < probaReussite;
  }

  /// Joue un tour complet : le joueur a repondu (correct ou non),
  /// on simule le bot, et on met a jour l'etat du combat.
  /// Retourne le resultat detaille du tour.
  ResultatTour jouerTour({
    required CombatState etat,
    required bool joueurCorrect,
    required String difficulte,
  }) {
    final botCorrect = botRepond(difficulte: difficulte);

    // --- Calcul combo joueur ---
    bool comboJoueurDeclenche = false;
    int degatsInfliges = 0;

    if (joueurCorrect) {
      etat.comboJoueur++;
      if (etat.comboJoueur >= CombatState.seuilCombo) {
        // Combo ! Attaque speciale
        comboJoueurDeclenche = true;
        degatsInfliges = CombatState.degatsSpeciaux;
        etat.comboJoueur = 0; // Reset apres le combo
      } else {
        degatsInfliges = CombatState.degatsNormaux;
      }
    } else {
      etat.comboJoueur = 0; // Reset du combo si mauvaise reponse
    }

    // --- Calcul combo bot ---
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

    // --- Appliquer les degats ---
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

    // Extraire les animes uniques
    final animes = (reponse as List)
        .map((row) => row['anime'] as String)
        .toSet()
        .toList();
    animes.sort();
    return animes;
  }
}
