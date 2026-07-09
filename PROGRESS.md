# PROGRESS — Otaku Verse

Derniere mise a jour : 2026-07-09
Version en cours : V1
Module en cours : Progression (Etape 7)

## Termine et teste
- Etape 0 : structure de dossiers, .gitignore, .env.example, repo Git init
- Etape 1 : projet Flutter cree, compile et tourne sur emulateur Android (Pixel 8)
- Etape 2 : Supabase connecte (URL + anon key, test OK)
- Etape 3 : Design system (theme.dart, violet electrique #7B2FF7)
- Etape 4 : Authentification (inscription, connexion, deconnexion)
- Etape 5 : 20 questions One Piece importees dans Supabase via script Node.js
- Etape 6 : Moteur de quiz fonctionnel
  - Recuperation des questions depuis Supabase
  - Timer 20s par question
  - Feedback bonne/mauvaise reponse (vert/rouge)
  - Explication affichee apres reponse
  - Ecran de resultat (score, XP)
  - RLS corrige : acces lecture pour anon + authenticated

## En cours
- Etape 7 : Systeme de progression (XP, niveaux, rangs)

## Prochaine etape
- Creer table profils dans Supabase (xp, niveau, rang)
- Mettre a jour le profil apres chaque quiz
- Afficher le niveau/XP sur l'accueil

## Decisions techniques prises
- Couleur d'accent : violet electrique #7B2FF7
- Auth : email sans confirmation (dev)
- Navigation auth : StreamBuilder dans AuthGate
- RLS questions : lecture pour anon + authenticated
- Import questions : service_role key (bypass RLS)
- Timer quiz : 20 secondes par question

## Problemes connus / points d'attention
- Flutter non accessible depuis bash de Claude Code
- Design fonctionnel, refonte prevue post-V1
- Validation reponses cote client pour l'instant (Edge Function a ajouter plus tard)

## Dernier commit pousse
- 5bdd6c7 : "Etape 5 : 20 questions One Piece + script import Node.js vers Supabase"
