# ROADMAP PUBLICATION STORES — Otaku Verse (De la Bêta V9.2 à Google Play & App Store)

Objectif : Passer de la version test actuelle (V9.2 fonctionnelle, 22/22 tickets codés, APK 64,9 Mo) à une **application publiable, fluide, sécurisée et prête à encaisser** sur Google Play Store puis Apple App Store.

Document compagnon pour les visuels : `ASSETS_A_CREER_VISUEL_3D.txt`
Suivi d'avancement global : `PROGRESS.md`

---

## PHASE A — Plein Écran Immersif, Refonte UI "Style Free Fire" & 3D (Impact visuel maximal)
- [x] **A1. Mode Plein Écran Immersif & Identité Native**
  - Activer `SystemUiMode.immersiveSticky` dans `app/lib/main.dart` + support des encoches caméra (`shortEdges`) dans Android styles (`values-v28/styles.xml`).
  - Renommer l'application de `otaku_verse` à `Otaku Verse` dans `AndroidManifest.xml` et iOS `Info.plist`.
  - Générer les 5 icônes Android mipmap (`logo_icone.jpg`) et le Splash Screen natif sombre (`logo_sombre.jpg`).
- [x] **A2. Refonte Responsive du Hub Principal (`app_shell.dart`)**
  - Supprimer tous les `Positioned` à pixels fixes (fin définitive des chevauchements sur Samsung A15, iPhone X/11 et petits écrans).
  - Adopter la mise en page aérée inspirée de Free Fire : Top Bar fine (Profil/Rang + OC/VC + Amis/Mail/Paramètres), colonne gauche fine (Boutique, Classements, Quêtes, Saison, Init.), scène centrale large plein écran avec le personnage 3D sur socle, colonne droite compacte, et bas-droite propre avec sélecteur de mode empilé au-dessus du bouton `JOUER`.
- [x] **A3. Sélecteur de Modes Plein Écran (`mode_selector_page.dart`)**
  - Remplacer le petit panneau coulissant actuel par un véritable écran horizontal plein écran sur `modes_selector_bg.webp` avec 2 onglets (`MODES OFFICIELS` / `COMMUNAUTÉ`), 2 grandes cartes phares à gauche (`DIVISION`, `SOLO`) et grille `.webp` à droite pour tous les autres modes.
- [x] **A4. Refonte Aérée du Profil & des Paramètres (`profile_page.dart`, `parametres_page.dart`)**
  - Passer le Profil en disposition 3 colonnes inspirée de Free Fire sur `profil_podium_bg.webp` : onglets verticaux à gauche (`Aperçu`, `Collection`, `Classement`, `Verse Analytics`, `Guide`, `Paramètres`), personnage 3D en grand au centre sur son podium, et fiche joueur respirante à droite.
- [x] **A5. Intégration 3D `.glb` + Décors d'Arène + Audio**
  - Intégrer le viewer 3D léger (`OtakuSkin3DViewer` + `model_viewer_plus`, rotation au doigt 360° + auto-rotate) avec Kio embarqué (0,93 Mo) et les 10 modèles compressés (12,85 Mo total) en streaming/cache Cloudflare R2, plus repli instantané sur PNG transparent.
  - Brancher les décors d'arène (`assets/images/backgrounds/`), les 6 médailles de rangs (`assets/images/ranks/`), les 4 cadres cosmétiques (`assets/images/frames/`) et le gestionnaire audio (`audio_manager.dart`, prêt dès dépôt des 8 `.mp3`).

---

## PHASE B — Observabilité, Stabilité Réseau & Support Joueur (Zéro avis 1 étoile)
- [x] **B1. Firebase Crashlytics (Android & iOS)**
  - Ajouter `firebase_crashlytics` dans `pubspec.yaml` + plugin Gradle Crashlytics + capture `FlutterError.onError` et `PlatformDispatcher.instance.onError` dans `main.dart` (`analytics_service.dart`).
  - Recevoir en temps réel la ligne exacte, le modèle du téléphone et la version Android/iOS de chaque crash.
- [x] **B2. Firebase Analytics & Rétention**
  - Ajouter `firebase_analytics` (`analytics_service.dart`) et tracer les événements clés : `tutorial_phase_a_start/complete`, `signup_complete`, `match_start/end`, `shop_open`, `share_card_export`, `question_report`.
- [x] **B3. Résilience Réseau & Mise à Jour Forcée**
  - Bandeau propre « Connexion perdue — Réessayer » en cas de coupure 4G dans `app_shell.dart`.
  - Contrôle semver `min_app_version` dans `app_feature_flags` (`feature_flags_service.dart`) pour inviter proprement à mettre à jour l'app en cas de correctif critique.
- [x] **B4. Signalement d'Erreurs Questions & Support**
  - Bouton « Signaler » sur l'écran de feedback en combat (`combat_page.dart`, table Supabase `question_reports` lisible dans `admin_dashboard/app/reports/`) + contact support dans les Paramètres.

---

## PHASE C — Blindage Sécurité & Conformité Obligatoire Stores (Bloquants avant sortie publique)
- [x] **C1. Suppression de Compte In-App (Obligatoire Google Play & Apple)**
  - Bouton « Supprimer définitivement mon compte » dans `parametres_page.dart` avec confirmation `SUPPRIMER` + action serveur `delete_account` dans `shop-tutorial-engine` supprimant `auth.users` et les données liées en cascade.
- [x] **C2. Verrouillage SQL `profiles` & Firebase RTDB**
  - Migration SQL durcie (`scripts/v93_securite_observabilite.sql`) interdisant au client de modifier directement `xp_totale`, `niveau`, `rang`, `is_vip`, `pts_division`, `division_id` dans `profiles` (tout passe par Edge Functions/RPC).
  - `"economie": { ".read": false, ".write": false }` dans `scripts/firebase_database_rules.json` (à publier dans Firebase Console).
  - Ancienne clé privée FCM (`a1df729...`) révoquée dans Google Cloud Console et nouvelle clé (`558d7a3...`) active dans `FCM_SERVICE_ACCOUNT` sur Supabase (fichiers locaux supprimés).
- [x] **C3. Documents Légaux Publics**
  - Politique de Confidentialité (`/privacy`) et Conditions Générales d'Utilisation (`/terms`) créées dans `admin_dashboard/app/` + lecteur intégré (`legal_pages.dart`) dans les Paramètres de l'app.

---

## PHASE D — Monétisation Réelle (AdMob + Paiements Vérifiés Serveur)
- [ ] **D1. Google AdMob (Publicités Volontaires Récompensées)**
  - Créer le compte AdMob + unités publicitaires Rewarded Video (`x2 OC`, `+40 OC Coup de Pouce`, `Seconde Chance Solo`).
  - Intégrer `google_mobile_ads` avec vérification serveur (SSV) avant crédit dans `match-engine`.
- [ ] **D2. Google Play Billing & Apple IAP (Achats Intégrés Officiels)**
  - Configurer les 5 Packs VC, le Pass Sans Pub 1 An, le Pack Démarrage et les Abonnements VIP Mensuel/Annuel dans Google Play Console et App Store Connect.
  - Remplacer le mode sandbox de `shop-tutorial-engine` par la vérification cryptographique des reçus officiels côté serveur (Google Play Developer API / Apple App Store Server API).
- [ ] **D3. Boutique Web Mobile Money (Optionnel Afrique de l'Ouest)**
  - Si vous activez Wave / Orange Money / PayDunya, le proposer via une boutique web externe créditant le compte Supabase après validation d'un webhook signé HMAC.

---

## PHASE E — Optimisation Poids, Bêta Fermée & Publication Officielle
- [ ] **E1. Optimisation du Poids (< 25 Mo téléchargés)**
  - Convertir toutes les images lourdes en `.webp`, activer la compilation Android App Bundle obfusquée :
    `flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info`
  - Sauvegarder le keystore Android (`key.properties` + fichier `.jks`) dans au moins 2 endroits sûrs hors-ligne.
- [ ] **E2. Test Fermé Google Play (Obligatoire 14 jours / 12 testeurs)**
  - Créer le compte Google Play Console (25 $ une fois), remplir la fiche Store (captures `store_assets/`, Data Safety, classification âge IARC), publier en piste Test Fermé avec minimum 12 testeurs actifs pendant 14 jours continus.
  - Corriger les éventuels crashs remontés par Firebase Crashlytics.
- [ ] **E3. Lancement Public Palier 1 (Google Play puis iOS App Store)**
  - Ouverture publique en Palier 1 (`Solo` + `Division AI_ONLY` + `Tutoriel` + `Boutique`).
  - Déblocage progressif des Paliers 2 à 6 semaine après semaine directement depuis Supabase `app_feature_flags` sans republier d'APK.
  - Pour iOS : ouverture compte Apple Developer (99 $/an), build depuis un Mac (ou Codemagic CI/CD), soumission TestFlight puis App Store.
