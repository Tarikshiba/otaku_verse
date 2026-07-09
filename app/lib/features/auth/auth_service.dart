import 'package:supabase_flutter/supabase_flutter.dart';

/// Service qui gere toutes les operations d'authentification.
/// Utilise Supabase Auth sous le capot.
class AuthService {
  // Raccourci vers le client Supabase
  final _supabase = Supabase.instance.client;

  /// Inscription avec email + mot de passe.
  /// Retourne null si OK, ou un message d'erreur si ca echoue.
  Future<String?> inscription(String email, String motDePasse) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: motDePasse,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erreur inattendue : $e';
    }
  }

  /// Connexion avec email + mot de passe.
  /// Retourne null si OK, ou un message d'erreur si ca echoue.
  Future<String?> connexion(String email, String motDePasse) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: motDePasse,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erreur inattendue : $e';
    }
  }

  /// Deconnexion
  Future<void> deconnexion() async {
    await _supabase.auth.signOut();
  }

  /// Retourne l'utilisateur actuellement connecte (null si personne)
  User? get utilisateurActuel => _supabase.auth.currentUser;

  /// Ecoute les changements d'etat de connexion (connecte, deconnecte, etc.)
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;
}
