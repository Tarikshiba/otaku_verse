import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service de notifications push (Firebase Cloud Messaging).
/// Gere : permission, token FCM, stockage du token dans Supabase,
/// et reception des notifications en foreground/background.
class NotificationService {
  // Evite de lancer deux fois l'initialisation des notifications
  static bool _initialise = false;

  /// Initialise les notifications en arriere-plan sans jamais bloquer l'app :
  /// - Verifie que Firebase est bien pret
  /// - Demande la permission (Android 13+)
  /// - Recupere le token FCM avec un delai maximum (timeout)
  /// - Stocke le token dans la table profiles sur Supabase
  Future<void> initialiser() async {
    if (_initialise || Firebase.apps.isEmpty) return;
    _initialise = true;

    try {
      final messaging = FirebaseMessaging.instance;

      // Demander la permission (Android 13+ l'exige) avec delai de securite
      final settings = await messaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
          )
          .timeout(const Duration(seconds: 15));

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      // Recuperer le token FCM de cet appareil sans bloquer si le reseau est lent
      final token = await messaging
          .getToken()
          .timeout(const Duration(seconds: 10));
      if (token != null) {
        await _sauvegarderToken(token);
      }

      // Ecouter les changements de token (peut changer si l'app est reinstallee)
      messaging.onTokenRefresh.listen((nouveauToken) {
        _sauvegarderToken(nouveauToken);
      });

      // Ecouter les messages quand l'app est au premier plan
      FirebaseMessaging.onMessage.listen(_onMessageForeground);

      // Quand l'utilisateur tape sur une notif (app en background)
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageTap);
    } catch (e) {
      // Ne jamais faire planter ni figer l'application si FCM echoue
      debugPrint('NotificationService non bloquant : $e');
    }
  }

  /// Stocke le token FCM dans le profil du joueur (Supabase)
  Future<void> _sauvegarderToken(String token) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('profiles').update({
        'fcm_token': token,
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Sauvegarde token FCM ignoree : $e');
    }
  }

  /// Notification recue alors que l'app est ouverte
  void _onMessageForeground(RemoteMessage message) {
    // Pour l'instant on ne fait rien de special en foreground
    // (le point rouge sur Amis se met a jour au prochain refresh)
  }

  /// L'utilisateur a tape sur la notification (app en background/fermee)
  void _onMessageTap(RemoteMessage message) {
    // Plus tard : naviguer vers l'ecran Amis si c'est une demande d'ami
  }
}
