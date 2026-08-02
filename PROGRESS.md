# PROGRESS — Otaku Verse

Derniere mise a jour : 2026-08-02
Version en cours : V1.5
Module en cours : social + classements + skins

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

### V1.5 (en cours)
- Systeme d'amis complet :
  - Table friends dans Supabase (sender/receiver, status pending/accepted/declined, RLS)
  - Pseudo obligatoire a l'inscription (unique, 3-20 chars, modifiable dans profil)
  - Champ last_seen + is_in_combat dans profiles (statut en ligne)
  - Service friends_service.dart (recherche, envoi/acceptation/refus demandes, liste amis, statut)
  - Ecran Amis connecte a Supabase (4 onglets : Tous, En ligne, En combat, Demandes)
  - Recherche de joueurs par pseudo (recherche auto en tapant)
  - Profil public d'un joueur (tap sur un ami → voir son profil + ajouter)
  - Point rouge anime sur icone Amis quand demande en attente (disparait au tap)
  - Statut "En combat" automatique (set au debut/fin du combat)
  - Presence "En ligne" mise a jour a chaque ouverture de l'app

- Classements :
  - Table profiles enrichie avec colonne country (pays choisi a l'inscription, non modifiable)
  - Selecteur de pays a l'inscription + possibilite pour anciens comptes de choisir (1 fois)
  - Service classement_service.dart (mondial, national, amis)
  - Ecran classement avec 3 tabs (Mondial/National/Amis)
  - Ex aequo geres (meme XP = meme position)
  - Top 3 en or/argent/bronze, highlight de sa propre position
  - Tap sur un joueur → profil public
  - Accessible depuis l'accueil (bouton "Classement")

- Partage de resultats :
  - Bouton PARTAGER sur l'ecran de resultat de combat
  - Capture de l'ecran en image PNG via RepaintBoundary
  - Partage natif Android (share sheet) avec texte + image
  - Packages : share_plus, path_provider

- Collection de skins :
  - Table skins (10 skins : commun/rare/epique/legendaire, deblocage par level ou XP)
  - Table player_skins (relation joueur-skin, equipped flag)
  - Service skin_service.dart (lister, debloquer, equiper, skin gratuit auto)
  - Ecran collection avec 2 onglets (Ma Collection / Boutique)
  - Cartes compactes en scroll horizontal (mode paysage)
  - Ecran detail skin : apercu 3D rotatif (drag), description, rarete, bouton debloquer/equiper
  - Accessible depuis le profil (bouton COLLECTION + tap sur skin)

## En cours

### Prochaines etapes immédiates (meme session)
- Boutique separee accessible depuis l'accueil (espace d'achat distinct de la collection)
- Ecran Parametres dans le profil (regrouper pseudo, pays, deconnexion + futurs reglages)

### Reste a faire V1.5
- Notifications push (Firebase Cloud Messaging — quand projet Firebase configure)

### Assets visuels (attente equipe designers de la commu)
1. Illustrations/artworks dans les cartes de modes (silhouettes personnages)
2. Banniere evenement avec vraie image
3. Vrais SVG de textures (remplacer les CustomPainter placeholder)
4. Avatar joueur (image custom au lieu de l'icone Material)
5. Assets de skins (vrais visuels de personnages au lieu des icones placeholder)

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

## Problemes connus / points d'attention
- Flutter non accessible depuis bash de Claude Code (Tariq doit tester manuellement)
- 20 questions One Piece en base (besoin d'enrichir massivement avant lancement — objectif 10 000)
- Le fallback local en cas d'erreur reseau considere la reponse comme fausse (acceptable pour la V1)
- Performances a surveiller sur telephones d'entree de gamme
- Smart App Control Windows 11 bloquait impellerc.exe → desactive (solution definitive)
- Overflow profil stats partiellement corrige (FittedBox + paddings reduits)

## Dernier commit pousse
- "Refonte design etapes 5-6-7 + profil : Amis console, textures, polish combat, profil Liquid Glass" (2026-07-29)
