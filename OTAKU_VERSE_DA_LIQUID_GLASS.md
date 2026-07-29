# OTAKU VERSE — DIRECTION ARTISTIQUE V2.1
## "Apple rencontre Shonen Jump" — 10% Liquid Glass, 90% Identité Manga

---

## 0. PHILOSOPHIE (mise à jour — le point le plus important du document)

La V1 de ce document mettait le Liquid Glass un peu partout par défaut. Erreur.

**La règle Apple, correctement appliquée : le verre ne recouvre jamais tout, il sert à faire ressortir un élément précis au-dessus d'un fond qui, lui, reste profond, mat et texturé.** Si tout est en verre, tout devient gris et mou — on perd l'énergie du jeu.

Nouvelle répartition :

> **10% Liquid Glass** → structure la navigation (top bar, bottom bar, cartes flottantes, popups, sélection de mode, notifications, barres de progression)
> **90% identité manga** → énergie du contenu (illustrations, trames, speedlines, onomatopées, animations d'impact, motifs propres à chaque section)

Le Liquid Glass est **l'écrin**. Le manga est **l'univers**. Jamais l'inverse.

Autre changement fondamental par rapport à la V1 : on ne doit **jamais avoir l'impression de charger un nouvel écran**. Chaque tap doit donner l'impression que l'interface **change d'état**, pas qu'elle "va ailleurs" — un bouton devient un titre, un avatar devient une carte profil, une carte de mode devient l'écran de setup. C'est le principe central de Persona 5 / Zenless Zone Zero repris ici : la continuité visuelle entre deux états, jamais une coupure.

Références qui infusent cette DA (sans jamais être copiées littéralement) :
- **eFootball** → fluidité de la structure de hub
- **Zenless Zone Zero** → énergie des animations d'UI
- **Honkai Star Rail** → qualité de finition des cartes
- **Dragon Ball Sparking Zero** → impact et lisibilité des coups
- **Persona 5** → transitions comme changement d'état, pas comme navigation
- **Apple Liquid Glass (iOS 26)** → matériau du HUD, jamais du décor

---

## 1. LE HUB — NOUVELLE STRUCTURE DE NAVIGATION

On abandonne la logique actuelle (Accueil / Défis / Collection / Solo / Amis / Quitter en tabs plats).

### 1.1 Écran Accueil = le HUB
```
              OTAKU VERSE
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   [Avatar] Itachi:Uchiha  Nv.24    🪙 12 450   💎 860

   ┌──────────────────────────────┐
   │  ÉVÉNEMENT — GUERRE DES CLANS │  (bannière verre, illustration pleine largeur)
   │  [ VOIR L'ÉVÉNEMENT ]         │
   └──────────────────────────────┘

   EN BREF
   [Lancer un combat] [Défis du jour] [Récompenses]

   ACTUALITÉS
   [Nouveau skin disponible]

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ACCUEIL   JOUER (bouton central, énorme)   AMIS   PROFIL
```
Le bouton **JOUER** de la tab bar n'est pas une icône comme les autres : c'est un **médaillon central surélevé**, plus gros, en verre teinté violet avec glow permanent — exactement comme le mockup que tu as posté. C'est le cœur de l'app, il doit se voir immédiatement.

### 1.2 Le geste clé : la caméra descend, l'écran ne change pas
Au tap sur JOUER :
- l'écran d'accueil ne se ferme pas et n'est pas remplacé par un push classique
- la **caméra virtuelle descend** (translation Y du contenu Accueil vers le haut, hors champ, sur ~400ms `easeInOutCubic`) pendant que les cartes de modes **montent depuis le bas** et se mettent en place (translateY + fade + scale 0.9→1.0, légèrement décalées dans le temps entre chaque carte — un stagger de 40ms par carte pour un effet de vague, pas toutes en même temps)
- le bouton JOUER lui-même reste visible en position "active" (glow plus fort) pendant toute cette vue — il sert d'ancre visuelle, on sait toujours qu'on est "dans" Jouer

### 1.3 Grille de cartes de modes (le hub "Jouer")
Chaque mode = une carte immense, verticale, avec :
- illustration monochrome/dégradée d'un personnage en fond (silhouette stylisée manga — voir note IP en §9)
- bande verticale latérale avec le nom du mode en typo façon tranche de tome manga
- texture propre au mode en surimpression (voir §4)
- reflet Liquid Glass fin qui glisse sur la carte au survol/tap
- au tap : la carte **grandit et devient l'écran suivant** (morph, pas un push — voir §7.2)

| Mode | Couleur dominante | Contenu de la carte |
|---|---|---|
| **SOLO** | Violet `#7B2FF7` | Personnage seul, particules ambiantes légères |
| **DIVISION** | Rouge `#F72F4E` | Logo de rang énorme, effets électriques discrets, indication du classement actuel |
| **ÉVÉNEMENTS** | Change selon l'event (or par défaut `#F7B32F`) | Illustration unique qui change avec l'événement en cours, fond légèrement animé |
| **DUEL** | Orange `#FF7A2F` | "VS" énorme, deux silhouettes qui se font face |
| **COOP** | Bleu `#2F8FF7` | Deux personnages, effet de connexion/énergie partagée entre eux |

*(Ajustement vs V1 : Coop passe de cyan à bleu franc, Duel passe de violet à orange — ça évite la confusion avec Solo qui garde le violet signature, et ça donne à chaque mode une identité chromatique bien distincte, cohérent avec la maquette que tu as validée.)*

### 1.4 Navigation secondaire
Sous le HUB, accessible depuis la tab bar (icônes classiques, pas de médaillon géant) : **Accueil · Jouer · Amis · Profil**. Collection, Missions et Boutique restent accessibles en raccourcis depuis l'Accueil (cartes "En bref") plutôt qu'en tabs séparés — ça évite la surcharge de la tab bar et le problème initial où plusieurs tabs redirigeaient au même endroit.

---

## 2. TEXTURES PAR SECTION (le point que ChatGPT pousse plus loin que la V1, et il a raison)

Chaque section a **son propre motif de fond**, jamais une couleur seule. Opacité stricte entre **4% et 8%**, jamais plus (sinon ça pollue la lisibilité) :

| Section | Motif |
|---|---|
| Combat | Speedlines radiales/horizontales |
| Collection | Grille de cases de planche manga (bordures fines type comic panel) |
| Boutique | Motif billets + étoiles |
| Profil | Motif géométrique japonais (seigaiha / asanoha stylisé) |
| Défis / Missions | Éclats façon explosion manga |
| Amis | Bulles de dialogue en filigrane |
| Division | Éclats électriques |
| Événements | Change dynamiquement selon l'event actif |

Ces textures sont des assets SVG/PNG tileables statiques, appliquées en `blend mode overlay`, coût de rendu quasi nul (compatible bas de gamme).

---

## 3. LIQUID GLASS — LISTE STRICTE DES SURFACES AUTORISÉES

**Autorisé (et uniquement ça) :**
- Top bar (avatar, niveau, monnaies)
- Bottom bar / tab bar flottante
- Cartes flottantes (bannière événement, cartes "En bref", cartes de mode dans le hub Jouer)
- Popups / bottom sheets (paramétrage combat, confirmation)
- Écran de sélection de mode de combat (les chips difficulté/anime)
- Notifications / toasts
- Barres de progression (XP, PV — le fond vide de la barre est en verre, le remplissage est un aplat de couleur pleine)

**Interdit :**
- Le fond de scène (toujours mat + texturé, jamais flouté)
- Les illustrations de personnages (jamais floutées, jamais derrière du verre — elles doivent rester nettes et impactantes)
- Le texte lui-même

Spécifications techniques du matériau (inchangées depuis la V1, elles étaient déjà correctes) :
- Verre neutre : `rgba(255,255,255,0.08)` + `blur(24px)` + bordure `rgba(255,255,255,0.14)` 1px
- Verre teinté (par couleur de mode) : fond `couleur à 18% d'opacité` + `blur(20px)` + bordure `couleur à 35% d'opacité`
- Reflet spéculaire : dégradé `rgba(255,255,255,0.25)→transparent` à 120°, glisse au tap (150ms `easeOutCubic`)
- Ombre : `0 8px 32px rgba(0,0,0,0.45)`

---

## 4. PALETTE — MISE À JOUR

| Rôle | Hex |
|---|---|
| Fond absolu | `#0A0A0F` |
| Violet signature (Solo, marque, XP) | `#7B2FF7` |
| Violet glow | `#A970FF` |
| Division | `#F72F4E` |
| Coop | `#2F8FF7` |
| Duel | `#FF7A2F` |
| Événement (défaut) | `#F7B32F` |
| PV haut | `#2ECC71` |
| PV moyen | `#F7B32F` |
| PV critique (<20%) | `#FF2E4D` + pulse |
| Combo x2 | `#A970FF` |
| Combo x3 / Spécial | `#FFD23F` |
| Victoire | `#3FFFB0` |
| Défaite | `#FF2E5C` |

Typographies : inchangées de la V1 (Anton/Bebas Neue pour titres, **Bangers** pour onomatopées, Manrope pour UI, Space Grotesk pour chiffres/HUD).

---

## 5. TAB BAR — COMPORTEMENT DÉTAILLÉ

- Flottante, verre, coins très arrondis, marge 12px des bords
- **Le bouton JOUER central est plus grand que les autres icônes**, légèrement surélevé (translateY -8px par rapport à la ligne des autres icônes), glow violet permanent (pulse lent, opacity 0.5↔0.8 sur 2.5s)
- Sur les autres onglets : un blob de verre teinté glisse sous l'onglet actif (`Curves.easeOutExpo`, 320ms), s'étire légèrement pendant le trajet (scaleX 1.0→1.15→1.0)
- L'icône active grossit légèrement (scale 1.0→1.2, 200ms) et son label texte apparaît progressivement (fade + slide up 4px) alors que les icônes inactives n'affichent pas de label — ça densifie l'info sans surcharger

---

## 6. TRANSITIONS COMME CHANGEMENT D'ÉTAT (pas de navigation classique)

Trois exemples concrets à répliquer partout où c'est possible :

1. **Tap Profil (icône top bar ou tab)** → l'avatar grossit, avance vers le centre de l'écran, et se transforme en la carte profil complète (le cadre hexagonal de l'avatar devient la capsule verre du skin 3D). Jamais un push d'écran.
2. **Tap Collection** → le mot "Collection" (raccourci sur l'accueil) grossit et devient le titre de l'écran Collection pendant que les cartes de la collection montent depuis le bas avec un stagger.
3. **Tap "Lancer un combat"** → le bouton lui-même s'étire et devient directement la première carte du hub Jouer (Solo), sans étape intermédiaire.

Règle générale de timing : `300-400ms`, `Curves.easeInOutCubic`, avec toujours un léger scale-in (0.94→1.0) sur l'élément qui arrive pour donner de la profondeur.

---

## 7. ÉCRAN DE COMBAT — RÈGLE CENTRALE : **RIEN N'EST JAMAIS IMMOBILE**

Même quand le joueur ne fait rien, il doit se passer quelque chose à l'écran en permanence :
- Les barres de PV "respirent" (légère pulsation d'opacité du contour, 3s de boucle)
- Le timer pulse doucement à chaque seconde qui passe (scale 1.0→1.04→1.0, 150ms par tick)
- Le fond a des lignes/speedlines qui défilent très lentement en continu
- Les portraits des combattants clignent des yeux ou ont un micro-mouvement de respiration en boucle
- Les particules ambiantes montent doucement derrière les personnages
- Les boutons de réponse ont une très légère oscillation (translateY ±1px, 4s de boucle) — assez pour dire "je suis vivant", jamais assez pour distraire de la lecture

### 7.1 Rythme du feedback — tout se joue en ~350ms, pas plus
Séquence à la bonne réponse (à enchaîner, pas en série longue) :
`flash (60ms) → whoosh + shake du côté touché (100ms) → texte d'impact "HIT!" en Bangers qui scale-in avec overshoot (120ms) → barre de PV qui se vide avec easing rapide (150ms, en overlap avec le texte) → particules d'impact (80ms) → mise à jour du compteur de combo`
Tout ceci doit être **nerveux**, jamais alangui — c'est la plus grosse différence avec la V1 qui laissait des animations un peu molles (fade simple). Ici chaque étape a de l'overshoot ou du shake, pas de simple fade linéaire.

### 7.2 Combo x3 / Attaque spéciale — changement d'état total de l'écran
Quand le combo atteint x3 :
- le fond entier prend une teinte rouge/or en overlay (transition rapide, 150ms)
- les bords de l'écran vibrent légèrement (translation ±3px aléatoire sur quelques frames)
- le compteur de combo devient gigantesque au centre, texte "SPECIAL ATTACK" en Bangers énorme qui rentre avec un scale-elastic
- puis "BOOM" — flash blanc plein écran (100ms) + explosion façon manga (speedlines radiales qui explosent depuis le point d'impact) + les 30 dégâts s'affichent avec un poids visuel bien supérieur au dégât normal

### 7.3 PV critique (<20%)
Changement d'état global, pas juste une couleur qui change :
- les deux barres passent en rouge avec pulse plus rapide
- le timer clignote
- de légers éclairs traversent le fond de temps en temps
- le fond général s'assombrit légèrement (vignette qui se renforce)
- tout ça communique l'urgence sans qu'on ait besoin de lire un seul mot

---

## 8. ÉCRANS DE RÉSULTAT

**Victoire** : explosion façon manga, confettis stylisés (pas des confettis génériques ronds — des formes d'éclats/étoiles manga), "K.O." qui claque à l'écran, barre d'XP qui se remplit en live avec un tick si level up, badge qui se débloque avec un pop, bouton REJOUER qui arrive avec un rebond élastique.

**Défaite** : traitement différent, pas juste le même écran en rouge — le **verre se fissure visuellement** (overlay de craquelures qui apparaît brièvement sur les cartes), le titre "DÉFAITE" tombe plutôt que de scale-in, les particules ambiantes disparaissent, on ressent un ralentissement. Le bouton REJOUER reste très gros et très accessible — l'idée étant que le joueur en défaite veuille relancer tout de suite, pas qu'il se sente puni dans la navigation.

---

## 9. ÉCRAN AMIS — INTERFACE "CONSOLE", PAS UNE SIMPLE LISTE

Structure en sections empilées, chacune avec compteur :
```
EN LIGNE (3)
🟢 NarutoKing   —   rang, niveau, anime préféré
🟢 Luffy92
🟢 EirenYeager

EN COMBAT (1)
⚔ Zoro   — statut "en combat", non cliquable pour défier

DEMANDES REÇUES (5)   /   DEMANDES ENVOYÉES (2)

[ AJOUTER UN AMI ]
```
Chaque carte ami est une ligne verre fine avec avatar, rang/niveau, anime préféré en tag, et une icône de statut. Le "EN COMBAT" est un état à part entière (pas juste "en ligne") — logique, puisqu'on ne peut pas défier quelqu'un déjà en combat.

---

## 10. PROFIL

Le skin 3D n'est plus juste posé sur le fond : il est dans une **capsule de verre qui tourne doucement en boucle** (léger reflet qui parcourt la capsule), et quand le joueur glisse le doigt sur l'écran, le personnage **suit légèrement le mouvement** (rotation bornée, pas un contrôle 3D complet — un simple `GestureDetector` qui pilote un `AnimationController` de rotation Y sur une plage de ±15°, avec retour élastique à la position de repos si on relâche).

---

## 11. NOTE IMPORTANTE — ILLUSTRATIONS DE PERSONNAGES

La maquette de référence utilise des personnages issus d'animes existants (Naruto, One Piece, etc.) pour montrer l'intention artistique. Pour la version commerciale de l'app, il faudra soit :
- des illustrations **originales** dans un style inspiré manga (silhouettes/persos génériques créés pour Otaku Verse),
- soit des accords de licence explicites si tu veux vraiment utiliser des personnages d'animes précis dans les cartes de mode/questions.

Utiliser des personnages protégés dans les assets commerciaux de l'app (pas juste dans les questions de quiz, qui relèvent plus du fair use factuel) expose à un risque de droits d'auteur direct. Je peux t'aider à écrire un brief d'illustration original si tu veux avancer sur cette base plutôt que sur des persos existants.

---

## 12. PRIORISATION D'IMPLÉMENTATION (mise à jour)

1. Tab bar Liquid Glass + bouton JOUER central surélevé
2. Le hub Jouer avec l'effet "caméra descend / cartes montent" (répond directement à ton retour sur la nav)
3. Feedback de combat nerveux (~350ms, overshoot, shake, flash) — c'est le chantier qui change le plus la sensation de jeu
4. États combo x3 et PV critique (changement d'état global de l'écran)
5. Écran Amis façon console
6. Écrans résultat (victoire/défaite différenciés)
7. Textures par section (§2) — dernier, car cosmétique et non bloquant

---

*Document V2.1 — prêt à être découpé en tickets Flutter, chaque section = un ticket de dev.*
