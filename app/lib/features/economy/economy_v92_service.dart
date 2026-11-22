import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// === SERVICE ECONOMIE & ENGINE V9.2 (SUPABASE) ===
/// Centralise la lecture des 4 compteurs isoles (XP, OC, VC bonus/payes, Points Division)
/// et tous les appels securises a l'Edge Function `match-engine`.
class WalletV92 {
  final int ocBalance;
  final int vcBonus;
  final int vcPaid;
  final int seasonFreeVcEarned;

  const WalletV92({
    this.ocBalance = 0,
    this.vcBonus = 0,
    this.vcPaid = 0,
    this.seasonFreeVcEarned = 0,
  });

  /// Total de Verse Coins depensables (le serveur debite toujours vcBonus en 1er)
  int get totalVc => vcBonus + vcPaid;

  factory WalletV92.fromMap(Map<String, dynamic> map) {
    return WalletV92(
      ocBalance: (map['oc_balance'] as num?)?.toInt() ?? 0,
      vcBonus: (map['vc_bonus'] as num?)?.toInt() ?? 0,
      vcPaid: (map['vc_paid'] as num?)?.toInt() ?? 0,
      seasonFreeVcEarned: (map['season_free_vc_earned'] as num?)?.toInt() ?? 0,
    );
  }
}

class EconomyV92Service {
  final _supabase = Supabase.instance.client;

  // ===========================================================================
  // FORMULES MIROIR EXACTES V9.2 (pour affichage UI instantane — verite serveur)
  // ===========================================================================

  /// Cout en XP pour passer du niveau L au niveau L+1 (§1.3)
  static int xpPourNiveauSuivant(int niveau) {
    if (niveau <= 5) return 100 * niveau;
    if (niveau <= 15) return 120 * niveau;
    if (niveau <= 30) return 130 * niveau;
    if (niveau <= 50) return 140 * niveau;
    if (niveau <= 75) return 7000;
    return 25000;
  }

  /// Niveau exact depuis xp_totale (autorise la retrogradation si XP baisse)
  static int calculerNiveau(int xpTotale) {
    if (xpTotale <= 0) return 1;
    int lvl = 1;
    int acc = 0;
    while (true) {
      final step = xpPourNiveauSuivant(lvl);
      if (acc + step > xpTotale) break;
      acc += step;
      lvl++;
    }
    return lvl;
  }

  /// XP accumulee a l'interieur du niveau courant (pour la barre de progression)
  static int xpDansNiveauActuel(int xpTotale) {
    if (xpTotale <= 0) return 0;
    int lvl = 1;
    int acc = 0;
    while (true) {
      final step = xpPourNiveauSuivant(lvl);
      if (acc + step > xpTotale) break;
      acc += step;
      lvl++;
    }
    return xpTotale - acc;
  }

  /// Titre de Rang officiel permanent (100% independant de tout achat boutique)
  static String titreRangOfficiel(int niveau) {
    if (niveau <= 5) return 'Novice du Verse';
    if (niveau <= 15) return 'Apprenti Otaku';
    if (niveau <= 30) return 'Erudit des Arcs';
    if (niveau <= 50) return "Maitre de l'Encre";
    if (niveau <= 75) return 'Seigneur du Verse';
    return 'Legende Eternelle ★${niveau - 75}';
  }

  /// Couleur officielle du Badge de Rang selon la tranche de niveau (§1.3)
  static Color couleurBadgeRang(int niveau) {
    if (niveau <= 5) return const Color(0xFFCD7F32); // Bronze Initie
    if (niveau <= 15) return const Color(0xFF8FA4B8); // Acier Trempe
    if (niveau <= 30) return const Color(0xFFC0D6E4); // Argent Astral
    if (niveau <= 50) return const Color(0xFFFFC107); // Or Shonen
    if (niveau <= 75) return const Color(0xFF7BE8FF); // Platine Ethere
    return const Color(0xFFFF4D8D); // Legende Eternelle
  }

  /// Division (10 a 1) selon les seuils V9.2 (§6.1 : 0 a 1900+ pts)
  static int calculerDivision(int pts) {
    if (pts >= 1900) return 1;
    if (pts >= 1570) return 2;
    if (pts >= 1270) return 3;
    if (pts >= 1000) return 4;
    if (pts >= 760) return 5;
    if (pts >= 550) return 6;
    if (pts >= 370) return 7;
    if (pts >= 220) return 8;
    if (pts >= 100) return 9;
    return 10;
  }

  static String nomDivision(int division) {
    switch (division) {
      case 1:
        return 'Legende du Verse';
      case 2:
        return 'Hokage';
      case 3:
        return 'Yonko';
      case 4:
        return 'Amiral';
      case 5:
        return 'Vice-Amiral';
      case 6:
        return 'Capitaine';
      case 7:
        return 'Jonin';
      case 8:
        return 'Chunin';
      case 9:
        return 'Genin';
      default:
        return 'Academie';
    }
  }

  /// Arbitrage officiel des frais d'arene en Otaku Coins (§1.4 / ECO-05)
  /// - Niveaux 1 a 5 : TOUJOURS 0 OC
  /// - Mode Division des Niv. 6 : la Division prevaut exclusivement
  /// - Autres modes des Niv. 6 : le Niveau prevaut exclusivement
  static int fraisAreneOc({
    required int niveau,
    required int divisionId,
    required String mode,
  }) {
    if (niveau <= 5) return 0;
    if (mode == 'division') {
      if (divisionId >= 9) return 10;
      if (divisionId >= 6) return 15;
      if (divisionId >= 3) return 30;
      return 50;
    }
    if (niveau <= 15) return 15;
    if (niveau <= 30) return 30;
    return 50;
  }

  // ===========================================================================
  // LECTURE PORTEFEUILLE & BANDEAU CLASSEMENT
  // ===========================================================================

  /// Recupere le portefeuille OC / VC du joueur connecte depuis `economy_wallets`.
  Future<WalletV92> recupererPortefeuille() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return const WalletV92();
    try {
      final row = await _supabase
          .from('economy_wallets')
          .select('oc_balance, vc_bonus, vc_paid, season_free_vc_earned')
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return const WalletV92();
      return WalletV92.fromMap(row);
    } catch (_) {
      return const WalletV92();
    }
  }

  /// Recupere les donnees du Bandeau dynamique d'affluence en haut des classements (§6.5 / UI-04).
  Future<Map<String, dynamic>> recupererBandeauCagnotte({
    String mode = 'division',
    String? country,
  }) async {
    try {
      final data = await _supabase.rpc('get_leaderboard_pot_info', params: {
        'p_mode': mode,
        'p_country': country,
      });
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}
    return {
      'mode': mode,
      'qualified_players': 0,
      'active_tier': 1,
      'top1_vc': 25,
      'top2_vc': 15,
      'top3_vc': 10,
      'next_threshold': 10,
      'next_top1_vc': 50,
    };
  }

  // ===========================================================================
  // APPELS SECURISES A L'EDGE FUNCTION `match-engine`
  // ===========================================================================

  Future<Map<String, dynamic>> demarrerMatch({
    required String mode,
    required String difficulty,
    String malusMode = 'normal',
    bool xpInsurance = false,
    int confidencePotOc = 0,
  }) async {
    final res = await _supabase.functions.invoke(
      'match-engine',
      body: {
        'action': 'start_match',
        'mode': mode,
        'difficulty': difficulty,
        'malus_mode': malusMode,
        'xp_insurance': xpInsurance,
        'confidence_pot_oc': confidencePotOc,
      },
    );
    final data = res.data is Map ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
    if (res.status != 200) {
      throw MatchStartException(
        message: data['error']?.toString() ?? 'Erreur demarrage match (${res.status})',
        statusCode: res.status,
        canRescueAd: data['can_rescue_ad'] == true,
        cooldownSeconds: (data['cooldown_seconds'] as num?)?.toInt(),
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> soumettreReponse({
    required String matchId,
    required String questionId,
    required String answer,
    required int responseTimeMs,
    bool isTimeout = false,
    String? workSlug,
    int? difficultyLevel,
  }) async {
    final res = await _supabase.functions.invoke(
      'match-engine',
      body: {
        'action': 'submit_answer',
        'match_id': matchId,
        'question_id': questionId,
        'answer': answer,
        'response_time_ms': responseTimeMs,
        'is_timeout': isTimeout,
        if (workSlug != null && workSlug.isNotEmpty) 'work_slug': workSlug,
        if (difficultyLevel != null && difficultyLevel > 0) 'difficulty_level': difficultyLevel,
      },
    );
    final data = res.data is Map ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
    if (res.status != 200) {
      throw Exception(data['error']?.toString() ?? 'Erreur validation (${res.status})');
    }
    return data;
  }

  Future<Map<String, dynamic>> cloturerMatch({
    required String matchId,
    bool abandon = false,
  }) async {
    final res = await _supabase.functions.invoke(
      'match-engine',
      body: {
        'action': 'end_match',
        'match_id': matchId,
        'abandon': abandon,
      },
    );
    return res.data is Map ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
  }

  /// Bouton Roi fin de match : Doubler mes OC (x2) via pub volontaire (max 10/j)
  Future<Map<String, dynamic>> doublerOcMatch(String matchId) async {
    final res = await _supabase.functions.invoke(
      'match-engine',
      body: {'action': 'double_oc_ad', 'match_id': matchId},
    );
    final data = res.data is Map ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
    if (res.status != 200) {
      throw Exception(data['error']?.toString() ?? 'Impossible de doubler les OC');
    }
    return data;
  }

  /// Anti-soft-lock : Coup de Pouce (+40 OC via pub, max 3/j) quand solde < frais d'arene
  Future<Map<String, dynamic>> reclamerCoupDePouceOc(String mode) async {
    final res = await _supabase.functions.invoke(
      'match-engine',
      body: {'action': 'rescue_oc_ad', 'mode': mode},
    );
    final data = res.data is Map ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
    if (res.status != 200) {
      throw Exception(data['error']?.toString() ?? 'Coup de Pouce indisponible');
    }
    return data;
  }

  /// Mode Solo uniquement : Seconde Chance (+100 PV sur 350 PV, 1 fois/match)
  Future<Map<String, dynamic>> activerSecondeChance(String matchId, {bool payWithOc = false}) async {
    final res = await _supabase.functions.invoke(
      'match-engine',
      body: {
        'action': 'second_chance',
        'match_id': matchId,
        'pay_with_oc': payWithOc,
      },
    );
    final data = res.data is Map ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
    if (res.status != 200) {
      throw Exception(data['error']?.toString() ?? 'Seconde Chance indisponible');
    }
    return data;
  }
}

class MatchStartException implements Exception {
  final String message;
  final int statusCode;
  final bool canRescueAd;
  final int? cooldownSeconds;

  MatchStartException({
    required this.message,
    required this.statusCode,
    this.canRescueAd = false,
    this.cooldownSeconds,
  });

  @override
  String toString() => message;
}
