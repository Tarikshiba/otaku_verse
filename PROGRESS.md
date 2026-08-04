# PROGRESS — Otaku Verse

Derniere mise a jour : 2026-08-04
Version en cours : V1.5 (COMPLETE) — Distribution en place
Module en cours : pret pour V2 (multijoueur temps reel)

## ATTENTION - CHANGEMENT DE DIRECTION IMPORTANT (2026-07-09)

Suite a un retour d'experience utilisateur, le concept a evolue en profondeur.
Voir ROADMAP_OTAKU_VERSE.md v2.1, section 6 "Le mode Combat" pour le detail complet.

Resume : le quiz solo classique (vertical, question/4 choix dans le vide) est
remplace par un mode combat horizontal contre un bot (PV, degats, combos,
K.O., 10 questions max). Le multijoueur reel reste en V2 comme prevu, mais
reutilisera ce moteur de combat.

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
- "V1.5 complete : redesign PDF, boite a lettres Supabase, edge function notifications, quetes, boutique 4 categories" (2026-08-03)
