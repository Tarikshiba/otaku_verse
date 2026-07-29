# PROGRESS — Otaku Verse

Derniere mise a jour : 2026-07-29
Version en cours : V1
Module en cours : refonte design (pre-etape)

## ATTENTION - CHANGEMENT DE DIRECTION IMPORTANT (2026-07-09)

Suite a un retour d'experience utilisateur, le concept a evolue en profondeur.
Voir ROADMAP_OTAKU_VERSE.md v2.1, section 6 "Le mode Combat" pour le detail complet.

Resume : le quiz solo classique (vertical, question/4 choix dans le vide) est
remplace par un mode combat horizontal contre un bot (PV, degats, combos,
K.O., 10 questions max). Le multijoueur reel reste en V2 comme prevu, mais
reutilisera ce moteur de combat.

## Termine et teste
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

## En cours — Refonte design (DA V2.1 "Apple rencontre Shonen Jump")

### DA recue et en cours d'implementation
Document : OTAKU_VERSE_DA_LIQUID_GLASS.md (10% Liquid Glass, 90% identite manga)

### Refonte etape 1 — FAIT
- Nouveau theme.dart : palette DA V2.1 complete, Google Fonts (Anton, Bebas Neue, Bangers, Manrope, Space Grotesk)
- Widget LiquidGlass reutilisable (backdrop blur, bordure, ombre, teinte par mode)
- Tab bar Liquid Glass flottante avec bouton JOUER central surelevee + glow pulse violet
- AppShell : navigation par tabs (Accueil, Jouer, Amis, Profil) en mode paysage
- Accueil placeholder : top bar verre, banniere evenement, raccourcis (Combat, Defis, Rewards)

### Refonte etape 2 — FAIT
- Hub Jouer : 5 cartes de modes (Solo actif, Division/Events/Duel/Coop "BIENTOT")
- Chaque carte a sa couleur dominante, icone, gradient, glow si actif
- Animation stagger a l'entree (cartes montent une par une, 40ms de decalage)
- Transition Accueil <-> Jouer animee (slide + fade, 400ms easeInOutCubic)
- Solo lance le combat setup

### Refonte etape 3 — FAIT
- Flash blanc d'impact (60ms) avant chaque degat
- Shake violent (150ms, amplitude x2) au lieu de 400ms mou
- Onomatopees en Bangers avec overshoot elastic + double glow (HIT!, SPECIAL!, BOOM!, MISS, K.O.!)
- Tempo reduit : 1.2s de feedback au lieu de 2.5s (combat plus nerveux)
- Couleurs combo : combo2 violet glow, combo3 or
- Barres PV avec typo HUD (Space Grotesk), couleurs pvHaut/pvMoyen/pvCritique
- Vignette rouge qui pulse quand PV < 20% (etat critique visuel)
- Compteur combo avec couleurs distinctes (violet → or a x2+)

### Refonte etape 4 — FAIT
- Combo x3 : changement d'etat total (fond rouge/or overlay, screen shake global, flash intense, "SPECIAL!" geant en or)
- Ecran resultat victoire : radial glow vert, titre 48px avec double glow, K.O.! en or, stats PV cote a cote, XP en carte verre
- Ecran resultat defaite : vignette rouge, titre sobre, pas d'explosion
- Ecran egalite : neutre, titre or
- Boutons REJOUER/ACCUEIL accessibles (scroll si overflow paysage)
- Fix : top bar accueil synchro avec le vrai profil Supabase (niveau, rang)

### Refonte etape 5 — FAIT
- Ecran Amis facade console (DA §9)
- Header avec compteur + bouton AJOUTER en verre teinte
- Tabs de filtrage : En ligne (vert), En combat (orange), Demandes (violet) avec compteurs
- Cartes amis en Liquid Glass : indicateur statut, avatar, pseudo, rang, badge statut, icone defier
- Contenu statique (backend amis prevu V1.5)

### Refonte etape 6 — FAIT
- Textures par section via CustomPainter (placeholder avant vrais SVG en prod)
- Bulles de dialogue en fond ecran Amis, seigaiha en fond Profil
- Systeme SectionTexture reutilisable (5 types : speedlines, seigaiha, eclats, bulles, electrique)
- Opacite 6%, pas d'impact performance
- Note : les vrais assets SVG seront produits pour la mise en production finale

### Refonte etape 7 — FAIT
- Barres PV qui "respirent" (bordure pulse opacite, 800ms boucle)
- Timer pulse/grossit quand < 5s (scale 1.0→1.06, style critique)
- Timer utilise typo HUD (Space Grotesk) + coins arrondis
- Boutons de reponse oscillent subtilement (±1px, decales par index)
- Boutons avec coins arrondis (8px au lieu de 2px)

## REFONTE DESIGN TERMINEE

## Prochaine etape
- Tests globaux V1 (checklist ROADMAP §14)
- Enrichissement base de questions (objectif 10 000, actuellement 20)
- Mise en production (assets SVG definitifs, illustrations originales)

## Decisions techniques prises
- Couleur d'accent : violet electrique #7B2FF7 (peut changer avec la refonte)
- Auth : email sans confirmation (dev)
- Navigation auth : StreamBuilder dans AuthGate
- RLS questions : lecture pour anon + authenticated
- Import questions : service_role key (bypass RLS)
- Timer combat : 20 secondes par question
- PV de depart : 100 pour chaque combattant
- Degats normaux : 15 PV / Degats combo (attaque speciale) : 30 PV
- Seuil combo : 3 bonnes reponses d'affilee (reset a 0 apres declenchement ou mauvaise reponse)
- Bot : probabilite de reussite selon difficulte (facile 30%, moyen 50%, difficile 70%, expert 85%)
- Format de combat : max 10 questions, K.O. immediat possible, sinon decompte PV
- Skin joueur V1 : un seul skin fixe en 3D, rotatif dans le profil (pas de collection avant V1.5)
- Grille de choix 2x2 en paysage (au lieu de liste verticale)
- L'ancien code quiz (quiz_page.dart, quiz_result_page.dart) est conserve mais plus utilise depuis l'accueil
- Dashboard admin : acces restreint a Drx@otaku.admin et Heat@otaku.admin
- Validation reponses : Edge Function cote serveur (fallback local si hors-ligne = reponse consideree fausse)

## Problemes connus / points d'attention
- Flutter non accessible depuis bash de Claude Code (Tariq doit tester manuellement)
- 20 questions One Piece en base (besoin d'enrichir massivement avant lancement — objectif 10 000)
- Le fallback local en cas d'erreur reseau considere la reponse comme fausse (acceptable pour la V1)
- Performances a surveiller sur telephones d'entree de gamme apres la refonte design

## Dernier commit pousse
- "Refonte design etapes 5-6-7 : ecran Amis, textures sections, polish combat" (2026-07-29)
