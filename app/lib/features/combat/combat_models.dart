// Modeles de donnees pour le mode combat.
// Contient les classes qui representent l'etat d'un combat en cours.

/// Les parametres choisis par le joueur avant de lancer un combat.
class CombatParams {
  /// Anime sur lequel porteront les questions (null = toutes categories)
  final String? anime;

  /// Difficulte choisie : facile, moyen, difficile, expert, adaptatif
  final String difficulte;

  CombatParams({
    this.anime,
    required this.difficulte,
  });
}

/// L'etat complet d'un combat en cours (PV, combos, historique).
class CombatState {
  /// Points de vie du joueur (demarre a 100)
  int pvJoueur;

  /// Points de vie du bot (demarre a 100)
  int pvBot;

  /// Compteur de combo du joueur (bonnes reponses d'affilee)
  int comboJoueur;

  /// Compteur de combo du bot
  int comboBot;

  /// Numero de la question en cours (1 a 10)
  int questionActuelle;

  /// Nombre reel de questions dans ce combat (peut etre < 10 si la base en a moins)
  final int nbQuestions;

  /// PV de depart pour les deux combattants
  static const int pvDepart = 100;

  /// Nombre max de questions par combat (ideal, si la base en a assez)
  static const int questionsMax = 10;

  /// Degats d'une attaque normale (bonne reponse)
  static const int degatsNormaux = 15;

  /// Degats d'une attaque speciale (combo atteint = 3 bonnes d'affilee)
  static const int degatsSpeciaux = 30;

  /// Nombre de bonnes reponses d'affilee pour declencher un combo
  static const int seuilCombo = 3;

  CombatState({required this.nbQuestions})
      : pvJoueur = pvDepart,
        pvBot = pvDepart,
        comboJoueur = 0,
        comboBot = 0,
        questionActuelle = 1;

  /// Le combat est-il termine ? (K.O. ou toutes les questions epuisees)
  bool get estTermine => pvJoueur <= 0 || pvBot <= 0 || questionActuelle > nbQuestions;

  /// Qui a gagne ? Compare les PV.
  /// 'joueur', 'bot', ou 'egalite'
  String get vainqueur {
    if (pvBot <= 0) return 'joueur';
    if (pvJoueur <= 0) return 'bot';
    if (pvJoueur > pvBot) return 'joueur';
    if (pvBot > pvJoueur) return 'bot';
    return 'egalite';
  }
}

/// Resultat d'un tour (apres que joueur et bot ont "repondu")
class ResultatTour {
  /// Le joueur a-t-il bien repondu ?
  final bool joueurCorrect;

  /// Le bot a-t-il bien repondu ?
  final bool botCorrect;

  /// Degats infliges au bot ce tour (0 si joueur a mal repondu)
  final int degatsInfliges;

  /// Degats subis par le joueur ce tour (0 si bot a mal repondu)
  final int degatsSubis;

  /// Le joueur a-t-il declenche un combo (attaque speciale) ?
  final bool comboJoueurDeclenche;

  /// Le bot a-t-il declenche un combo ?
  final bool comboBotDeclenche;

  ResultatTour({
    required this.joueurCorrect,
    required this.botCorrect,
    required this.degatsInfliges,
    required this.degatsSubis,
    required this.comboJoueurDeclenche,
    required this.comboBotDeclenche,
  });
}
