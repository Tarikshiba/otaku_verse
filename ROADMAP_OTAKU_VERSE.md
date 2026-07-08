# OTAKU VERSE — CAHIER DES CHARGES & ROADMAP TECHNIQUE

**Version 2.0 — Document de référence projet**
**Auteurs : Tariq (Dr. X) × Heat**
**Repo GitHub : https://github.com/Tarikshiba/otaku_verse**

---

## COMMENT UTILISER CE DOCUMENT

Ce fichier est lu par Claude Code en complément de `CLAUDE.md` et `PROGRESS.md`.
Il contient la vision, les fonctionnalités et le **plan d'exécution étape par étape jusqu'à la V1**.
On ne commence jamais une nouvelle version tant que la précédente n'est pas testée et validée.

---

## SOMMAIRE

1. [Vision du projet](#1-vision-du-projet)
2. [Direction artistique — Design](#2-direction-artistique--design)
3. [Stack technique](#3-stack-technique)
4. [Architecture modulaire](#4-architecture-modulaire)
5. [Base de données des questions](#5-base-de-données-des-questions)
6. [Fonctionnalités — vue globale](#6-fonctionnalités--vue-globale)
7. [PLAN D'EXÉCUTION V1 — Étape par étape](#7-plan-dexécution-v1--étape-par-étape)
8. [V1 — Détail fonctionnel complet](#8-v1--détail-fonctionnel-complet)
9. [V1.5 → V5 — Aperçu (post-MVP)](#9-v15--v5--aperçu-post-mvp)
10. [Sécurité](#10-sécurité)
11. [Workflow Git / GitHub](#11-workflow-git--github)
12. [Outils à installer](#12-outils-à-installer)
13. [Checklist de fin de V1](#13-checklist-de-fin-de-v1)
14. [Glossaire](#14-glossaire)

---

## 1. VISION DU PROJET

**Otaku Verse** est une plateforme mobile de quiz compétitif dédiée à la culture manga, anime et pop culture francophone. Le joueur progresse dans un univers appelé **le Verse** : quiz solo, duels en temps réel, divisions compétitives inspirées d'eFootball, saisons, événements, récompenses.

### Ce que ce n'est PAS
- Pas un simple quiz statique et jetable
- Pas un réseau social
- Pas un RPG complet

### Ce que c'est
- Un moteur de quiz intelligent, avec des dizaines/centaines de milliers de questions
- Un système de progression (XP, niveaux, rangs, badges, titres, collections)
- Un mode multijoueur (le Verse) : duels, coop, divisions, matchmaking
- Une plateforme pensée pour évoluer pendant plusieurs années sans reconstruction complète

### Public cible
Fans de manga/anime/pop culture au Sénégal et en Afrique francophone, 15–30 ans, mobile-first, du fan occasionnel à l'expert compétitif.

---

## 2. DIRECTION ARTISTIQUE — DESIGN

> Tariq n'est pas designer et le sait. Cette section existe pour que Claude Code prenne des décisions de design fortes sans attendre une direction artistique détaillée à chaque écran.

### 2.1 Ce qu'on refuse absolument

- ❌ Glassmorphism (fonds flous translucides) — signature visuelle "app générée par IA en 2024"
- ❌ Dégradés violet → bleu → rose mous et génériques
- ❌ Cartes blanches aux coins arrondis avec ombre légère (look SaaS B2B)
- ❌ Icônes Material Design par défaut sans retouche
- ❌ Illustrations "flat design" de bonhommes génériques
- ❌ Emojis à la place d'iconographie réelle

### 2.2 Ce qu'on vise

**Un langage visuel manga/imprimé, pas "app mobile lambda" :**

- **Trames et screentones** — texture de points façon impression manga N&B, utilisée en fond ou en accent plutôt que des dégradés lisses
- **Traits d'encre et contours marqués** — bordures noires épaisses façon planche manga sur certains éléments clés (cartes de récompense, badges)
- **Lignes de vitesse / speed lines** — pour les transitions et animations de victoire, de montée de niveau
- **Onomatopées stylisées** en guise d'accents visuels (BOOM, LEVEL UP!, K.O.) dans les moments de feedback fort
- **Une seule couleur d'accent dominante et saturée** (pas un camaïeu) — par exemple un rouge encre ou un violet électrique unique, sur fond très sombre quasi noir, façon jaquette de tankōbon
- **Typographie à impact** pour les titres (police display avec du caractère, pas une sans-serif neutre), typographie sobre et très lisible pour le contenu (questions, texte long)
- **Compositions asymétriques** plutôt que des grilles parfaitement centrées — cadrages dynamiques façon page de manga
- **Iconographie custom ou fortement retravaillée**, jamais des packs d'icônes par défaut tels quels

### 2.3 Ambiance recherchée
Sobre, sombre, impactant. Le joueur doit ressentir qu'il ouvre un artefact culte, pas une app de sondage. Référence de sensation : jaquette d'un manga culte + interface d'un jeu de combat stylé, pas un dashboard.

### 2.4 Process
- Palette de couleurs, typographies et composants de base définis et validés **avant** de coder le premier écran (étape 3 du plan d'exécution, section 7)
- Si Tariq veut faire une maquette Figma, le faire uniquement pour 2-3 écrans clés (Accueil, Quiz, Résultat) — pas besoin de tout maquetter avant de coder

---

## 3. STACK TECHNIQUE

| Composant | Choix | Pourquoi |
|---|---|---|
| App mobile | **Flutter (Dart)** | Un seul code pour iOS + Android + tablettes, performances natives, écosystème riche pour animations |
| Gestion d'état | **Riverpod** | Plus simple à apprendre et à expliquer que Bloc, robuste, évolutif, très utilisé donc bien documenté |
| Backend principal | **Supabase** | PostgreSQL managé, Auth intégrée, Storage, API auto-générée, dashboard natif, cloud (pas de serveur à gérer) |
| Temps réel (Verse, à partir de V2) | **Firebase Realtime Database + Cloud Messaging** | Latence très faible pour les duels live + notifications push fiables iOS/Android |
| Logique métier serveur | **Supabase Edge Functions** (TypeScript/Deno) | Validation des réponses côté serveur, calculs de score, anti-triche |
| Dashboard admin | **Next.js + TypeScript + Tailwind CSS** | Web app séparée, déployée sur Vercel, connectée à Supabase |
| Base de questions (source) | Fichiers **Markdown (.md)** | Lisible, versionnable sur Git, facile à écrire même sans coder |
| Contrôle de version | **Git + GitHub** | Repo : `github.com/Tarikshiba/otaku_verse` |

---

## 4. ARCHITECTURE MODULAIRE

**Règle d'or :** chaque module est indépendant. Un bug dans la boutique ne doit jamais casser le quiz. Un module ne touche jamais directement les données d'un autre module — il passe par une interface définie.

| Module | Rôle | Version d'introduction |
|---|---|---|
| `auth` | Inscription, connexion, sessions | V1 |
| `profile` | Profil joueur, stats, personnalisation | V1 |
| `quiz_engine` | Sélection et logique des quiz | V1 |
| `questions_db` | Base de données des questions | V1 |
| `progression` | XP, niveaux, rangs, badges | V1 |
| `rewards` | Récompenses de base, défis quotidiens | V1 |
| `admin` | Dashboard back-office | V1 |
| `social` | Amis, classements, partage | V1.5 |
| `notifications` | Push, in-app | V1.5 |
| `verse` | Duels temps réel, divisions, coop | V2 |
| `events` | Événements, saisons, tournois | V3 |
| `monetization` | Pay-to-win, publicités, boutique | V4 |

---

## 5. BASE DE DONNÉES DES QUESTIONS

### Format source : `.md` structuré

```markdown
---
id: OP_001_0042
anime: One Piece
arc: Alabasta
chapitre: 155
type: personnage
difficulte: moyen
tags: [capitaine, equipage, chapeau-de-paille]
---

**Question :** Quel est le nom du capitaine de l'équipage du Chapeau de Paille ?

- A: Zoro
- B: Nami
- C: Monkey D. Luffy
- D: Shanks

**Bonne réponse :** C

**Explication :** Monkey D. Luffy est le fondateur et capitaine de l'équipage du Chapeau de Paille.
```

### Table PostgreSQL (Supabase)

```sql
CREATE TABLE questions (
  id              TEXT PRIMARY KEY,
  anime           TEXT NOT NULL,
  arc             TEXT,
  chapitre        TEXT,
  type            TEXT NOT NULL,
  difficulte      TEXT NOT NULL,        -- facile, moyen, difficile, expert
  question        TEXT NOT NULL,
  choix_a         TEXT NOT NULL,
  choix_b         TEXT NOT NULL,
  choix_c         TEXT NOT NULL,
  choix_d         TEXT NOT NULL,
  bonne_reponse   CHAR(1) NOT NULL,
  explication     TEXT,
  tags            TEXT[],
  statut          TEXT DEFAULT 'actif',
  frequence       INTEGER DEFAULT 0,
  taux_reussite   FLOAT DEFAULT 0.0,
  created_at      TIMESTAMP DEFAULT NOW()
);
```

### Script d'import
Un script (Node.js ou Python) lit tous les `.md` du dossier `questions_db/`, valide les champs obligatoires, détecte les doublons, puis insère dans Supabase. Ce script est un des tout premiers livrables techniques (voir plan d'exécution).

### Moteur de sélection (résumé)
Ne choisit jamais au hasard : exclut les questions vues récemment, équilibre les difficultés et catégories, adapte la difficulté au niveau du joueur.

---

## 6. FONCTIONNALITÉS — VUE GLOBALE

| Fonctionnalité | Version |
|---|---|
| Inscription / connexion | V1 |
| Profil joueur + stats de base | V1 |
| Quiz solo (rapide, par anime, par difficulté) | V1 |
| XP, niveaux, rangs | V1 |
| Badges, défis quotidiens, récompense de connexion | V1 |
| Dashboard admin (questions, users) | V1 |
| Classements (mondial, national, amis) | V1.5 |
| Système d'amis, notifications push | V1.5 |
| Duels temps réel, divisions, coop, invitation par code | V2 |
| Saisons, événements, tournois | V3 |
| Monnaie virtuelle, boutique, abonnement, pay-to-win encadré | V4 |
| Battle Royale, guildes, expansion multi-licences | V5 |

---

## 7. PLAN D'EXÉCUTION V1 — ÉTAPE PAR ÉTAPE

> Chaque étape doit être terminée, testée et comprise par Tariq avant de passer à la suivante. Après chaque étape validée, Claude Code doit mettre à jour `PROGRESS.md` et dire à Tariq de push.

### Étape 0 — Mise en place de l'environnement
- Installer les outils (voir section 12)
- Créer le repo GitHub `otaku_verse`
- Cloner en local, ouvrir dans VS Code
- Placer `CLAUDE.md`, `ROADMAP_OTAKU_VERSE.md` à la racine
- Premier commit : structure de dossiers vide + `.gitignore`

### Étape 1 — Initialisation du projet Flutter
- Créer le projet Flutter dans `app/`
- Configurer pour cibler iOS + Android + tablettes
- Vérifier que l'app vide tourne sur émulateur ET sur le téléphone Android de Tariq (USB debug)
- Commit + push

### Étape 2 — Fondations Supabase
- Créer le projet Supabase
- Configurer les variables d'environnement (`.env`, jamais commité)
- Connecter Flutter à Supabase (test de connexion simple)
- Commit + push

### Étape 3 — Design system (fondations visuelles)
- Définir la palette de couleurs finale, la typographie, les composants de base (boutons, cartes, textes) selon la direction artistique (section 2)
- Créer un écran de démonstration avec tous les composants pour validation visuelle par Tariq AVANT de construire les vrais écrans
- Commit + push une fois validé

### Étape 4 — Authentification (module `auth`)
- Écrans : inscription, connexion, choix pseudo/avatar/anime préféré
- Connexion Supabase Auth (email + Google/Apple si simple à intégrer)
- Test : créer un compte, se déconnecter, se reconnecter
- Commit + push

### Étape 5 — Base de données des questions
- Créer 50-100 questions `.md` de test (One Piece par exemple)
- Écrire et tester le script d'import vers Supabase
- Vérifier les données dans le dashboard Supabase
- Commit + push

### Étape 6 — Moteur de quiz (module `quiz_engine`)
- Logique de sélection de questions (anti-répétition, équilibrage)
- Écran de quiz : question, 4 choix, timer, feedback bonne/mauvaise réponse
- Validation de la réponse **côté serveur** (Edge Function), jamais côté client
- Test : jouer un quiz complet du début à la fin
- Commit + push

### Étape 7 — Progression (module `progression`)
- XP, niveaux, rangs (voir barème section 8)
- Mise à jour du profil après chaque quiz
- Écran de résultat de fin de quiz
- Commit + push

### Étape 8 — Profil joueur (module `profile`)
- Écran profil : stats, historique, badges
- Commit + push

### Étape 9 — Récompenses de base (module `rewards`)
- Défis quotidiens (génération automatique, reset à minuit)
- Récompense de connexion quotidienne
- Badges de base
- Commit + push

### Étape 10 — Accueil (écran central)
- Assemblage de l'écran d'accueil avec tous les éléments (profil, jouer maintenant, défi du jour, récompense quotidienne)
- Commit + push

### Étape 11 — Dashboard admin (V1 minimal)
- Next.js : gestion des questions (ajout/modif/désactivation), gestion des utilisateurs de base
- Connexion sécurisée réservée à Tariq/Heat
- Commit + push

### Étape 12 — Tests globaux V1
- Test complet du parcours utilisateur sur émulateur ET téléphone physique
- Correction des bugs trouvés
- Revue de sécurité de base (voir section 10)
- Voir checklist section 13

### Étape 13 — Bilan V1 avant V1.5
- Session de revue avec Tariq : qu'est-ce qui marche, qu'est-ce qui doit changer
- Mise à jour finale de `PROGRESS.md`
- Décision commune : on passe à V1.5 (classements, amis) seulement une fois la V1 stable

---

## 8. V1 — DÉTAIL FONCTIONNEL COMPLET

### 8.1 Écrans V1
- **Onboarding** : splash → inscription/connexion → choix pseudo, avatar, anime préféré
- **Accueil** : profil (avatar, niveau, XP), bouton Jouer maintenant, défi du jour, récompense quotidienne, accès rapide profil
- **Jouer** : Quiz Rapide / Quiz par Anime / Quiz par Difficulté / Quiz Personnalisé
- **Quiz** : question, 4 choix, timer, feedback immédiat, progression
- **Résultat** : score, XP gagné, badges débloqués, rejouer/accueil
- **Profil** : avatar, stats, badges, historique

### 8.2 XP

| Action | XP |
|---|---|
| Quiz terminé | +20 |
| Bonne réponse | +10 |
| Quiz sans faute | +50 bonus |
| Défi quotidien complété | +30 |
| Connexion quotidienne | +15 |

Courbe : XP requise niveau N = `100 × N × 1.2`

### 8.3 Rangs (noms à valider avec Heat)

| Rang | Niveau |
|---|---|
| Débutant | 1–5 |
| Apprenti Otaku | 6–15 |
| Passionné | 16–30 |
| Expert | 31–50 |
| Maître du Verse | 51–75 |
| Légende | 76+ |

### 8.4 Défis quotidiens (exemples)
Terminer 3 quiz · Obtenir 15 bonnes réponses · Quiz sans faute · Jouer sur un anime précis · Réussir un quiz Expert

### 8.5 Badges de base
Premier Pas · Perfectionniste · Fidèle (7 jours) · Chasseur de Connaissances (100 bonnes réponses) · Montée en Grade (niveau 10)

### 8.6 Données techniques
- Minimum 10 000 questions au lancement, 5 animes minimum (One Piece, Naruto, Dragon Ball, Jujutsu Kaisen, Bleach recommandés)
- iOS 14+ / Android 8+
- Temps de chargement cible < 2s

---

## 9. V1.5 → V5 — APERÇU (POST-MVP)

*(Détail complet à reprendre uniquement une fois la V1 validée — ne pas anticiper le code avant.)*

- **V1.5** : classements (mondial/national/amis), système d'amis, notifications push, partage de résultats
- **V2 — Le Verse** : duels temps réel (Firebase), divisions inspirées eFootball, matchmaking, coop, invitation par code
- **V3** : saisons (8 semaines), événements temporaires, tournois, missions longue durée
- **V4** : monnaie virtuelle (Verse Coins), boutique cosmétique, Pass Premium, pay-to-win strictement cosmétique/confort (jamais d'avantage compétitif direct)
- **V5** : Battle Royale Quiz, guildes/clans, classement mondial, expansion vers manhwa/webtoon/jeux vidéo

---

## 10. SÉCURITÉ

- Aucune clé API en dur dans le code — toujours `.env`, toujours dans `.gitignore`
- Validation des réponses de quiz **côté serveur uniquement** (Edge Function) — le client ne reçoit jamais la bonne réponse à l'avance
- Mots de passe gérés exclusivement par Supabase Auth (jamais stockés/gérés manuellement)
- Sessions avec expiration (JWT + refresh token)
- Dashboard admin sur authentification séparée de l'app mobile, accès restreint à Tariq/Heat
- Avant chaque `git push`, vérifier qu'aucun secret n'est présent dans les fichiers commités (Claude Code doit le signaler explicitement)

---

## 11. WORKFLOW GIT / GITHUB

1. Repo : `https://github.com/Tarikshiba/otaku_verse`
2. Branche principale : `main`
3. Claude Code **ne push jamais**. Il prépare les fichiers, propose un message de commit clair, et dit à Tariq : *"Tu peux push maintenant."*
4. Commandes que Tariq exécutera (Claude Code les lui rappelle à chaque fois) :
   ```
   git add .
   git commit -m "message proposé par Claude"
   git push
   ```
5. Un commit par étape terminée du plan d'exécution (section 7) — pas de commit géant fourre-tout.

---

## 12. OUTILS À INSTALLER

| Outil | Usage |
|---|---|
| **VS Code** | Déjà installé — éditeur principal |
| **Extension Flutter + Dart** (VS Code) | Support du langage, exécution, débogage |
| **Flutter SDK** | Framework de l'app mobile |
| **Android Studio** (ou juste les outils en ligne de commande + un émulateur) | Émulateur Android + outils de build Android |
| **Xcode** (uniquement si accès à un Mac plus tard pour publier sur iOS) | Requis pour build/publier iOS — pas bloquant pour développer au départ si test priorisé sur Android |
| **Git** | Déjà nécessaire pour le repo |
| **Node.js** | Scripts d'import de questions + dashboard Next.js |
| **Compte Supabase** (gratuit pour démarrer) | Backend |
| **Compte Firebase** (gratuit pour démarrer) | Temps réel à partir de V2 |
| **Compte Vercel** (gratuit) | Déploiement du dashboard admin |

*Claude Code guidera Tariq à l'installation de chaque outil au moment précis où il devient nécessaire dans le plan d'exécution — pas besoin de tout installer le premier jour.*

---

## 13. CHECKLIST DE FIN DE V1

- [ ] Inscription/connexion fonctionnelles sur émulateur ET téléphone physique
- [ ] Quiz jouable sans crash sur 50 parties de suite
- [ ] XP, niveaux, rangs corrects après chaque quiz
- [ ] Défis quotidiens générés et reset à minuit
- [ ] Badges attribués correctement
- [ ] Récompense de connexion quotidienne fonctionnelle
- [ ] Dashboard admin : import de questions, gestion utilisateurs OK
- [ ] Validation des réponses vérifiée côté serveur (test : tenter de tricher côté client échoue)
- [ ] Aucune clé API exposée dans le repo Git
- [ ] Temps de chargement < 2s
- [ ] Design conforme à la direction artistique (section 2) — validé visuellement par Tariq

---

## 14. GLOSSAIRE

| Terme | Définition |
|---|---|
| Le Verse | Univers multijoueur compétitif de l'app |
| Edge Function | Fonction serveur Supabase (logique métier sécurisée) |
| Riverpod | Librairie de gestion d'état Flutter |
| Division | Échelon compétitif du Verse (V2, inspiré eFootball) |
| PROGRESS.md | Carnet de bord technique maintenu par Claude Code à chaque session |

---

*Document version 2.0 — Otaku Verse — Tariq (Dr. X) × Heat*
