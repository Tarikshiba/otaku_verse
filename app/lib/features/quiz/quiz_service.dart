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
}
