import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// === SERVICE OBSERVABILITE : FIREBASE CRASHLYTICS & ANALYTICS (PHASE B1 & B2) ===
/// - Capture automatiquement les plantages Flutter et asynchrones avec le modele de telephone
/// - Trace les evenements cles de retention sans jamais bloquer l'interface
/// - Inactif proprement pendant les tests unitaires (`FLUTTER_TEST`)
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _initialized = false;

  bool get _isTestEnv {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// Initialise Crashlytics (capture globale d'erreurs) et Analytics apres Firebase.initializeApp()
  Future<void> initialiser() async {
    if (_initialized || _isTestEnv) return;
    try {
      _analytics = FirebaseAnalytics.instance;
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }
      _initialized = true;
    } catch (_) {
      // Ne jamais faire planter le demarrage si Analytics/Crashlytics est indisponible
    }
  }

  /// Associe l'ID anonymise (UUID Supabase) aux rapports Crashlytics
  Future<void> definirUtilisateur(String? userId) async {
    if (_isTestEnv || !_initialized) return;
    try {
      await _analytics?.setUserId(id: userId);
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
      }
    } catch (_) {}
  }

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    if (_isTestEnv || !_initialized) return;
    try {
      await _analytics?.logEvent(name: name, parameters: params);
    } catch (_) {}
  }

  Future<void> logTutorialPhaseAStart() => _log('tutorial_phase_a_start');
  Future<void> logTutorialPhaseAComplete(String animeSlug) =>
      _log('tutorial_phase_a_complete', {'anime_slug': animeSlug});
  Future<void> logSignupComplete() => _log('signup_complete');
  Future<void> logMatchStart({required String mode, required String difficulty, required String workSlug}) =>
      _log('match_start', {'mode': mode, 'difficulty': difficulty, 'work_slug': workSlug});
  Future<void> logMatchEnd({required String mode, required String outcome, required int r2LoadMs}) =>
      _log('match_end', {'mode': mode, 'outcome': outcome, 'r2_load_ms': r2LoadMs});
  Future<void> logShopOpen(int tabIndex) => _log('shop_open', {'tab_index': tabIndex});
  Future<void> logShareCardExport() => _log('share_card_export');
  Future<void> logQuestionReport(String reason) => _log('question_report', {'reason': reason});

  Future<void> enregistrerErreurNonFatale(Object error, StackTrace stack, {String? contexte}) async {
    if (_isTestEnv || !_initialized || kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.recordError(error, stack, reason: contexte, fatal: false);
    } catch (_) {}
  }
}
