import 'package:supabase_flutter/supabase_flutter.dart';

/// === SERVICE DE PILOTAGE A DISTANCE (FEATURE FLAGS V9.2 — §8.1) ===
/// Permet d'ouvrir ou fermer chaque mode de jeu depuis Supabase (table app_feature_flags)
/// sans jamais avoir besoin de republier une mise a jour sur le Play Store ou l'App Store.
class FeatureFlag {
  final String key;
  final bool isEnabled;
  final Map<String, dynamic> modeConfig;
  final String launchLabel;

  const FeatureFlag({
    required this.key,
    required this.isEnabled,
    required this.modeConfig,
    required this.launchLabel,
  });

  factory FeatureFlag.fromMap(Map<String, dynamic> map) {
    final rawConfig = map['mode_config'];
    return FeatureFlag(
      key: map['flag_key'] as String? ?? '',
      isEnabled: map['is_enabled'] == true,
      modeConfig: rawConfig is Map ? Map<String, dynamic>.from(rawConfig) : {},
      launchLabel: map['launch_label'] as String? ?? 'Bientot disponible',
    );
  }
}

class FeatureFlagsService {
  // Singleton simple pour partager le cache des flags dans toute l'app
  static final FeatureFlagsService _instance = FeatureFlagsService._internal();
  factory FeatureFlagsService() => _instance;
  FeatureFlagsService._internal();

  final _supabase = Supabase.instance.client;

  // Valeurs par defaut Palier 1 (utilisees tant que le serveur n'a pas repondu)
  final Map<String, FeatureFlag> _flags = {
    'mode_solo': const FeatureFlag(
      key: 'mode_solo',
      isEnabled: true,
      modeConfig: {'initial_hp': 350, 'max_questions': 40, 'global_timer_sec': 120},
      launchLabel: 'Ouvert',
    ),
    'mode_division': const FeatureFlag(
      key: 'mode_division',
      isEnabled: true,
      modeConfig: {'division_matchmaking_mode': 'AI_ONLY', 'initial_hp': 350, 'max_questions': 40},
      launchLabel: 'Ouvert — Saison 1',
    ),
    'mode_duel_ami': const FeatureFlag(
      key: 'mode_duel_ami',
      isEnabled: false,
      modeConfig: {},
      launchLabel: 'Ouverture Semaine 2 !',
    ),
    'mode_salon_live': const FeatureFlag(
      key: 'mode_salon_live',
      isEnabled: false,
      modeConfig: {'cost_vc_non_vip': 150},
      launchLabel: 'Ouverture Semaine 3 !',
    ),
    'mode_guildes': const FeatureFlag(
      key: 'mode_guildes',
      isEnabled: false,
      modeConfig: {'max_members': 4},
      launchLabel: 'Ouverture Semaine 5 !',
    ),
    'mode_coop': const FeatureFlag(
      key: 'mode_coop',
      isEnabled: false,
      modeConfig: {'cost_vc': 0, 'team_hp': 525},
      launchLabel: 'Ouverture Semaine 5 !',
    ),
    'mode_donjons': const FeatureFlag(
      key: 'mode_donjons',
      isEnabled: false,
      modeConfig: {'cost_vc_non_vip': 100},
      launchLabel: 'Ouverture Semaine 5 !',
    ),
    'mode_battle_royale': const FeatureFlag(
      key: 'mode_battle_royale',
      isEnabled: false,
      modeConfig: {'max_players': 10, 'fill_bots_after_seconds': 8},
      launchLabel: 'Ouverture Semaine 6 !',
    ),
    'mode_events_tournois': const FeatureFlag(
      key: 'mode_events_tournois',
      isEnabled: false,
      modeConfig: {},
      launchLabel: 'Ouverture Semaine 6 !',
    ),
  };

  /// Charge tous les flags depuis Supabase et met a jour le cache local.
  Future<void> chargerFlags() async {
    try {
      final rows = await _supabase.from('app_feature_flags').select();
      for (final row in (rows as List)) {
        final flag = FeatureFlag.fromMap(Map<String, dynamic>.from(row));
        if (flag.key.isNotEmpty) {
          _flags[flag.key] = flag;
        }
      }
    } catch (_) {
      // En cas de perte reseau, on garde les valeurs de repli Palier 1
    }
  }

  /// Indique si un mode est ouvert aux joueurs.
  bool estOuvert(String flagKey) => _flags[flagKey]?.isEnabled ?? false;

  /// Retourne le texte d'annonce (ex: "Ouverture Semaine 2 !").
  String labelLancement(String flagKey) =>
      _flags[flagKey]?.launchLabel ?? 'Bientot disponible';

  /// Retourne la configuration JSON du mode (ex: division_matchmaking_mode).
  Map<String, dynamic> configMode(String flagKey) =>
      _flags[flagKey]?.modeConfig ?? const {};

  /// Retourne le mode actif de matchmaking en Division (AI_ONLY, HYBRID_5S, PVP_PRIORITY_8S).
  String get modeMatchmakingDivision =>
      configMode('mode_division')['division_matchmaking_mode']?.toString() ?? 'AI_ONLY';

  /// Verifie si le joueur s'est deja inscrit sur la liste d'attente d'un mode verrouille.
  Future<bool> estInscritAlerte(String flagKey) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final res = await _supabase
          .from('feature_waitlist')
          .select('id')
          .eq('user_id', userId)
          .eq('flag_key', flagKey)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  /// Inscrit le joueur pour recevoir une notification Push le jour ou le mode s'ouvre.
  Future<bool> sInscrireAlerte(String flagKey) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      await _supabase.from('feature_waitlist').upsert(
        {'user_id': userId, 'flag_key': flagKey},
        onConflict: 'user_id,flag_key',
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
