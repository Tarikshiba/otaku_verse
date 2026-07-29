import 'package:supabase_flutter/supabase_flutter.dart';

/// Represente une question de quiz
class Question {
  final String id;
  final String anime;
  final String? arc;
  final String type;
  final String difficulte;
  final String question;
  final String choixA;
  final String choixB;
  final String choixC;
  final String choixD;
  // bonneReponse garde en local uniquement pour le mode hors-ligne (fallback)
  final String bonneReponse;
  final String? explication;

  Question({
    required this.id,
    required this.anime,
    this.arc,
    required this.type,
    required this.difficulte,
    required this.question,
    required this.choixA,
    required this.choixB,
    required this.choixC,
    required this.choixD,
    required this.bonneReponse,
    this.explication,
  });

  /// Cree une Question depuis les donnees Supabase (Map)
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      anime: map['anime'],
      arc: map['arc'],
      type: map['type'],
      difficulte: map['difficulte'],
      question: map['question'],
      choixA: map['choix_a'],
      choixB: map['choix_b'],
      choixC: map['choix_c'],
      choixD: map['choix_d'],
      bonneReponse: map['bonne_reponse'],
      explication: map['explication'],
    );
  }

  /// Retourne la liste des 4 choix sous forme [lettre, texte]
  List<MapEntry<String, String>> get choix => [
        MapEntry('A', choixA),
        MapEntry('B', choixB),
        MapEntry('C', choixC),
        MapEntry('D', choixD),
      ];
}

/// Resultat retourne par l'Edge Function apres validation
class ResultatValidation {
  final bool joueurCorrect;
  final bool botCorrect;
  final int degatsInfliges;
  final int degatsSubis;
  final bool comboJoueurDeclenche;
  final bool comboBotDeclenche;
  final int nouveauComboJoueur;
  final int nouveauComboBot;

  ResultatValidation({
    required this.joueurCorrect,
    required this.botCorrect,
    required this.degatsInfliges,
    required this.degatsSubis,
    required this.comboJoueurDeclenche,
    required this.comboBotDeclenche,
    required this.nouveauComboJoueur,
    required this.nouveauComboBot,
  });

  factory ResultatValidation.fromJson(Map<String, dynamic> json) {
    return ResultatValidation(
      joueurCorrect: json['joueur_correct'] ?? false,
      botCorrect: json['bot_correct'] ?? false,
      degatsInfliges: json['degats_infliges'] ?? 0,
      degatsSubis: json['degats_subis'] ?? 0,
      comboJoueurDeclenche: json['combo_joueur_declenche'] ?? false,
      comboBotDeclenche: json['combo_bot_declenche'] ?? false,
      nouveauComboJoueur: json['nouveau_combo_joueur'] ?? 0,
      nouveauComboBot: json['nouveau_combo_bot'] ?? 0,
    );
  }
}

/// Service qui gere la recuperation des questions depuis Supabase.
class QuizService {
  final _supabase = Supabase.instance.client;

  /// Acces au client Supabase (utilise par CombatService pour les requetes)
  SupabaseClient get supabaseClient => _supabase;

  /// Recupere un lot de questions aleatoires.
  /// [nombre] : combien de questions on veut
  /// [anime] : filtrer par anime (optionnel)
  /// [difficulte] : filtrer par difficulte (optionnel)
  Future<List<Question>> recupererQuestions({
    int nombre = 10,
    String? anime,
    String? difficulte,
  }) async {
    // Construit la requete
    var requete = _supabase
        .from('questions')
        .select()
        .eq('statut', 'actif');

    if (anime != null) {
      requete = requete.eq('anime', anime);
    }
    if (difficulte != null) {
      requete = requete.eq('difficulte', difficulte);
    }

    // Recupere les questions, limitees au nombre voulu, en ordre aleatoire
    final reponse = await requete.limit(nombre);

    // Convertit en objets Question
    final questions = (reponse as List)
        .map((q) => Question.fromMap(q))
        .toList();

    // Melange pour avoir un ordre aleatoire
    questions.shuffle();

    return questions;
  }

  /// Appelle l'Edge Function pour valider une reponse cote serveur.
  /// C'est le serveur qui verifie si la reponse est correcte et calcule les degats.
  Future<ResultatValidation> validerReponse({
    required String questionId,
    required String reponse,
    required int comboJoueur,
    required int comboBot,
    required String difficulte,
  }) async {
    final response = await _supabase.functions.invoke(
      'valider-reponse',
      body: {
        'question_id': questionId,
        'reponse': reponse,
        'combo_joueur': comboJoueur,
        'combo_bot': comboBot,
        'difficulte': difficulte,
      },
    );

    if (response.status != 200) {
      throw Exception('Erreur serveur: ${response.status}');
    }

    final data = response.data as Map<String, dynamic>;
    return ResultatValidation.fromJson(data);
  }
}
