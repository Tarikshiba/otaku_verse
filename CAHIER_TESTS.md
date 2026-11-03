# CAHIER DE TESTS — Otaku Verse (Tariq & Heat)

Ce document recense l'ensemble des fonctionnalites a verifier sur vos deux telephones une fois l'APK final compile et distribue sur Firebase App Distribution.

## 1. Pre-requis Serveur (avant installation de l'APK)
- [x] Executer `scripts/add_question_image_column.sql` dans l'editeur SQL de Supabase (fait le 2026-11-03).
- [x] Redeployer l'Edge Function `valider-reponse` sur Supabase (fait le 2026-11-03).
- [x] Copier le contenu de `scripts/firebase_database_rules.json` dans la console Firebase (`Realtime Database > Regles > Publier`) sur le projet `otaku-verse-6e05e` (fait le 2026-11-03).

## 2. Dashboard Admin Next.js
- [x] Connexion administrateur et ajout d'une image sur une question (valide le 2026-11-03).
- [ ] Importation en masse de fichiers `.md` ou `.csv` (fichiers de Heat).

## 3. V2 — Verse Multijoueur (1v1, Division, Coop, Anti-abandon)
- [ ] Accueil : verifier que le bouton `MODE SELECTIONNE` affiche bien l'icone de medaille pour `DIVISION` et non plus le cadenas.
- [ ] Ecran Division (`verse_division_page.dart`) : verifier qu'il n'y a plus de bande jaune/noire de depassement en bas de l'ecran en orientation horizontale.
- [ ] Matchmaking Division solo : lancer une recherche seul, attendre 10 secondes et verifier que le bot `A.K.I.N.A` rejoint la partie.
- [ ] Matchmaking Division a deux (Tariq + Heat) : lancer une recherche en meme temps en etant a moins de 2 divisions d'ecart et verifier que vous tombez l'un contre l'autre.
- [ ] Synchronisation du combat (`verse_combat_page.dart`) : verifier que la question passe a la suivante des que vous avez tous les deux repondu (ou a la fin des 15 secondes), que les PV baissent en direct, et que les images des questions s'affichent.
- [ ] Cloture serveur du match : verifier l'attribution de l'XP et des points de division (`+25` victoire, `-15` defaite, `+5` egalite).
- [ ] Salon Duel Amical personnalise : creer un salon avec choix de l'anime, de l'arc, de la difficulte et du nombre de questions, puis rejoindre avec le code a 6 chiffres sur le telephone de Heat.
- [ ] Mode Cooperatif (Coop) : jouer a 2 allies contre le quiz et verifier le score d'equipe partage.
- [ ] Systeme Anti-abandon : quitter volontairement un match en cours et verifier la penalite de `-30 points`, la victoire automatique pour l'adversaire et le blocage temporaire (cooldown de 5 min au 1er abandon, 30 min au 3e).

## 4. V3 — Saisons, Evenements, Tournois & Missions de Carriere
- [ ] Saisons (8 semaines) : verifier l'affichage de la saison active, du classement saisonnier et des paliers de recompenses.
- [ ] Evenements temporaires : rejoindre un evenement thematique anime et verifier son classement dedie.
- [ ] Tournois : tester l'inscription, le cumul du score de groupe et l'arbre du Top 8.
- [ ] Missions longue duree (Carriere) : verifier la progression des objectifs de carriere et le deblocage des titres/badges.

## 5. V4 — Monetisation (Verse Coins, Pass Premium, Boutique)
- [ ] Compteur de `Verse Coins` dans l'en-tete et gain/depense en boutique.
- [ ] Pass Premium mensuel : affichage de la piste gratuite et de la piste Premium + deblocage de recompenses.
- [ ] Publicites recompensees (mode simulation/test) : verifier le bonus de Verse Coins / XP apres visionnage.

## 6. V5 — Expansion (Battle Royale Quiz & Guildes/Clans)
- [ ] Battle Royale Quiz : tester une partie multi-joueurs avec elimination progressive jusqu'au dernier survivant.
- [ ] Systeme de Guildes / Clans : creer un clan, inviter Heat, verifier le classement des clans et le chat/tableau de bord d'equipe.
