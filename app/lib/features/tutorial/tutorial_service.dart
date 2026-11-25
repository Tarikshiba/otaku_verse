import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// === SERVICE TUTORIEL 2 PHASES (TUTO-01, §4.1 & §4.2, TESTS 3, 5, 6) ===
/// Phase A (pre-compte) : suivie localement puis synchronisee sur Supabase
/// des l'inscription / connexion (+300 OC + 100 XP + 1er Goodies 300 OC).
/// Phase B (Hub, 6 etapes verrouillees sur actions reelles) : suivie dans
/// `profiles.tutorial_phase_b_steps` et recompensee cote serveur a la 6e etape
/// (+25 VC + 100 OC + Titre officiel « Initié du Verse »).
class TutorialService {
  static const String _prefPhaseADone = 'v92_tutorial_phase_a_done';
  static const String _prefPhaseAPendingStarterBuy = 'v92_tutorial_phase_a_buy_starter';
  static const String _prefFavoriteAnime = 'v92_tutorial_favorite_anime';
  static const String _prefHubTourDone = 'v92_hub_guided_tour_done';
  static const String _prefVisitedPrefix = 'v92_phase_b_visited_step_';

  final SupabaseClient _supabase = Supabase.instance.client;

  static const List<Map<String, dynamic>> phaseBSteps = [
    {
      'step': 1,
      'titre': 'Calendrier 21 jours (Boutique)',
      'desc': 'Réclame le Jour 1 du Calendrier 21 jours dans la Boutique (onglet Calendrier & OC).',
      'actionLabel': 'OUVRIR BOUTIQUE',
      'serverChecked': true,
    },
    {
      'step': 2,
      'titre': 'Premier Combat Solo (350 PV)',
      'desc': 'Termine un Combat Solo (0 OC de frais jusqu\'au Niv. 5, 21 œuvres et 6 difficultés).',
      'actionLabel': 'LANCER SOLO',
      'serverChecked': true,
    },
    {
      'step': 3,
      'titre': 'Premier Duel en Division',
      'desc': 'Termine 1 match classé en Mode Division pour entrer dans le classement des 10 Divisions.',
      'actionLabel': 'ALLER EN DIVISION',
      'serverChecked': true,
    },
    {
      'step': 4,
      'titre': 'Découvrir la Boutique & Goodies',
      'desc': 'Explore les Goodies et Cosmétiques VC (zéro pay-to-win, zéro XP en boutique).',
      'actionLabel': 'VISITER BOUTIQUE',
      'serverChecked': false,
    },
    {
      'step': 5,
      'titre': 'Consulter les Classements & le Profil',
      'desc': 'Ouvre la rubrique Classements (Division & 10 paliers) ou ton Profil joueur.',
      'actionLabel': 'VOIR CLASSEMENTS',
      'serverChecked': false,
    },
    {
      'step': 6,
      'titre': 'Guide du jeu ou Alerte « M\'alerter »',
      'desc': 'Consulte le Guide du jeu dans ton Profil ou active une alerte sur un mode futur pour débloquer +25 VC, +100 OC et le Titre « Initié du Verse » !',
      'actionLabel': 'OUVRIR LE GUIDE',
      'serverChecked': true,
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

  /// Reinitialise l'etat local a la deconnexion pour qu'un nouveau compte cree
  /// sur le meme telephone relance proprement Phase A + visite guidee (Test 5)
  Future<void> resetLocalStateOnLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefPhaseADone, false);
    await prefs.setBool(_prefPhaseAPendingStarterBuy, false);
    await prefs.setBool(_prefHubTourDone, false);
    for (int i = 1; i <= 6; i++) {
      await prefs.remove('$_prefVisitedPrefix$i');
    }
  }

  /// Enregistre qu'un ecran lie a une etape Phase B a bien ete visite
  Future<void> marquerVisiteEtape(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefVisitedPrefix$step', true);
  }

  Future<bool> aVisiteEtape(int step) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefVisitedPrefix$step') ?? false;
  }

  Future<Set<int>> recupererEtapesVisiteesLocalement() async {
    final prefs = await SharedPreferences.getInstance();
    final set = <int>{};
    for (int i = 1; i <= 6; i++) {
      if (prefs.getBool('$_prefVisitedPrefix$i') == true) {
        set.add(i);
      }
    }
    return set;
  }

  Future<bool> doitAfficherVisiteGuideeHub() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_prefHubTourDone) ?? false);
  }

  Future<void> marquerVisiteGuideeHubTerminee() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefHubTourDone, true);
  }

  /// Verifie si le compte connecte n'a pas encore fait la Phase A en base (cas d'une inscription directe)
  Future<bool> compteDoitFairePhaseA() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final prof = await _supabase
          .from('profiles')
          .select('tutorial_phase_a_done, combats_joues')
          .eq('id', uid)
          .maybeSingle();
      if (prof == null) return false;
      final alreadyDone = prof['tutorial_phase_a_done'] == true;
      final matches = (prof['combats_joues'] as num?)?.toInt() ?? 0;
      return !alreadyDone && matches == 0;
    } catch (_) {
      return false;
    }
  }

  static bool _phaseASyncEnCours = false;

  /// Synchronise la recompense Phase A (+300 OC + 100 XP + achat 1er Goodies 300 OC)
  /// des que le joueur est connecte sur le Hub.
  Future<String?> synchroniserPhaseASiEnAttente() async {
    if (_phaseASyncEnCours) return null;
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final localDone = prefs.getBool(_prefPhaseADone) ?? false;
    final wantsStarter = prefs.getBool(_prefPhaseAPendingStarterBuy) ?? false;
    if (!localDone) return null;

    _phaseASyncEnCours = true;
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
      if (res.status >= 400) return null;
      final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
      if (data['already_done'] == true || data['error'] != null) {
        return null;
      }

      if (wantsStarter) {
        await _supabase.functions.invoke(
          'shop-tutorial-engine',
          body: {
            'action': 'purchase_goodie',
            'item_id': 'skin_mazu',
            'auto_equip': true,
          },
        );
        await prefs.setBool(_prefPhaseAPendingStarterBuy, false);
        return 'Bienvenue ! +300 OC, +100 XP et ton 1er Goodies équipé !';
      }

      return data['message']?.toString();
    } catch (_) {
      return null;
    } finally {
      _phaseASyncEnCours = false;
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

  /// Valide une etape (1..6) de la Phase B cote serveur (avec preuve de visite reelle)
  Future<Map<String, dynamic>> validerEtapePhaseB(int step, {bool verifiedVisit = false}) async {
    try {
      final res = await _supabase.functions.invoke(
        'shop-tutorial-engine',
        body: {
          'action': 'complete_tutorial_phase_b_step',
          'step': step,
          'verified_visit': verifiedVisit,
        },
      );
      final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
      if (res.status >= 400 || data['error'] != null) {
        throw Exception(data['error']?.toString() ?? 'Action non encore accomplie.');
      }
      return data;
    } on FunctionException catch (e) {
      final details = e.details is Map ? Map<String, dynamic>.from(e.details as Map) : <String, dynamic>{};
      throw Exception(details['error']?.toString() ?? 'Accomplis d\'abord cette action avant de valider.');
    }
  }

  /// Verifie et valide automatiquement cote serveur toutes les etapes Phase B accomplies
  /// sans que le joueur ait besoin de cliquer sur le bouton VERIFIER.
  Future<Map<String, dynamic>> synchroniserEtapesPhaseBAutomatiquement() async {
    final etat = await recupererEtatPhaseB();
    List<int> steps = List<int>.from(etat['steps'] as List? ?? []);
    bool claimed = etat['claimed'] == true;
    if (claimed) {
      return {
        'steps': steps,
        'claimed': true,
        'newlyCompleted': <int>[],
        'rewardMessage': null,
      };
    }

    final visited = await recupererEtapesVisiteesLocalement();
    final newlyCompleted = <int>[];
    String? rewardMessage;

    for (final stepNum in const [1, 2, 3, 4, 5, 6]) {
      if (steps.contains(stepNum)) continue;
      // Les etapes 4 et 5 reposent sur la visite d'ecran (inutile d'appeler le serveur si non visite)
      if ((stepNum == 4 || stepNum == 5) && !visited.contains(stepNum)) {
        continue;
      }
      try {
        final res = await validerEtapePhaseB(
          stepNum,
          verifiedVisit: visited.contains(stepNum),
        );
        final updatedSteps = (res['steps'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList();
        if (updatedSteps != null) {
          steps = updatedSteps;
        } else if (!steps.contains(stepNum)) {
          steps.add(stepNum);
        }
        newlyCompleted.add(stepNum);
        if (res['reward_claimed'] == true) {
          claimed = true;
          rewardMessage = res['message']?.toString() ??
              'Parcours d\'Initiation terminé ! +25 VC, +100 OC et Titre « Initié du Verse » débloqués !';
        }
      } catch (_) {
        // Etape non encore accomplie cote serveur : on passe silencieusement
      }
    }

    return {
      'steps': steps,
      'claimed': claimed,
      'newlyCompleted': newlyCompleted,
      'rewardMessage': rewardMessage,
    };
  }
}
