import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/core/analytics_service.dart';
import 'features/notifications/notification_service.dart';
import 'features/tutorial/tutorial_phase_a_page.dart';
import 'features/tutorial/tutorial_service.dart';
import 'shared/app_shell.dart';
import 'shared/splash_intro_overlay.dart';

void main() async {
  // Prepare le moteur Flutter avant tout appel natif (Firebase, orientation, etc.)
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation horizontale forcee + Plein Ecran Immersif des le demarrage (Phase A1)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialiser Firebase + Crashlytics + Analytics sans bloquer si un service echoue
  bool firebasePret = false;
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    firebasePret = true;
    await AnalyticsService.instance.initialiser();
  } catch (e) {
    debugPrint('Demarrage Firebase ignore (non bloquant) : $e');
  }

  // Charger le fichier .env et initialiser Supabase (indispensable pour le jeu)
  String? erreurDemarrage;
  try {
    await dotenv.load(fileName: ".env");
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (supabaseUrl == null ||
        supabaseUrl.isEmpty ||
        supabaseAnonKey == null ||
        supabaseAnonKey.isEmpty) {
      throw StateError('Variables SUPABASE_URL ou SUPABASE_ANON_KEY absentes.');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    ).timeout(const Duration(seconds: 12));
  } catch (e) {
    erreurDemarrage = e.toString();
    debugPrint('Erreur critique au demarrage : $e');
  }

  // Si Supabase n'a pas pu s'initialiser, afficher un ecran clair au lieu d'un splash fige
  if (erreurDemarrage != null) {
    runApp(_StartupErrorApp(message: erreurDemarrage));
    return;
  }

  // Lancer l'interface immediatement (declenche SplashIntroOverlay sans attendre FCM)
  runApp(const OtakuVerseApp());

  // Initialiser les notifications push en arriere-plan apres l'affichage du 1er ecran
  if (firebasePret) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService().initialiser());
    });
  }
}

/// Ecran de secours affiche uniquement si le demarrage critique (Supabase/.env) echoue.
class _StartupErrorApp extends StatelessWidget {
  final String message;
  const _StartupErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Otaku Verse',
      debugShowCheckedModeBanner: false,
      theme: otakuTheme,
      home: Scaffold(
        backgroundColor: OtakuColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, color: OtakuColors.accent, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Impossible de démarrer Otaku Verse',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OtakuVerseApp extends StatelessWidget {
  const OtakuVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Otaku Verse',
      debugShowCheckedModeBanner: false,
      theme: otakuTheme,
      home: const SplashIntroOverlay(child: AuthGate()),
    );
  }
}

/// Decide quel ecran afficher selon l'etat de connexion et du Tutoriel Phase A.
/// Reste TOUJOURS dans l'arbre et ecoute le stream auth en continu.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  final _tutorialService = TutorialService();
  StreamSubscription<AuthState>? _authSub;

  User? _utilisateur;
  bool _afficherInscription = false;
  bool _phaseADoneChecked = false;
  bool _phaseADone = true;

  @override
  void initState() {
    super.initState();
    _utilisateur = _authService.utilisateurActuel;
    _verifierPhaseA();

    // Ecoute les changements de session UNE SEULE FOIS par evenement
    // (evite la boucle infinie ou signedOut reinitialisait _phaseADone a chaque clic)
    _authSub = _authService.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final event = data.event;
      final user = data.session?.user ?? _authService.utilisateurActuel;

      setState(() {
        _utilisateur = user;
        if (event == AuthChangeEvent.signedOut) {
          _phaseADone = false;
          _afficherInscription = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _verifierPhaseA() async {
    final done = await _tutorialService.isPhaseADoneLocally();
    if (!mounted) return;
    setState(() {
      _phaseADone = done;
      _phaseADoneChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Utilisateur connecte -> Hub principal AppShell
    final user = _utilisateur ?? _authService.utilisateurActuel;
    if (user != null) {
      AnalyticsService.instance.definirUtilisateur(user.id);
      return const AppShell();
    }

    if (!_phaseADoneChecked) {
      return const Scaffold(
        backgroundColor: OtakuColors.background,
        body: Center(child: CircularProgressIndicator(color: OtakuColors.accent)),
      );
    }

    // Nouveau joueur non connecte -> Tutoriel Phase A avant creation de compte (§4.1)
    if (!_phaseADone) {
      return TutorialPhaseAPage(
        onTermineVersInscription: () {
          setState(() {
            _phaseADone = true;
            _afficherInscription = true;
          });
        },
        onDejaUnCompte: () {
          setState(() {
            _phaseADone = true;
            _afficherInscription = false;
          });
        },
      );
    }

    // Pas connecte -> connexion ou inscription
    if (_afficherInscription) {
      return RegisterPage(
        onBasculeConnexion: () => setState(() => _afficherInscription = false),
      );
    }
    return LoginPage(
      onBasculeInscription: () => setState(() => _afficherInscription = true),
    );
  }
}
