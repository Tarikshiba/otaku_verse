import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service de la V4 (Section 11 de la Roadmap) :
/// Gère la monnaie virtuelle Verse Coins, les Publicités récompensées opt-in,
/// le Pass Premium mensuel, les Coffres et les Articles/Boosters de la Boutique.
class MonetisationV4Service {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://otaku-verse-6e05e-default-rtdb.europe-west1.firebasedatabase.app',
  );
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Récupère le portefeuille V4 du joueur (Verse Coins, Pass Premium, Boost XP, inventaire)
  Future<Map<String, dynamic>> recupererPortefeuille() async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      final ref = _db.ref('economie/$userId');
      final snap = await ref.get();
      if (snap.exists && snap.value is Map) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        final int now = DateTime.now().millisecondsSinceEpoch;
        final int doubleXpUntil = data['doubleXpUntil'] ?? 0;
        final int minutesBoost = doubleXpUntil > now ? ((doubleXpUntil - now) / 60000).ceil() : 0;
        final List<String> articles = (data['articlesPossedes'] as List?)?.map((e) => e.toString()).toList() ?? [];

        return {
          'verseCoins': data['verseCoins'] ?? 100,
          'passPremium': data['passPremium'] == true,
          'doubleXpActif': minutesBoost > 0,
          'minutesBoostRestantes': minutesBoost,
          'pubsVuesSession': data['pubsVuesSession'] ?? 0,
          'articlesPossedes': articles,
          'dernierBonusQuotidien': data['dernierBonusQuotidien'] ?? '',
        };
      } else {
        // Initialisation d'un portefeuille de départ avec 100 Verse Coins offerts
        final initData = {
          'verseCoins': 100,
          'passPremium': false,
          'doubleXpUntil': 0,
          'pubsVuesSession': 0,
          'articlesPossedes': <String>[],
          'dernierBonusQuotidien': '',
        };
        await ref.set(initData);
        return {
          'verseCoins': 100,
          'passPremium': false,
          'doubleXpActif': false,
          'minutesBoostRestantes': 0,
          'pubsVuesSession': 0,
          'articlesPossedes': <String>[],
          'dernierBonusQuotidien': '',
        };
      }
    } catch (_) {
      return {
        'verseCoins': 100,
        'passPremium': false,
        'doubleXpActif': false,
        'minutesBoostRestantes': 0,
        'pubsVuesSession': 0,
        'articlesPossedes': <String>[],
        'dernierBonusQuotidien': '',
      };
    }
  }

  /// Acheter un pack de Verse Coins (mode simulation pour tests APK Tariq & Heat)
  Future<int> acheterPackCoins(int quantite) async {
    final userId = _supabase.auth.currentUser!.id;
    final p = await recupererPortefeuille();
    final int nouveauSolde = (p['verseCoins'] as int) + quantite;
    await _db.ref('economie/$userId').update({'verseCoins': nouveauSolde});
    return nouveauSolde;
  }

  /// Activer l'abonnement mensuel Pass Premium (+20% XP, sans pub, +50 Coins/jour, cadre Premium)
  Future<void> activerPassPremium() async {
    final userId = _supabase.auth.currentUser!.id;
    final p = await recupererPortefeuille();
    final int nouveauSolde = (p['verseCoins'] as int) + 50; // Premier bonus quotidien crédité d'office
    final List<String> articles = List<String>.from(p['articlesPossedes'] as List<String>);
    if (!articles.contains('cadre_premium_or')) {
      articles.add('cadre_premium_or');
    }
    await _db.ref('economie/$userId').update({
      'passPremium': true,
      'verseCoins': nouveauSolde,
      'articlesPossedes': articles,
    });
  }

  /// Réclamer le bonus quotidien de Verse Coins (+50 Coins avec Pass Premium, +15 Coins en gratuit)
  Future<String> reclamerBonusQuotidienCoins() async {
    final userId = _supabase.auth.currentUser!.id;
    final p = await recupererPortefeuille();
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    if (p['dernierBonusQuotidien'] == today) {
      throw Exception("Bonus quotidien de Verse Coins déjà récupéré aujourd'hui.");
    }
    final bool isPremium = p['passPremium'] == true;
    final int gain = isPremium ? 50 : 15;
    final int nouveauSolde = (p['verseCoins'] as int) + gain;
    await _db.ref('economie/$userId').update({
      'verseCoins': nouveauSolde,
      'dernierBonusQuotidien': today,
    });
    return "+$gain Verse Coins récupérés (${isPremium ? 'Bonus Pass Premium' : 'Bonus Gratuit'}) !";
  }

  /// Regarder une publicité récompensée opt-in (Roadmap 11.2 : Double XP 15 min + 30 Coins, max 1 pub / 3 quiz)
  Future<String> validerPubRecompensee() async {
    final userId = _supabase.auth.currentUser!.id;
    final p = await recupererPortefeuille();
    final int pubsVues = p['pubsVuesSession'] as int? ?? 0;
    if (pubsVues >= 3) {
      throw Exception("Limite atteinte (fréquence max respectée). Joue 3 quiz avant la prochaine pub.");
    }

    final int nouveauSolde = (p['verseCoins'] as int) + 30;
    final int doubleXpUntil = DateTime.now().millisecondsSinceEpoch + (15 * 60 * 1000);

    await _db.ref('economie/$userId').update({
      'verseCoins': nouveauSolde,
      'doubleXpUntil': doubleXpUntil,
      'pubsVuesSession': pubsVues + 1,
    });

    return "Double XP activé pendant 15 minutes + 30 Verse Coins reçus !";
  }

  /// Acheter un article cosmétique ou un booster avec des Verse Coins (aucun Pay-to-Win : Roadmap 11.4)
  Future<String> acheterArticleBoutique({
    required String articleId,
    required String nom,
    required int coutCoins,
    int xpBonus = 0,
    int minutesDoubleXp = 0,
    bool estCoffre = false,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final p = await recupererPortefeuille();
    final int solde = p['verseCoins'] as int;
    final List<String> articles = List<String>.from(p['articlesPossedes'] as List<String>);

    if (!estCoffre && minutesDoubleXp == 0 && articles.contains(articleId)) {
      throw Exception("Tu possèdes déjà cet article.");
    }
    if (solde < coutCoins) {
      throw Exception("Solde insuffisant ($solde / $coutCoins Verse Coins).");
    }

    final int nouveauSolde = solde - coutCoins;
    int doubleXpUntil = DateTime.now().millisecondsSinceEpoch;
    int gainXpTotal = xpBonus;
    String messageResultat = "$nom débloqué !";

    if (estCoffre) {
      final tirages = [150, 250, 400];
      gainXpTotal = tirages[Random().nextInt(tirages.length)];
      messageResultat = "Coffre Mystère ouvert : +$gainXpTotal XP gagnés !";
    } else if (minutesDoubleXp > 0) {
      doubleXpUntil = DateTime.now().millisecondsSinceEpoch + (minutesDoubleXp * 60 * 1000);
      messageResultat = "$nom activé pendant $minutesDoubleXp min !";
    } else {
      articles.add(articleId);
    }

    await _db.ref('economie/$userId').update({
      'verseCoins': nouveauSolde,
      'articlesPossedes': articles,
      if (minutesDoubleXp > 0) 'doubleXpUntil': doubleXpUntil,
    });

    if (gainXpTotal > 0) {
      try {
        final prof = await _supabase.from('profiles').select('xp_totale').eq('id', userId).maybeSingle();
        if (prof != null) {
          final int xp = (prof['xp_totale'] ?? 0) + gainXpTotal;
          await _supabase.from('profiles').update({'xp_totale': xp}).eq('id', userId);
        }
      } catch (_) {}
    }

    return messageResultat;
  }
}
