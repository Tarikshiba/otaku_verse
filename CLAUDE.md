# CLAUDE.md — Contexte permanent du projet Otaku Verse

> ⚠️ CE FICHIER EST LU AUTOMATIQUEMENT PAR CLAUDE CODE AU DÉMARRAGE DE CHAQUE SESSION.
> Tariq (alias Dr. X) n'a jamais besoin de répéter le contexte. Tout est ici.

---

## QUI JE SUIS EN TANT QUE CLAUDE CODE SUR CE PROJET

Je travaille avec **Tariq**, étudiant en cybersécurité (SIMAC, UNCHK Sénégal), autodidacte en code depuis 2019, débutant sur Flutter/Dart. Son collaborateur s'appelle **Heat** (50/50 sur le projet, Heat gère le budget, Tariq gère 100% de la technique).

**Règles impératives de comportement :**

1. **Tariq ne connaît PAS le langage qu'on utilise (Dart/Flutter).** Chaque bout de code doit être commenté simplement, en français, comme si j'expliquais à quelqu'un qui code pour la première fois dans ce langage. Pas de jargon non expliqué.
2. **Je ne code jamais plusieurs fonctionnalités d'un coup.** On avance étape par étape, on teste, on valide ensemble, puis on continue.
3. **Je ne casse jamais ce qui fonctionne déjà.** Avant toute modification d'un fichier existant, je vérifie l'impact sur le reste du projet (voir architecture modulaire dans le ROADMAP).
4. **Je ne push jamais sur GitHub moi-même.** C'est TOUJOURS Tariq qui fait le `git push`. Mon rôle : lui dire clairement quand un jalon est atteint et prêt à être poussé, avec le message de commit suggéré.
5. **Sécurité systématique :** jamais de clé API en dur dans le code, toujours via variables d'environnement (`.env`, jamais committé — vérifier `.gitignore` à chaque session).
6. **Design :** voir section "Direction artistique" du ROADMAP — jamais de design générique "app IA" (pas de glassmorphism fade, pas de dégradés violet-bleu mous, pas d'icônes Material par défaut). Le style doit crier MANGA, pas SaaS.

---

## AU DÉBUT DE CHAQUE SESSION, JE DOIS

1. Lire ce fichier `CLAUDE.md` (fait automatiquement).
2. Lire `ROADMAP_OTAKU_VERSE.md` à la racine pour le cahier des charges complet.
3. Lire `PROGRESS.md` à la racine — **c'est mon carnet de bord**. Il contient :
   - Où on en est exactement (version, module, dernière tâche terminée)
   - Ce qui a été testé et validé
   - Ce qui reste à faire pour la suite
   - Les décisions techniques prises en cours de route (et pourquoi)
   - Les problèmes rencontrés et comment ils ont été résolus
4. Résumer à Tariq en 3-4 phrases où on en est avant de continuer, pour qu'il confirme qu'on reprend bien où il faut.

## À LA FIN DE CHAQUE SESSION (ou à chaque étape significative), JE DOIS

1. Mettre à jour `PROGRESS.md` avec précision (voir template dans ce fichier plus bas).
2. Dire explicitement à Tariq : **"On peut push maintenant. Voici le message de commit suggéré : [message]"**
3. Ne jamais laisser une session se terminer sans que `PROGRESS.md` reflète la réalité exacte de l'avancement.

---

## TEMPLATE DE PROGRESS.md (à créer/mettre à jour)

```markdown
# PROGRESS — Otaku Verse

Dernière mise à jour : [date]
Version en cours : [V1 / V1.5 / V2...]
Module en cours : [ex: auth, quiz_engine...]

## ✅ Terminé et testé
- [liste précise]

## 🔨 En cours
- [tâche actuelle, où on s'est arrêté exactement]

## ⏭️ Prochaine étape
- [action précise à reprendre]

## 🧠 Décisions techniques prises
- [ex: "on utilise Riverpod plutôt que Provider parce que..."]

## ⚠️ Problèmes connus / points d'attention
- [liste]

## 📦 Dernier commit poussé
- [hash ou description + date]
```

---

## STACK TECHNIQUE (rappel rapide — détails dans ROADMAP)

- **App mobile :** Flutter (Dart) — iOS + Android + tablettes
- **Backend principal :** Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **Temps réel (Verse V2+) :** Firebase Realtime Database + Cloud Messaging
- **Dashboard admin :** Next.js + TypeScript + Tailwind (séparé de l'app mobile)
- **Gestion d'état Flutter :** Riverpod (recommandé — simple à expliquer, robuste, évolutif)
- **Repo GitHub :** https://github.com/Tarikshiba/otaku_verse

## STRUCTURE DE DOSSIERS DU PROJET

```
otaku_verse/                      ← dossier racine (ce que tu ouvres dans VS Code)
├── CLAUDE.md                     ← ce fichier
├── ROADMAP_OTAKU_VERSE.md        ← cahier des charges complet
├── PROGRESS.md                   ← carnet de bord (créé à la première session)
├── .gitignore                    ← exclut .env, build/, etc.
├── .env.example                  ← modèle des variables d'environnement (sans vraies clés)
├── app/                          ← application Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/                 ← config, thème, constantes
│   │   ├── features/             ← un dossier par module (auth, quiz, profile...)
│   │   └── shared/                ← widgets réutilisables
│   └── ...
├── questions_db/                  ← fichiers .md des questions de quiz
├── scripts/                        ← scripts d'import questions, utilitaires
└── admin_dashboard/                ← Next.js (à partir de V1 fin / V1.5)
```

---

## RÈGLE D'OR ABSOLUE

> Si je ne suis pas sûr de quelque chose (nom de variable, choix technique, structure), je pose la question à Tariq plutôt que de supposer. Il préfère qu'on avance lentement et juste que vite et cassé.
