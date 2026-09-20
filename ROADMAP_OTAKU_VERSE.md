**OTAKU VERSE**

*Cahier des Charges & Roadmap Technique*

Version 1.0 — Document de référence projet

Auteurs : Tariq (Dr. X) × Heat

# 1. STACK TECHNIQUE RETENUE

## 2.1 Application mobile — Flutter

Pourquoi Flutter :

- Un seul codebase pour iOS et Android (iPhones, iPads, Android phones et tablettes)

- Performances natives (pas de WebView)

- Architecture modulaire native (packages, providers, modules indépendants)

- Communauté large, excellent support Google

- Idéal pour les animations riches (Verse, récompenses, badges)

**Langage : Dart**

## 2.2 Backend — Supabase (principal) + Firebase (temps réel Verse)

### Supabase

- Base de données PostgreSQL managée

- Authentification intégrée (email, Google, Apple, Discord)

- API REST + Realtime channels

- Storage pour les assets (avatars, badges, images)

- Dashboard admin natif pour la BDD

- Open source, scalable, tarification prévisible

### Firebase (en complément pour le Verse)

- Firestore ou Realtime Database pour les duels live (latence \< 100ms)

- Firebase Cloud Messaging (notifications push iOS + Android)

### Pourquoi cette combinaison

- Supabase gère tout le data statique (questions, profils, classements, récompenses)

- Firebase gère uniquement la couche temps réel critique (duels live)

- Les deux sont des clouds managés, pas besoin de VPS à gérer soi-même

## 2.3 Backend logique métier — Supabase Edge Functions

- Fonctions serverless en TypeScript/Deno

- Calcul des scores, validation des réponses, attribution des récompenses

- Logique anti-triche côté serveur

- Déclencheurs automatiques (fin de saison, attribution de badges, classements)

## 2.4 Dashboard Admin — Next.js

- Application web séparée (pas dans l'app mobile)

- Next.js + TypeScript + Tailwind CSS

- Connecté à Supabase via l'API admin

- Accès restreint par rôles (super admin, modérateur, éditeur de contenu)

## 2.5 Schéma d'ensemble

> \[App Flutter iOS/Android\]
>
> \|
>
> \| HTTPS / WebSocket
>
> \|
>
> \[Supabase\] \<-\> \[Firebase Realtime DB\] (duels live uniquement)
>
> \|
>
> +-- PostgreSQL (questions, profils, classements, recompenses)
>
> +-- Auth (comptes utilisateurs)
>
> +-- Storage (avatars, badges, assets)
>
> +-- Edge Functions (logique metier, anti-triche, calculs)
>
> \|
>
> \[Dashboard Admin Next.js\] \<-\> \[Supabase Admin API\]

# 2. ARCHITECTURE GÉNÉRALE

## 3.1 Principe fondamental : Modularité stricte

Chaque module est indépendant. Un bug dans le système de boutique ne casse pas le quiz. L'ajout d'un nouveau mode de jeu ne touche pas le système de progression.

## 3.2 Modules principaux

| **Module**    | **Rôle**                                | **Dépendances**          |
|---------------|-----------------------------------------|--------------------------|
| auth          | Inscription, connexion, sessions        | Aucune                   |
| profile       | Profil joueur, stats, personnalisation  | auth                     |
| quiz_engine   | Sélection et distribution des questions | questions_db             |
| questions_db  | Base de données des questions           | Aucune                   |
| progression   | XP, niveaux, rangs, badges, titres      | quiz_engine, profile     |
| verse         | Duels temps réel, divisions, coop       | quiz_engine, progression |
| social        | Amis, invitations, activité             | profile                  |
| events        | Événements, saisons, tournois           | quiz_engine, progression |
| rewards       | Récompenses, collections, boutique      | progression              |
| monetization  | Pay-to-win, publicités                  | rewards                  |
| notifications | Push, in-app                            | Tous modules             |
| admin         | Dashboard back-office                   | Tous modules             |

> *Tu valides heat ? C’est l’architecture la plus saine et viable que j’ai trouvé. (OUI JE VALIDE, ON AJUSTERA APRES S’IL LE FAUT VRAIMENT)*

# 3. BASE DE DONNÉES DES QUESTIONS

## 4.1 Format source recommandé : Markdown structuré (.md)

Le format .md est recommandé car il est lisible, parsable, versionnable sur Git et compatible avec tous les éditeurs.

### Exemple de question en .md

> ---
>
> id: OP_001_0042
>
> anime: One Piece
>
> arc: Alabasta
>
> chapitre: 155
>
> type: personnage
>
> difficulte: moyen
>
> tags: \[capitaine, equipage, chapeau-de-paille\]
>
> ---
>
> Question : Quel est le nom du capitaine de l'equipage du Chapeau de Paille ?
>
> \- A: Zoro
>
> \- B: Nami
>
> \- C: Monkey D. Luffy
>
> \- D: Shanks
>
> Bonne reponse : C
>
> Explication : Monkey D. Luffy est le fondateur et capitaine...

## 4.2 Structure de la table PostgreSQL

> CREATE TABLE questions (
>
> id TEXT PRIMARY KEY,
>
> anime TEXT NOT NULL,
>
> arc TEXT,
>
> chapitre TEXT,
>
> type TEXT NOT NULL,
>
> difficulte TEXT NOT NULL, -- facile, moyen, difficile, expert
>
> question TEXT NOT NULL,
>
> choix_a TEXT NOT NULL,
>
> choix_b TEXT NOT NULL,
>
> choix_c TEXT NOT NULL,
>
> choix_d TEXT NOT NULL,
>
> bonne_reponse CHAR(1) NOT NULL,
>
> explication TEXT,
>
> tags TEXT\[\],
>
> statut TEXT DEFAULT 'actif',
>
> frequence INTEGER DEFAULT 0,
>
> taux_reussite FLOAT DEFAULT 0.0,
>
> mode_solo BOOLEAN DEFAULT TRUE,
>
> mode_verse BOOLEAN DEFAULT TRUE,
>
> reserve_event BOOLEAN DEFAULT FALSE,
>
> created_at TIMESTAMP DEFAULT NOW()
>
> );

## 4.3 Reformulation Solo vs Verse

Le moteur détecte le mode actif et reformule la question dynamiquement.

- Solo : "Quel est le nom du capitaine de l'équipage du Chapeau de Paille ?" (complet, pédagogique)

- Verse : "Qui commande l'équipage du Chapeau de Paille ?" (court, percutant, compétitif)

Recommandation : champ pré-généré pour les 100 000 premières questions, Edge Function pour les ajouts futurs.

## 4.4 Moteur de sélection — Algorithme

> 1\. Recup filtres (anime, difficulte, mode)
>
> 2\. Exclure questions vues dans les 48h par le joueur
>
> 3\. Selectionner N questions :
>
> \- 30% facile / 40% moyen / 20% difficile / 10% expert
>
> \- Max 3 questions du meme type par partie de 10
>
> 4\. Reformuler selon le mode (solo/verse)
>
> 5\. Envoyer le lot chiffre au client
>
> 6\. Valider CHAQUE reponse cote serveur (jamais cote client)
>
> 7\. Fin de quiz : calcul score + XP + badges → profil

Donc pour les Q/R qu’on a déjà si tu me les envoie en pdf je vais les converti en format que le programme comprend.

# 5. FONCTIONNALITÉS — VUE GLOBALE

## Légende des versions

| **Symbole** | **Version**      | **Description**                            |
|-------------|------------------|--------------------------------------------|
| ✅ V1       | MVP              | Premier lancement — socle de l'application |
| 🔶 V1.5     | Post-lancement   | Social, classements, notifications         |
| 🟦 V2       | Le Verse         | Multijoueur temps réel, divisions          |
| 🟪 V3       | Saisons & Events | Contenu saisonnier, tournois               |
| 🟥 V4       | Monétisation     | Pay-to-win, boutique, abonnement           |
| ⬛ V5       | Expansion        | Modes avancés, clans, mondial              |

## Tableau complet des fonctionnalités

| **Fonctionnalité**                   | **Version** | **Priorité** |
|--------------------------------------|-------------|--------------|
| Inscription / Connexion              | ✅ V1       | Critique     |
| Profil joueur de base                | ✅ V1       | Critique     |
| Quiz Solo rapide                     | ✅ V1       | Critique     |
| Quiz par anime / difficulté          | ✅ V1       | Haute        |
| Système XP & Niveaux                 | ✅ V1       | Critique     |
| Rangs (Débutant → Légende)           | ✅ V1       | Haute        |
| Défis quotidiens                     | ✅ V1       | Haute        |
| Badges & Succès de base              | ✅ V1       | Moyenne      |
| Récompense de connexion quotidienne  | ✅ V1       | Haute        |
| Dashboard Admin V1                   | ✅ V1       | Critique     |
| Classement global + national         | 🔶 V1.5     | Haute        |
| Système d'amis                       | 🔶 V1.5     | Moyenne      |
| Notifications push                   | 🔶 V1.5     | Haute        |
| Partage résultats                    | 🔶 V1.5     | Basse        |
| Duel temps réel (1v1)                | 🟦 V2       | Critique     |
| Matchmaking par rang                 | 🟦 V2       | Critique     |
| Divisions & montée/descente de grade | 🟦 V2       | Critique     |
| Partie privée via code invitation    | 🟦 V2       | Haute        |
| Mode Coopératif (Coop)               | 🟦 V2       | Haute        |
| Saisons complètes                    | 🟪 V3       | Critique     |
| Événements temporaires               | 🟪 V3       | Haute        |
| Tournois                             | 🟪 V3       | Haute        |
| Missions longue durée                | 🟪 V3       | Moyenne      |
| Publicités in-app                    | 🟥 V4       | Critique     |
| Monnaie virtuelle (Verse Coins)      | 🟥 V4       | Critique     |
| Boutique cosmétique                  | 🟥 V4       | Haute        |
| Abonnement Premium                   | 🟥 V4       | Haute        |
| Battle Royale Quiz                   | ⬛ V5       | Moyenne      |
| Guildes / Clans                      | ⬛ V5       | Haute        |
| Classement mondial                   | ⬛ V5       | Haute        |

# 6. ROADMAP VERSIONNÉE

## Vue d'ensemble

> V1 ──────────── V1.5 ──────── V2 ──────────── V3 ──────────── V4 ──── V5
>
> MVP Solo Social & Le Verse Saisons & Moneti. Expansion
>
> Quiz Engine Classements Multijoueur Événements Boutiq. Avancés
>
> Profils Amis Temps Réel Tournois Abo. Clans
>
> Progression Notifs Divisions Missions PtW Mondial
>
> Admin V1 Partage Coop + Invit. Long terme

## Durées estimées et conditions de passage

| **Version**       | **Durée estimée** | **Condition de passage à la suivante**    |
|-------------------|-------------------|-------------------------------------------|
| V1 — MVP          | 4–8 Semaine       | Tests validés, app stable iOS + Android   |
| V1.5 — Social     | 1–2 mois          | Retours utilisateurs V1 intégrés          |
| V2 — Verse        | 2–3 mois          | Infra temps réel testée sous charge       |
| V3 — Saisons      | 2–3 mois          | Base utilisateurs active (events viables) |
| V4 — Monétisation | 1–2 mois          | Modèle éco validé avec base de joueurs    |
| V5 — Expansion    | En continu        | —                                         |

# 7. V1 — MVP DÉTAILLÉ

> *Bien sur je ne compte pas tout créer en mm temps mais de manière versionner, parce que faut eviter les crash*

## 7.1 Écrans V1

### Onboarding (3 écrans max)

- Splash screen + logo animé

- Inscription (pseudo, email, mot de passe) ou connexion Google/Apple

- Choix du pseudo + anime préféré + avatar (grille d'avatars fixes)

- → Redirection vers l'Accueil

### Accueil

- Bandeau profil (avatar, pseudo, niveau, XP bar)

- Bouton principal JOUER MAINTENANT (Quiz Rapide)

- Carte "Défi du Jour" avec progression visuelle

- Carte "Récompense quotidienne" (coffre à ouvrir)

- Accès rapide : Classement, Mon Profil

- Bannière événement (vide en V1, préparée pour V3)

### Menu Jouer

- Quiz Rapide (sélection auto, toutes œuvres)

- Quiz par Anime (liste des animes disponibles)

- Quiz par Difficulté (Facile / Moyen / Difficile / Expert)

- Quiz Personnalisé (anime + difficulté + nombre de questions)

### Écran de Quiz

- Question en haut (texte)

- 4 choix (boutons A / B / C / D)

- Timer visuel (cercle ou barre)

- Indicateur de progression (Question 3/10)

- Score en temps réel

- Animation bonne/mauvaise réponse + explication

### Résultat de fin de Quiz

- Score final (étoiles 1–3)

- XP gagné + montée de niveau si applicable

- Badges débloqués

- Boutons : Rejouer / Retour Accueil / Voir Classement

### Profil

- Avatar + pseudo + rang + titre actif

- Statistiques : quiz joués, bonnes réponses, taux de réussite, XP totale

- Badges obtenus

- Historique des dernières parties

## 7.2 Système XP & Progression V1

| **Action**              | **XP gagnée** |
|-------------------------|---------------|
| Quiz terminé            | +20 XP        |
| Bonne réponse           | +10 XP        |
| Quiz sans faute         | +50 XP bonus  |
| Défi quotidien complété | +30 XP        |
| Connexion quotidienne   | +15 XP        |
| Premier quiz du jour    | +10 XP bonus  |

## 7.3 Rangs V1 (noms à finaliser avec Heat// JE VALIDE)

| **Rang**        | **Niveau requis** |
|-----------------|-------------------|
| Débutant        | 1–5               |
| Apprenti Otaku  | 6–15              |
| Passionné       | 16–30             |
| Expert          | 31–50             |
| Maître du Verse | 51–75             |
| Légende         | 76+               |

*Courbe de progression : XP requise pour passer au niveau N = 100 × N × 1.2*

## 7.4 Défis quotidiens V1

Générés automatiquement chaque jour à minuit. 3 défis par joueur :

| **Défi**                    | **Récompense**            |
|-----------------------------|---------------------------|
| Terminer 3 quiz             | +50 XP + 10 Coins         |
| Obtenir 15 bonnes réponses  | +30 XP                    |
| Terminer un quiz sans faute | +80 XP + Badge temporaire |
| Jouer sur un anime précis   | +40 XP                    |
| Réussir un quiz Expert      | +60 XP                    |

## 7.5 Badges V1 (liste de base)

| **Badge**                 | **Condition de débloquage** |
|---------------------------|-----------------------------|
| Premier Pas               | Terminer son premier quiz   |
| Perfectionniste           | Premier sans-faute          |
| Fidèle                    | 7 connexions consécutives   |
| Chasseur de Connaissances | 100 bonnes réponses         |
| Passionné One Piece       | 10 quiz One Piece terminés  |
| Montée en Grade           | Atteindre le niveau 10      |
| Challenger                | Atteindre le rang Expert    |

## 7.6 Données techniques V1

- Nombre minimum de questions au lancement : 10 000 (5 animes minimum)

- Animes recommandés V1 : One Piece, Naruto, Dragon Ball, Jujutsu Kaisen, Bleach

- Temps de chargement cible : \< 2 secondes pour lancer un quiz

- Compatibilité : iOS 14+ / Android 8+

# 8. V1.5 — CLASSEMENTS & VERSE SOCIAL

> *Objectif V1.5 : Ajouter la dimension sociale et compétitive légère. Le joueur commence à se mesurer aux autres.*

## 8.1 Nouvelles fonctionnalités

### Classements complets

- Classement mondial (top 1000 visible, position du joueur toujours affichée)

- Classement national (par pays détecté à l'inscription)

- Classement par anime

- Classement entre amis

### Système d'amis

- Recherche par pseudo

- Envoi/acceptation de demandes d'amis

- Fil d'activité des amis (badge obtenu, niveau atteint, record battu)

- Défi entre amis asynchrone (quiz identique, comparaison de score)

### Notifications push

- Rappel défi quotidien (configurable par le joueur)

- Alerte : un ami t'a dépassé au classement

- Récompense disponible

- Nouvel événement (préparation V3)

### Partage de résultats

- Carte de résultat partageable générée automatiquement

- Contient : score, anime, rang, pseudo, logo Otaku Verse SN (le SN il faut l’enlever)

- Compatible Instagram, WhatsApp, TikTok

## 8.2 Formule de score de classement

*Score = (XP totale × 0.4) + (taux de réussite × 1000 × 0.3) + (quiz joués × 2 × 0.3)*

# 9. V2 — LE VERSE (MULTIJOUEUR TEMPS RÉEL)

> *Objectif V2 : Introduire le mode compétitif inspiré d'eFootball. Le joueur peut affronter d'autres joueurs en temps réel, monter en division et jouer avec ses amis.*

## 9.1 Architecture technique Verse

> \[Joueur A - Flutter\] \<-\> \[Firebase Realtime DB\] \<-\> \[Joueur B - Flutter\]
>
> \|
>
> \[Supabase Edge Function\]
>
> (validation, scores, classement)

### Flow d'un duel

- 1\. Joueur A appuie sur "Trouver un duel"

- 2\. Matchmaking Edge Function cherche un adversaire de rang similaire (±2 divisions)

- 3\. Si trouvé en \< 30s → match créé dans Firebase

- 4\. Si non trouvé → bot adaptatif ou file d'attente étendue

- 5\. Les deux joueurs reçoivent les MÊMES questions en même temps

- 6\. Chaque réponse est envoyée au serveur immédiatement

- 7\. Timer par question : 15 secondes (géré côté serveur)

- 8\. En fin de duel : Edge Function calcule les scores et met à jour les divisions

## 9.2 Système de Divisions (inspiré eFootball)

| **Division** | **Nom suggéré**  | **Points requis** |
|--------------|------------------|-------------------|
| 10           | Académie         | 0–99              |
| 9            | Genin            | 100–249           |
| 8            | Chunin           | 250–499           |
| 7            | Jonin            | 500–849           |
| 6            | Capitaine        | 850–1 299         |
| 5            | Vice-Amiral      | 1 300–1 849       |
| 4            | Amiral           | 1 850–2 499       |
| 3            | Yonko            | 2 500–3 249       |
| 2            | Hokage           | 3 250–3 999       |
| 1            | Légende du Verse | 4 000+            |

## 9.3 Système de points Verse

| **Résultat** | **Points**                                  |
|--------------|---------------------------------------------|
| Victoire     | +25 points (+bonus si rang supérieur battu) |
| Défaite      | -15 points (-5 si rang très inférieur)      |
| Match nul    | +5 points chacun                            |
| Abandon      | -30 points                                  |

## 9.4 Modes du Verse V2

### Duel Classé

- Matchmaking automatique par division

- Impact direct sur le classement Verse

- Récompenses à chaque victoire

### Duel Amical (via code d'invitation)

- Le joueur génère un code à 6 caractères

- L'ami le saisit et rejoint la salle

- Aucun impact sur le classement

- Paramètres personnalisables (anime, difficulté, nombre de questions)

### Mode Coopératif (Coop)

- 2 joueurs contre le quiz (pas l'un contre l'autre)

- Questions partagées, réponses combinées

- Score d'équipe, récompenses partagées

- Disponible entre amis ou via matchmaking

## 9.5 Matchmaking — Règles

> Recherche adversaire :
>
> Division identique → timeout 10s
>
> Division ±1 → timeout 20s
>
> Division ±2 → timeout 30s
>
> Aucun adversaire → bot adaptatif ou file etendue
>
> Bot adaptatif :
>
> \- Simule un adversaire au meme niveau
>
> \- Indicateur discret "Entrainement" affiché
>
> \- Recompenses legerement reduites vs duel humain

## 9.6 Anti-abandon

- Abandon avant la fin : -30 points + cooldown 5 minutes

- 3 abandons consécutifs : cooldown 30 minutes

- L'adversaire reçoit la victoire + bonus

# 10. V3 — SAISONS, ÉVÉNEMENTS & COMPÉTITION AVANCÉE

> *Objectif V3 : Créer un calendrier de contenu qui donne une raison de revenir chaque semaine.*

## 10.1 Saisons

- Durée : 8 semaines par saison

- Classement saisonnier dédié (repart de zéro chaque saison)

- Pass Saison (gratuit + premium — voir V4)

- Récompenses exclusives à débloquer par palier

- Thème visuel par saison (ex : Saison 1 "L'Ère des Pirates" = One Piece)

- Questions réservées à cette saison débloquées

### Fin de saison

- Distribution des récompenses selon rang final

- Archivage du classement (visible sur les profils)

- Annonce de la saison suivante

- Soft reset des divisions Verse (protection : max -2 divisions)

## 10.2 Événements temporaires

- Durée : 3 à 7 jours

- Thème : un anime spécifique (ex : "Semaine Jujutsu Kaisen")

- Questions exclusives débloquées uniquement pendant l'événement

- Récompenses limitées (badges, avatars, titres "Édition Limitée")

- Classement événementiel dédié

### Calendrier type

> Semaine 1-2 : Événement One Piece
>
> Semaine 3 : Défi communautaire (tous animes)
>
> Semaine 4-5 : Événement Naruto
>
> Semaine 6 : Tournoi mensuel
>
> Semaine 7-8 : Événement surprise / Anniversaire app

## 10.3 Tournois

- Inscription libre ou sur invitation

- Phase de groupes (score cumulé sur 10 duels)

- Finale top 8 en élimination directe

- Durée totale : 1 semaine

- Récompenses : titres exclusifs, Verse Coins, badge de champion

## 10.4 Missions longue durée

| **Mission**               | **Récompense**               |
|---------------------------|------------------------------|
| Jouer 100 duels Verse     | Titre "Guerrier du Verse"    |
| Atteindre Division 5      | Badge "Montée en Puissance"  |
| Participer à 3 événements | Avatar exclusif              |
| Finir une saison Top 100  | Titre de saison              |
| Réussir 5 000 questions   | Badge "Encyclopédie Vivante" |

# 11. V4 — MONÉTISATION & ÉCONOMIE VIRTUELLE

> *Objectif V4 : Générer des revenus durables sans briser l'équilibre du jeu.*

## 11.1 Monnaie virtuelle : Verse Coins

### Obtention gratuite

- Connexion quotidienne

- Fin de quiz

- Défis et missions

- Classements saisonniers

### Achat payant

- Pack 500 Coins → Prix à définir (FCFA / XOF)

- Pack 1 500 Coins → Prix à définir

- Pack 5 000 Coins → Prix à définir

## 11.2 Publicités (joueurs gratuits)

- Pub optionnelle entre les quiz (pas forcée pendant une partie)

- Pub récompensée : "Regarde une pub → Double XP pendant 15 min"

- Pas de pub pendant un duel Verse

- Fréquence max : 1 pub par 3 quiz

## 11.3 Pass Premium (abonnement mensuel)

### Inclut

- Suppression totale des publicités

- +20% XP sur tous les quiz

- Accès anticipé aux événements

- Bonus quotidien Verse Coins (+50/jour)

- Cadre de profil exclusif "Premium"

- File de matchmaking prioritaire

### Ne donne PAS

- Questions exclusives (le contenu reste identique pour tous)

- Avantage direct en duel (le gameplay reste équitable)

## 11.4 Pay-to-Win — Définition

### Acceptable (cosmétique + confort)

- Avatars, cadres, thèmes, effets visuels premium

- Slots de défis supplémentaires

- Accès illimité au Quiz Personnalisé (gratuits = 5/jour)

- Boosts d'XP temporaires (ne changent pas le score au classement)

### À ÉVITER (casse l'équité — règle absolue)

- Acheter des réponses correctes

- Voir les bonnes réponses avant de répondre

- Scores gonflés artificiellement au classement

## 11.5 Tableau de monétisation

| **Source**                 | **Type**                        | **Version** |
|----------------------------|---------------------------------|-------------|
| Publicités inter-quiz      | Gratuit (revenus publicitaires) | V4          |
| Pubs récompensées (opt-in) | Gratuit                         | V4          |
| Achats Verse Coins         | In-App Purchase                 | V4          |
| Pass Premium (abonnement)  | Abonnement mensuel              | V4          |
| Boutique cosmétique        | In-App Purchase                 | V4          |
| Pass Saison Premium        | In-App Purchase                 | V3+V4       |
| Coffres                    | In-App Purchase                 | V4          |

# 12. DASHBOARD ADMIN

## 12.1 Accès et rôles

| **Rôle**           | **Permissions**                               |
|--------------------|-----------------------------------------------|
| Super Admin        | Accès total à toutes les fonctionnalités      |
| Éditeur de contenu | Gestion questions, événements, saisons        |
| Modérateur         | Gestion utilisateurs, signalements, sanctions |
| Statistiques       | Lecture seule, tableaux de bord               |

## 12.2 Modules du dashboard

### Gestion des utilisateurs

- Recherche par pseudo / email

- Voir profil complet (stats, historique, sanctions)

- Suspendre / bannir / réactiver un compte

- Modifier un rang manuellement (cas exceptionnels)

### Gestion des questions

- Import batch de fichiers .md

- Recherche multi-critères (anime, arc, difficulté, tags, statut)

- Modifier / désactiver / réactiver une question

- Voir les stats d'une question (fréquence, taux de réussite)

- Détection de doublons

### Gestion des événements

- Créer / planifier un événement (dates, thème, récompenses)

- Associer des questions réservées à un événement

- Activer / désactiver un événement en temps réel

### Statistiques

- Joueurs actifs (DAU / MAU)

- Quiz joués par jour

- Taux de rétention J1, J7, J30

- Duels Verse joués

- Revenus (si monétisation active)

- Questions les plus / moins jouées

## 12.3 Stack Dashboard Admin

- Next.js (TypeScript) + Tailwind CSS

- Connexion Supabase via clé admin (jamais exposée côté client)

- Authentification séparée de l'app mobile

- Déployé sur Vercel

# 13. SÉCURITÉ & ANTI-TRICHE

## 13.1 Règles fondamentales

- La validation des réponses se fait TOUJOURS côté serveur (Edge Function)

- Le client ne reçoit JAMAIS la bonne réponse avant d'avoir répondu

- Le timer est géré côté serveur (une réponse en retard est ignorée)

## 13.2 Détection de comportements anormaux

| **Comportement suspect**                 | **Seuil d'alerte** | **Action automatique**     |
|------------------------------------------|--------------------|----------------------------|
| Taux de réussite \> 98% (100+ questions) | Flag automatique   | Vérification manuelle      |
| Temps de réponse moyen \< 1 seconde      | Flag automatique   | Suspension temporaire      |
| Plusieurs comptes depuis la même IP      | Flag               | Vérification manuelle      |
| Score impossible en Verse                | Immédiat           | Annulation + avertissement |
| 5+ abandons en 1h                        | Automatique        | Cooldown 2 heures          |

## 13.3 Authentification

- JWT sécurisés via Supabase Auth

- Refresh tokens avec expiration

- Sessions invalidées à la déconnexion

- Option recommandée : connexion Google / Apple

# 14. DESIGN & UX — PRINCIPES DIRECTEURS

## 14.1 Palette de couleurs suggérée

| **Rôle**          | **Code HEX** | **Usage**                        |
|-------------------|--------------|----------------------------------|
| Fond principal    | \#0D0D1A     | Arrière-plan général (dark mode) |
| Accent principal  | \#7B2FFF     | Boutons, titres, éléments clés   |
| Accent secondaire | \#FF6B35     | Énergie, animations, alertes     |
| Texte principal   | \#FFFFFF     | Texte sur fond sombre            |
| Texte secondaire  | \#A0A0C0     | Labels, métadonnées              |
| Succès            | \#00E676     | Bonne réponse, validation        |
| Erreur            | \#FF3D71     | Mauvaise réponse, alerte         |

## 14.2 Règles UX non-négociables

- Maximum 2 taps pour lancer un quiz depuis l'accueil

- Feedback immédiat à chaque réponse (son + couleur + animation)

- Jamais d'écran de chargement \> 2 secondes sans indicateur de progression

- Toujours un objectif visible sur l'écran d'accueil

- Le score et le progrès sont affichés en permanence pendant un quiz

- Aucune action irréversible sans confirmation explicite

## 14.3 Écrans prioritaires pour Figma

- 1\. Accueil

- 2\. Sélection de mode de jeu

- 3\. Écran de quiz (question + timer + choix)

- 4\. Résultat de fin de quiz

- 5\. Profil joueur

- 6\. Écran de duel Verse (V2)

# 15. CHECKLISTS DE VALIDATION INTER-VERSIONS

> *Avant de passer d'une version à la suivante, toutes les cases doivent être cochées.*

## Checklist V1 → V1.5

- ☐ Inscription et connexion fonctionnelles sur iOS et Android

- ☐ Quiz Solo jouable sans crash sur 50 parties de suite

- ☐ XP et niveaux mis à jour correctement

- ☐ Défis quotidiens générés et resetés à minuit

- ☐ Badges attribués correctement

- ☐ Récompense quotidienne fonctionnelle

- ☐ Dashboard admin : import questions, gestion users OK

- ☐ Temps de chargement \< 2s

- ☐ Testé sur au moins 3 modèles Android + iPhone 12 minimum

## Checklist V1.5 → V2

- ☐ Classements global et national corrects

- ☐ Système d'amis : ajout, suppression, fil d'activité

- ☐ Notifications push fonctionnelles iOS + Android

- ☐ Partage de résultats : image générée correctement

- ☐ Aucun bug critique signalé sur V1 depuis 2 semaines

## Checklist V2 → V3

- ☐ Duel temps réel stable avec latence \< 200ms

- ☐ Matchmaking fonctionne (humain + bot adaptatif)

- ☐ Divisions : montée, descente, protection active

- ☐ Code d'invitation : création et join fonctionnels

- ☐ Mode Coop jouable à 2

- ☐ Anti-abandon opérationnel

- ☐ Tests de charge : 100 duels simultanés sans crash

## Checklist V3 → V4

- ☐ Saison créée et clôturée correctement depuis le dashboard

- ☐ Événements : activation, questions réservées, récompenses

- ☐ Tournois : inscription, phases, finale, distribution récompenses

- ☐ Missions longue durée suivies correctement

## Checklist V4 → V5

- ☐ Pubs intégrées (AdMob ou alternative)

- ☐ Achat Verse Coins fonctionnel (App Store + Google Play)

- ☐ Pass Premium : activation, avantages appliqués

- ☐ Boutique : achats cosmétiques fonctionnels

- ☐ Aucun avantage compétitif direct vendu

# Annexe — Glossaire

| **Terme**     | **Définition**                                                      |
|---------------|---------------------------------------------------------------------|
| Verse         | L'univers multijoueur compétitif de l'application                   |
| Verse Coins   | Monnaie virtuelle principale de l'application                       |
| Division      | Échelon compétitif dans le Verse (inspiré eFootball)                |
| Soft reset    | Réinitialisation partielle du classement en fin de saison           |
| Edge Function | Fonction serverless côté Supabase (logique métier sécurisée)        |
| DAU / MAU     | Daily / Monthly Active Users (joueurs actifs quotidiens / mensuels) |
| IAP           | In-App Purchase (achat intégré dans l'application)                  |
| Bot adaptatif | Adversaire simulé quand aucun humain n'est disponible               |
| Matchmaking   | Système automatique de mise en relation de deux joueurs             |

*Document version 1.0 — Otaku Verse SN — Tariq (Dr. X) × Heat*

*Prochaine révision : après validation V1 en conditions réelles, une fois que je l’aurai bulder bien sur.*
