import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'shared/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Paysage force sur toute l'app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

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

/// Decide quel ecran afficher selon l'etat de connexion.
/// Reste TOUJOURS dans l'arbre — ecoute le stream auth en continu.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  bool _afficherInscription = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authService.onAuthStateChange,
      builder: (context, snapshot) {
        // Utilisateur connecte → nouveau shell avec tab bar
        if (_authService.utilisateurActuel != null) {
          return const AppShell();
        }

        // Pas connecte → connexion ou inscription
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

