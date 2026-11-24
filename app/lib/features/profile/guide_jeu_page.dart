import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../economy/economy_v92_service.dart';
import '../tutorial/tutorial_service.dart';

/// === RUBRIQUE "INFOS / GUIDE DU JEU" DANS LE PROFIL (DEMANDE UX HEAT — TEST 41BIS) ===
/// Explique clairement au joueur toutes les mecaniques officielles V9.2 :
/// - Les 4 monnaies et compteurs isoles (XP, OC, VC, Points Division)
/// - La matrice de degats sur 350 PV (Normal, HAYA!!, COMBO x3, Clash, Auto-faute)
/// - Les 4 Malus speciaux (Texte Inverse, Sans Voyelles, Brouillard d'Encre, Eclipse 5s)
/// - Les contrats avant-match (Malus, Assurance XP 25 OC, Puits de Confiance 15/30 OC)
/// - Les 10 Divisions, les rangs officiels et la protection debutant Niv. 1-5
class GuideJeuPage extends StatefulWidget {
  const GuideJeuPage({super.key});

  @override
  State<GuideJeuPage> createState() => _GuideJeuPageState();
}

class _GuideJeuPageState extends State<GuideJeuPage> {
  @override
  void initState() {
    super.initState();
    // Valide la visite reelle du Guide pour l'etape 6 du Parcours d'Initiation Phase B
    TutorialService().marquerVisiteEtape(6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
                      child: const Icon(Icons.arrow_back_rounded, color: OtakuColors.textPrimary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.menu_book_rounded, color: OtakuColors.accent, size: 22),
                  const SizedBox(width: 8),
                  Text('INFOS & GUIDE DU JEU', style: OtakuTypo.headlineLarge.copyWith(fontSize: 19)),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    _buildSection(
                      '1. LES 4 COMPTEURS DU VERSE (ZÉRO PAY-TO-WIN)',
                      OtakuColors.accent,
                      [
                        'XP (Expérience) : mesure ton Niveau et ton Badge de Rang officiel permanent. L\'XP ne se dépense jamais en boutique et ne s\'achète jamais.',
                        'OC (Otaku Coins) : monnaie 100 % gratuite gagnée en combat, dans le Calendrier 21 jours et via les pubs volontaires. Sert aux frais d\'arène (dès Niv. 6), à l\'Assurance XP, au Puits de Confiance et aux recharges.',
                        'VC (Verse Coins) : monnaie cosmétique (Goodies, Cadres, Finishers, Emotes, Titres) et création de Salons Live / Donjons. Jusqu\'à 150 VC gratuits par saison (Calendrier + Initiation + Événements).',
                        'Points de Division : classent les joueurs de la Division 10 (Académie) jusqu\'à la Division 1 (Légende du Verse). Seuls les classements compétitifs ont des cagnottes VC (jamais le classement général XP).',
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildSection(
                      '2. MATRICE DE DÉGÂTS SUR 350 PV (40 Q · CHRONO 02:00)',
                      OtakuColors.pvHaut,
                      [
                        'Bonne réponse normale : -15 PV (+ -5 PV Auto-faute si l\'adversaire se trompe = -20 PV).',
                        'HAYA!! (réponse juste en moins de 2 secondes) : -18 PV (ou -23 PV avec Auto-faute adverse).',
                        'COMBO ×3 (strictement chaque multiple de 3 bonnes réponses d\'affilée : 3e, 6e, 9e...) : -30 PV (ou -35 PV avec Auto-faute).',
                        'COMBO ×3 + HAYA!! : -36 PV (ou -41 PV avec Auto-faute).',
                        'Clash (les 2 joueurs répondent juste) : le plus rapide inflige ses pleins dégâts et subit une riposte fixe de -8 PV (-15 PV si le 2nd était en Combo ×3).',
                        'Auto-faute : toute mauvaise réponse ou timeout retire -5 PV.',
                        'Seconde Chance (Solo uniquement) : si tu tombes à 0 PV, tu as 5 secondes pour repartir avec +100 PV (vidéo volontaire ou 30 OC, 1 fois par match).',
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildSection(
                      '3. LES 4 MALUS SPÉCIAUX & CONTRATS AVANT-MATCH',
                      OtakuColors.modeDuel,
                      [
                        'Texte Inversé : l\'énoncé s\'affiche à l\'envers.',
                        'Sans Voyelles : au maximum 1 voyelle par mot est remplacée par un point (•).',
                        'Brouillard d\'Encre : appuie ou gratte l\'écran pour révéler la question.',
                        'Éclipse : tu as 5 secondes pour lire la question avant qu\'elle ne disparaisse.',
                        'Contrat Malicieux : +25 % OC en cas de victoire (-20 XP si tu finis sous 50 % de bonnes réponses, jamais appliqué en victoire K.O.).',
                        'Assurance XP (25 OC, dès Niv. 6) : divise par 2 la perte d\'XP en cas de défaite (jamais sur un abandon).',
                        'Puits de Confiance (15 ou 30 OC) : doublé (×2 = 30 ou 60 OC) sur victoire K.O. avec ≤ 4 erreurs OU victoire aux points ≥ 80 %. Remboursé sur nul actif ≥ 80 %.',
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildSection(
                      '4. PROTECTION DÉBUTANT, RANGS OFFICIELS & ÉROSION',
                      const Color(0xFFFFD700),
                      [
                        'Niveaux 1 à 5 (Novice du Verse) : 0 OC de frais d\'arène et 0 perte d\'XP en cas de défaite (seul l\'abandon volontaire retire -50 XP).',
                        'Dès le Niveau 6 : la perte nette d\'XP s\'active en défaite, et les frais d\'arène OC s\'appliquent (indexés sur ta Division en mode Division, ou sur ton Niveau ailleurs).',
                        'Rangs officiels : Novice du Verse (1–5), Apprenti Otaku (6–15), Érudit des Arcs (16–30), Maître de l\'Encre (31–50), Seigneur du Verse (51–75), Légende Éternelle ★1/★2... (76+).',
                        'Érosion hebdomadaire (Niv. 16+) : 0 perte si tu joues au moins 1 match tous les 7 jours (14 jours pour les VIP). Sinon -20 / -30 / -40 XP par semaine, plancher absolu au Niveau 15 (12 300 XP).',
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildSection(
                      '5. LES 10 DIVISIONS (SEUILS & FRAIS OC DÈS NIV. 6)',
                      OtakuColors.modeDivision,
                      EconomyV92Service.divisionsOfficielles.map((d) {
                        final plage = d['max'] == null ? '${d['min']}+ pts' : '${d['min']}–${d['max']} pts';
                        return 'Division ${d['id']} (${d['nom']}) : $plage · Frais d\'arène : ${d['frais']} OC';
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String titre, Color accent, List<String> lignes) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OtakuColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: OtakuTypo.headlineSmall.copyWith(fontSize: 13, color: accent)),
          const SizedBox(height: 8),
          ...lignes.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('• $l', style: OtakuTypo.bodySmall.copyWith(fontSize: 11, color: Colors.white, height: 1.35)),
            ),
          ),
        ],
      ),
    );
  }
}
