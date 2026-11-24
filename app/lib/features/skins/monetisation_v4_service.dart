import 'package:supabase_flutter/supabase_flutter.dart';
import '../economy/economy_v92_service.dart';

/// === SERVICE BOUTIQUE & MONETISATION V9.2 (100% SUPABASE) ===
/// Remplace l'ancien service V4 Firebase RTDB :
/// - ZERO Booster d'XP, ZERO Coffre Mystere XP, ZERO VC contre pub (ECO-02)
/// - 5 Packs VC calibres au franc pres (SHOP-01)
/// - 3 Offres claires : Sans Pub 1 An, Pack Demarrage (1x), VIP Mensuel/Annuel (SHOP-02)
/// - Calendrier 21 jours (plafond 150 VC/saison + swap 250 OC cycle 2)
/// - Verse Analytics : 7 Stats Pro exclusives VIP (§2.3 #4)
class MonetisationV4Service {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EconomyV92Service _economy = EconomyV92Service();

  Future<Map<String, dynamic>> _invokeShop(Map<String, dynamic> body) async {
    try {
      final res = await _supabase.functions.invoke('shop-tutorial-engine', body: body);
      final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
      if (res.status >= 400 || data['error'] != null) {
        throw Exception(data['error']?.toString() ?? 'Erreur serveur boutique (${res.status})');
      }
      return data;
    } on FunctionException catch (e) {
      final details = e.details is Map ? Map<String, dynamic>.from(e.details as Map) : <String, dynamic>{};
      throw Exception(details['error']?.toString() ?? 'Action boutique indisponible (${e.status}).');
    }
  }

  /// Recupere l'etat complet du portefeuille, des abonnements et des cosmetiques depuis Supabase
  Future<Map<String, dynamic>> recupererPortefeuille() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return {
        'ocBalance': 0,
        'verseCoins': 0,
        'vcBonus': 0,
        'vcPaid': 0,
        'seasonFreeVcEarned': 0,
        'passPremium': false,
        'noAdsActif': false,
        'starterPackClaimed': false,
        'articlesPossedes': <String>[],
        'calendarDay': 0,
        'calendarCycle': 1,
        'calendarClaimedToday': false,
      };
    }

    try {
      final wallet = await _economy.recupererPortefeuille();
      final prof = await _supabase
          .from('profiles')
          .select('is_vip, vip_expires_at, no_ads_expires_at, starter_pack_claimed')
          .eq('id', userId)
          .maybeSingle();

      final cosmetics = await _supabase
          .from('player_cosmetics')
          .select('item_id, category, equipped')
          .eq('user_id', userId);

      final claims = await _supabase
          .from('daily_calendar_claims')
          .select('cycle_number, day_number, claimed_date')
          .eq('user_id', userId)
          .order('cycle_number', ascending: false)
          .order('day_number', ascending: false)
          .limit(1);

      final now = DateTime.now();
      final todayIso = now.toIso8601String().substring(0, 10);
      final vipExp = prof?['vip_expires_at'] != null ? DateTime.tryParse(prof!['vip_expires_at'].toString()) : null;
      final noAdsExp = prof?['no_ads_expires_at'] != null ? DateTime.tryParse(prof!['no_ads_expires_at'].toString()) : null;

      final bool isVip = prof?['is_vip'] == true && (vipExp == null || vipExp.isAfter(now));
      final bool noAdsActif = isVip || (noAdsExp != null && noAdsExp.isAfter(now));

      final ownedIds = List<Map<String, dynamic>>.from(cosmetics)
          .map((e) => e['item_id']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();

      int calCycle = 1;
      int calDay = 0;
      bool claimedToday = false;
      if ((claims as List).isNotEmpty) {
        final last = Map<String, dynamic>.from(claims.first as Map);
        calCycle = (last['cycle_number'] as num?)?.toInt() ?? 1;
        calDay = (last['day_number'] as num?)?.toInt() ?? 0;
        claimedToday = last['claimed_date']?.toString() == todayIso;
      }

      return {
        'ocBalance': wallet.ocBalance,
        'verseCoins': wallet.totalVc,
        'vcBonus': wallet.vcBonus,
        'vcPaid': wallet.vcPaid,
        'seasonFreeVcEarned': wallet.seasonFreeVcEarned,
        'passPremium': isVip,
        'vipExpiresAt': prof?['vip_expires_at']?.toString(),
        'noAdsActif': noAdsActif,
        'noAdsExpiresAt': prof?['no_ads_expires_at']?.toString(),
        'starterPackClaimed': prof?['starter_pack_claimed'] == true,
        'articlesPossedes': ownedIds,
        'calendarDay': calDay,
        'calendarCycle': calCycle,
        'calendarClaimedToday': claimedToday,
      };
    } catch (_) {
      return {
        'ocBalance': 0,
        'verseCoins': 0,
        'vcBonus': 0,
        'vcPaid': 0,
        'seasonFreeVcEarned': 0,
        'passPremium': false,
        'noAdsActif': false,
        'starterPackClaimed': false,
        'articlesPossedes': <String>[],
        'calendarDay': 0,
        'calendarCycle': 1,
        'calendarClaimedToday': false,
      };
    }
  }

  /// Acheter un des 5 Packs VC officiels (§2.1 / SHOP-01)
  Future<String> acheterPackVcOfficiel(String packId) async {
    final res = await _invokeShop({'action': 'purchase_vc_pack', 'pack_id': packId});
    return res['message']?.toString() ?? 'Pack VC credite !';
  }

  /// Activer une des 3 offres monetisation (§2.2 / SHOP-02 : no_ads_1y, starter_pack, vip_monthly, vip_yearly)
  Future<String> acheterOffreOfficielle(String offerId) async {
    final res = await _invokeShop({'action': 'purchase_offer', 'offer_id': offerId});
    return res['message']?.toString() ?? 'Offre activee !';
  }

  /// Acheter un cosmetique ou Goodies via le catalogue serveur (§2.4 / SHOP-03)
  Future<String> acheterArticleBoutiqueV92(String itemId, {bool autoEquip = false}) async {
    final res = await _invokeShop({
      'action': 'purchase_goodie',
      'item_id': itemId,
      'auto_equip': autoEquip,
    });
    return res['message']?.toString() ?? 'Article debloque !';
  }

  /// Reclamer la case du jour du Calendrier 21 jours (§2.1)
  Future<String> reclamerJourCalendrier21() async {
    final res = await _invokeShop({'action': 'claim_calendar_day'});
    return res['message']?.toString() ?? 'Recompense du jour recuperee !';
  }

  /// Coup de Pouce anti-soft-lock : +40 OC via pub volontaire (max 3/jour, ZERO VC)
  Future<String> reclamerCoupDePouceOc({String mode = 'solo'}) async {
    final res = await _economy.reclamerCoupDePouceOc(mode);
    return res['message']?.toString() ?? '+40 OC credites !';
  }

  /// Depenser des VC pour creer un Donjon (100 VC) ou un Salon Live (150 VC) — gratuit pour VIP
  Future<Map<String, dynamic>> payerCreationCommunaute(String feature) async {
    return _invokeShop({'action': 'spend_vc_feature', 'feature': feature});
  }

  /// Recuperer les 7 Stats Pro VIP ("Verse Analytics") depuis le serveur (§2.3 #4)
  Future<Map<String, dynamic>> recupererVerseAnalyticsVip() async {
    return _invokeShop({'action': 'get_vip_analytics'});
  }

  /// Recharge OC : Competences d'Aura (20 OC — §1.4 / Test 31)
  Future<String> rechargerCompetenceAura() async {
    final res = await _invokeShop({'action': 'recharge_aura_skill'});
    return res['message']?.toString() ?? 'Compétence d\'Aura rechargée (-20 OC) !';
  }

  /// Recharge OC : Reactiver un jour manque du Calendrier 21 jours (40 / 80 / 160 OC ou gratuit VIP 1x/sem)
  Future<String> reactiverJourManqueCalendrier() async {
    final res = await _invokeShop({'action': 'recover_calendar_day'});
    return res['message']?.toString() ?? 'Jour manqué réactivé !';
  }

  /// Recharge OC : Debloquer 3 Defis bonus du jour (50 OC — §1.4 / Test 31)
  Future<String> debloquerDefisBonusOc() async {
    final res = await _invokeShop({'action': 'buy_bonus_challenges'});
    return res['message']?.toString() ?? '3 Défis Bonus débloqués (-50 OC) !';
  }
}
