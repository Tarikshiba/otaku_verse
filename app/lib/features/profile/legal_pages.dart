import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// === PAGES LEGALES INTEGREES (POLITIQUE DE CONFIDENTIALITE & CGU — PHASE C3) ===
/// Lisibles directement dans l'app meme hors-ligne et alignees sur les pages web
/// publiques `/privacy` et `/terms` exigees par Google Play Console et Apple App Store.
class LegalDocumentPage extends StatelessWidget {
  final bool isPrivacyPolicy;
  const LegalDocumentPage({super.key, required this.isPrivacyPolicy});

  static const String supportEmail = 'support@otakuverse.app';

  @override
  Widget build(BuildContext context) {
    final titre = isPrivacyPolicy
        ? 'POLITIQUE DE CONFIDENTIALITÉ'
        : 'CONDITIONS GÉNÉRALES D\'UTILISATION';

    final sections = isPrivacyPolicy ? _privacySections : _termsSections;

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: OtakuColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: OtakuColors.border),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OtakuTypo.headlineLarge.copyWith(fontSize: 17),
                    ),
                  ),
                  Text(
                    'Màj : 24/11/2026',
                    style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: sections.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final sec = sections[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: OtakuColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: OtakuColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sec['titre']!,
                            style: OtakuTypo.headlineSmall.copyWith(fontSize: 13, color: OtakuColors.accent),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            sec['texte']!,
                            style: OtakuTypo.bodySmall.copyWith(fontSize: 11, color: Colors.white70, height: 1.45),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const List<Map<String, String>> _privacySections = [
    {
      'titre': '1. Données collectées',
      'texte': 'Otaku Verse collecte uniquement les données nécessaires au jeu : ton adresse email de connexion, ton pseudo, ton pays optionnel, tes statistiques de combat (XP, niveau, rang, victoires, division), tes cosmétiques débloqués et un jeton technique de notification push (Firebase).',
    },
    {
      'titre': '2. Confidentialité et anonymisation',
      'texte': 'Ton adresse email et tes soldes de monnaies (OC et VC) ne sont jamais visibles par les autres joueurs. Les cartes de partage 9:16 anonymisent par défaut le pseudo des adversaires et amis, sauf activation volontaire dans les Paramètres.',
    },
    {
      'titre': '3. Stabilité et diagnostics techniques',
      'texte': 'Firebase Crashlytics et Firebase Analytics collectent des diagnostics anonymisés (modèle de téléphone, version système, trace de plantage, écrans visités) dans le seul but de corriger les bugs et d\'améliorer la fluidité du jeu.',
    },
    {
      'titre': '4. Suppression définitive de tes données',
      'texte': 'Tu peux supprimer définitivement ton compte et l\'ensemble de tes données à tout moment depuis Paramètres > Supprimer définitivement mon compte, ou en écrivant à $supportEmail. La suppression est immédiate et irréversible.',
    },
  ];

  static const List<Map<String, String>> _termsSections = [
    {
      'titre': '1. Règles du jeu et équité (Zéro Pay-to-Win)',
      'texte': 'Otaku Verse est un jeu de quiz compétitif. Les skins (Goodies), cadres, titres et effets visuels n\'accordent aucun avantage en match classé. Toute tentative de triche, d\'automatisation ou de manipulation réseau entraîne la suspension du compte.',
    },
    {
      'titre': '2. Monnaies virtuelles (OC et VC) et achats',
      'texte': 'Les Otaku Coins (OC) sont gagnés gratuitement en jouant. Les Verse Coins (VC) et abonnements VIP sont des contenus numériques virtuels sans valeur monétaire extérieure, non remboursables après consommation conformément aux règles de Google Play et de l\'App Store.',
    },
    {
      'titre': '3. Propriété intellectuelle',
      'texte': 'Les personnages originaux d\'Otaku Verse (Kio, Mazú, Tavik, Ruvé, Hesk, Ilka, Vael, Dakoré, Ysaé, Cassio Vey, Soryn et Nyxara), les interfaces et le code appartiennent à l\'équipe Otaku Verse. Les questions de culture manga et anime relèvent du quiz éducatif et culturel.',
    },
    {
      'titre': '4. Support et contact',
      'texte': 'Pour toute question, demande de support ou signalement d\'erreur dans une question, utilise le bouton « Signaler une erreur » en combat ou contacte l\'équipe à $supportEmail.',
    },
  ];
}
