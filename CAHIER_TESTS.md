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

## 4. V3 — Saisons, Evenements, Tournois & Missions de Carriere (`verse_v3_hub_page.dart`)
- [ ] Accueil : verifier le bouton `Saison V3` dans la colonne de gauche et le mode `EVENEMENT` debloque dans le selecteur de mode.
- [ ] Onglet `SAISON 1` : verifier l'affichage de "L'Ere des Pirates", du Soft Reset protege (max -2 divisions), du classement saisonnier et le bouton `RECLAMER` sur les paliers de saison.
- [ ] Onglet `EVENEMENTS` : cliquer sur `PARTICIPER` sur un evenement temporaire (One Piece, Naruto ou Multi-Verse) et verifier que cela lance un match et incremente le compteur d'evenements.
- [ ] Onglet `TOURNOIS` : cliquer sur `S'INSCRIRE`, lancer un duel de poule (`JOUER DUEL 1/10`), verifier que le score cumule augmente et que l'arbre des Quarts de Finale Top 8 s'affiche.
- [ ] Onglet `CARRIERE` : verifier les barres de progression des 5 missions longue duree (`100 duels`, `Division 5`, `3 evenements`, `Top 100`, `5 000 questions`) et la reclamation d'une mission terminee.

## 5. V4 — Monetisation (Verse Coins, Pass Premium, Boutique `boutique_screen.dart`)
- [ ] Accueil : cliquer sur le bouton `PASS & COINS` en haut a droite et verifier qu'il ouvre directement l'onglet Pass & Coins de la Boutique.
- [ ] En-tete Boutique : verifier l'affichage du solde de depart (`100 COINS`).
- [ ] Onglet `Articles & Coffres` : acheter un article cosmetique (ex: Cadre Shonen Jump a 150 Coins apres avoir pris un pack) ou ouvrir un `Coffre Mystere Otaku` (200 Coins) et verifier le gain d'XP aleatoire.
- [ ] Onglet `Booster XP & Pub` : cliquer sur `REGARDER` sur la Publicite Recompensee Opt-In (spot simule de 3s) et verifier l'activation du badge `2X XP (15 m)` en haut de la boutique + le gain de `+30 Verse Coins`.
- [ ] Onglet `Pass Premium & Coins` : cliquer sur `ACTIVER (TEST)` sur le Pass Premium Mensuel, verifier l'apparition du badge `PASS PREMIUM`, puis tester le bouton `RECLAMER +50/J` et l'achat d'un Pack (`500`, `1500` ou `5000 COINS`).

## 6. V5 — Expansion (Battle Royale Quiz & Guildes/Clans)
- [ ] Accueil : verifier la presence du mode `BATTLE_ROYALE` dans le selecteur de modes et du bouton `Guildes` sous `Amis` a droite.
- [ ] Battle Royale Quiz (`verse_battle_royale_page.dart`) : lancer une arene a 10 joueurs (ou rejoindre avec le code a 6 chiffres sur le 2e telephone), verifier le bandeau des 10 survivants en temps reel, l'elimination a 0 PV (`-35 PV` par erreur) et le gain d'XP + Verse Coins selon le rang final (`TOP #1` a `#10`).
- [ ] Guildes / Clans (`verse_guildes_page.dart`) : creer une guilde avec Nom, Tag (2 a 4 lettres) et Devise, envoyer un message dans le salon de discussion du clan, puis verifier l'onglet `CLASSEMENT MONDIAL` et rejoindre la guilde depuis le telephone de Heat.

## 7. Procedure de Build APK & Envoi a Heat (Firebase App Distribution)
1. [x] Copier une derniere fois le contenu complet de `scripts/firebase_database_rules.json` dans la console Firebase (`Realtime Database > Regles > Publier`) pour activer les noeuds V3, V4 et V5 (`saisons`, `evenements`, `tournois`, `carriere`, `economie`, `battle_royale`, `guildes`) (fait le 2026-11-03).
2. [x] Compiler l'APK release signe depuis `C:\All-projects\2026\Otaku_verse\app` :
   `flutter build apk --release` (fait le 2026-11-03 : `app-release.apk` 53.8 MB).
3. [x] Envoyer l'APK a Heat et au groupe `testers` via `C:\All-projects\2026\Otaku_verse\upload-apk.bat` (fait le 2026-11-03).
