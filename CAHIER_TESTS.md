# CAHIER DE TESTS V9.3 — Otaku Verse (Test Conjoint Tariq & Heat)

Ce cahier couvre l'ensemble des correctifs terrain V9.2 (Chantier 1), la refonte Free Fire + 10 personnages originaux en 3D animee Mixamo/R2 (Chantier 2) et le socle Stabilite + Securite Stores + Profil Public 3D (Chantier 3).

APK Release signe a installer sur vos deux telephones : `app/build/app/outputs/flutter-apk/app-release.apk` (65,9 Mo)
Cochez chaque case sur le terrain et notez tout bug visuel, latence, calcul suspect ou texte coupe pour le retour de session suivante.

---

## 0. Infrastructure Deployee en Production (Deja Verifiee)
- [x] SQL V9.2 (`scripts/v92_correctifs_terrain.sql`) + SQL V9.3 (`scripts/v93_securite_observabilite.sql`) executes sur Supabase.
- [x] Edge Functions deployees : `match-engine`, `valider-reponse`, `shop-tutorial-engine`, `envoyer-notification`.
- [x] Cle privee FCM renouvelee dans `FCM_SERVICE_ACCOUNT` (ancienne cle revoquee), regles Firebase RTDB publiees (`economie: false`).
- [x] Cloudflare R2 + Worker (`otaku-verse-quiz-api`) : 1 254 803 questions + 10 modeles 3D `.glb` animes (`skin_kio.glb` a `skin_cassio_vey.glb`).

---

## 1. Ouverture, Identite Native & Plein Ecran (Phase A1)
- [ ] **Icone & nom d'application** : verifier sur l'ecran d'accueil Android que l'icone affiche bien le renard transparent sur fond sombre (sans damier ni bord blanc) et que le nom est `Otaku Verse`.
- [ ] **Splash Android 12+ & Animation Coupure Manga** : au lancement, verifier le fond sombre sans cercle blanc disgracieux, puis la coupure lumineuse cyan/orange + logo renard + titre `OTAKU VERSE` (~1,8 s, cliquable pour passer).
- [ ] **Mode plein ecran immersif (`immersiveSticky`)** : verifier que les barres Android restent masquees en paysage, sans zone noire bizarre autour de l'encoche camera.

---

## 2. Authentification & Tutoriel 2 Phases (Tests 3, 5, 6)
- [ ] **Validation Auth** : verifier le rejet d'un email invalide, le blocage d'un mot de passe faible (< 8 car., sans majuscule/chiffre) et le lien `Mot de passe oublie ?`.
- [ ] **Phase A (installation propre ou apres deconnexion + nouveau compte)** :
  - Carrousel des 21 oeuvres reelles R2 (verifier l'absence de Solo Leveling).
  - Combat decouverte 5 questions avec animations `HAYA!!`, `COMBO x3` et `K.O. · KECCHAKU!` bien lisibles.
  - Achat guide du 1er Goodies (`Mazu`, 300 OC) -> creation de compte -> verifie `+100 XP` et `Mazu` equipe sur le Hub.
- [ ] **Visite guidee du Hub** : verifier l'affichage des 4 bulles de bienvenue a la premiere arrivee sur l'Accueil.
- [ ] **Validation automatique Init Phase B (`Init. X/6`)** :
  - Faire chaque action (Calendrier J1, 1 Solo, 1 Division, visiter Boutique, visiter Classements/Profil, ouvrir Guide du jeu) et revenir sur l'Accueil.
  - Verifier que chaque etape se coche toute seule sans appuyer sur `VERIFIER`, et qu'a 6/6 la recompense tombe (`+25 VC`, `+100 OC`, Titre `Initie du Verse` avec accents).

---

## 3. Accueil Free Fire, 3D Animee & Selecteur de Modes (Phase A2-A5, Tests 7, 9)
- [ ] **Zero chevauchement sur petit ecran (Tecno Spark 20)** : verifier Top Bar (Profil + cadre + medaille rang + XP + OC + VC + `PUB +OC` + Boite aux lettres + Parametres), colonne gauche, scene 3D centrale et colonne droite.
- [ ] **Personnage 3D anime au sol** : verifier que Kio (et tout autre perso equipe) joue son animation Mixamo face a toi (sans T-Pose), pieds ancres sur le cercle lumineux, rotation libre 360° au doigt et bouton `3D / 2D` fonctionnel.
- [ ] **Pastille rouge Boite aux lettres** : verifier a la premiere connexion du jour que la pastille rouge apparait immediatement sur l'enveloppe (+15 XP Connexion quotidienne a reclamer).
- [ ] **Bouton `PUB +OC` sur l'Accueil** : cliquer dessus et verifier le credit `+25 OC` (0 VC, plafond 5/jour).
- [ ] **Selecteur de modes plein ecran** : cliquer sur `CHANGER DE MODE` en bas a droite, verifier le fond `modes_selector_bg.webp`, les 2 onglets (`MODES OFFICIELS` / `COMMUNAUTE`), les grandes cartes `DIVISION` et `SOLO` a gauche, la grille des autres modes a droite et le modal `M'alerter` sur les modes verrouilles.
- [ ] **Bandeau hors-ligne (Phase B3)** : couper la 4G/Wi-Fi, relancer/actualiser le Hub et verifier l'apparition du bandeau rouge `Connexion perdue` + bouton `REESSAYER`.

---

## 4. Combat Solo 350 PV, 4 Malus, Signalement & Economie (Tests 11, 15-25, 30, Phase B4)
- [ ] **Configuration Solo** : verifier les 21 oeuvres (noms propres sans underscore), 6 difficultes, mini-explications avant-match, frais `0 OC` du Niv. 1 au Niv. 5, `15/30/50 OC` des Niv. 6.
- [ ] **Assurance XP (25 OC) & Puits de Confiance (15/30 OC)** :
  - Verifier l'explication claire sur l'Assurance XP si Niv. 1-5 (grise/inutile car XP deja protegee).
  - En cas de mise Puits de Confiance, verifier en fin de match le detail complet (`mise`, `retour`, `statut`, `raison`).
- [ ] **Matrice 350 PV & lisibilite** : verifier le Face-Off d'entree, le nom propre de l'oeuvre + arc en haut de chaque question, les choix A/B/C/D melanges, le Badge de Rang + Niveau credible sur le Bot IA, et les degats exacts (`-15/-20` Normal, `-18/-23` Haya!!, `-30/-35` Combo x3, `-36/-41` Combo + Haya!!, `-5` Auto-faute).
- [ ] **Les 4 Malus (mode Malicieux)** : verifier `Texte Inverse`, `Sans Voyelles` (max 1 voyelle masquee par mot avec `•`), `Brouillard d'Encre` et `Eclipse 5s` (plus aucun Effet Miroir).
- [ ] **Bouton `Signaler` en combat (Phase B4)** : apres une reponse, cliquer sur `Signaler`, choisir un motif + commentaire optionnel et envoyer ; verifier le message de confirmation (puis verifier que le signalement apparait bien dans `question_reports` / admin `/reports`).
- [ ] **AFK Solo, Seconde Chance & Fin de match** :
  - Laisser 2 questions expirer en Solo : verifier l'avertissement jaune (et 0 cooldown 5 min apres un Solo).
  - Tomber a 0 PV en Solo : verifier la fenetre `Seconde Chance (+100 PV)` pendant 5s.
  - Verifier le gros bouton `REJOUER`, `DOUBLER MES OC (x2)`, `K.O. · KECCHAKU!` et zero erreur brute `429` ou `FunctionException`.
- [ ] **Protection XP Niv. 1-5 vs Niv. 6+** : verifier 0 perte d'XP en defaite du Niv. 1 au Niv. 5 (sauf abandon volontaire `-50 XP`), et perte nette seche a partir du Niv. 6.

---

## 5. Division, Classements & Profil Public 3D (Tests 10, 26, 27, 3.1)
- [ ] **Rubrique `Classements` sur l'Accueil** : verifier l'affichage prioritaire Division (10 paliers avec seuils et frais OC, bandeau cagnotte dynamique, bouton `JOUER > DIVISION`, avatars reels des joueurs).
- [ ] **Classement General XP** : verifier que le bandeau cagnotte n'y apparait plus.
- [ ] **Profil Public 3D (clic sur un autre joueur dans Classements ou Amis)** :
  - Verifier l'ouverture du podium 3 colonnes avec SON personnage 3D anime, son cadre, sa medaille de rang PNG, sa Division, son pays, ses stats publiques et l'onglet `Skins` en lecture seule.
  - Verifier qu'on ne peut rien modifier sur son profil, et que ni son email ni ses soldes OC/VC n'apparaissent.
  - Tester le bouton `AJOUTER` (demande d'ami).

---

## 6. Boutique Showroom 3D, 10 Personnages, Profil 3 Colonnes & Partage 9:16 (Tests 31, 36-41)
- [ ] **10 personnages originaux sans copyright** : verifier dans `Boutique > Goodies` les noms `Kio`, `Mazu`, `Tavik`, `Ruve`, `Hesk`, `Ilka`, `Vael`, `Dakore`, `Ysae`, `Cassio Vey` (+ Fondateurs `Soryn`, `Nyxara`).
- [ ] **Streaming 3D R2 a la demande** : ouvrir la fiche de 2 ou 3 autres persos (ex: `Ysae`, `Ilka`, `Cassio Vey`), verifier le telechargement 3D anime depuis Cloudflare R2 et que la 2e ouverture est instantanee (cache local `v2_anim`).
- [ ] **Cosmetiques, Calendrier 21j & Recharges OC** : verifier l'apercu des 4 cadres PNG transparents, la reclamation Calendrier 21j, `Coup de Pouce +40 OC`, et les 3 recharges OC (Jour manque 40/80/160 OC ou gratuit VIP, Aura 20 OC, 3 Defis Bonus 50 OC).
- [ ] **Offres VIP & 5 Packs VC** : verifier la mise en avant VIP Annuel (`29 900 FCFA / -29 %`), le panneau explicatif detaille au clic sur chaque pack/abonnement et les 8 privileges VIP.
- [ ] **Profil 3 colonnes & Verse Analytics VIP** : verifier les onglets a gauche (`Apercu`, `Collection`, `Classement`, `Verse Analytics`, `Guide du jeu`, `Parametres`), le podium 3D central, l'equipement d'un skin/cadre dans `Collection`, la page `Guide du jeu` et la page plein ecran `Verse Analytics (7 Stats Pro)` une fois VIP actif.
- [ ] **Carte de Partage 9:16** : partager une victoire et verifier le logo transparent `logo_icone.png`, le nom propre de l'oeuvre, l'adversaire non tronque, les accents francais et l'anonymisation par defaut.

---

## 7. Parametres, Conformite Stores & Securite (Phase C)
- [ ] **Audio & Cache 3D** : tester les interrupteurs Musique/Effets sonores et le bouton `VIDER` sur le cache local 3D.
- [ ] **Support & Documents Legaux** : ouvrir `Politique de Confidentialite`, `CGU` et `Support & Contact` dans Parametres.
- [ ] **Suppression de compte (a tester UNIQUEMENT sur un compte jetable de test !)** : tester `Supprimer definitivement mon compte`, verifier qu'il exige de taper `SUPPRIMER`, puis verifier que le compte est bien supprime et deconnecte proprement.
- [ ] **Deconnexion propre** : tester `Deconnexion` et verifier le retour propre sans blocage.
