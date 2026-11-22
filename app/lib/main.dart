import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/notifications/notification_service.dart';
import 'features/tutorial/tutorial_phase_a_page.dart';
import 'features/tutorial/tutorial_service.dart';
import 'shared/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialiser Firebase (pour les notifications push)
  await Firebase.initializeApp();

  // Orientation horizontale forcee sur toute l'app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialiser les notifications push
  await NotificationService().initialiser();

  runApp(const OtakuVerseApp());
}

class OtakuVerseApp extends StatelessWidget {
  const OtakuVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Otaku Verse',
      debugShowCheckedModeBanner: false,
      theme: otakuTheme,
      home: const AuthGate(),
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

  bool _afficherInscription = false;
  bool _phaseADoneChecked = false;
  bool _phaseADone = true;

  @override
  void initState() {
    super.initState();
    _verifierPhaseA();
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
    return StreamBuilder<AuthState>(
      stream: _authService.onAuthStateChange,
      builder: (context, snapshot) {
        // Utilisateur connecte -> Hub principal AppShell
        if (_authService.utilisateurActuel != null) {
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
      },
    );
  }
}
