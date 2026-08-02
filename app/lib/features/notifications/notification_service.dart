import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service de notifications push (Firebase Cloud Messaging).
/// Gere : permission, token FCM, stockage du token dans Supabase,
/// et reception des notifications en foreground/background.
class NotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;

  /// Initialise les notifications :
  /// - Demande la permission
  /// - Recupere le token FCM
  /// - Stocke le token dans la table profiles (pour que le serveur sache ou envoyer)
  /// - Ecoute les messages en foreground
  Future<void> initialiser() async {
    // Demander la permission (Android 13+ l'exige)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return;
    }

    // Recuperer le token FCM de cet appareil
    final token = await _messaging.getToken();
    if (token != null) {
      await _sauvegarderToken(token);
    }

    // Ecouter les changements de token (peut changer si l'app est reinstallee)
    _messaging.onTokenRefresh.listen(_sauvegarderToken);

    // Ecouter les messages quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen(_onMessageForeground);

    // Quand l'utilisateur tape sur une notif (app en background)
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageTap);
  }

  /// Stocke le token FCM dans le profil du joueur (Supabase)
  Future<void> _sauvegarderToken(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('profiles').update({
      'fcm_token': token,
    }).eq('id', userId);
  }

  /// Notification recue alors que l'app est ouverte
  void _onMessageForeground(RemoteMessage message) {
    // Pour l'instant on ne fait rien de special en foreground
    // (le point rouge sur Amis se met a jour au prochain refresh)
    // On pourrait afficher un snackbar plus tard
  }

  /// L'utilisateur a tape sur la notification (app en background/fermee)
  void _onMessageTap(RemoteMessage message) {
    // Plus tard : naviguer vers l'ecran Amis si c'est une demande d'ami
  }
}
