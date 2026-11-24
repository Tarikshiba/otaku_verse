// Modeles de donnees pour le moteur de combat V9.2 (350 PV / 40 Q / Double Timer 2 min).

/// Les parametres choisis par le joueur avant de lancer un combat.
class CombatParams {
  /// Mode de jeu : 'solo' ou 'division'
  final String mode;

  /// Slug de l'oeuvre sur R2 (null = multi-oeuvres)
  final String? anime;
  final String? arc;

  /// Difficulte choisie : facile, moyen, difficile, expert, maitre, adaptatif
  final String difficulte;

  /// Contrat de Malus (§7.5) : 'zen', 'normal', 'malicieux'
  final String malusMode;

  /// Options avant-match (§1.4)
  final bool xpInsurance;
  final int confidencePotOc;

  /// Identifiant du match cree cote serveur par `match-engine`
  final String? matchId;

  /// Infos de l'adversaire (Bot calibre ou adversaire de Division AI_ONLY)
  final String opponentPseudo;
  final int? opponentLevel;
  final int? opponentDivisionId;

  CombatParams({
    this.mode = 'solo',
    this.anime,
    this.arc,
    required this.difficulte,
    this.malusMode = 'normal',
    this.xpInsurance = false,
    this.confidencePotOc = 0,
    this.matchId,
    this.opponentPseudo = 'A.K.I.N.A',
    this.opponentLevel,
    this.opponentDivisionId,
  });
}

/// L'etat complet d'un combat en cours (350 PV, 40 questions max, chrono global 120s).
class CombatState {
  int pvJoueur;
  int pvBot;
  int comboJoueur;
  int comboBot;
  int questionActuelle;
  final int nbQuestions;

  /// Constantes officielles V9.2 (§7.2 & §7.4)
  static const int pvDepart = 350;
  static const int questionsMax = 40;
  static const int chronoGlobalSec = 120;
  static const int degatsNormaux = 15;
  static const int degatsSpeciaux = 30;
  static const int autoFaute = 5;
  static const int seuilCombo = 3;

  CombatState({required this.nbQuestions})
      : pvJoueur = pvDepart,
        pvBot = pvDepart,
        comboJoueur = 0,
        comboBot = 0,
        questionActuelle = 1;

  bool get estTermine => pvJoueur <= 0 || pvBot <= 0 || questionActuelle > nbQuestions;

  String get vainqueur {
    if (pvBot <= 0 && pvJoueur > 0) return 'joueur';
    if (pvJoueur <= 0 && pvBot > 0) return 'bot';
    if (pvJoueur > pvBot) return 'joueur';
    if (pvBot > pvJoueur) return 'bot';
    return 'egalite';
  }
}

/// Resultat d'un tour retourne par le serveur (`match-engine`).
class ResultatTour {
  final bool joueurCorrect;
  final bool botCorrect;
  final int degatsInfliges;
  final int degatsSubis;
  final int autoFauteP1;
  final int autoFauteP2;
  final bool comboJoueurDeclenche;
  final bool comboBotDeclenche;
  final String bonneReponse;
  final String? explication;
  final bool hayaTriggered;
  final String? clashWinner; // 'p1', 'p2', 'tie', null
  final bool suddenDeathTriggered;
  final bool canSecondChance;
  final bool matchFinished;
  final bool afkWarning;
  final int consecutiveTimeouts;
  final int? remainingGlobalMs;
  final Map<String, dynamic>? summary;

  ResultatTour({
    required this.joueurCorrect,
    required this.botCorrect,
    required this.degatsInfliges,
    required this.degatsSubis,
    this.autoFauteP1 = 0,
    this.autoFauteP2 = 0,
    required this.comboJoueurDeclenche,
    required this.comboBotDeclenche,
    this.bonneReponse = '',
    this.explication,
    this.hayaTriggered = false,
    this.clashWinner,
    this.suddenDeathTriggered = false,
    this.canSecondChance = false,
    this.matchFinished = false,
    this.afkWarning = false,
    this.consecutiveTimeouts = 0,
    this.remainingGlobalMs,
    this.summary,
  });
}
