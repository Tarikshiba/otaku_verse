# PROGRESS : Otaku Verse

Derniere mise a jour : 2026-11-25
Version en cours : V9.3.2 Consolidee (Correctifs terrain Samsung : R8/Firebase, 3D WebView, Cases Manga, AuthGate & Trigger SQL service_role)
Documents de reference : `CAHIER_MODIFICATIONS_DEV_OTAKU_VERSE.docx` (V9.2 Finale), `Les retours après le test de heat/002_cahier_de_test_V9.2_complet.md.docx`, `OTAKU_VERSE_PERSONNAGES.md`, `OTAKU_VERSE_DA_LIQUID_GLASS.md`
Roadmap vers la sortie Stores : `ROADMAP_PUBLICATION_STORES.md`
Checklist creation assets & 3D : `ASSETS_A_CREER_VISUEL_3D.txt`
Plan de tests terrain : `CAHIER_TESTS.md`
Ancienne roadmap archivee : `archive/ROADMAP_OTAKU_VERSE.md`

---

## 1. ETAT DE LA BASE EXISTANTE & DEPLOIEMENTS ACTIFS

- **Application Flutter (Android)** : `dart analyze` a 0 erreur, `flutter test` passe (11/11), APK Release signe V9.3.2 compile (`app/build/app/outputs/flutter-apk/app-release.apk`, 66,1 Mo) et valide en direct sur Samsung physique (`R58X70WH7SB`).
- **Supabase Production (`houbjgugzznytilkfwyf`)** : migration SQL V9.2 executee (`scripts/v92_socle_supabase.sql`), 4 Edge Functions deployees (`match-engine`, `shop-tutorial-engine`, `valider-reponse`, `envoyer-notification`), secrets `QUIZ_WORKER_URL` et `WORKER_API_SECRET` actifs.
- **Cloudflare R2 + Worker (`otaku-verse-quiz`)** : 1 254 803 questions reparties sur 21 oeuvres (105 shards `.json.gz` + `catalog.json` = 133,08 Mo) servies en direct par `https://otaku-verse-quiz-api.otakuverse-221.workers.dev`.
- **Logos** : 5 logos officiels compresses (376 Ko) integres dans `app/assets/images/logos/` et `admin_dashboard/public/`.

---

## 2. SECURITE PRIORITAIRE & MENAGE (ETAPE 1)

- [x] **CLEAN-01** : Extraction propre des 3 archives Drive dans `drive_sources/`, suppression des `.zip`, nettoyage `.gitignore`, archivage de `ROADMAP_OTAKU_VERSE.md` dans `archive/`.
- [x] **SEC-01** : `scripts/fcm_secret_b64.txt` retire du suivi Git et supprime du disque ; ancienne cle privee FCM (`a1df729...`) revoquee dans Google Cloud Console et nouvelle cle (`558d7a3...`) deployee dans `FCM_SERVICE_ACCOUNT` sur Supabase le 24/11/2026.
- [x] **SEC-02** : Authentification admin verifiee cote serveur via JWT Bearer (`admin_dashboard/lib/admin-auth.ts`) sur `/api/questions`, `/api/questions/import` et `/api/questions/upload-image` + correction du parser 13/14 colonnes (`npx tsc --noEmit` OK).
- [x] **SEC-03** : Suppression de `bonne_reponse` du `select()` client et de la route `/draw` du Worker Cloudflare R2 (revelee uniquement apres validation serveur).
- [x] **SEC-04** : Verification du JWT cote serveur dans `valider-reponse`, `match-engine` et `shop-tutorial-engine`, plus cle `service_role` exigee sur les appels internes de `envoyer-notification`.
- [x] **SEC-05 (Socle SQL)** : Migration SQL V9.2 executee dans Supabase avec RLS sur toutes les tables V9.2.

---

## 3. CHECKLIST OFFICIELLE V9.2 (22/22 TICKETS CODES)

### Economie, XP & Compteurs SQL
- [x] **ECO-01** (§1.1) : 4 compteurs SQL isoles (`xp_totale`, `oc_balance`, `vc_bonus` + `vc_paid`, `pts_*`) + `economy_ledger` + RPC `spend_verse_coins` (debite `vc_bonus` en 1er).
- [x] **ECO-02** (§1.2) : Suppression totale des depenses d'XP en boutique, des Boosters d'XP, du Coffre Mystere XP et des VC contre pub.
- [x] **ECO-03** (§1.2-1.3) : Perte Nette Seche d'XP en defaite (des Niv. 6), 6 modes (Facile a Maitre + Adaptatif), erosion hebdomadaire douce (`apply_weekly_xp_erosion`).
- [x] **ECO-04** (§1.3 / §7.3) : Widget `OfficialRankBadge` permanent (`app/lib/shared/rank_badge.dart`) integre sur Accueil, Profil, Combat, Division et Carte de partage.
- [x] **ECO-05** (§1.4 / §7.5) : Arbitrage Frais d'Arene OC (`get_arena_entry_fee` + `EconomyV92Service.fraisAreneOc`) dans `combat_setup_page.dart` et `verse_division_page.dart`.
- [x] **ECO-06** (§1.4 / §2.1) : Bouton Roi "Doubler mes OC (x2)" en fin de match + Coup de Pouce (+40 OC si solde < frais) branches sur `match-engine`, 0 VC sur les pubs, plafond SQL 150 VC/saison.

### Boutique & Monetisation
- [x] **SHOP-01** (§2.1) : 5 Packs VC exacts (Base + Bonus VC, remises unitaires `-9,5 %`, `-18,8 %`, `-26,9 %`, `-33,7 %` sur base 6,00 FCFA/VC) dans `boutique_screen.dart` + `shop-tutorial-engine`.
- [x] **SHOP-02** (§2.2-2.3) : 3 offres (Pass Sans Pub 1 An 4 500 FCFA, Pack Demarrage 6 500 FCFA 1x/compte, Abonnement VIP Mensuel 3 500 FCFA / 1er mois 2 500 FCFA et Annuel 29 900 FCFA + 8 privileges + 7 Stats Pro Verse Analytics dans `profile_page.dart`).
- [x] **SHOP-03** (§2.4) : Catalogue Goodies 100 % en VC (Classiques 350-500 VC, Epiques 700-900 VC, Fondateurs Legendaires Soryn & Nyxara 1 200-1 500 VC + cosmetiques VC), sauf 1 Goodies tuto a 300 OC.

### UI/UX & Partage 9:16
- [x] **UI-01** (§3.2) : Avatars/Goodies non coupes (`SafeAvatarBox` : `BoxFit.contain` + `Alignment.topCenter` + padding haut >= 12 px) sur Accueil, Profil, Boutique et Carte 9:16.
- [x] **UI-02** (§3.2) : Protection anti-overflow (`Flexible`/`Expanded` + `TextOverflow.ellipsis` + `SingleChildScrollView`) sur Accueil, Setup, Combat, Division, Boutique et Classements.
- [x] **UI-03** (§3.2) : Auto-sizing des textes longs (15pt / 13.5pt / 12pt) dans les questions et boutons A/B/C/D de `combat_page.dart`.
- [x] **UI-04** (§3.2 / §6.5) : Bandeau dynamique d'affluence et cagnotte en haut de `classement_screen.dart` via RPC `get_leaderboard_pot_info`.
- [x] **UI-05** (§3.3 / §7.6) : Carte verticale 9:16 (1080x1920 dans `victory_share_card.dart`) avec anonymisation par defaut du perdant, masquage des soldes OC/VC et opt-in `allow_share_pseudo_friends` dans `parametres_page.dart`.

### Tutoriel, Communaute, Classements & Gameplay
- [x] **TUTO-01** (§4.1-4.2) : Tutoriel 2 Phases (`tutorial_phase_a_page.dart` + `tutorial_service.dart` + banniere Phase B 6 etapes sur `app_shell.dart`).
- [x] **COMM-01** (§5.1 / §6.6) : Tarifs unifies dans `verse_communaute_page.dart` + `shop-tutorial-engine` (Donjon 100 VC, Salon Live JKLM 150 VC, gratuits VIP, rejoindre = 0 VC ; Coop 2v2 = 0 VC / 525 PV ; Battle Royale 350 PV / 40 Q).
- [x] **RANK-01** (§6.1-6.3) : 7 scenarios d'issue de match sans cas orphelin + seuils 10 Divisions (0 a 1 900+ pts).
- [x] **RANK-02** (§6.7) : Push "Un ami t'a depasse" dans `match-engine` + `envoyer-notification` avec throttle strict serveur (`notification_throttles` : 1x/24h/ami, max 2/jour global, silence 22h-08h local).
- [x] **GAME-01** (§7.2-7.4) : Moteur V9.2 complet (`combat_page.dart` + `combat_service.dart` + `match-engine` + R2) : Double Timer 2 min + 20s/Q, 350 PV / 40 Q, Auto-Faute -5 PV, Haya!!, Combo multiples de 3, Mort Subite, 5 Malus Flutter et Seconde Chance Solo.

### Lancement Progressif & Base 21 Oeuvres
- [x] **LAUNCH-01 / 02 / 03** (§8.1-8.3) : `app_feature_flags` + `feature_waitlist`, Division `AI_ONLY` Semaine 1, Palier 1 actif sur `app_shell.dart`.
- [x] **FIX-01 / 02 / 03 / 04** : Import admin 13/14 colonnes, vrai compteur `_unreadMails`, quetes sur vraies stats, 21 oeuvres dynamiques en Duel.
- [x] **DATA-01** : 1 254 803 questions en ligne sur Cloudflare R2 + 5 logos integres.

---

## 4. PLAN ACTUEL : CHANTIER 1 (RETOURS TERRAIN HEAT) PUIS CHANTIER 2 (NOUVEAUX PERSOS, 3D & UI)

### Chantier 1 (CODE & VERIFIE, PRET A DEPLOYER SUR SUPABASE) : Retours Terrain V9.2 de Heat (48 points, 23 anomalies P0/P1)
Source : `Les retours après le test de heat/002_cahier_de_test_V9.2_complet.md.docx` + 12 captures Tecno Spark 20.

#### Etape 1.1 : Bugs Critiques Economie, Degats & Calculs Serveur (P0 Bloquant)
- [x] **1.1.a Protection XP Niv. 1-5 & Perte Nette Seche Niv. 6+** (Test 25, Calculs #2 et #3) : niveau calcule de facon autoritaire depuis `xp_totale`, 0 perte d'XP en defaite ou AFK du Niv. 1 au Niv. 5, seul l'abandon volontaire retire -50 XP (`match-engine`, `valider-reponse`).
- [x] **1.1.b Puits de Confiance (15/30 OC) & Assurance XP (25 OC)** (Tests 21, 30, Calculs #5 et #6) : retour complet `oc_pot_stake`, `oc_pot_return`, `pot_status` et `pot_reason` cote serveur et affichage complet sur l'ecran de fin de match ; Assurance XP active des Niv. 6 (`FLOOR(perte/2)`) avec garde-fou serveur et explication claire sous Niv. 6.
- [x] **1.1.c Matrice de Degats 350 PV exacte** (Test 16, Calcul #1) : `valider-reponse` et `match-engine` alignes sur Normal `-15/-20`, HAYA!! `-18/-23`, COMBO x3 `-30/-35`, COMBO x3 + HAYA!! `-36/-41`, riposte Clash `-8` (`-15` si Combo x3), Bot Facile `-12/-17`, avec affichage detaille des PV infliges/subis.
- [x] **1.1.d Audit SQL complet Economie** (Tests 28, 29, 31, 32, 35, 36, Calculs #4, #7-#12) : migration `scripts/v92_correctifs_terrain.sql` (titres officiels accentues, anti-double-debit `last_erosion_applied_at` sur `apply_weekly_xp_erosion` + `apply_weekly_xp_erosion_all()`, table RLS `player_question_errors`, recharges OC 20 OC Aura / 40-80-160 OC Jour manque + gratuit VIP 1x/sem / 50 OC 3 Defis bonus, `equipped_skin_key` pour les avatars en classement).

#### Etape 1.2 : Classements, Badges, Bots IA, Fin de Match & Cooldown 429 (P0)
- [x] **1.2.a Nettoyage Classement XP & Rubrique Classements sur l'Accueil** (Tests 10, 26, 27) : bandeau cagnotte retire du Classement General XP, nouvelle rubrique "Classements" sur l'Accueil (Division en priorite avec 10 Divisions visibles, seuils, frais OC, bandeau cagnotte dynamique, bouton `JOUER > DIVISION`, onglets Guildes / BR / Tournois par palier).
- [x] **1.2.b Avatars, Badges Bots IA & Compteur XP** (Tests 7, 10) : avatars reels affiches dans les classements (`SafeAvatarBox`), Badge de Rang + Niveau credible sur chaque Bot IA en Solo et Division, compteur XP dans la Top Bar, `OfficialRankBadge(prominent: true)` sur le Profil.
- [x] **1.2.c Fin de match, Seconde Chance Solo & Cooldown 429** (Tests 11, 20, 21, 23, 24) : gros bouton `REJOUER` prioritaire, fenetre Seconde Chance Solo avec decompte 5s (Video ou 30 OC pour +100 PV), mention claire `K.O. · KECCHAKU!`, capture propre de `FunctionException` (plus aucune erreur brute 429), avertissement au 2e timeout AFK en Solo et suppression du cooldown 5 min en Solo (reserve PvP / Division).

#### Etape 1.3 : Tutoriel, UI Tecno Spark 20, Combat, 4 Malus & Guide du Jeu (P0 / P1)
- [x] **1.3.a Tutoriel Phase A & Phase B + Auth** (Tests 3, 5, 6) : 21 oeuvres reelles au carrousel (Solo Leveling retire), validation email + mot de passe securise (8+ car., maj/min/chiffre) + "Mot de passe oublie", visite guidee du Hub en 4 etapes, reinitialisation propre a la deconnexion + verification `compteDoitFairePhaseA()` (fix bug post-deconnexion), verrouillage serveur des 6 etapes Phase B + Titre "Initié du Verse" et respect des titres officiels avec accents.
- [x] **1.3.b Correction des 3 chevauchements UI sur Tecno Spark 20** (Test 9) : refonte responsive du Hub `app_shell.dart` sans `Positioned` fixes (Top Bar / Corps 3 zones avec avatar adaptatif / Bottom Bar separes).
- [x] **1.3.c Lisibilite Combat & 4 Malus propres** (Tests 4, 15, 17, 18, 22) : nom propre de l'oeuvre en haut de chaque question, ralentissement et agrandissement des effets `HAYA!!` / `COMBO ×3` / `KECCHAKU!` + Face-Off + temps de lecture 1,45s, suppression Effet Miroir, Sans Voyelles (max 1 voyelle/mot avec `•` + badge `SANS VOYELLES`), Eclipse passe a 5s.
- [x] **1.3.d Ajouts UX Heat** (Tests 7, 13, 41bis) : bouton `PUB +OC` (+25 OC, 0 VC, max 5/j) dans la Top Bar de l'Accueil, page dediee `guide_jeu_page.dart` ("Infos / Guide du jeu") dans le Profil + mini-explications avant-match.

#### Etape 1.4 : Boutique VIP, Verse Analytics, Partage 9:16 & Preparation Quiz V4.0 (P1)
- [x] **1.4.a Offres VIP & Verse Analytics plein ecran** (Tests 37, 39) : carte vedette VIP Annuel (29 900 FCFA / -29 %) mise fortement en avant, panneau explicatif au clic sur chaque pack/abonnement (versement echelonne 800 + 200x12 VC + 8 privileges VIP), nouvelle page plein ecran interactive `verse_analytics_page.dart` (radar 5 axes, courbe 50 matchs, difficultes, carnet d'erreurs revisable avec filtre anime, comparateur H2H).
- [x] **1.4.b 5 corrections Partage 9:16 & Parametres** (Tests 40, 41) : logo `logo_icone.jpg` non coupe (`OTAKU VERSE`), nom propre de l'oeuvre, adversaire non tronque sur 2 lignes, tous les accents francais, texte vie privee en langage naturel de jeu, deconnexion propre dans `parametres_page.dart`.
- [x] **1.4.c Preparation Pipeline Quiz V4.0** (Test 2, Partie 5) : double securite melange aleatoire A/B/C/D cote app (`choixMelanges` preservant la cle serveur) + support `.md` V4.0 et 5 formats `arc_name` sans limite d'arcs dans `scripts/build_r2_shards.py` (reimport R2 en attente du feu vert de Heat).

#### Actions deploiement executees le 24/11/2026
- [x] Executer `scripts/v92_correctifs_terrain.sql` dans Supabase > SQL Editor.
- [x] Deployer les 3 Edge Functions mises a jour : `npx supabase functions deploy match-engine`, `valider-reponse`, `shop-tutorial-engine`.

---

### Chantier 2 (CODE & VERIFIE) : Nouveaux Personnages (`OTAKU_VERSE_PERSONNAGES.md`), 3D compressee via R2 & Refonte UI Free Fire (Phase A)
- [x] **2.1 Rangement sources bruts & Compression 3D `.glb` (-98,2 %)** : `Skin_3D` (705 Mo), `T-POSE` (39 Mo) et `carte skins` (28 Mo) deplaces hors APK dans `assets_sources_raw/` (ajoute au `.gitignore`). Script reutilisable `scripts/compress_skins_glb.mjs` (decimation QEM Meshopt ~30k-42k tris + textures 1024px JPEG + quantification) : 10 modeles passes de **704,0 Mo a 12,85 Mo** (entre 0,93 Mo et 1,94 Mo par perso). Kio (`skin_kio.glb`, 0,93 Mo) embarque dans `app/assets/models/skins/`, les 10 modeles propres (`skin_kio.glb`..`skin_cassio_vey.glb`) prets dans `r2_build/models/skins/` + route Cloudflare Worker `GET /models/<skin_key>.glb` + script `scripts/upload_r2_models.ps1`.
- [x] **2.2 Assets 2D & 10 personnages originaux anti-copyright** : 10 portraits transparents nommes proprement `skin_kio.png`..`skin_cassio_vey.png` (zero nom copyrighte ninja/pirate/hokage/titan dans les fichiers ou cles), `lobby_arene_principale.png` (3,1 Mo) converti en `.webp` (345 Ko), `Ranks/` renomme en `ranks/`, 4 cadres PNG transparents integres (`frames/`). Renommage complet (`Kio`, `Mazú`, `Tavik`, `Ruvé`, `Hesk`, `Ilka`, `Vael`, `Dakoré`, `Ysaé`, `Cassio Vey`) dans `skin_model.dart`, `skin_service.dart`, `shop-tutorial-engine`, `v92_correctifs_terrain.sql` et `pubspec.yaml`.
- [x] **2.3 Identite native & Plein Ecran Immersif (Phase A1)** : `SystemUiMode.immersiveSticky` dans `main.dart`, `shortEdges` (encoche camera Android API 28+) dans `values-v28/styles.xml`, nom natif `Otaku Verse` dans `AndroidManifest.xml` et `Info.plist`, 5 icones mipmap generees depuis `logo_icone.jpg` et Splash Screen sombre genere depuis `logo_sombre.jpg`.
- [x] **2.4 Refonte UI Free Fire, Viewer 3D R2 & Audio (Phases A2-A5)** :
  - `skin_3d_cache_service.dart` + `skin_3d_viewer.dart` (`model_viewer_plus` 360° interactif avec streaming + cache local R2 et repli 2D instantane + toggle 3D/2D).
  - `app_shell.dart` sur `lobby_arene_principale.webp` avec mise en page Free Fire (mode actif empile sur `JOUER` en bas a droite, cadre d'avatar et bouton Parametres en Top Bar, scene 3D centrale large).
  - `mode_selector_page.dart` plein ecran horizontal sur `modes_selector_bg.webp` (onglets `MODES OFFICIELS` / `COMMUNAUTE`, 2 grandes cartes `DIVISION` & `SOLO` a gauche, grille `.webp` a droite).
  - `profile_page.dart` en 3 colonnes sur `profil_podium_bg.webp` (navigation verticale, podium 3D central, fiche joueur avec vraies medailles PNG `ranks/rank_*.png`, cadres `frames/cadre_*.png` et onglet Collection).
  - `boutique_screen.dart` sur `boutique_showroom_bg.webp` avec viewer 3D dans le showroom et apercus des cadres PNG ; `parametres_page.dart` avec toggles audio (`audio_manager.dart`, pret pour les 8 `.mp3`) et gestion du cache local 3D.

- [x] **2.5 Finitions retour emulateur Android (24/11)** :
  - Recadrage transparent de `logo_icone.png` (512x512) + regeneration des 5 icones Android (`mipmap-*`) sur fond `#0B0A16` + Splash natif Android 12+ (`values-v31/styles.xml`) sans cercle blanc.
  - Animation d'ouverture Option B (`splash_intro_overlay.dart`, coupure manga cyan/orange + onde de choc + surgissement du logo renard, 60 FPS Flutter pur).
  - Ancrage des pieds des personnages 3D au sol (`skin_3d_viewer.dart` : ombre de contact, cadrage bas, `cameraOrbit` incline, `autoPlay: true` et `autoRotate: false` face camera avec rotation libre 360° au doigt).
  - Conversion des 10 animations Mixamo FBX -> GLB (`scripts/convert_mixamo_fbx_to_glb.mjs`) avec version de cache `v2_anim` dans `skin_3d_cache_service.dart`.
  - Validation automatique de l'Init Phase B au retour sur le Hub (`synchroniserEtapesPhaseBAutomatiquement`) et correction de la pastille rouge Boite aux lettres (`verifierDailyLogin()` appele des le chargement du Hub).

#### Actions deploiement executees le 24/11/2026 (Chantier 1 + Chantier 2 en production)
- [x] Executer `scripts/v92_correctifs_terrain.sql` dans Supabase > SQL Editor.
- [x] Deployer les 3 Edge Functions Supabase : `npx supabase functions deploy match-engine`, `valider-reponse`, `shop-tutorial-engine`.
- [x] Uploader les 10 `.glb` propres (`skin_kio.glb`..`skin_cassio_vey.glb`) sur Cloudflare R2 (`scripts/upload_r2_models.ps1`).
- [x] Deployer le Worker Cloudflare (`npx wrangler deploy`, version `6d88c15b-c49c-4fac-b98d-ab32e52deb91`).
- [ ] En attente de Tariq plus tard : 8 pistes audio (`app/assets/audio/*.mp3`) et nouveaux designs Soryn / Nyxara (`.png` + `.glb`).

### Chantier 3 (CODE & VERIFIE) : Profil Public 3D + Phase B (Stabilite) + Phase C (Securite & Conformite Stores)
- [x] **3.1 Profil Public Joueur 3D en lecture seule (`profil_public_page.dart`)** :
  - Podium 3 colonnes sur `profil_podium_bg.webp` : personnage 3D anime du joueur (`OtakuSkin3DViewer`), avatar avec son cadre equipe, vraie medaille de rang PNG, Division, pays, titre actif, stats publiques (XP, combats, victoires, taux, K.O. saison), onglet `Skins` en lecture seule (aucune edition possible, jamais de soldes OC/VC ni d'email), et bouton `AJOUTER` / statut `AMI`.
  - RPC securisee `get_public_player_profile(p_target_user_id UUID)` dans `scripts/v93_securite_observabilite.sql`.
- [x] **3.2 Phase B : Crashlytics, Analytics, Resilience Reseau & Signalement Questions** :
  - `firebase_crashlytics` + `firebase_analytics` integres (`pubspec.yaml`, `settings.gradle.kts`, `app/build.gradle.kts`, `main.dart`, `analytics_service.dart`).
  - Bandeau de perte reseau « Connexion perdue : Réessayer » + controle semver `min_app_version` dans `feature_flags_service.dart` et `app_shell.dart`.
  - Bouton « Signaler » dans `_buildFeedback()` de `combat_page.dart` -> table RLS `question_reports` (`v93_securite_observabilite.sql`) + route admin protegee JWT `admin_dashboard/app/api/reports/route.ts` + page `admin_dashboard/app/reports/page.tsx` + contact support dans `parametres_page.dart`.
- [x] **3.3 Phase C : Suppression de Compte In-App, Verrouillage SQL/RTDB & Documents Legaux** :
  - Bouton « Supprimer definitivement mon compte » (confirmation `SUPPRIMER`) dans `parametres_page.dart` -> action serveur `delete_account` dans `shop-tutorial-engine` supprimant `auth.users` et toutes les tables liees.
  - Trigger SQL `protect_profiles_sensitive_columns()` dans `scripts/v93_securite_observabilite.sql` interdisant au client de modifier directement `xp_totale`, `niveau`, `rang`, `is_vip`, `pts_division`, `division_id`, etc. (`progression_service.dart` passe par la RPC `ajouter_xp`) + `"economie": { ".read": false, ".write": false }` dans `scripts/firebase_database_rules.json`.
  - Pages publiques `/privacy` et `/terms` dans `admin_dashboard/app/` + lecteur integre `legal_pages.dart` accessible depuis `parametres_page.dart`.

#### Actions deploiement Chantier 3 executees le 24/11/2026 (100 % en production)
- [x] Executer `scripts/v93_securite_observabilite.sql` dans Supabase > SQL Editor.
- [x] Deployer l'Edge Function mise a jour : `npx supabase functions deploy shop-tutorial-engine`.
- [x] Publier `scripts/firebase_database_rules.json` (`economie: false`) dans Firebase Console > Realtime Database > Regles.
- [x] Revoquer l'ancienne cle privee FCM dans Google Cloud Console, mettre la nouvelle dans `FCM_SERVICE_ACCOUNT` sur Supabase et supprimer les fichiers locaux.

#### Correctif Demarrage Release V9.3.1 (25/11/2026 : valide sur Samsung physique)
- [x] **FIX-R8-01 (AGP 9 / R8 Full Mode + Firebase)** : R8 supprimait les constructeurs `public <init>()` des `ComponentRegistrar` Firebase (`CrashlyticsRegistrar`, `FirebaseMessagingKtxRegistrar`, `FirebaseInstallationsKtxRegistrar`), provoquant `NullPointerException: FirebaseCrashlytics component is not present` sur `Firebase.initializeApp()` en Release (alors que Debug/emulateur passait). Ajout de `app/android/app/proguard-rules.pro` branche dans `app/android/app/build.gradle.kts` (`proguardFiles`).
- [x] **FIX-BOOT-01 (Demarrage non bloquant & paysage immediat)** : `NotificationService().initialiser()` deplace en arriere-plan apres `runApp()` avec `try/catch` + timeouts dans `app/lib/features/notifications/notification_service.dart`, `Firebase.initializeApp()` et `Supabase.initialize()` securises avec ecran de secours `_StartupErrorApp` dans `app/lib/main.dart`, et `android:screenOrientation="sensorLandscape"` ajoute sur `MainActivity` dans `app/android/app/src/main/AndroidManifest.xml`.
- [x] **Verification terrain** : `usage.txt` confirme la conservation des constructeurs `ComponentRegistrar`, `flutter test` 11/11 OK, APK Release V9.3.1 (66,1 Mo) installe et lance sur Samsung physique avec ouverture directe, animation `SplashIntroOverlay` et demande de permission notifications propre.

#### Correctifs Terrain Samsung V9.3.2 (25/11/2026 : 4 retours Tariq traites et deployes en prod)
- [x] **FIX-3D-01 (3D WebView en Release)** : erreur `net::ERR_CLEARTEXT_NOT_PERMITTED` sur `http://127.0.0.1` (`model_viewer_plus`) corrigee proprement via `app/android/app/src/main/res/xml/network_security_config.xml` (HTTPS force sur Internet, HTTP autorise uniquement en boucle locale `127.0.0.1` / `localhost`) reference dans `AndroidManifest.xml`.
- [x] **FIX-INTRO-01 (Animation d'ouverture Planche & Cases de Manga)** : refonte complete de `app/lib/shared/splash_intro_overlay.dart` avec trace a l'encre de 4 cases de manga asymetriques + hachures de trame + lignes de vitesse radiales `shuchu-sen` + case hero centrale inclinée encadree blanc/orange autour du logo renard et du titre `OTAKU VERSE` (suppression de la barre de chargement generique).
- [x] **FIX-AUTH-01 (Boucle "J'ai deja un compte")** : remplacement de la verification `signedOut` dans `build()` de `AuthGate` (`app/lib/main.dart`) par un `StreamSubscription<AuthState>` dans `initState()` pour ne reinitialiser `_phaseADone` qu'une seule fois a la deconnexion, plus ajout du bouton `J'ai deja un compte · Se connecter` a l'etape 3 de `tutorial_phase_a_page.dart`.
- [x] **FIX-SQL-01 (Faille +300 OC en boucle & Trigger `service_role`)** : mise a jour du trigger `protect_profiles_sensitive_columns()` en production Supabase (`scripts/v93_1_fix_trigger_service_role.sql` + `scripts/v93_securite_observabilite.sql`) pour autoriser `service_role` (Edge Functions), verrou atomique + verification d'erreur sur `profiles.update()` dans `supabase/functions/shop-tutorial-engine/index.ts` (redeploye en prod) et garde anti-doublon dans `tutorial_service.dart`.

### Phases D et E (A VENIR APRES TEST CONJOINT TARIQ & HEAT — detail dans `ROADMAP_PUBLICATION_STORES.md`)
- [ ] **Phase D (Monetisation reelle)** : Google AdMob (SSV serveur), Google Play Billing & Apple IAP (comptes Stores requis), boutique Web Mobile Money optionnelle.
- [ ] **Phase E (Publication Stores)** : Build Android App Bundle obfusque (`flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info`), sauvegarde hors-ligne `upload-keystore.jks` + `key.properties`, mise en ligne HTTPS des pages `/privacy` et `/terms`, 14 jours de test ferme Google Play (12 testeurs), lancement public Palier 1 puis iOS App Store.
- [ ] **Contenus en attente** : 8 pistes audio (`app/assets/audio/*.mp3`), nouveaux visuels Soryn & Nyxara (`.png` + `.glb` animes), reimport Quiz V4.0 sur R2 apres retour de Heat.

---

## 5. POINT DE REPRISE POUR LA PROCHAINE SESSION

- **Etat actuel (24/11/2026)** : Chantiers 1, 2 et 3 100 % codes, testes (`dart analyze` 0 erreur, `flutter test` 11/11, `admin_dashboard` + `cloudflare_worker` `tsc` 0 erreur) et deployes en production (Supabase SQL V9.2+V9.3, 4 Edge Functions, FCM renouvele, RTDB `economie: false`, 10 `.glb` animes Mixamo sur Cloudflare R2).
- **Action immediate entre deux sessions** : Tariq et Heat testent ensemble le nouvel APK Release V9.3 sur leurs telephones en cochant `CAHIER_TESTS.md`.
- **Ordre de priorite a la prochaine session** :
  1. Traiter en priorite tous les retours / bugs / ajustements remontes par Tariq et Heat apres leur session de test sur `CAHIER_TESTS.md` (s'il y en a).
  2. Integrer les contenus des que Tariq ou Heat les fournit (8 pistes audio `.mp3`, nouveaux Soryn/Nyxara, fichiers Quiz V4.0 `.md`).
  3. S'il n'y a pas d'ajout ni de blocage terrain, enchainer directement sur ce qu'il reste pour publier sur les Stores : **Phase D** (AdMob + Google Play Billing / Apple IAP) puis **Phase E** (`.aab` obfusque + test ferme Google Play 14 jours / 12 testeurs + lancement Palier 1).
