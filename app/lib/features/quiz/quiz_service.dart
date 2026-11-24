import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../economy/economy_v92_service.dart';

/// Option de reponse melangee cote client (Double securite V4.0 Partie 5.1) :
/// - displayLetter : lettre affichee sur le bouton (A, B, C, D dans l'ordre visuel)
/// - originalKey   : lettre d'origine attendue par le serveur lors de la validation
class ShuffledChoice {
  final String displayLetter;
  final String originalKey;
  final String text;

  const ShuffledChoice({
    required this.displayLetter,
    required this.originalKey,
    required this.text,
  });
}

/// Represente une question de quiz (compatible Supabase V1 et Cloudflare R2 V9.2)
class Question {
  final String id;
  final String anime;
  final String? workSlug;
  final String? arc;
  final String domain;
  final String type;
  final String difficulte;
  final int difficultyLevel;
  final String variantCode;
  final String question;
  final String choixA;
  final String choixB;
  final String choixC;
  final String choixD;
  // Securite : toujours vide avant la reponse du joueur (revele par le serveur apres clic)
  final String bonneReponse;
  final String? explication;
  final String? imageUrl;
  final List<String>? wordBank;
  final String? unit;
  final double? minSlider;
  final double? maxSlider;

  Question({
    required this.id,
    required this.anime,
    this.workSlug,
    this.arc,
    this.domain = 'GLOBAL',
    required this.type,
    required this.difficulte,
    this.difficultyLevel = 2,
    this.variantCode = '1.1',
    required this.question,
    required this.choixA,
    required this.choixB,
    required this.choixC,
    required this.choixD,
    this.bonneReponse = '',
    this.explication,
    this.imageUrl,
    this.wordBank,
    this.unit,
    this.minSlider,
    this.maxSlider,
  });

  static String _labelFromLevel(int lvl) {
    switch (lvl) {
      case 1:
        return 'facile';
      case 2:
        return 'moyen';
      case 3:
        return 'difficile';
      case 4:
        return 'expert';
      case 5:
        return 'maitre';
      default:
        return 'moyen';
    }
  }

  static int _levelFromLabel(String? lbl) {
    switch ((lbl ?? '').toLowerCase()) {
      case 'facile':
        return 1;
      case 'moyen':
        return 2;
      case 'difficile':
        return 3;
      case 'expert':
        return 4;
      case 'maitre':
      case 'maître':
        return 5;
      default:
        return 2;
    }
  }

  /// Cree une Question depuis Supabase (format V1)
  factory Question.fromMap(Map<String, dynamic> map) {
    final diff = map['difficulte']?.toString() ?? 'moyen';
    final rawAnime = map['anime']?.toString() ?? '';
    final slug = map['work_slug']?.toString();
    return Question(
      id: map['id'].toString(),
      anime: EconomyV92Service.nomPropreOeuvre(slug ?? rawAnime),
      workSlug: slug,
      arc: map['arc']?.toString(),
      domain: map['domain']?.toString() ?? 'GLOBAL',
      type: map['type']?.toString() ?? 'general',
      difficulte: diff,
      difficultyLevel: (map['difficulty_level'] as num?)?.toInt() ?? _levelFromLabel(diff),
      variantCode: map['variant_code']?.toString() ?? '1.1',
      question: map['question']?.toString() ?? '',
      choixA: map['choix_a']?.toString() ?? '',
      choixB: map['choix_b']?.toString() ?? '',
      choixC: map['choix_c']?.toString() ?? '',
      choixD: map['choix_d']?.toString() ?? '',
      bonneReponse: '',
      explication: map['explication']?.toString(),
      imageUrl: map['image_url']?.toString(),
    );
  }

  /// Cree une Question depuis le Cloudflare Worker R2 (format V9.2 / V4.0 sans bonne reponse)
  factory Question.fromR2Map(Map<String, dynamic> map) {
    final lvl = (map['difficulty_level'] as num?)?.toInt() ?? 2;
    final slug = map['work_slug']?.toString() ?? '';
    final rawWb = map['word_bank'] is List
        ? (map['word_bank'] as List).map((e) => e.toString()).toList()
        : null;
    if (rawWb != null && rawWb.length > 1) {
      rawWb.shuffle(Random());
    }
    return Question(
      id: map['id']?.toString() ?? '',
      anime: EconomyV92Service.nomPropreOeuvre(slug),
      workSlug: slug,
      arc: map['arc_name']?.toString(),
      domain: map['domain']?.toString() ?? 'GLOBAL',
      type: map['variant_code']?.toString() ?? '1.1',
      difficulte: _labelFromLevel(lvl),
      difficultyLevel: lvl,
      variantCode: map['variant_code']?.toString() ?? '1.1',
      question: map['question']?.toString() ?? '',
      choixA: map['choix_a']?.toString() ?? '',
      choixB: map['choix_b']?.toString() ?? '',
      choixC: map['choix_c']?.toString() ?? '',
      choixD: map['choix_d']?.toString() ?? '',
      bonneReponse: '',
      wordBank: rawWb,
      unit: map['unit']?.toString(),
      minSlider: (map['min_slider'] as num?)?.toDouble(),
      maxSlider: (map['max_slider'] as num?)?.toDouble(),
    );
  }

  /// Retourne les choix non vides (gere QCM 4 choix et Vrai/Faux ou Duel 2 choix)
  List<MapEntry<String, String>> get choix {
    final list = <MapEntry<String, String>>[
      MapEntry('A', choixA),
      MapEntry('B', choixB),
    ];
    if (choixC.isNotEmpty) list.add(MapEntry('C', choixC));
    if (choixD.isNotEmpty) list.add(MapEntry('D', choixD));
    return list;
  }

  /// Retourne les choix dans un ordre aleatoire (Double securite V4.0 : supprime tout biais sur A)
  /// tout en conservant `originalKey` pour la validation serveur sur R2/Supabase.
  List<ShuffledChoice> choixMelanges([Random? rng]) {
    final raw = List<MapEntry<String, String>>.from(choix);
    // Ne pas melanger Vrai/Faux classique (2.1) pour garder Vrai / Faux naturel
    if (variantCode != '2.1' && raw.length >= 2) {
      raw.shuffle(rng ?? Random());
    }
    const letters = ['A', 'B', 'C', 'D'];
    return List.generate(
      raw.length,
      (i) => ShuffledChoice(
        displayLetter: letters[i],
        originalKey: raw[i].key,
        text: raw[i].value,
      ),
    );
  }
}

/// Resultat retourne par l'Edge Function apres validation
class ResultatValidation {
  final bool joueurCorrect;
  final bool botCorrect;
  final String bonneReponse;
  final int degatsInfliges;
  final int degatsSubis;
  final bool comboJoueurDeclenche;
  final bool comboBotDeclenche;
  final int nouveauComboJoueur;
  final int nouveauComboBot;

  ResultatValidation({
    required this.joueurCorrect,
    required this.botCorrect,
    this.bonneReponse = '',
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
      bonneReponse: json['bonne_reponse'] ?? '',
      degatsInfliges: json['degats_infliges'] ?? 0,
      degatsSubis: json['degats_subis'] ?? 0,
      comboJoueurDeclenche: json['combo_joueur_declenche'] ?? false,
      comboBotDeclenche: json['combo_bot_declenche'] ?? false,
      nouveauComboJoueur: json['nouveau_combo_joueur'] ?? 0,
      nouveauComboBot: json['nouveau_combo_bot'] ?? 0,
    );
  }
}

/// Service qui gere la recuperation des questions (Cloudflare R2 en priorite, Supabase en secours).
class QuizService {
  final _supabase = Supabase.instance.client;

  // URL publique du Cloudflare Worker (ne contient aucun secret)
  static String get workerUrl {
    final envUrl = dotenv.env['QUIZ_WORKER_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl.replaceAll(RegExp(r'/$'), '');
    return 'https://otaku-verse-quiz-api.otakuverse-221.workers.dev';
  }

  // Cache local du catalogue des 21 oeuvres (evite des appels reseau repetes)
  static Map<String, dynamic>? _catalogCache;

  SupabaseClient get supabaseClient => _supabase;

  /// Recupere le catalogue complet des 21 oeuvres depuis Cloudflare R2 (`/catalog`).
  Future<List<Map<String, dynamic>>> recupererCatalogueR2() async {
    if (_catalogCache != null && _catalogCache!['works'] is List) {
      return List<Map<String, dynamic>>.from(_catalogCache!['works']);
    }
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final req = await client.getUrl(Uri.parse('$workerUrl/catalog'));
      final res = await req.close().timeout(const Duration(seconds: 8));
      final body = await res.transform(utf8.decoder).join();
      client.close();
      if (res.statusCode == 200) {
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        _catalogCache = decoded;
        if (decoded['works'] is List) {
          return List<Map<String, dynamic>>.from(decoded['works']);
        }
      }
    } catch (_) {}
    return [];
  }

  /// Tire un lot de 40 questions (ou N questions) depuis Cloudflare R2 (`/draw`).
  /// Aucune bonne reponse ne transite jamais vers l'application.
  Future<List<Question>> tirerLotR2({
    String mode = 'solo',
    String? workSlug,
    String? arcName,
    String? domain,
    String? difficulty,
    int count = 40,
    List<String>? variants,
  }) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final req = await client.postUrl(Uri.parse('$workerUrl/draw'));
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      req.write(jsonEncode({
        'mode': mode,
        'count': count,
        if (workSlug != null && workSlug.isNotEmpty) 'work_slug': workSlug,
        if (arcName != null && arcName.isNotEmpty) 'arc_name': arcName,
        if (domain != null && domain.isNotEmpty) 'domain': domain,
        if (difficulty != null && difficulty.isNotEmpty) 'difficulty': difficulty,
        // Par defaut : formats a choix (QCM, Intrus, Qui suis-je, Vrai/Faux, Duel A/B)
        'variants': variants ?? ['1.1', '1.2', '1.4', '2.1', '2.2'],
      }));
      final res = await req.close().timeout(const Duration(seconds: 12));
      final body = await res.transform(utf8.decoder).join();
      client.close();

      if (res.statusCode == 200) {
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        final rawList = decoded['questions'] as List? ?? [];
        final questions = rawList
            .whereType<Map>()
            .map((e) => Question.fromR2Map(Map<String, dynamic>.from(e)))
            .where((q) => q.choixA.isNotEmpty && q.choixB.isNotEmpty)
            .toList();
        if (questions.isNotEmpty) return questions;
      }
    } catch (_) {}

    // Repli automatique sur Supabase si R2 est injoignable
    return recupererQuestions(
      nombre: count,
      anime: workSlug?.replaceAll('_', ' '),
      arc: arcName,
      difficulte: difficulty == 'adaptatif' ? null : difficulty,
    );
  }

  /// Recupere un lot de questions depuis Supabase (sans bonne_reponse).
  Future<List<Question>> recupererQuestions({
    int nombre = 10,
    String? anime,
    String? arc,
    String? difficulte,
  }) async {
    var requete = _supabase
        .from('questions')
        .select('id, anime, arc, type, difficulte, question, choix_a, choix_b, choix_c, choix_d, explication, image_url')
        .eq('statut', 'actif');

    if (anime != null) {
      requete = requete.ilike('anime', anime);
    }
    if (arc != null) {
      requete = requete.ilike('arc', arc);
    }
    if (difficulte != null) {
      requete = requete.eq('difficulte', difficulte);
    }

    final reponse = await requete.limit(nombre);
    final questions = (reponse as List).map((q) => Question.fromMap(q)).toList();
    questions.shuffle();
    return questions;
  }

  /// Validation legacy (mode Verse V2) via l'Edge Function `valider-reponse`.
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
