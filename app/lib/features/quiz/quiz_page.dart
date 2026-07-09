import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'quiz_service.dart';
import 'quiz_result_page.dart';

/// Ecran principal du quiz : affiche les questions une par une,
/// avec un timer, feedback bonne/mauvaise reponse, et passe a la suivante.
class QuizPage extends StatefulWidget {
  final List<Question> questions;

  const QuizPage({super.key, required this.questions});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // Index de la question actuelle
  int _indexActuel = 0;

  // Reponse selectionnee (null = pas encore repondu)
  String? _reponseChoisie;

  // Timer : 20 secondes par question
  static const int _tempsParQuestion = 20;
  int _tempsRestant = _tempsParQuestion;
  Timer? _timer;

  // Resultats accumules
  int _bonnesReponses = 0;
  int _totalXp = 0;
  final List<bool> _resultats = [];

  @override
  void initState() {
    super.initState();
    _demarrerTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _demarrerTimer() {
    _tempsRestant = _tempsParQuestion;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_tempsRestant <= 0) {
        // Temps ecoule = mauvaise reponse automatique
        timer.cancel();
        _validerReponse(null);
      } else {
        setState(() => _tempsRestant--);
      }
    });
  }

  /// Quand le joueur clique sur un choix
  void _onChoixSelectionne(String lettre) {
    if (_reponseChoisie != null) return; // Deja repondu
    _timer?.cancel();
    _validerReponse(lettre);
  }

  /// Valide la reponse et affiche le feedback
  void _validerReponse(String? reponse) {
    final question = widget.questions[_indexActuel];
    final estCorrect = reponse == question.bonneReponse;

    setState(() {
      _reponseChoisie = reponse ?? ''; // String vide = temps ecoule
    });

    if (estCorrect) {
      _bonnesReponses++;
      _totalXp += 10; // +10 XP par bonne reponse
    }
    _resultats.add(estCorrect);

    // Passe a la question suivante apres 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _questionSuivante();
    });
  }

  void _questionSuivante() {
    if (_indexActuel + 1 >= widget.questions.length) {
      // Quiz termine
      _terminerQuiz();
    } else {
      setState(() {
        _indexActuel++;
        _reponseChoisie = null;
      });
      _demarrerTimer();
    }
  }

  void _terminerQuiz() {
    // Bonus sans faute
    int bonusXp = 0;
    if (_bonnesReponses == widget.questions.length) {
      bonusXp = 50;
    }

    // XP de base pour avoir termine le quiz
    final xpTotal = _totalXp + 20 + bonusXp;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultPage(
          totalQuestions: widget.questions.length,
          bonnesReponses: _bonnesReponses,
          xpGagne: xpTotal,
          sansFaute: _bonnesReponses == widget.questions.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_indexActuel];
    final aRepondu = _reponseChoisie != null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header : progression + timer
              _buildHeader(question),
              const SizedBox(height: 24),

              // Question
              Text(question.question, style: OtakuTypo.bodyLarge),
              const SizedBox(height: 24),

              // Choix de reponses
              ...question.choix.map((choix) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildChoix(
                      lettre: choix.key,
                      texte: choix.value,
                      bonneReponse: question.bonneReponse,
                      aRepondu: aRepondu,
                    ),
                  )),

              const Spacer(),

              // Explication (visible apres avoir repondu)
              if (aRepondu && question.explication != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: OtakuColors.surface,
                    border: Border.all(color: OtakuColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    question.explication!,
                    style: OtakuTypo.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header avec anime, progression, timer
  Widget _buildHeader(Question question) {
    return Column(
      children: [
        // Anime + difficulte
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              question.anime.toUpperCase(),
              style: OtakuTypo.label.copyWith(color: OtakuColors.accent),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _couleurDifficulte(question.difficulte),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                question.difficulte.toUpperCase(),
                style: OtakuTypo.label.copyWith(
                  fontSize: 10,
                  color: _couleurDifficulte(question.difficulte),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Barre de progression + timer
        Row(
          children: [
            // Progression (ex: 3/10)
            Text(
              '${_indexActuel + 1}/${widget.questions.length}',
              style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted),
            ),
            const SizedBox(width: 12),
            // Barre de progression
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (_indexActuel + 1) / widget.questions.length,
                  minHeight: 4,
                  backgroundColor: OtakuColors.border,
                  valueColor: const AlwaysStoppedAnimation(OtakuColors.accent),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _tempsRestant <= 5
                    ? OtakuColors.error.withValues(alpha: 0.15)
                    : OtakuColors.surface,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: _tempsRestant <= 5 ? OtakuColors.error : OtakuColors.border,
                ),
              ),
              child: Text(
                '${_tempsRestant}s',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _tempsRestant <= 5 ? OtakuColors.error : OtakuColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construit un choix de reponse
  Widget _buildChoix({
    required String lettre,
    required String texte,
    required String bonneReponse,
    required bool aRepondu,
  }) {
    Color couleurBordure = OtakuColors.border;
    Color couleurFond = Colors.transparent;

    if (aRepondu) {
      if (lettre == bonneReponse) {
        // C'est la bonne reponse → vert
        couleurBordure = OtakuColors.success;
        couleurFond = OtakuColors.success.withValues(alpha: 0.1);
      } else if (lettre == _reponseChoisie) {
        // C'est ce que le joueur a choisi et c'est faux → rouge
        couleurBordure = OtakuColors.error;
        couleurFond = OtakuColors.error.withValues(alpha: 0.1);
      }
    }

    return GestureDetector(
      onTap: aRepondu ? null : () => _onChoixSelectionne(lettre),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: couleurBordure, width: aRepondu ? 2 : 1),
          borderRadius: BorderRadius.circular(2),
          color: couleurFond,
        ),
        child: Row(
          children: [
            // Lettre dans un carre
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: couleurBordure, width: 1.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                lettre,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: couleurBordure == OtakuColors.border
                      ? OtakuColors.textSecondary
                      : couleurBordure,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texte,
                style: TextStyle(
                  fontSize: 15,
                  color: couleurBordure == OtakuColors.border
                      ? OtakuColors.textPrimary
                      : couleurBordure,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _couleurDifficulte(String difficulte) {
    switch (difficulte) {
      case 'facile':
        return OtakuColors.success;
      case 'moyen':
        return OtakuColors.warning;
      case 'difficile':
        return OtakuColors.error;
      case 'expert':
        return const Color(0xFFFF4081);
      default:
        return OtakuColors.textMuted;
    }
  }
}
