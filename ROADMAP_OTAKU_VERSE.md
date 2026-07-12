# OTAKU VERSE — CAHIER DES CHARGES & ROADMAP TECHNIQUE

**Version 2.1 — Document de référence projet**
**Auteurs : Tariq (Dr. X) × Heat**
**Repo GitHub : https://github.com/Tarikshiba/otaku_verse**

---

## CHANGELOG DEPUIS LA V2.0

Suite à un retour d'expérience utilisateur (Heat a trouvé les apps de quiz classiques ennuyantes — questions répétitives, présentation plate en mode vertical), la direction produit de la V1 évolue :

- Le quiz solo classique (répondre à des questions dans le vide) est **remplacé** par un **mode combat horizontal** dès la V1.
- Le combat oppose le joueur à un **bot** en V1 (le multijoueur temps réel reste en V2, comme prévu, mais réutilisera la mécanique de combat validée en V1).
- Les combos (3 bonnes réponses d'affilée) déclenchent une attaque spéciale animée.
- Les skins de personnages passent en 3D consultable dans le profil (V1 : un skin fixe unique — la collection/achat arrive en V1.5).
- Le reste de l'architecture (stack technique, modules, sécurité, workflow Git) ne change pas.

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
6. [Le mode Combat — cœur de la V1](#6-le-mode-combat--cœur-de-la-v1)
7. [Fonctionnalités — vue globale](#7-fonctionnalités--vue-globale)
8. [PLAN D'EXÉCUTION V1 — Étape par étape](#8-plan-dexécution-v1--étape-par-étape)
9. [V1 — Détail fonctionnel complet](#9-v1--détail-fonctionnel-complet)
10. [V1.5 → V5 — Aperçu (post-MVP)](#10-v15--v5--aperçu-post-mvp)
11. [Sécurité](#11-sécurité)
12. [Workflow Git / GitHub](#12-workflow-git--github)
13. [Outils à installer](#13-outils-à-installer)
14. [Checklist de fin de V1](#14-checklist-de-fin-de-v1)
15. [Glossaire](#15-glossaire)

---

## 1. VISION DU PROJET

**Otaku Verse** est une plateforme mobile de quiz compétitif dédiée à la culture manga, anime et pop culture francophone. Le joueur progresse dans un univers appelé **le Verse** : combats de quiz, duels en temps réel, divisions compétitives inspirées d'eFootball, saisons, événements, récompenses.

### Ce que ce n'est PAS
- Pas un simple quiz statique et jetable
- Pas un réseau social
- Pas un RPG complet

### Ce que c'est
- Un moteur de quiz intelligent, avec des dizaines/centaines de milliers de questions
- Une expérience de **combat** — chaque quiz est un affrontement, pas une liste de questions
- Un système de progression (XP, niveaux, rangs, badges, titres, collections)
- Un mode multijoueur (le Verse) : duels, coop, divisions, matchmaking (V2)
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
- **Lignes de vitesse / speed lines** — pour les transitions, les coups portés en combat, les montées de niveau
- **Onomatopées stylisées** en guise d'accents visuels (BOOM, LEVEL UP!, K.O.) dans les moments de feedback fort — notamment à chaque coup porté en combat et à chaque combo
- **Une seule couleur d'accent dominante et saturée** (pas un camaïeu) — par exemple un rouge encre ou un violet électrique unique, sur fond très sombre quasi noir, façon jaquette de tankōbon
- **Typographie à impact** pour les titres (police display avec du caractère, pas une sans-serif neutre), typographie sobre et très lisible pour le contenu (questions, texte long)
- **Compositions asymétriques** plutôt que des grilles parfaitement centrées — cadrages dynamiques façon page de manga
- **Iconographie custom ou fortement retravaillée**, jamais des packs d'icônes par défaut tels quels

### 2.3 Ambiance recherchée
Sobre, sombre, impactant. Le joueur doit ressentir qu'il ouvre un artefact culte, pas une app de sondage. Référence de sensation : jaquette d'un manga culte + interface d'un jeu de combat stylé, pas un dashboard.

### 2.4 Deux registres visuels distincts

- **Hors combat (profil, accueil, menus)** : format vertical, ambiance manga sombre décrite ci-dessus, skin du joueur visible et rotatif en 3D dans le profil
- **Écran de combat** : format **horizontal forcé**, mise en scène façon jeu de combat mobile (type eFootball/Free Fire en session) — les deux personnages (joueur à une extrémité, adversaire à l'autre) se font face, barres de vie visibles, la question et les choix de réponse occupent l'espace central

### 2.5 Process
- Palette de couleurs, typographies et composants de base définis et validés **avant** de coder le premier écran (étape 3 du plan d'exécution, section 8)
- Si Tariq veut faire une maquette Figma, le faire uniquement pour 2-3 écrans clés (Accueil, Combat, Résultat) — pas besoin de tout maquetter avant de coder

---

## 3. STACK TECHNIQUE

| Composant | Choix | Pourquoi |
|---|---|---|
| App mobile | **Flutter (Dart)** | Un seul code pour iOS + Android + tablettes, performances natives, écosystème riche pour animations |
| Gestion d'état | **Riverpod** | Plus simple à apprendre et à expliquer que Bloc, robuste, évolutif, très utilisé donc bien documenté |
| Backend principal | **Supabase** | PostgreSQL managé, Auth intégrée, Storage, API auto-générée, dashboard natif, cloud (pas de serveur à gérer) |
| Animations de combat | **2D** (Rive ou sprites animés légers) | Le combat reste jouable sur tous les téléphones sans faire chuter les performances |
| Skin du personnage (profil) | **3D léger** (modèle simple rotatif, viewer intégré) | Effet "collection premium" dans le profil sans alourdir l'écran de combat |
| Temps réel (Verse, à partir de V2) | **Firebase Realtime Database + Cloud Messaging** | Latence très faible pour les duels live + notifications push fiables iOS/Android |
| Logique métier serveur | **Supabase Edge Functions** (TypeScript/Deno) | Validation des réponses côté serveur, calcul des dégâts et du score, anti-triche |
| Dashboard admin | **Next.js + TypeScript + Tailwind CSS** | Web app séparée, déployée sur Vercel, connectée à Supabase |
| Base de questions (source) | Fichiers **Markdown (.md)** | Lisible, versionnable sur Git, facile à écrire même sans coder |
| Contrôle de version | **Git + GitHub** | Repo : `github.com/Tarikshiba/otaku_verse` |

---

## 4. ARCHITECTURE MODULAIRE

**Règle d'or :** chaque module est indépendant. Un bug dans la boutique ne doit jamais casser le combat. Un module ne touche jamais directement les données d'un autre module — il passe par une interface définie.

| Module | Rôle | Version d'introduction |
|---|---|---|
| `auth` | Inscription, connexion, sessions | V1 |
| `profile` | Profil joueur, stats, skin 3D, personnalisation | V1 |
| `combat_engine` | Logique de combat (PV, dégâts, combos, bot) | V1 |
| `questions_db` | Base de données des questions | V1 |
| `progression` | XP, niveaux, rangs, badges | V1 |
| `rewards` | Récompenses de base, défis quotidiens | V1 |
| `admin` | Dashboard back-office | V1 |
| `social` | Amis, classements, partage | V1.5 |
| `notifications` | Push, in-app | V1.5 |
| `verse` | Duels temps réel, divisions, coop | V2 |
| `events` | Événements, saisons, tournois | V3 |
| `monetization` | Pay-to-win, publicités, boutique, skins additionnels | V4 |

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
Un script (Node.js) lit tous les `.md` du dossier `questions_db/`, valide les champs obligatoires, détecte les doublons, puis insère dans Supabase.

### Moteur de sélection (résumé)
Ne choisit jamais au hasard : exclut les questions vues récemment, équilibre les difficultés et catégories, adapte la difficulté au niveau du joueur et à la difficulté du bot en cours de combat.

---

## 6. LE MODE COMBAT — CŒUR DE LA V1

### 6.1 Principe général

Avant V2.0, un "quiz" consistait à répondre à des questions dans le vide. En V2.1, **tout passe par le combat**. Il n'existe plus de mode "solo classique" séparé : le combat contre un bot devient l'unique moteur de jeu de la V1, et sert de base réutilisable pour le futur duel joueur-contre-joueur (V2).

### 6.2 Avant le combat — paramétrage

Le joueur choisit, avant de lancer le combat :
- **L'anime** sur lequel porteront les questions (ou "toutes catégories")
- **La difficulté globale visée** (facile / moyen / difficile / expert / adaptatif)

Ce choix remplace les anciens modes "Quiz Rapide / par Anime / par Difficulté" — au lieu de choisir un *type* de quiz, le joueur choisit les *paramètres de son combat*.

### 6.3 Mise en scène du combat

- Écran forcé en **mode paysage (horizontal)**
- Le personnage du joueur est positionné à une extrémité de l'écran, celui du bot à l'autre extrémité, face à face
- Chacun a une **barre de vie (PV)** visible au-dessus de son personnage
- La question et les 4 choix de réponse occupent l'espace central de l'écran
- Un timer par question, comme en V2.0

### 6.4 Déroulement d'un tour

1. La question s'affiche avec un temps limité pour répondre
2. **Bonne réponse du joueur** → le personnage du joueur attaque, le bot perd des PV (animation d'attaque + onomatopée)
3. **Bonne réponse du bot** (simulée selon sa difficulté) → le bot attaque, le joueur perd des PV
4. **Mauvaise réponse ou temps écoulé** → pas d'attaque ce tour-ci
5. Le combat enchaîne directement sur la question suivante

### 6.5 Système de combo

- **3 bonnes réponses d'affilée** (par le joueur ou par le bot) déclenchent une **attaque spéciale** : animation dédiée plus marquée, dégâts renforcés
- Une mauvaise réponse ou un temps écoulé réinitialise le compteur de combo
- Le système de combo est générique et réutilisable (même mécanique en V2 pour les duels réels)

### 6.6 Fin du combat

- **Limite de 10 questions maximum** par combat
- **K.O. immédiat** si un des deux personnages (joueur ou bot) tombe à 0 PV avant la 10ᵉ question — le combat s'arrête là, victoire immédiate
- Si la 10ᵉ question est atteinte sans K.O. → celui qui a le plus de PV restants (ou qui a infligé le plus de dégâts cumulés) remporte le combat

### 6.7 Le bot (V1)

- **Difficulté progressive/adaptative** : le bot ne répond pas à un taux de réussite fixe, son niveau de "précision" et de "vitesse de réponse" s'ajuste selon :
  - La difficulté choisie par le joueur avant le combat
  - Éventuellement le niveau/rang du joueur (à affiner à l'implémentation)
- Le bot est entièrement simulé côté serveur (Edge Function) — jamais de logique de triche visible côté client
- Cette brique de simulation du bot est conçue pour être **réutilisée en V2** comme adversaire de secours si aucun joueur humain n'est disponible en matchmaking

### 6.8 Skin du joueur

- En **V1** : un seul skin par défaut, en 3D, consultable et rotatif depuis l'écran de profil (pas de choix ni de collection)
- La collection de skins, achats et personnalisation vestimentaire arrivent en **V1.5**

---

## 7. FONCTIONNALITÉS — VUE GLOBALE

| Fonctionnalité | Version |
|---|---|
| Inscription / connexion | V1 |
| Profil joueur + stats de base + skin 3D fixe | V1 |
| Combat vs bot (paramétrable anime/difficulté) | V1 |
| Combos et attaques spéciales | V1 |
| XP, niveaux, rangs | V1 |
| Badges, défis quotidiens, récompense de connexion | V1 |
| Dashboard admin (questions, users) | V1 |
| Classements (mondial, national, amis) | V1.5 |
| Système d'amis, notifications push | V1.5 |
| Collection de skins, boutique cosmétique de base | V1.5 |
| Duels temps réel, divisions, coop, invitation par code | V2 |
| Saisons, événements, tournois | V3 |
| Monnaie virtuelle, boutique complète, abonnement, pay-to-win encadré | V4 |
| Battle Royale, guildes, expansion multi-licences | V5 |

---

## 8. PLAN D'EXÉCUTION V1 — ÉTAPE PAR ÉTAPE

> Chaque étape doit être terminée, testée et comprise par Tariq avant de passer à la suivante. Après chaque étape validée, Claude Code doit mettre à jour `PROGRESS.md` et dire à Tariq de push.
>
> **Étapes déjà réalisées lors de la V2.0 et conservées telles quelles :** 0 (environnement), 1 (init Flutter), 2 (fondations Supabase), 3 (design system), 4 (authentification), 5 (base de données des questions).
>
> **À partir de l'étape 6, le plan est adapté au nouveau mode Combat.**

### Étape 0 — Mise en place de l'environnement ✅
### Étape 1 — Initialisation du projet Flutter ✅
### Étape 2 — Fondations Supabase ✅
### Étape 3 — Design system (fondations visuelles) ✅
### Étape 4 — Authentification (module `auth`) ✅
### Étape 5 — Base de données des questions ✅

### Étape 6 — Refonte : moteur de combat (module `combat_engine`)
- Créer la table `combats` (ou équivalent) pour suivre l'état d'un combat en cours (PV joueur, PV bot, historique des réponses, combo en cours)
- Écran paramétrage : choix anime + difficulté avant de lancer un combat
- Écran de combat en mode paysage forcé : positionnement des deux personnages, barres de PV, zone question/réponses
- Logique de dégâts par bonne réponse, simulation du bot, gestion du combo (3 bonnes réponses d'affilée)
- Validation des réponses et calcul des dégâts **côté serveur** (Edge Function), jamais côté client
- Condition de fin : K.O. avant 10 questions, ou décompte des PV à la 10ᵉ question
- Test : jouer un combat complet du début à la fin (victoire par K.O. et victoire aux points)
- Commit + push

### Étape 7 — Progression (module `progression`)
- XP, niveaux, rangs (voir barème section 9)
- Mise à jour du profil après chaque combat
- Écran de résultat de fin de combat (victoire/défaite, XP gagné, badges débloqués)
- Commit + push

### Étape 8 — Profil joueur (module `profile`)
- Écran profil : stats, historique des combats, badges
- Intégration du skin 3D fixe, consultable et rotatif
- Commit + push

### Étape 9 — Récompenses de base (module `rewards`)
- Défis quotidiens (génération automatique, reset à minuit)
- Récompense de connexion quotidienne
- Badges de base
- Commit + push

### Étape 10 — Accueil (écran central)
- Assemblage de l'écran d'accueil avec tous les éléments (profil, lancer un combat, défi du jour, récompense quotidienne)
- Commit + push

### Étape 11 — Dashboard admin (V1 minimal)
- Next.js : gestion des questions (ajout/modif/désactivation), gestion des utilisateurs de base
- Connexion sécurisée réservée à Tariq/Heat
- Commit + push

### Étape 12 — Tests globaux V1
- Test complet du parcours utilisateur sur émulateur ET téléphone physique
- Test spécifique du mode combat : plusieurs combats de suite, vérifier stabilité des animations et de la logique de dégâts
- Correction des bugs trouvés
- Revue de sécurité de base (voir section 11)
- Voir checklist section 14

### Étape 13 — Bilan V1 avant V1.5
- Session de revue avec Tariq et Heat : qu'est-ce qui marche, qu'est-ce qui doit changer (notamment ressenti du combat)
- Mise à jour finale de `PROGRESS.md`
- Décision commune : on passe à V1.5 (collection de skins, classements, amis) seulement une fois la V1 stable

---

## 9. V1 — DÉTAIL FONCTIONNEL COMPLET

### 9.1 Écrans V1
- **Onboarding** : splash → inscription/connexion → choix pseudo, avatar, anime préféré
- **Accueil** : profil (avatar, niveau, XP), bouton Lancer un combat, défi du jour, récompense quotidienne, accès rapide profil
- **Paramétrage combat** : choix de l'anime, choix de la difficulté
- **Combat** (mode paysage) : personnages face à face, PV, question, 4 choix, timer, feedback immédiat, animations d'attaque et de combo
- **Résultat** : victoire/défaite, score, XP gagné, badges débloqués, rejouer/accueil
- **Profil** : avatar/skin 3D rotatif, stats, badges, historique des combats

### 9.2 XP

| Action | XP |
|---|---|
| Combat terminé | +20 |
| Bonne réponse | +10 |
| Combat gagné par K.O. | +30 bonus |
| Combat gagné sans subir un seul dégât | +50 bonus |
| Défi quotidien complété | +30 |
| Connexion quotidienne | +15 |

Courbe : XP requise niveau N = `100 × N × 1.2`

### 9.3 Rangs (noms à valider avec Heat)

| Rang | Niveau |
|---|---|
| Débutant | 1–5 |
| Apprenti Otaku | 6–15 |
| Passionné | 16–30 |
| Expert | 31–50 |
| Maître du Verse | 51–75 |
| Légende | 76+ |

### 9.4 Défis quotidiens (exemples)
Gagner 3 combats · Obtenir 15 bonnes réponses · Gagner un combat par K.O. · Combattre sur un anime précis · Gagner un combat en difficulté Expert

### 9.5 Badges de base
Premier Pas · Sans Égratignure (combat gagné sans dégât) · Fidèle (7 jours) · Chasseur de Connaissances (100 bonnes réponses) · Montée en Grade (niveau 10) · K.O. Éclair (victoire par K.O. avant la 5ᵉ question)

### 9.6 Données techniques
- Minimum 10 000 questions au lancement, 5 animes minimum (One Piece, Naruto, Dragon Ball, Jujutsu Kaisen, Bleach recommandés)
- iOS 14+ / Android 8+
- Temps de chargement cible < 2s
- Animations de combat en 2D, optimisées pour rester fluides sur téléphones d'entrée de gamme

---

## 10. V1.5 → V5 — APERÇU (POST-MVP)

*(Détail complet à reprendre uniquement une fois la V1 validée — ne pas anticiper le code avant.)*

- **V1.5** : collection de skins (achat/déblocage), classements (mondial/national/amis), système d'amis, notifications push, partage de résultats
- **V2 — Le Verse** : duels temps réel (Firebase) réutilisant le `combat_engine` de la V1 contre un vrai joueur, divisions inspirées eFootball, matchmaking, coop, invitation par code
- **V3** : saisons (8 semaines), événements temporaires, tournois, missions longue durée
- **V4** : monnaie virtuelle (Verse Coins), boutique cosmétique complète, Pass Premium, pay-to-win strictement cosmétique/confort (jamais d'avantage compétitif direct)
- **V5** : Battle Royale Quiz, guildes/clans, classement mondial, expansion vers manhwa/webtoon/jeux vidéo

---

## 11. SÉCURITÉ

- Aucune clé API en dur dans le code — toujours `.env`, toujours dans `.gitignore`
- Validation des réponses de combat **côté serveur uniquement** (Edge Function) — le client ne reçoit jamais la bonne réponse à l'avance, ni ne calcule lui-même les dégâts
- Mots de passe gérés exclusivement par Supabase Auth (jamais stockés/gérés manuellement)
- Sessions avec expiration (JWT + refresh token)
- Dashboard admin sur authentification séparée de l'app mobile, accès restreint à Tariq/Heat
- Avant chaque `git push`, vérifier qu'aucun secret n'est présent dans les fichiers commités (Claude Code doit le signaler explicitement)

---

## 12. WORKFLOW GIT / GITHUB

1. Repo : `https://github.com/Tarikshiba/otaku_verse`
2. Branche principale : `main`
3. Claude Code **ne push jamais**. Il prépare les fichiers, propose un message de commit clair, et dit à Tariq : *"Tu peux push maintenant."*
4. Commandes que Tariq exécutera (Claude Code les lui rappelle à chaque fois) :
   ```
   git add .
   git commit -m "message proposé par Claude"
   git push
   ```
5. Un commit par étape terminée du plan d'exécution (section 8) — pas de commit géant fourre-tout.

---

## 13. OUTILS À INSTALLER

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

## 14. CHECKLIST DE FIN DE V1

- [ ] Inscription/connexion fonctionnelles sur émulateur ET téléphone physique
- [ ] Combat jouable sans crash sur 50 combats de suite
- [ ] Les deux conditions de fin de combat fonctionnent (K.O. avant 10 questions, décompte à la 10ᵉ question)
- [ ] Le système de combo (3 bonnes réponses d'affilée) déclenche bien l'attaque spéciale
- [ ] Le bot ajuste sa difficulté selon le paramétrage choisi
- [ ] XP, niveaux, rangs corrects après chaque combat
- [ ] Défis quotidiens générés et reset à minuit
- [ ] Badges attribués correctement
- [ ] Récompense de connexion quotidienne fonctionnelle
- [ ] Skin 3D visible et rotatif dans le profil
- [ ] Dashboard admin : import de questions, gestion utilisateurs OK
- [ ] Validation des réponses et calcul des dégâts vérifiés côté serveur (test : tenter de tricher côté client échoue)
- [ ] Aucune clé API exposée dans le repo Git
- [ ] Temps de chargement < 2s
- [ ] Design conforme à la direction artistique (section 2) — validé visuellement par Tariq, y compris le passage vertical/horizontal

---

## 15. GLOSSAIRE

| Terme | Définition |
|---|---|
| Le Verse | Univers multijoueur compétitif de l'app |
| Combat | Affrontement de quiz (joueur vs bot en V1, joueur vs joueur en V2), avec PV, dégâts et combos |
| Combo | Trois bonnes réponses d'affilée déclenchant une attaque spéciale animée |
| K.O. | Fin immédiate d'un combat quand un des deux personnages atteint 0 PV |
| Edge Function | Fonction serveur Supabase (logique métier sécurisée) |
| Riverpod | Librairie de gestion d'état Flutter |
| Division | Échelon compétitif du Verse (V2, inspiré eFootball) |
| PROGRESS.md | Carnet de bord technique maintenu par Claude Code à chaque session |

---

*Document version 2.1 — Otaku Verse — Tariq (Dr. X) × Heat*
