import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Ecran de resultat affiche a la fin d'un quiz.
/// Montre le score, les XP gagnes, et un bouton pour revenir.
class QuizResultPage extends StatelessWidget {
  final int totalQuestions;
  final int bonnesReponses;
  final int xpGagne;
  final bool sansFaute;

  const QuizResultPage({
    super.key,
    required this.totalQuestions,
    required this.bonnesReponses,
    required this.xpGagne,
    required this.sansFaute,
  });

  @override
  Widget build(BuildContext context) {
    final pourcentage = (bonnesReponses / totalQuestions * 100).round();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Feedback principal
              Text(
                sansFaute ? 'PARFAIT !' : pourcentage >= 70 ? 'BIEN JOUE !' : 'CONTINUE !',
                style: OtakuTypo.impact.copyWith(
                  fontSize: 28,
                  color: sansFaute
                      ? OtakuColors.accent
                      : pourcentage >= 70
                          ? OtakuColors.success
                          : OtakuColors.warning,
                ),
              ),
              const SizedBox(height: 32),

              // Score
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: OtakuColors.surface,
                  border: Border.all(color: OtakuColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Text(
                      '$bonnesReponses / $totalQuestions',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: OtakuColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'bonnes reponses',
                      style: OtakuTypo.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    // Barre de score visuelle
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: bonnesReponses / totalQuestions,
                        minHeight: 8,
                        backgroundColor: OtakuColors.border,
                        valueColor: AlwaysStoppedAnimation(
                          pourcentage >= 70 ? OtakuColors.success : OtakuColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // XP gagne
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: OtakuColors.accent),
                  borderRadius: BorderRadius.circular(4),
                  color: OtakuColors.accent.withValues(alpha: 0.08),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt, color: OtakuColors.accent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      '+$xpGagne XP',
                      style: OtakuTypo.headlineLarge.copyWith(color: OtakuColors.accent),
                    ),
                  ],
                ),
              ),

              // Bonus sans faute
              if (sansFaute) ...[
                const SizedBox(height: 12),
                Text(
                  'BONUS SANS FAUTE : +50 XP',
                  style: OtakuTypo.label.copyWith(color: OtakuColors.accent),
                ),
              ],

              const SizedBox(height: 40),

              // Bouton retour
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Retourne a l'accueil
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('RETOUR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
