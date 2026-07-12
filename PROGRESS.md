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
- Etape 6 : moteur de combat complet (PV, degats, combo, bot, parametrage, paysage force, animations shake + onomatopees)
- Etape 7 : progression (XP, niveaux, rangs) + table profiles dans Supabase, affichage XP en fin de combat
- Etape 8 : ecran profil (stats, niveau, rang, barre XP, skin rotatif, taux de victoire)

## En cours — Etape 9 (recompenses de base)

### A faire
- Defis quotidiens (generation automatique, reset a minuit)
- Recompense de connexion quotidienne
- Badges de base (Premier Pas, Sans Egratignure, Fidele, etc.)

## Prochaine etape
- Etape 10 : ecran d'accueil final (assembler tous les elements)

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
- Validation reponses cote client pour l'instant (Edge Function a ajouter — non bloquant)
- Pas de personnages visuels encore (juste les barres de PV avec labels TOI / BOT)
- 20 questions One Piece en base (le combat s'adapte au nombre reel)

## Dernier commit pousse
- "Etape 8 : ecran profil (stats, niveau, rang, skin rotatif, barre XP)" (2026-07-12)
