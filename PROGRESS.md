# PROGRESS — Otaku Verse

Derniere mise a jour : 2026-11-03
Version en cours : V2 (100% TERMINEE) -> Passage a la V3
Module en cours : verse (Salon amical personnalisable, Mode Coop, Anti-abandon, Regles Firebase)

## MISE A JOUR DE LA ROADMAP (2026-09-20)

La roadmap officielle a ete remplacee par une nouvelle version.
Changements cles par rapport a l'ancienne roadmap :
- Retour au decoupage clair des fonctionnalites : V1 (Solo MVP), V1.5 (Social), V2 (Verse Multijoueur avec Firebase), V3 (Saisons), V4 (Monetisation).
- La section 14 (Design/UX) de la nouvelle roadmap est obsolete. Le document OTAKU_VERSE_DA_LIQUID_GLASS.md est l'unique reference pour le design.
- L'architecture confirme l'utilisation de Supabase pour les donnees statiques et de Firebase exclusivement pour les duels en temps reel de la V2.
- La progression existante listee ci-dessous reste la source de verite. Les fonctionnalites deja developpees en V1 et V1.5 (y compris le moteur de combat) sont conservees.

## En cours : Corrections post-test et Refonte UI (2026-09-20)
- Refonte de l'Accueil (hub central façon Free Fire, retrait de la bottom nav bar).
- Mise en place du nouveau systeme de navigation avec boutons Retour.
- Correction des proportions du profil.
- Connexion des quetes a Supabase pour eviter les reclamations multiples.
- Ajout de la pastille de notification sur la boite de reception.
- Correction de la logique d'affichage des amis.
- Ajout de la barre de recherche et filtres par continent pour l'inscription (Pays).
- Refonte de l'ecran de parametrage du combat (sans scroll, anime).

## Termine et teste

### V1 (complete)
- Etape 0 : structure de dossiers, .gitignore, .env.example, repo Git init
- Etape 1 : projet Flutter cree, compile et tourne sur emulateur Android (Pixel 8)
- Etape 2 : Supabase connecte (URL + anon key, test OK)
- Etape 3 : Design system (theme.dart, violet electrique #7B2FF7)
- Etape 4 : Authentification (inscription, connexion, deconnexion)
- Etape 5 : 20 questions One Piece importees dans Supabase via script Node.js
- Etape 6 : moteur de combat complet (PV, degats, combo, bot, parametrage, paysage force, animations shake + onomatopees)
- Etape 7 : progression (XP, niveaux, rangs) + table profiles dans Supabase, affichage XP en fin de combat
- Etape 8 : ecran profil (stats, niveau, rang, barre XP, skin rotatif, taux de victoire)
- Etape 9 : recompenses (connexion quotidienne +15 XP, 3 defis du jour +30 XP chacun, badges)
- Etape 10 : ecran accueil style eFootball (top bar, banniere evenement, navigation tabs, boutons raccourcis, quitter, deconnexion dans profil)
- Etape 11 : dashboard admin Next.js (login securise Drx/Heat, gestion questions CRUD, vue utilisateurs, API routes avec service_role key)
- Etape 12 : validation serveur — Edge Function "valider-reponse" deployee sur Supabase (anti-triche, le serveur verifie les reponses et calcule les degats)
- Refonte design complete (DA V2.1 "Apple rencontre Shonen Jump") — 7 sous-etapes

### V1.5 (COMPLETE — 2026-08-03)
- Systeme d'amis complet (recherche par pseudo, ajout, statut en ligne/en combat, demandes)
- Classements (mondial, national, amis — ecran 3 tabs, top 3 medailles)
- Partage de resultats (capture PNG + share sheet Android)
- Collection de skins (10 skins, deblocage par level/XP, ecran detail 3D rotatif)
- Notifications push (FCM API V1, Edge Function, trigger SQL sur demande d'ami)
- Ecran Parametres (compte, graphismes, audio, session)
- Redesign complet selon PDF "Disposition et design" (tab bar 5 onglets, accueil Free Fire, boutique 4 categories, quetes, boite a lettres)
- Boite a lettres (table mailbox Supabase, rewards reclames manuellement)
- Boutique separee de la Collection (onglet tab bar = achat, modal profil = possedes)

### Hebergement / Distribution (COMPLETE — 2026-08-04)
- Keystore de signature cree (upload-keystore.jks, alias otaku-verse, validite 10000 jours)
- Build Gradle configure pour signer en release (key.properties)
- APK release genere (app-release.apk, 51.8 MB)
- Firebase App Distribution configure (projet otaku-verse-6e05e)
- Groupe "testers" cree (shibatarik129@gmail.com, constantinove16@gmail.com)
- APK uploade et invitations envoyees par email
- Script upload-apk.bat pour les futures mises a jour

## Prochaine etape

### Prochaine session — Dashboard Admin & Import en Masse
- Coder la fonctionnalite d'importation de questions en masse (via upload de fichier .md ou .csv) directement depuis le Dashboard Admin (Next.js).
- Parser et inserer les nouveaux fichiers fournis par Heat (`naruto introduction quiz.md` et `otaku verse east blue v2.md`) via ce nouveau systeme.
- Si le temps le permet : entamer la V2

### V2 — Multijoueur temps reel
Objectif : permettre aux joueurs de s'affronter en duel live (1v1).

Etapes prevues :
1. Firebase Realtime Database — setup + regles de securite
2. Matchmaking (file d'attente, appairage par niveau/rang)
3. Mode Duel 1v1 (defier un ami via notif, ou trouver un adversaire aleatoire)
4. Combat synchronise (memes questions, timer partage, PV en temps reel)
5. Mode Division (classement PvP separe du classement IA, rangs competitifs)
6. Systeme de clans / equipes
7. Separation XP IA vs XP PvP (comme eFootball)
8. Evenements / saisons (a preciser)

### Avant la V2 — a faire idealement
- Enrichir la base de questions (objectif 10 000, actuellement 20)
- Brancher les quetes sur Supabase (actuellement donnees statiques)
- Remplir les articles/boosters/promos dans la boutique (actuellement placeholders)
- Tester les performances sur telephones entree de gamme

## Decisions techniques prises
- Couleur d'accent : violet electrique #7B2FF7
- Auth : email sans confirmation (dev)
- Navigation auth : StreamBuilder dans AuthGate
- RLS questions : lecture pour anon + authenticated
- Import questions : service_role key (bypass RLS)
- Timer combat : 20 secondes par question
- PV de depart : 100 pour chaque combattant
- Degats normaux : 15 PV / Degats combo (attaque speciale) : 30 PV
- Seuil combo : 3 bonnes reponses d'affilee
- Bot : probabilite de reussite selon difficulte (facile 30%, moyen 50%, difficile 70%, expert 85%)
- Format de combat : max 10 questions, K.O. immediat possible, sinon decompte PV
- Dashboard admin : acces restreint a Drx@otaku.admin et Heat@otaku.admin
- Validation reponses : Edge Function cote serveur (fallback local si hors-ligne)
- Pseudo : unique, 3-20 chars (lettres/chiffres/underscore), obligatoire a l'inscription
- Pays : choisi a l'inscription, non modifiable apres (classement national)
- Skins : deblocage par niveau ou depense XP, un seul equipe a la fois
- Partage : capture RepaintBoundary + Share.shareXFiles (share_plus)
- Notifications : FCM API V1 + Edge Function + trigger pg_net
- Boite a lettres : table mailbox Supabase, rewards reclames manuellement
- Boutique : onglet tab bar (achat), Collection : modal profil (possedes)
- Signature APK : keystore JKS, alias otaku-verse, key.properties (gitignore)
- Distribution : Firebase App Distribution, groupe "testers", upload via CLI

## Problemes connus / points d'attention
- Flutter non accessible depuis bash de Claude Code (Tariq doit tester manuellement)
- 20 questions One Piece en base (besoin d'enrichir massivement avant lancement — objectif 10 000)
- Le fallback local en cas d'erreur reseau considere la reponse comme fausse (acceptable pour la V1)
- Performances a surveiller sur telephones d'entree de gamme
- Smart App Control Windows 11 bloquait impellerc.exe → desactive (solution definitive)
- Le fichier scripts/fcm_secret_b64.txt est dans le repo (contient le service account encode) — a retirer avant open source
- Quetes : donnees statiques pour l'instant (a brancher sur Supabase comme mailbox)
- Articles/Boosters/Promos dans la boutique : placeholders (a remplir quand les items existent)
- iOS : necessite un Mac + compte Apple Developer (99$/an) — pas disponible pour l'instant

## Dernier commit pousse
- `819e0bd` : "feat(v2): synchro combat temps reel, securisation Edge Function, Mode Division et images questions admin" (2026-11-03)
- En cours de push : "feat(v2): salon amical personnalisable, mode cooperatif, systeme anti-abandon et regles firebase" (2026-11-03)

## 5. ÉTAPES V2 RÉALISÉES (2026-11-03)

1. **Amélioration de la synchronisation de combat (FAIT — 2026-11-03)**
   - Enregistrement de `answeredIndex` par joueur dans Firebase et passage à la question suivante uniquement quand les deux joueurs ont répondu ou que le chronomètre de 15s est écoulé (`_passerQuestionSuivante`).
2. **Supabase Edge Functions pour la V2 (FAIT — 2026-11-03)**
   - Suppression de `bonneReponse` dans Firebase (`matchmaking_service.dart`), validation des réponses et combos V2 via l'Edge Function `valider-reponse`, et ajout de l'action serveur `cloturer_match_verse` pour attribuer l'XP et calculer les points de division en fin de match.
3. **Mode Division (Classé) (FAIT — 2026-11-03)**
   - Nettoyage des doublons de syntaxe dans `combat_service.dart`.
   - File d'attente globale dans `matchmaking_service.dart` avec appairage réel entre joueurs humains (±2 divisions) et repli sur bot adaptatif au bout de 10s.
   - Gestion complète des 10 divisions (`Académie` à `Légende du Verse`), des points de division et de l'XP PvP dans `verse_division_page.dart` et `verse_combat_page.dart`.
4. **Finalisation du Dashboard Admin (FAIT — 2026-11-03)**
   - Ajout de la route API `/api/questions/upload-image` (vérification MIME et taille max 5 Mo, stockage Supabase Storage `questions-images`), mise à jour de l'interface `app/questions/page.tsx` avec aperçu miniature, script SQL `scripts/add_question_image_column.sql` et affichage de l'image dans `verse_combat_page.dart`.

## 6. PROCHAINES ÉTAPES (SELON ROADMAP_OTAKU_VERSE.md)

### A. Déploiement, correctifs initiaux et cahier de tests (FAIT — 2026-11-03)
1. **SQL & Edge Function déployés** : `scripts/add_question_image_column.sql` exécuté sur Supabase (`Success. No rows returned`) et Edge Function `valider-reponse` redéployée en production sur `houbjgugzznytilkfwyf`.
2. **Upload d'image Admin validé** : ajout et persistance d'une image sur une question depuis `admin_dashboard/app/questions/page.tsx` vérifiés.
3. **Correctifs UI & Firebase V2** :
   - Suppression de l'icône de cadenas forcée sur le sélecteur de mode de l'accueil (`app/lib/shared/app_shell.dart`).
   - Correction du dépassement vertical de 22 pixels en affichage horizontal sur `app/lib/features/verse/verse_division_page.dart`.
   - Création des règles de sécurité Firebase Realtime Database (`scripts/firebase_database_rules.json`) et sécurisation des appels dans `matchmaking_service.dart`.
4. **Cahier de tests créé** : ajout de `CAHIER_TESTS.md` à la racine pour centraliser tous les tests sur téléphones réels (Tariq & Heat) après la compilation de l'APK.

### B. Finition de la V2 (Section 9 de la Roadmap) — FAIT (2026-11-03)
1. **Paramètres personnalisables en Duel Amical (FAIT)** : choix de l'anime, de l'arc, de la difficulté et du nombre de questions lors de la création d'un salon privé (`verse_duel_setup_page.dart` & `matchmaking_service.dart`).
2. **Mode Coopératif (Coop) (FAIT)** : 2 joueurs alliés (ou duo avec l'IA alliée `A.K.I.N.A`) contre les 200 PV du Gardien du Verse, avec bonus de synergie, PV d'équipe partagés et récompenses (`verse_coop_page.dart` & `app_shell.dart`).
3. **Système Anti-abandon (Section 9.6) (FAIT)** : boîte de confirmation d'abandon dans `verse_combat_page.dart`, pénalité de -30 points, compteur `abandonsConsecutifs`, blocage temporaire (`cooldownUntil` de 5 min au 1er abandon, 30 min dès 3 abandons consécutifs) vérifié dans `verse_division_page.dart` et victoire automatique attribuée à l'adversaire.

### C. Passage à la V3 — Saisons, Événements & Compétition avancée (Section 10 de la Roadmap)
1. **Saisons (8 semaines)** : classement saisonnier dédié, thème visuel par saison, questions réservées, récompenses de fin de saison et soft reset des divisions (max -2 divisions).
2. **Événements temporaires (3 à 7 jours)** : événements thématiques par anime avec classement dédié et récompenses en édition limitée.
3. **Tournois** : phase de groupes (score cumulé sur 10 duels) puis finale Top 8 en élimination directe sur une semaine.
4. **Missions longue durée** : objectifs de carrière (100 duels Verse, Division 5, 5 000 questions réussies) débloquant des titres et badges exclusifs.

### D. V4 & V5 (Sections 11 et suite de la Roadmap)
1. **V4 Monétisation** : monnaie virtuelle Verse Coins, publicités inter-quiz et récompensées (opt-in), Pass Premium mensuel et boutique cosmétique complète.
2. **V5 Expansion** : Battle Royale Quiz et système de Guildes / Clans.
