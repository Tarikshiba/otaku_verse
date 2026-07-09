import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Point d'entree de l'application Otaku Verse.
/// On initialise dotenv (pour lire les cles depuis .env)
/// puis Supabase avant de lancer l'app.
void main() async {
  // Obligatoire avant d'appeler du code async dans main()
  WidgetsFlutterBinding.ensureInitialized();

  // Charge les variables depuis le fichier .env
  await dotenv.load(fileName: ".env");

  // Initialise Supabase avec l'URL et la cle anon
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const OtakuVerseApp());
}

/// Widget racine de l'application
class OtakuVerseApp extends StatelessWidget {
  const OtakuVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Otaku Verse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const ConnexionTestPage(),
    );
  }
}

/// Page temporaire qui affiche si la connexion a Supabase fonctionne.
/// On la remplacera par le vrai ecran d'accueil a l'etape 3.
class ConnexionTestPage extends StatefulWidget {
  const ConnexionTestPage({super.key});

  @override
  State<ConnexionTestPage> createState() => _ConnexionTestPageState();
}

class _ConnexionTestPageState extends State<ConnexionTestPage> {
  String _status = 'Test en cours...';

  @override
  void initState() {
    super.initState();
    _testConnexion();
  }

  /// Teste la connexion a Supabase.
  /// Si l'initialisation s'est bien passee, le client existe et on est connecte.
  Future<void> _testConnexion() async {
    try {
      final supabase = Supabase.instance.client;
      // Requete simple : demander les donnees d'une table qui n'existe pas encore
      // Ca retourne une liste vide (pas une erreur) si la connexion est OK
      await supabase.from('_test_connexion').select().limit(1);
      // Si on arrive ici sans exception de type reseau, la connexion fonctionne
      setState(() {
        _status = 'Connexion a Supabase reussie !';
      });
    } catch (e) {
      // Une erreur 404 ou "relation does not exist" = connexion OK, table absente (normal)
      final erreur = e.toString();
      if (erreur.contains('does not exist') || erreur.contains('404') || erreur.contains('42P01')) {
        setState(() {
          _status = 'Connexion a Supabase reussie !';
        });
      } else {
        setState(() {
          _status = 'Erreur : $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'OTAKU VERSE',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _status.contains('reussie')
                      ? Colors.greenAccent
                      : _status.contains('Erreur')
                          ? Colors.redAccent
                          : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
