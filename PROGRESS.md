# PROGRESS — Otaku Verse

Derniere mise a jour : 2026-07-12
Version en cours : V1
Module en cours : combat_engine (Etape 6 refonte)

## ATTENTION - CHANGEMENT DE DIRECTION IMPORTANT (2026-07-09)

Suite a un retour d'experience utilisateur, le concept a evolue en profondeur.
Voir ROADMAP_OTAKU_VERSE.md v2.1, section 6 "Le mode Combat" pour le detail complet.

Resume : le quiz solo classique (vertical, question/4 choix dans le vide) est
remplace par un mode combat horizontal contre un bot (PV, degats, combos,
K.O., 10 questions max). Le multijoueur reel reste en V2 comme prevu, mais
reutilisera ce moteur de combat.

## Termine et teste
- Etape 0 : structure de dossiers, .gitignore, .env.example, repo Git init
- Etape 1 : projet Flutter cree, compile et tourne sur emulateur Android (Pixel 8)
- Etape 2 : Supabase connecte (URL + anon key, test OK)
- Etape 3 : Design system (theme.dart, violet electrique #7B2FF7)
- Etape 4 : Authentification (inscription, connexion, deconnexion)
- Etape 5 : 20 questions One Piece importees dans Supabase via script Node.js

## En cours — Etape 6 refonte (moteur de combat)

### Fait (2026-07-12)
- Modeles de donnees combat (CombatParams, CombatState, ResultatTour) dans combat_models.dart
- CombatService : logique degats, simulation bot, gestion combo (3 bonnes reponses = attaque speciale x2 degats)
- Ecran de parametrage (combat_setup_page.dart) : choix anime + difficulte avant le combat
- Ecran de combat (combat_page.dart) en mode paysage force :
  - Barres de PV joueur et bot avec couleurs dynamiques (vert/orange/rouge)
  - Indicateur de combo en cours (x1, x2...)
  - Timer 20s par question
  - Grille 2x2 des choix (adaptee au paysage)
  - Feedback apres reponse en deux colonnes (joueur gauche / bot droite)
  - Conditions de fin : K.O. (0 PV) ou decompte a la derniere question
  - Ecran de resultat : victoire/defaite/egalite, PV restants, bouton rejouer/accueil
- Accueil modifie : bouton JOUER remplace par COMBATTRE → mene au parametrage combat
- App entiere forcee en paysage (global dans main.dart)
- Bugs corriges : overflow ecrans (scrollable), RangeError si < 10 questions, feedback sur mauvaise question, vainqueur incorrect
- Teste et valide sur emulateur par Tariq (victoire, defaite, egalite OK)

### Reste a faire pour completer l'Etape 6
- Ajouter des animations d'attaque (meme minimales : flash, shake)
- Ajouter les onomatopees visuelles (BOOM, K.O.!) lors des coups / combos
- Validation reponses cote serveur (Edge Function) — peut etre reporte
- Plus de questions en base (actuellement 20 One Piece, le combat s'adapte au nombre reel)

## Prochaine etape
- Finir les tests manuels de l'Etape 6 sur emulateur
- Une fois le combat valide : passer a l'Etape 7 (progression — XP, niveaux, rangs)

## Decisions techniques prises
- Couleur d'accent : violet electrique #7B2FF7
- Auth : email sans confirmation (dev)
- Navigation auth : StreamBuilder dans AuthGate
- RLS questions : lecture pour anon + authenticated
- Import questions : service_role key (bypass RLS)
- Timer combat : 20 secondes par question
- PV de depart : 100 pour chaque combattant
- Degats normaux : 15 PV / Degats combo (attaque speciale) : 30 PV
- Seuil combo : 3 bonnes reponses d'affilee (reset a 0 apres declenchement ou mauvaise reponse)
- Bot : probabilite de reussite selon difficulte (facile 30%, moyen 50%, difficile 70%, expert 85%)
- Format de combat : max 10 questions, K.O. immediat possible, sinon decompte PV
- Skin joueur V1 : un seul skin fixe en 3D, rotatif dans le profil (pas de collection avant V1.5)
- Grille de choix 2x2 en paysage (au lieu de liste verticale)
- L'ancien code quiz (quiz_page.dart, quiz_result_page.dart) est conserve mais plus utilise depuis l'accueil

## Problemes connus / points d'attention
- Flutter non accessible depuis bash de Claude Code (Tariq doit tester manuellement)
- Validation reponses cote client pour l'instant (Edge Function a ajouter — non bloquant pour le test)
- Les animations de combat sont minimales (pas encore d'attaque visuelle animee, juste du texte de feedback)
- Pas de personnages visuels encore (juste les barres de PV avec labels TOI / BOT)

## Dernier commit pousse
- f2c58f4 : "Etape 6 : moteur de quiz fonctionnel (timer, feedback, resultats, fix RLS)"
  (c'est l'ancien quiz vertical — le code combat ci-dessus n'est pas encore commit)
