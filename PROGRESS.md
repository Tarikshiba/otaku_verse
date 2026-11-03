# PROGRESS — Otaku Verse

Derniere mise a jour : 2026-11-03
Version en cours : V5 + DA Liquid Glass (100% TERMINE — EN PHASE DE TESTS TERRAIN TARIQ & HEAT)
Module en cours : Retours tests terrain (APK Release 1.0.0 distribué sur Firebase App Distribution)

---

## 1. ETAT GLOBAL DU PROJET

Toutes les versions prevues par `ROADMAP_OTAKU_VERSE.md` (V1, V1.5, V2, V3, V4, V5) ainsi que l'integration visuelle de `OTAKU_VERSE_DA_LIQUID_GLASS.md` (21 illustrations manga decoupees et connectees) sont codees, compilees en release et distribuees aux testeurs.

### V1 — Solo MVP & Infrastructure (TERMINE)
- Authentification Supabase (inscription avec recherche de pays par continent, connexion, deconnexion).
- Moteur de combat Solo en affichage horizontal force contre l'IA (5 niveaux de difficulte, filtre par anime et par arc, timer, barres de PV, combos x3, animations de secousse et onomatopees).
- Progression joueur (XP, niveaux, rangs, statistiques) et validation serveur anti-triche via l'Edge Function Supabase `valider-reponse`.
- Dashboard Admin Next.js (`admin_dashboard/`) avec acces securise (`Drx@otaku.admin` / `Heat@otaku.admin`), CRUD questions, import en masse et upload d'images (`questions-images`).

### V1.5 — Social, Collection & Distribution (TERMINE)
- Systeme d'amis complet (recherche par pseudo, demandes, presence en ligne et statut "en combat", notifications push FCM V1).
- Classements (Mondial, National, Amis), Boite aux lettres (`mailbox`), Quetes synchronisees avec Supabase et Partage de resultat en image PNG.
- Collection de 10 skins deblocables par niveau ou XP avec apercu 3D oscillant.
- Signature Android Release (`upload-keystore.jks`) et distribution automatisee via `upload-apk.bat` sur Firebase App Distribution (`otaku-verse-6e05e`).

### V2 — Verse Multijoueur Temps Reel (TERMINE)
- Regles de securite Firebase Realtime Database publiees (`scripts/firebase_database_rules.json`).
- **Mode Division (Classe)** : 10 divisions (`Academie` a `Legende du Verse`), matchmaking temps reel (±2 divisions) avec repli sur bot adaptatif apres 10s, synchronisation de tour (`answeredIndex`) et validation serveur (`cloturer_match_verse`).
- **Duel Amical personnalisable** : creation et jonction par code a 6 chiffres avec choix de l'anime, de l'arc, de la difficulte et du nombre de questions (`verse_duel_setup_page.dart`).
- **Mode Cooperatif (Coop)** : 2 joueurs allies (ou duo avec l'IA alliee `A.K.I.N.A`) contre les 200 PV du Gardien du Verse, avec bonus de synergie (`verse_coop_page.dart`).
- **Systeme Anti-abandon** : confirmation avant de quitter, penalite de -30 PTS, victoire immediate pour l'adversaire et blocage temporaire (`cooldownUntil` de 5 min au 1er abandon, 30 min des 3 abandons consecutifs).

### V3 — Saisons, Evenements & Competition Avancee (TERMINE)
- **Saisons (8 semaines)** : Saison 1 "L'Ere des Pirates" (theme One Piece), classement saisonnier temps reel, 4 paliers de recompenses et calcul du Soft Reset protege (`max -2 divisions`).
- **Evenements temporaires (3 a 7 jours)** : evenements thematiques par anime (`Semaine One Piece`, `Semaine Naruto`, `Defi Communautaire Multi-Verse`) avec lancement direct de combat.
- **Tournois** : inscription au Tournoi Mensuel, phase de groupes (score cumule sur 10 duels) et arbre de Finale Top 8.
- **Missions Carriere** : suivi et reclamation des 5 objectifs longue duree de la Roadmap (`verse_v3_hub_page.dart` & `verse_v3_service.dart`).

### V4 — Monetisation & Economie Virtuelle Non Pay-to-Win (TERMINE)
- **Verse Coins** : portefeuille joueur (100 Coins offerts au depart), bonus quotidien (+15/j gratuit, +50/j avec Pass) et packs en mode test (`monetisation_v4_service.dart`).
- **Publicites recompensees opt-in** : spot simule octroyant `Double XP 15 min` + `30 Verse Coins` (jamais pendant un duel).
- **Pass Premium mensuel** : activation test donnant zero pub, +20% XP, +50 Coins/jour, Cadre Premium et file prioritaire.
- **Boutique Cosmetique & Confort** : Coffre Mystere Otaku, Cadre Shonen Jump, Effet K.O. Eclairs du Haki, Titre Seigneur du Verse et Boosters XP (`boutique_screen.dart`).

### V5 — Expansion : Battle Royale & Guildes (TERMINE)
- **Battle Royale Quiz (10 joueurs)** : survie a 10 combattants, -35 PV par erreur, elimination a 0 PV et recompenses selon le rang (`verse_battle_royale_page.dart`).
- **Guildes / Clans** : creation de guilde (Nom, Tag, Devise), adhesion, chat temps reel et Classement Mondial des Guildes (`verse_guildes_page.dart`).

### DA Liquid Glass & Nettoyage Architecture (TERMINE — 2026-11-03)
- Decoupage et integration des **21 illustrations manga** dans `app/assets/images/skins/`, `app/assets/images/modes/` et `app/assets/images/events/`.
- Connexion visuelle sur l'Accueil (`app_shell.dart`), la Boutique (`boutique_screen.dart`), le Profil (`profile_page.dart`), les Arenes (`verse_combat_page.dart`, `verse_coop_page.dart`) et le Hub V3 (`verse_v3_hub_page.dart`).
- Nettoyage du depot : suppression des dossiers vides (`assets/textures/`, `assets/models/`), des anciens ecrans V1 obsoletes (`quiz_page.dart`, `quiz_result_page.dart`, `rewards_page.dart`), des scripts Python temporaires (`fix_progress.py`, `update_progress.py`) et des `.gitkeep` inutiles.

---

## 2. PROCHAINE SESSION : RETOURS TESTS TERRAIN (TARIQ & HEAT)

1. Parcourir `CAHIER_TESTS.md` a deux sur les telephones Android avec l'APK Release.
2. Noter les ajustements souhaites (equilibrage des degats/timers, ergonomie UI, nouveaux packs de questions via le Dashboard Admin).
3. Appliquer les correctifs et ameliorations demandes suite aux tests.
