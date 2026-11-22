# PROGRESS — Otaku Verse

Derniere mise a jour : 2026-11-22
Version en cours : V1.5.5 Consolidee — Calibrage V9.2 Finale & Lancement Progressif par Paliers
Document de reference : `CAHIER_MODIFICATIONS_DEV_OTAKU_VERSE.docx` (V9.2 Finale) + `OTAKU_VERSE_DA_LIQUID_GLASS.md`
Ancienne roadmap archivee : `archive/ROADMAP_OTAKU_VERSE.md`

---

## 1. ETAT DE LA BASE EXISTANTE (PRE-V9.2)

Le socle initial V1 a V5 (Auth Supabase, Combat Solo, Amis, Boite aux lettres, Skins, Verse Temps Reel Firebase, Saisons/Tournois, Boutique, Battle Royale, Guildes, 21 illustrations DA Liquid Glass, APK Release 1.0.0) a ete teste sur le terrain par Tariq et Heat.
Suite aux retours terrain, le projet passe sur la specification verrouillee **V9.2 Finale** : tout coder proprement, durcir la securite serveur, integrer la base de 1 281 697 questions (21 oeuvres) et piloter l'ouverture par paliers via `app_feature_flags`.

---

## 2. SECURITE PRIORITAIRE & MENAGE (ETAPE 1)

- [x] **CLEAN-01** : Extraction propre des 3 archives Drive dans `drive_sources/` (`01_resumes` 312 fichiers, `02_quiz_21_oeuvres` 5 999 fichiers `.md.docx`, `03_logos` 5 logos), suppression des `.zip`, ajout dans `.gitignore`, archivage de `ROADMAP_OTAKU_VERSE.md` dans `archive/`.
- [x] **SEC-01** : `scripts/fcm_secret_b64.txt` retire du suivi Git par Tariq (`git rm --cached`). Pense a regenerer la cle privee FCM dans Google Cloud Console si le depot etait deja pousse.
- [x] **SEC-02** : Authentification admin verifiee cote serveur via JWT Bearer (`admin_dashboard/lib/admin-auth.ts`) sur `/api/questions`, `/api/questions/import` et `/api/questions/upload-image` + validation stricte des champs + correction du parser import 13/14 colonnes (`npx tsc --noEmit` OK).
- [x] **SEC-03** : Suppression de `bonne_reponse` du `select()` client dans `app/lib/features/quiz/quiz_service.dart` (revelee apres clic via `valider-reponse`).
- [x] **SEC-04** : Verification du JWT cote serveur dans `supabase/functions/valider-reponse/index.ts` et dans la nouvelle Edge Function `supabase/functions/match-engine/index.ts`.
- [x] **SEC-05 (Socle SQL)** : Migration SQL V9.2 executee dans Supabase (`scripts/v92_socle_supabase.sql` : Success) et Edge Functions `valider-reponse` + `match-engine` (avec support hybride R2/Supabase) deployees en production.

---

## 3. CHECKLIST OFFICIELLE V9.2 (22 TICKETS)

### Economie, XP & Compteurs SQL
- [x] **ECO-01** (§1.1 — Backend SQL pret) : 4 compteurs SQL isoles (`xp_totale`, `oc_balance`, `vc_bonus` + `vc_paid`, `pts_*`) + `economy_ledger` + RPC `spend_verse_coins` (debite `vc_bonus` en 1er).
- [x] **ECO-02** (§1.2) : Toute depense d'XP en boutique, les Boosters d'XP, le Coffre Mystere XP et les VC contre pub ont ete supprimes (`skin_model.dart`, `skin_service.dart`, `monetisation_v4_service.dart`, `boutique_screen.dart`, `shop-tutorial-engine`).
- [x] **ECO-03** (§1.2-1.3 — Backend SQL & Edge Function prets) : Perte Nette Seche d'XP en defaite (des Niv. 6), 6 modes (Facile a Maitre + Adaptatif), erosion hebdomadaire douce (`apply_weekly_xp_erosion`).
- [x] **ECO-04** (§1.3 / §7.3) : Widget `OfficialRankBadge` permanent (`app/lib/shared/rank_badge.dart`) integre sur Accueil, Profil, Combat et Division (100 % independant des achats).
- [x] **ECO-05** (§1.4 / §7.5) : Arbitrage Frais d'Arene OC (SQL `get_arena_entry_fee` + `EconomyV92Service.fraisAreneOc` integre dans `combat_setup_page.dart` et `verse_division_page.dart`).
- [x] **ECO-06** (§1.4 / §2.1) : Bouton Roi "Doubler mes OC (x2)" en fin de match + Coup de Pouce (+40 OC si solde < frais) branches sur `match-engine`, 0 VC sur les pubs, plafond SQL 150 VC/saison.

### Boutique & Monetisation
- [x] **SHOP-01** (§2.1) : Convention unique des 5 Packs VC (Base + Bonus VC, remises unitaires -9,5 % / -18,8 % / -26,9 % / -33,7 % sur base 6,00 FCFA/VC) dans `boutique_screen.dart` + `shop-tutorial-engine`.
- [x] **SHOP-02** (§2.2-2.3) : 3 offres (Pass Sans Pub 1 An 4 500 FCFA, Pack Demarrage 6 500 FCFA 1x/compte, Abonnement VIP Mensuel 3 500 FCFA / 1er mois 2 500 FCFA et Annuel 29 900 FCFA + 8 privileges + 7 Stats Pro Verse Analytics dans `profile_page.dart`).
- [x] **SHOP-03** (§2.4) : Catalogue Goodies 100 % en VC (Classiques 350-500 VC, Epiques 700-900 VC, Fondateurs Legendaires Soryn `avatar_soryn_ether_watcher` & Nyxara `avatar_nyxara_twin_fangs` 1 200-1 500 VC + cosmetiques VC), sauf 1 Goodies tuto a 300 OC. Cadrage non coupe `UI-01` sur toutes les cartes et l'apercu 3D.

### UI/UX & Partage 9:16
- [x] **UI-01** (§3.2) : Avatars/Goodies non coupes (`SafeAvatarBox` avec `BoxFit.contain` + `Alignment.topCenter` + padding haut >= 12px) sur Accueil et Profil.
- [x] **UI-02** (§3.2) : Protection anti-overflow (`Flexible`/`Expanded` + `TextOverflow.ellipsis` + `SingleChildScrollView`) sur Accueil, Setup, Combat, Division et Classements.
- [x] **UI-03** (§3.2) : Auto-sizing des textes longs (15pt / 13.5pt / 12pt) dans les questions et boutons A/B/C/D de `combat_page.dart`.
- [x] **UI-04** (§3.2 / §6.5) : Bandeau dynamique d'affluence et cagnotte en haut de `classement_screen.dart` via RPC `get_leaderboard_pot_info`.
- [x] **UI-05** (§3.3 / §7.6) : Carte verticale 9:16 (1080x1920 via `RepaintBoundary` dans `victory_share_card.dart`) de Partage de Victoire en 1 clic branchee sur `combat_page.dart`, avec anonymisation par defaut du perdant, masquage des soldes OC/VC et option opt-in `allow_share_pseudo_friends` dans `parametres_page.dart`.

### Tutoriel, Communaute, Classements & Gameplay
- [x] **TUTO-01** (§4.1-4.2) : Tutoriel 2 Phases code (`tutorial_service.dart`, `tutorial_phase_a_page.dart`, `main.dart`, `app_shell.dart`, `shop-tutorial-engine`) : Phase A sans compte (choix anime, combat 5Q avec Haya!!/Combo x3/Kecchaku, +300 OC +100 XP, 1er Goodies 300 OC) + Phase B (6 etapes Coachmarks sur le Hub -> +25 VC + 100 OC + Titre "Initie du Verse").
- [x] **COMM-01** (§5.1 / §6.6) : Tarifs unifies dans `verse_communaute_page.dart` + `shop-tutorial-engine` (Donjon Otaku Forge 100 VC hors VIP, Salon Live JKLM 150 VC hors VIP, gratuits VIP, rejoindre = 0 VC ; Coop 2v2 = 0 VC / 525 PV ; Battle Royale aligne 350 PV / 40 Q).
- [x] **RANK-01** (§6.1-6.3) : Table des 7 scenarios d'issue de match sans cas orphelin + nouveaux seuils 10 Divisions (0 a 1 900+ pts) en production.
- [x] **RANK-02** (§6.7) : Push "Un ami t'a depasse" integre dans `match-engine` + `envoyer-notification` avec throttle strict serveur (`notification_throttles` : 1x/24h/ami, max 2/jour global, silence 22h-08h local via `timezone_offset_minutes`, opt-out dans `parametres_page.dart`).
- [x] **GAME-01** (§7.2-7.4) : Moteur V9.2 cable de bout en bout (`combat_page.dart` + `combat_service.dart` + `match-engine` + Cloudflare R2) : Double Timer 2 min + 20s/Q, 350 PV / 40 Q, Auto-Faute -5 PV, Haya!!, Combo multiples de 3, Mort Subite 0 PV simultane, 5 Malus Flutter et Seconde Chance Solo.

### Lancement Progressif par Paliers
- [x] **LAUNCH-01** (§8.1) : `app_feature_flags` + `feature_waitlist` deployes et lus au demarrage par `FeatureFlagsService`.
- [x] **LAUNCH-02** (§8.2) : `verse_division_page.dart` pilote par `division_matchmaking_mode` (`AI_ONLY` Semaine 1 -> 0 WebSocket, Bot IA calibre + bareme officiel, puis `HYBRID_5S`).
- [x] **LAUNCH-03** (§8.3) : Palier 1 actif sur `app_shell.dart` (Solo + Division ouverts ; Duel, Coop, Events, Battle Royale et Guildes affiches avec cadenas dore + bouton "M'alerter").

### Details fonctionnels & Base 21 Oeuvres
- [x] **FIX-01** : Parser d'import admin compatible 13 et 14 colonnes.
- [x] **FIX-02** : Compteur `_unreadMails` rafraichi sur l'accueil via `MailboxService`.
- [x] **FIX-03** : Quetes branchees sur les vraies stats du profil avec credit XP reel.
- [x] **FIX-04** : Liste des 21 oeuvres et arcs chargee dynamiquement dans `verse_duel_setup_page.dart`.
- [x] **DATA-01 (1 254 803 questions en ligne sur Cloudflare R2)** : 5 logos compresses (376 Ko) integres dans `app/assets/images/logos/` et `admin_dashboard/public/`. Les 105 shards `.json.gz` (133,08 Mo, 21 oeuvres) + `catalog.json` sont en ligne sur R2, le Worker tourne sur `https://otaku-verse-quiz-api.otakuverse-221.workers.dev` et les secrets Supabase (`QUIZ_WORKER_URL`, `WORKER_API_SECRET`) sont actives.

---

## 4. PROCHAINE ETAPE (TOUS LES 22 TICKETS V9.2 CODÉS)

1. Redeployer les 2 Edge Functions mises a jour pour `RANK-02` (`match-engine` et `envoyer-notification`).
2. Lancer `flutter pub get ; flutter analyze ; flutter test` dans `app/` pour verifier 0 erreur.
3. Generer l'APK Release (`flutter build apk --release`) et effectuer la session de test terrain avec Heat (Palier 1 : Tutoriel 2 phases, Solo 350 PV / 40 Q, Division AI_ONLY, Boutique V9.2, Partage 9:16).

## 5. DECISIONS TECHNIQUES & POINTS D'ATTENTION

- Base de donnees quiz : 1 281 697 questions sur 21 oeuvres exportees en `.md.docx` (645 Mo sur disque). Depasse la limite de 500 Mo de Supabase Free : recommande de garder Supabase Free pour tout le transactionnel (Auth, profils, economie, classements, feature flags) et d'heberger le catalogue questions en JSON gzippe (~150 Mo) sur Cloudflare R2 (10 Go gratuits, 0 frais egress) servi par un Cloudflare Worker (100 000 req/jour gratuites).
- Dossier doublon Windows `01_RÉSUMÉS (Sources Extraites & Traduites)-20261122T114703Z-1-001` verrouille depuis WSL par des chemins NTFS > 260 caracteres : ignore dans `.gitignore`, a supprimer sous Windows (PowerShell ou Explorateur).
