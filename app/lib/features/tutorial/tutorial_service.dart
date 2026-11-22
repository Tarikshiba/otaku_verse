import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// === SERVICE TUTORIEL 2 PHASES (TUTO-01, §4.1 & §4.2) ===
/// Phase A (pre-compte) : suivie localement par SharedPreferences puis synchronisee
/// automatiquement sur Supabase des l'inscription / connexion (+300 OC + 100 XP).
/// Phase B (Hub, 6 etapes Coachmarks) : suivie dans `profiles.tutorial_phase_b_steps`
/// et recompensee cote serveur a la 6e etape (+25 VC + 100 OC + Titre "Initie du Verse").
class TutorialService {
  static const String _prefPhaseADone = 'v92_tutorial_phase_a_done';
  static const String _prefPhaseAPendingStarterBuy = 'v92_tutorial_phase_a_buy_starter';
  static const String _prefFavoriteAnime = 'v92_tutorial_favorite_anime';

  final SupabaseClient _supabase = Supabase.instance.client;

  static const List<Map<String, dynamic>> phaseBSteps = [
    {
      'step': 1,
      'titre': 'Accueil & Calendrier 21 jours',
      'desc': 'Recupere tes OC et jusqu\'a 100 VC gratuits sur le 1er cycle du Calendrier 21 jours dans la Boutique.',
    },
    {
      'step': 2,
      'titre': 'Avant-Match, Frais OC & Malus',
      'desc': 'Gratuit en OC jusqu\'au Niveau 5. Des le Niveau 6, mise tes OC en arene et tente les Malus pour plus de sensations.',
    },
    {
      'step': 3,
      'titre': 'Classement Division & Pertes d\'XP',
      'desc': 'Affronte l\'IA calibree en Division pour grimper de Div 10 a Div 1. Attention : des le Niveau 6, une defaite retire de l\'XP.',
    },
    {
      'step': 4,
      'titre': 'Battle Royale 10 joueurs',
      'desc': '350 PV, 40 questions et survie a 10 joueurs : les 3 plus rapides frappent tous les autres !',
    },
    {
      'step': 5,
      'titre': 'Communaute : Salons Live & Donjons',
      'desc': 'Cree des Soirees Quiz JKLM (150 VC ou gratuit VIP) et des Donjons Otaku Forge (100 VC ou gratuit VIP).',
    },
    {
      'step': 6,
      'titre': 'Evenements & Tournois',
      'desc': 'Chaque saison dure 8 semaines avec cagnottes dynamiques et podiums. Valide cette etape pour recevoir +25 VC, +100 OC et ton titre !',
    },
  ];

  Future<bool> isPhaseADoneLocally() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefPhaseADone) ?? false;
  }

  Future<void> markPhaseADoneLocally({
    required String favoriteAnimeSlug,
    required bool wantsStarterGoodie,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefPhaseADone, true);
    await prefs.setBool(_prefPhaseAPendingStarterBuy, wantsStarterGoodie);
    await prefs.setString(_prefFavoriteAnime, favoriteAnimeSlug);
  }

  /// Synchronise la recompense Phase A (+300 OC + 100 XP + achat 1er Goodies 300 OC)
  /// des que le joueur est connecte sur le Hub.
  Future<String?> synchroniserPhaseASiEnAttente() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final localDone = prefs.getBool(_prefPhaseADone) ?? false;
    final wantsStarter = prefs.getBool(_prefPhaseAPendingStarterBuy) ?? false;
    if (!localDone) return null;

    try {
      final prof = await _supabase
          .from('profiles')
          .select('tutorial_phase_a_done')
          .eq('id', uid)
          .maybeSingle();

      if (prof?['tutorial_phase_a_done'] == true) {
        return null;
      }

      final res = await _supabase.functions.invoke(
        'shop-tutorial-engine',
        body: {'action': 'complete_tutorial_phase_a'},
      );
      final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};

      if (wantsStarter && data['already_done'] != true) {
        await _supabase.functions.invoke(
          'shop-tutorial-engine',
          body: {
            'action': 'purchase_goodie',
            'item_id': 'starter_tuto_ninja',
            'auto_equip': true,
          },
        );
        await prefs.setBool(_prefPhaseAPendingStarterBuy, false);
        return 'Bienvenue ! +300 OC, +100 XP et ton 1er Goodies Ninja de Konoha equipe !';
      }

      return data['message']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Recupere l'avancement Phase B depuis Supabase `profiles`
  Future<Map<String, dynamic>> recupererEtatPhaseB() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      return {'steps': <int>[], 'claimed': true};
    }

    try {
      final prof = await _supabase
          .from('profiles')
          .select('tutorial_phase_b_steps, tutorial_phase_b_claimed')
          .eq('id', uid)
          .maybeSingle();

      final rawSteps = prof?['tutorial_phase_b_steps'];
      final steps = rawSteps is List
          ? rawSteps.map((e) => (e as num).toInt()).toList()
          : <int>[];

      return {
        'steps': steps,
        'claimed': prof?['tutorial_phase_b_claimed'] == true,
      };
    } catch (_) {
      return {'steps': <int>[], 'claimed': false};
    }
  }

  /// Valide une etape (1..6) de la Phase B cote serveur
  Future<Map<String, dynamic>> validerEtapePhaseB(int step) async {
    final res = await _supabase.functions.invoke(
      'shop-tutorial-engine',
      body: {'action': 'complete_tutorial_phase_b_step', 'step': step},
    );
    final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
    if (res.status >= 400 || data['error'] != null) {
      throw Exception(data['error']?.toString() ?? 'Validation impossible');
    }
    return data;
  }
}
