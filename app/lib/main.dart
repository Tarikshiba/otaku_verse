import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

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
        // Utilisateur connecte → accueil temporaire
        if (_authService.utilisateurActuel != null) {
          return AccueilTemporaire(authService: _authService);
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

/// Ecran d'accueil temporaire apres connexion.
class AccueilTemporaire extends StatelessWidget {
  final AuthService authService;

  const AccueilTemporaire({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final user = authService.utilisateurActuel;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('OTAKU VERSE', style: OtakuTypo.displayLarge),
              const SizedBox(height: 24),
              const Text('BIENVENUE !', style: OtakuTypo.impact),
              const SizedBox(height: 16),
              const Text('Connecte en tant que :', style: OtakuTypo.bodySmall),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'inconnu',
                style: OtakuTypo.headlineSmall.copyWith(color: OtakuColors.accent),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await authService.deconnexion();
                  },
                  child: const Text('SE DECONNECTER'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
