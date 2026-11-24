import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../features/combat/combat_setup_page.dart';
import '../features/core/analytics_service.dart';
import '../features/core/feature_flags_service.dart';
import '../features/economy/economy_v92_service.dart';
import '../features/profile/guide_jeu_page.dart';
import '../features/profile/parametres_page.dart';
import '../features/profile/profile_page.dart';
import '../features/progression/progression_service.dart';
import '../features/progression/quete_service.dart';
import '../features/rewards/boite_lettres_page.dart';
import '../features/rewards/mailbox_service.dart';
import '../features/skins/boutique_screen.dart';
import '../features/skins/monetisation_v4_service.dart';
import '../features/skins/skin_service.dart';
import '../features/social/amis_screen.dart';
import '../features/social/classement_screen.dart';
import '../features/social/friends_service.dart';
import '../features/tutorial/tutorial_phase_a_page.dart';
import '../features/tutorial/tutorial_service.dart';
import '../features/verse/mode_selector_page.dart';
import '../features/verse/verse_battle_royale_page.dart';
import '../features/verse/verse_communaute_page.dart';
import '../features/verse/verse_coop_page.dart';
import '../features/verse/verse_division_page.dart';
import '../features/verse/verse_duel_setup_page.dart';
import '../features/verse/verse_guildes_page.dart';
import '../features/verse/verse_v3_hub_page.dart';
import 'rank_badge.dart';
import 'skin_3d_viewer.dart';

/// === SHELL PRINCIPAL DE L'APP (V9.2 CONSOLIDE — TESTS 3, 5, 6, 7, 9, 27, 28, 31) ===
/// - Mise en page 100 % responsive (zero Positioned fixe => FIN des 3 chevauchements Tecno Spark 20)
/// - Top Bar : Profil + Badge de Rang + Compteurs XP, OC, VC + bouton « Pub +OC » + Boite aux lettres
/// - Rubrique dediee « Classements » sur l'Accueil (style eFootball : Division, 10 paliers, cagnotte)
/// - Parcours d'Initiation Phase B verrouille sur actions reelles + Titre « Initié du Verse »
/// - Relance Phase A si nouveau compte non initialise + Visite guidee du Hub apres creation de compte
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: OtakuColors.background,
      body: _AccueilPage(),
    );
  }
}

class _AccueilPage extends StatefulWidget {
  const _AccueilPage();

  @override
  State<_AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<_AccueilPage> {
  final _progressionService = ProgressionService();
  final _skinService = SkinService();
  final _economyService = EconomyV92Service();
  final _flagsService = FeatureFlagsService();
  final _mailboxService = MailboxService();
  final _tutorialService = TutorialService();

  Map<String, dynamic>? _profil;
  WalletV92 _wallet = const WalletV92();
  String _skinImageKey = 'skin_kio';
  String? _equippedFrameId;
  bool _notifAmis = false;
  int _unreadMails = 0;
  String _modeActif = 'SOLO';
  List<int> _phaseBSteps = [];
  bool _phaseBClaimed = true;
  bool _pubAccueilEnCours = false;
  bool _reseauHorsLigne = false;
  bool _updateDialogShown = false;

  @override
  void initState() {
    super.initState();
    _initialiserHub();
  }

  /// Charge toutes les donnees du Hub en parallele + gere Phase A & Visite guidee (Tests 3 & 5)
  Future<void> _initialiserHub() async {
    await _progressionService.creerProfilSiAbsent();
    final msgPhaseA = await _tutorialService.synchroniserPhaseASiEnAttente();

    final flagsOk = await _flagsService.chargerFlags();
    await Future.wait([
      _chargerProfilEtPortefeuille(),
      _verifierNotifAmis(),
      _chargerMailsNonLus(),
      _chargerTutorielPhaseB(),
    ]);

    if (!mounted) return;
    setState(() {
      _reseauHorsLigne = !flagsOk && _flagsService.lastFetchFailed;
    });

    if (_flagsService.miseAJourRequise && !_updateDialogShown) {
      _updateDialogShown = true;
      _afficherModalMiseAJour();
    }

    if (msgPhaseA != null && msgPhaseA.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msgPhaseA), backgroundColor: OtakuColors.pvHaut),
      );
    }

    // Bug post-deconnexion (Test 5) : si nouveau compte cree directement sans Phase A, la lancer maintenant
    final doitPhaseA = await _tutorialService.compteDoitFairePhaseA();
    if (mounted && doitPhaseA) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TutorialPhaseAPage(
            dejaConnecte: true,
            onTermineVersInscription: () => Navigator.pop(context),
            onDejaUnCompte: () => Navigator.pop(context),
          ),
        ),
      );
      if (!mounted) return;
      final syncMsg = await _tutorialService.synchroniserPhaseASiEnAttente();
      await _chargerProfilEtPortefeuille();
      await _chargerTutorielPhaseB();
      if (mounted && syncMsg != null && syncMsg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(syncMsg), backgroundColor: OtakuColors.pvHaut),
        );
      }
    }

    // Visite guidee du Hub apres creation de compte (Test 3)
    final showTour = await _tutorialService.doitAfficherVisiteGuideeHub();
    if (mounted && showTour) {
      await _tutorialService.marquerVisiteGuideeHubTerminee();
      if (mounted) _afficherVisiteGuideeHub();
    }
  }

  void _afficherModalMiseAJour() {
    final forced = _flagsService.forceUpdate;
    showDialog(
      context: context,
      barrierDismissible: !forced,
      builder: (ctx) => PopScope(
        canPop: !forced,
        child: AlertDialog(
          backgroundColor: OtakuColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: OtakuColors.accent.withValues(alpha: 0.7)),
          ),
          title: Row(
            children: [
              const Icon(Icons.system_update_rounded, color: OtakuColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'MISE À JOUR DISPONIBLE (v${_flagsService.minAppVersion})',
                  style: OtakuTypo.headlineSmall.copyWith(fontSize: 13.5, color: OtakuColors.accent),
                ),
              ),
            ],
          ),
          content: Text(
            _flagsService.updateMessage,
            style: OtakuTypo.bodySmall.copyWith(fontSize: 11.5, color: Colors.white70, height: 1.4),
          ),
          actions: [
            if (!forced)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('PLUS TARD', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted)),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.accent, foregroundColor: Colors.black),
              onPressed: () {
                if (!forced) Navigator.pop(ctx);
                _initialiserHub();
              },
              child: const Text('VÉRIFIER', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  void _afficherVisiteGuideeHub() {
    int page = 0;
    const etapes = [
      {
        'titre': '1/4 · Tes 3 Compteurs + Pub +OC',
        'desc': 'En haut à droite : ton XP (Niveau & Badge de Rang, jamais dépensée), tes Otaku Coins (OC gratuits pour l\'arène), tes Verse Coins (VC cosmétiques) et le bouton « Pub +OC ».',
      },
      {
        'titre': '2/4 · Solo, Division & Bouton JOUER',
        'desc': 'Choisis ton mode en bas à gauche (SOLO ou DIVISION ouverts dès le Palier 1), puis appuie sur JOUER en bas à droite. Les frais OC sont à 0 OC du Niveau 1 au Niveau 5 !',
      },
      {
        'titre': '3/4 · Rubrique Classements & 10 Divisions',
        'desc': 'Ouvre « Classements » à gauche pour voir ta Division actuelle, les 10 paliers officiels et la cagnotte saisonnière dynamique.',
      },
      {
        'titre': '4/4 · Parcours d\'Initiation (6 étapes)',
        'desc': 'Accomplis les 6 vraies actions dans « Init. 0/6 » (Calendrier, Solo, Division, Boutique, Classements, Guide) pour gagner +25 VC, +100 OC et le Titre « Initié du Verse » !',
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final item = etapes[page];
          return AlertDialog(
            backgroundColor: OtakuColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: OtakuColors.accent.withValues(alpha: 0.6)),
            ),
            title: Row(
              children: [
                const Icon(Icons.explore_rounded, color: OtakuColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item['titre']!, style: OtakuTypo.headlineSmall.copyWith(fontSize: 14, color: OtakuColors.accent)),
                ),
              ],
            ),
            content: Text(item['desc']!, style: OtakuTypo.bodySmall.copyWith(fontSize: 12, color: Colors.white, height: 1.4)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('PASSER', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: OtakuColors.accent, foregroundColor: Colors.black),
                onPressed: () {
                  if (page < etapes.length - 1) {
                    setDialogState(() => page++);
                  } else {
                    Navigator.pop(ctx);
                  }
                },
                child: Text(page < etapes.length - 1 ? 'SUIVANT' : 'C\'EST PARTI !', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _regarderPubAccueilOc() async {
    if (_pubAccueilEnCours) return;
    setState(() => _pubAccueilEnCours = true);
    try {
      final res = await _economyService.regarderPubAccueilOc();
      await _chargerProfilEtPortefeuille();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? '+25 Otaku Coins crédités !'),
          backgroundColor: OtakuColors.pvHaut,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _pubAccueilEnCours = false);
    }
  }

  Future<void> _chargerTutorielPhaseB() async {
    final res = await _tutorialService.synchroniserEtapesPhaseBAutomatiquement();
    if (!mounted) return;
    final newSteps = List<int>.from(res['steps'] as List? ?? []);
    final newClaimed = res['claimed'] == true;
    final newlyCompleted = List<int>.from(res['newlyCompleted'] as List? ?? []);
    final rewardMsg = res['rewardMessage']?.toString();

    setState(() {
      _phaseBSteps = newSteps;
      _phaseBClaimed = newClaimed;
    });

    if (rewardMsg != null && rewardMsg.isNotEmpty) {
      _chargerProfilEtPortefeuille();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rewardMsg), backgroundColor: OtakuColors.pvHaut),
      );
    } else if (newlyCompleted.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newlyCompleted.length == 1
                ? 'Initiation : étape ${newlyCompleted.first}/6 validée automatiquement (${newSteps.length}/6) !'
                : 'Initiation : ${newlyCompleted.length} étapes validées automatiquement (${newSteps.length}/6) !',
          ),
          backgroundColor: OtakuColors.pvHaut,
        ),
      );
    }
  }

  Future<void> _allerVersActionPhaseB(int stepNum) async {
    if (stepNum == 1) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const BoutiqueScreen(showBack: true, initialTab: 2)));
    } else if (stepNum == 2) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const CombatSetupPage()));
    } else if (stepNum == 3) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseDivisionPage()));
    } else if (stepNum == 4) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const BoutiqueScreen(showBack: true, initialTab: 0)));
    } else if (stepNum == 5) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassementScreen(initialSection: 'competitif')));
    } else if (stepNum == 6) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const GuideJeuPage()));
    }
    await _chargerProfilEtPortefeuille();
    await _chargerTutorielPhaseB();
  }

  Future<void> _ouvrirParcoursInitiationModal() async {
    Set<int> visitedSteps = await _tutorialService.recupererEtapesVisiteesLocalement();
    if (!mounted) return;
    String? modalError;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Dialog(
              backgroundColor: OtakuColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.school_rounded, color: Color(0xFFFFD700), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'PARCOURS D\'INITIATION (${_phaseBSteps.length}/6)',
                                style: OtakuTypo.headlineSmall.copyWith(fontSize: 14, color: const Color(0xFFFFD700)),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              icon: const Icon(Icons.close_rounded, color: OtakuColors.textMuted),
                            ),
                          ],
                        ),
                        Text(
                          'Chaque étape se valide automatiquement dès que tu accomplis l\'action (reviens sur l\'Accueil) pour débloquer +25 VC, +100 OC et le Titre « Initié du Verse ».',
                          style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                        ),
                        if (modalError != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: OtakuColors.error.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: OtakuColors.error),
                            ),
                            child: Text(modalError!, style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.error)),
                          ),
                        ],
                        const SizedBox(height: 10),
                        ...TutorialService.phaseBSteps.map((s) {
                          final int stepNum = s['step'] as int;
                          final bool done = _phaseBSteps.contains(stepNum);
                          final bool visited = visitedSteps.contains(stepNum);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 7),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: done ? OtakuColors.pvHaut.withValues(alpha: 0.12) : OtakuColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: done ? OtakuColors.pvHaut : OtakuColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  done ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                                  color: done ? OtakuColors.pvHaut : OtakuColors.modeEvent,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$stepNum. ${s['titre']}', style: OtakuTypo.headlineSmall.copyWith(fontSize: 12)),
                                      Text(s['desc'] as String, style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (!done) ...[
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: OtakuColors.accent,
                                      side: const BorderSide(color: OtakuColors.accent),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(dialogCtx);
                                      await _allerVersActionPhaseB(stepNum);
                                    },
                                    child: Text(s['actionLabel'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
                                  ),
                                  const SizedBox(width: 5),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: OtakuColors.pvHaut,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    onPressed: () async {
                                      try {
                                        final res = await _tutorialService.validerEtapePhaseB(
                                          stepNum,
                                          verifiedVisit: visited,
                                        );
                                        final newSteps = (res['steps'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [..._phaseBSteps, stepNum];
                                        final claimed = res['reward_claimed'] == true || _phaseBClaimed;
                                        if (mounted) {
                                          setState(() {
                                            _phaseBSteps = newSteps;
                                            _phaseBClaimed = claimed;
                                          });
                                          setModalState(() => modalError = null);
                                          if (res['reward_claimed'] == true) {
                                            _chargerProfilEtPortefeuille();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(res['message']?.toString() ?? 'Parcours terminé ! Titre « Initié du Verse » obtenu !'),
                                                backgroundColor: OtakuColors.pvHaut,
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        setModalState(() => modalError = e.toString().replaceAll('Exception: ', ''));
                                      }
                                    },
                                    child: const Text('VÉRIFIER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _chargerProfilEtPortefeuille() async {
    try {
      await _progressionService.creerProfilSiAbsent();
      await _skinService.donnerSkinGratuit();
      final results = await Future.wait([
        _progressionService.recupererProfil(),
        _skinService.tousLesSkins(),
        _economyService.recupererPortefeuille(),
      ]);
      final profil = results[0] as Map<String, dynamic>?;
      final skins = results[1] as List;
      final wallet = results[2] as WalletV92;
      final equipe = skins.where((s) => s.equipped).firstOrNull;
      final cadre = await _skinService.recupererCadreEquipe(isVip: profil?['is_vip'] == true);
      if (mounted) {
        setState(() {
          _profil = profil;
          _wallet = wallet;
          _equippedFrameId = cadre;
          if (equipe != null && equipe.imageKey.isNotEmpty) {
            _skinImageKey = equipe.imageKey;
          }
        });
      }
      FriendsService().mettreAJourPresence();
    } catch (_) {}
  }

  Future<void> _chargerMailsNonLus() async {
    try {
      // Cree la recompense de connexion quotidienne (+15 XP) des l'arrivee sur le Hub
      // pour allumer immediatement la pastille rouge sur l'icone Boite aux lettres
      await _mailboxService.verifierDailyLogin();
      final count = await _mailboxService.countNonReclamees();
      if (mounted) {
        setState(() => _unreadMails = count);
      }
    } catch (_) {}
  }

  Future<void> _verifierNotifAmis() async {
    try {
      final demandes = await FriendsService().demandesRecues();
      if (mounted) {
        setState(() => _notifAmis = demandes.isNotEmpty);
      }
    } catch (_) {}
  }

  String _modeAssetPath(String mode) {
    switch (mode) {
      case 'SOLO':
        return 'assets/images/modes/mode_solo_tall.webp';
      case 'DIVISION':
        return 'assets/images/modes/mode_division_tall.webp';
      case 'DUEL':
        return 'assets/images/modes/mode_duel_card.webp';
      case 'COOP':
        return 'assets/images/modes/mode_coop_card.webp';
      case 'EVENTS':
        return 'assets/images/modes/mode_events_card.webp';
      case 'BATTLE_ROYALE':
        return 'assets/images/modes/mode_br_card.webp';
      case 'SALONS_LIVE':
        return 'assets/images/modes/mode_salon_live_card.webp';
      case 'DONJONS':
        return 'assets/images/modes/mode_donjon_card.webp';
      default:
        return 'assets/images/modes/mode_solo_tall.webp';
    }
  }

  String _flagKeyPourMode(String mode) {
    switch (mode) {
      case 'SOLO':
        return 'mode_solo';
      case 'DIVISION':
        return 'mode_division';
      case 'DUEL':
        return 'mode_duel_ami';
      case 'COOP':
        return 'mode_coop';
      case 'EVENTS':
        return 'mode_events_tournois';
      case 'BATTLE_ROYALE':
        return 'mode_battle_royale';
      case 'SALONS_LIVE':
        return 'mode_salon_live';
      case 'DONJONS':
        return 'mode_donjons';
      default:
        return 'mode_solo';
    }
  }

  String _libelleMode(String mode) {
    switch (mode) {
      case 'BATTLE_ROYALE':
        return 'BATTLE ROYALE';
      case 'SALONS_LIVE':
        return 'SALONS LIVE';
      case 'DONJONS':
        return 'DONJONS';
      default:
        return mode;
    }
  }

  /// Ouvre le selecteur de modes plein ecran style Free Fire (Phase A3)
  Future<void> _ouvrirSelecteurModesPleinEcran() async {
    final chosen = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ModeSelectorPage(
          modeActif: _modeActif,
          flagsService: _flagsService,
          onLockedTap: _afficherTeaserModeVerrouille,
        ),
      ),
    );
    if (chosen != null && mounted) {
      setState(() => _modeActif = chosen);
    }
  }

  Future<void> _afficherTeaserModeVerrouille(String titreMode, String flagKey) async {
    final label = _flagsService.labelLancement(flagKey);
    bool dejaInscrit = await _flagsService.estInscritAlerte(flagKey);
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: OtakuColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: OtakuColors.modeEvent.withValues(alpha: 0.6)),
          ),
          title: Row(
            children: [
              const Icon(Icons.lock_rounded, color: OtakuColors.modeEvent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(titreMode, style: OtakuTypo.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: OtakuColors.modeEvent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(label, style: OtakuTypo.label.copyWith(color: OtakuColors.modeEvent)),
              ),
              const SizedBox(height: 10),
              Text(
                'Ce mode arrive progressivement par paliers pour garantir zéro lag et des matchs équilibrés. Active une alerte pour être prévenu dès son ouverture.',
                style: OtakuTypo.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('FERMER', style: OtakuTypo.label.copyWith(color: OtakuColors.textMuted)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: dejaInscrit ? OtakuColors.pvHaut : OtakuColors.modeEvent,
                foregroundColor: Colors.black,
              ),
              onPressed: dejaInscrit
                  ? null
                  : () async {
                      final ok = await _flagsService.sInscrireAlerte(flagKey);
                      if (ok) {
                        await _tutorialService.marquerVisiteEtape(6);
                        setDialogState(() => dejaInscrit = true);
                      }
                    },
              icon: Icon(dejaInscrit ? Icons.check_rounded : Icons.notifications_active_rounded, size: 16),
              label: Text(dejaInscrit ? 'ALERTE ACTIVÉE' : "M'ALERTER"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _lancerModeActif() async {
    final flagKey = _flagKeyPourMode(_modeActif);
    if (!_flagsService.estOuvert(flagKey)) {
      _afficherTeaserModeVerrouille(_libelleMode(_modeActif), flagKey);
      return;
    }
    if (_modeActif == 'SOLO') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const CombatSetupPage()));
    } else if (_modeActif == 'DIVISION') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseDivisionPage()));
    } else if (_modeActif == 'DUEL') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseDuelSetupPage()));
    } else if (_modeActif == 'COOP') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseCoopPage()));
    } else if (_modeActif == 'EVENTS') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseV3HubPage(initialTab: 1)));
    } else if (_modeActif == 'BATTLE_ROYALE') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseBattleRoyalePage()));
    } else if (_modeActif == 'SALONS_LIVE' || _modeActif == 'DONJONS') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseCommunautePage()));
    }
    _chargerProfilEtPortefeuille();
    _chargerTutorielPhaseB();
  }

  @override
  Widget build(BuildContext context) {
    final pseudo = _profil?['pseudo']?.toString() ?? 'Joueur';
    final xpTotale = (_profil?['xp_totale'] as num?)?.toInt() ?? 0;
    final niveau = (_profil?['niveau'] as num?)?.toInt() ?? 1;
    final divisionId = (_profil?['division_id'] as num?)?.toInt() ?? 10;
    final bool guildesOuvertes = _flagsService.estOuvert('mode_guildes');
    final bool eventsOuverts = _flagsService.estOuvert('mode_events_tournois');
    final bool salonsOuverts = _flagsService.estOuvert('mode_salon_live') || _flagsService.estOuvert('mode_donjons');
    final skinActif = SkinService.parImageKey(_skinImageKey);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Decor d'arene immersif plein ecran (Phase A5)
        Image.asset(
          'assets/images/backgrounds/lobby_arene_principale.webp',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(color: OtakuColors.background),
        ),
        // Voile d'ambiance sombre pour detachage net des widgets glassmorphism
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.95,
                colors: [
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.58),
                  OtakuColors.background.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
        ),

        // === MISE EN PAGE STYLE FREE FIRE 100 % RESPONSIVE (PHASE A2) ===
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              children: [
                // 1. TOP BAR FINE : Profil (avec cadre + medaille rang) | XP, OC, VC, Pub +OC, Mail, Parametres
                Row(
                  children: [
                    Flexible(
                      flex: 4,
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                          _chargerProfilEtPortefeuille();
                          _chargerTutorielPhaseB();
                        },
                        child: LiquidGlass(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          borderRadius: 16,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SafeAvatarBox(
                                assetPath: 'assets/images/skins/$_skinImageKey.png',
                                frameId: _equippedFrameId,
                                width: 36,
                                height: 36,
                                topPadding: 2,
                                borderRadius: 10,
                                borderColor: skinActif.accentColor,
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      pseudo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: OtakuTypo.headlineSmall.copyWith(fontSize: 12),
                                    ),
                                    const SizedBox(height: 1),
                                    OfficialRankBadge(niveau: niveau, divisionId: divisionId, compact: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildCurrencyChip(
                              label: '$xpTotale XP',
                              color: OtakuColors.accent,
                              icon: Icons.bolt_rounded,
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                                _chargerProfilEtPortefeuille();
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildCurrencyChip(
                              label: '${_wallet.ocBalance} OC',
                              color: const Color(0xFF4CC9F0),
                              icon: Icons.toll_rounded,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BoutiqueScreen(showBack: true, initialTab: 2)),
                                );
                                _chargerProfilEtPortefeuille();
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildCurrencyChip(
                              label: '${_wallet.totalVc} VC',
                              color: Colors.amber,
                              icon: Icons.diamond_rounded,
                              showPlus: true,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BoutiqueScreen(showBack: true, initialTab: 3)),
                                );
                                _chargerProfilEtPortefeuille();
                              },
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _pubAccueilEnCours ? null : _regarderPubAccueilOc,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: OtakuColors.pvHaut.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: OtakuColors.pvHaut.withValues(alpha: 0.75)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _pubAccueilEnCours ? Icons.hourglass_top_rounded : Icons.play_circle_filled_rounded,
                                      size: 14,
                                      color: OtakuColors.pvHaut,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'PUB +OC',
                                      style: OtakuTypo.hud.copyWith(fontSize: 10, color: OtakuColors.pvHaut),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => const BoiteLettresPage()));
                                _chargerMailsNonLus();
                                _chargerProfilEtPortefeuille();
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const LiquidGlass(
                                    padding: EdgeInsets.all(7),
                                    borderRadius: 14,
                                    child: Icon(Icons.mail_rounded, color: OtakuColors.textSecondary, size: 17),
                                  ),
                                  if (_unreadMails > 0)
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF2E4C),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: OtakuColors.background, width: 1.5),
                                          boxShadow: const [
                                            BoxShadow(color: Color(0xAAFF2E4C), blurRadius: 6),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$_unreadMails',
                                          style: OtakuTypo.label.copyWith(
                                            fontSize: 8.5,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ParametresPage(
                                      profil: _profil,
                                      onProfilChange: _chargerProfilEtPortefeuille,
                                    ),
                                  ),
                                );
                                _chargerProfilEtPortefeuille();
                              },
                              child: const LiquidGlass(
                                padding: EdgeInsets.all(7),
                                borderRadius: 14,
                                child: Icon(Icons.settings_rounded, color: OtakuColors.textSecondary, size: 17),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Bandeau propre en cas de perte reseau (Phase B3)
                if (_reseauHorsLigne)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: OtakuColors.error.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: OtakuColors.error.withValues(alpha: 0.75)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 15, color: OtakuColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Connexion perdue. Vérifie ta 4G ou ton Wi-Fi.',
                            style: OtakuTypo.bodySmall.copyWith(fontSize: 10.5, color: Colors.white),
                          ),
                        ),
                        GestureDetector(
                          onTap: _initialiserHub,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: OtakuColors.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('RÉESSAYER', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. CORPS PRINCIPAL FREE FIRE : Colonne Gauche | Scene 3D Centrale | Colonne Droite + CTA bas-droite
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Colonne gauche fine et scrollable
                      SizedBox(
                        width: 132,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildSideNavButton('Boutique', Icons.store_rounded, () async {
                                  AnalyticsService.instance.logShopOpen(0);
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const BoutiqueScreen(showBack: true)));
                                  _chargerProfilEtPortefeuille();
                                  _chargerTutorielPhaseB();
                                }),
                                const SizedBox(height: 7),
                                _buildSideNavButton('Classements', Icons.leaderboard_rounded, () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ClassementScreen(initialSection: 'competitif')),
                                  );
                                  _chargerProfilEtPortefeuille();
                                  _chargerTutorielPhaseB();
                                }),
                                const SizedBox(height: 7),
                                _buildSideNavButton('Quêtes', Icons.assignment_rounded, () async {
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => _QuetePage(profil: _profil)));
                                  _chargerProfilEtPortefeuille();
                                  _chargerMailsNonLus();
                                }),
                                const SizedBox(height: 7),
                                _buildSideNavButton(
                                  'Saison',
                                  eventsOuverts ? Icons.emoji_events_rounded : Icons.lock_rounded,
                                  () {
                                    if (eventsOuverts) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseV3HubPage()));
                                    } else {
                                      _afficherTeaserModeVerrouille('Saisons & Tournois', 'mode_events_tournois');
                                    }
                                  },
                                  locked: !eventsOuverts,
                                ),
                                if (!_phaseBClaimed) ...[
                                  const SizedBox(height: 7),
                                  _buildSideNavButton(
                                    'Init. ${_phaseBSteps.length}/6',
                                    Icons.school_rounded,
                                    _ouvrirParcoursInitiationModal,
                                    highlight: true,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Scene centrale large plein ecran : Viewer 3D .glb interactif 360° + repli 2D
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: OtakuSkin3DViewer(
                            imageKey: _skinImageKey,
                            accentColor: skinActif.accentColor,
                            characterName: skinActif.name,
                            characterSubtitle: skinActif.powerName.isNotEmpty ? skinActif.powerName : skinActif.role,
                          ),
                        ),
                      ),

                      // Colonne droite : raccourcis sociaux en haut + Selecteur Mode empile sur JOUER en bas (Free Fire)
                      SizedBox(
                        width: 196,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.topRight,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          _buildSideNavButton('Amis', Icons.people_rounded, () async {
                                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const AmisScreen()));
                                            _verifierNotifAmis();
                                          }, isRight: true),
                                          if (_notifAmis)
                                            Positioned(
                                              left: -4,
                                              top: -4,
                                              child: Container(
                                                width: 11,
                                                height: 11,
                                                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      _buildSideNavButton(
                                        'Guildes',
                                        guildesOuvertes ? Icons.shield_rounded : Icons.lock_rounded,
                                        () {
                                          if (guildesOuvertes) {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseGuildesPage()));
                                          } else {
                                            _afficherTeaserModeVerrouille('Guildes (4 joueurs)', 'mode_guildes');
                                          }
                                        },
                                        isRight: true,
                                        locked: !guildesOuvertes,
                                      ),
                                      const SizedBox(height: 6),
                                      _buildSideNavButton(
                                        'Salons',
                                        salonsOuverts ? Icons.groups_rounded : Icons.lock_rounded,
                                        () {
                                          if (salonsOuverts) {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseCommunautePage()));
                                          } else {
                                            _afficherTeaserModeVerrouille('Salons Live JKLM & Donjons', 'mode_salon_live');
                                          }
                                        },
                                        isRight: true,
                                        locked: !salonsOuverts,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Carte compacte du mode selectionne -> ouvre ModeSelectorPage plein ecran
                            GestureDetector(
                              onTap: _ouvrirSelecteurModesPleinEcran,
                              child: Container(
                                width: double.infinity,
                                height: 48,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.75), width: 1.3),
                                  color: OtakuColors.surface,
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      _modeAssetPath(_modeActif),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                    ),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.88),
                                            Colors.black.withValues(alpha: 0.45),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'CHANGER DE MODE',
                                                  style: OtakuTypo.label.copyWith(fontSize: 7.5, color: OtakuColors.accent),
                                                ),
                                                Text(
                                                  _libelleMode(_modeActif),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: OtakuTypo.headlineSmall.copyWith(fontSize: 13, color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.grid_view_rounded, color: OtakuColors.accent, size: 18),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),

                            // Bouton JOUER massif style Free Fire
                            GestureDetector(
                              onTap: _lancerModeActif,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFB703).withValues(alpha: 0.45),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                                    const SizedBox(width: 4),
                                    Text(
                                      'JOUER',
                                      style: OtakuTypo.headlineLarge.copyWith(
                                        fontSize: 19,
                                        color: Colors.black,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyChip({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    bool showPlus = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        borderRadius: 14,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(label, style: OtakuTypo.hud.copyWith(fontSize: 10, color: color)),
            if (showPlus) ...[
              const SizedBox(width: 3),
              Icon(Icons.add_circle_rounded, color: color, size: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSideNavButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isRight = false,
    bool locked = false,
    bool highlight = false,
  }) {
    final iconColor = highlight
        ? const Color(0xFFFFD700)
        : (locked ? OtakuColors.modeEvent : OtakuColors.textSecondary);
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        borderRadius: 12,
        tintColor: highlight ? const Color(0xFFFFD700) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: isRight
              ? [
                  Text(label, style: OtakuTypo.headlineSmall.copyWith(fontSize: 11)),
                  const SizedBox(width: 7),
                  Icon(icon, color: iconColor, size: 17),
                ]
              : [
                  Icon(icon, color: iconColor, size: 17),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: OtakuTypo.headlineSmall.copyWith(
                      fontSize: 11,
                      color: highlight ? const Color(0xFFFFD700) : OtakuColors.textPrimary,
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}

/// Ecran Quetes aligne V9.2 + option 3 Defis Bonus (50 OC) (Tests 12, 28, 31)
class _QuetePage extends StatefulWidget {
  final Map<String, dynamic>? profil;
  const _QuetePage({this.profil});

  @override
  State<_QuetePage> createState() => _QuetePageState();
}

class _QuetePageState extends State<_QuetePage> {
  final QueteService _queteService = QueteService();
  final ProgressionService _progressionService = ProgressionService();
  final MonetisationV4Service _shopService = MonetisationV4Service();
  bool _chargement = true;
  bool _achatBonusEnCours = false;
  late List<_Quete> _quetes;

  @override
  void initState() {
    super.initState();
    final combatsJoues = (widget.profil?['combats_joues'] as num?)?.toInt() ?? 0;
    final combatsGagnes = (widget.profil?['combats_gagnes'] as num?)?.toInt() ?? 0;
    final niveau = (widget.profil?['niveau'] as num?)?.toInt() ?? 1;

    _quetes = [
      _Quete(
        titre: 'Joue 3 combats',
        recompense: '+30 XP',
        xpAmount: 30,
        progression: combatsJoues.clamp(0, 3),
        objectif: 3,
        icon: Icons.bolt_rounded,
        couleur: OtakuColors.modeSolo,
      ),
      _Quete(
        titre: 'Gagne 1 combat',
        recompense: '+50 XP',
        xpAmount: 50,
        progression: combatsGagnes.clamp(0, 1),
        objectif: 1,
        icon: Icons.emoji_events_rounded,
        couleur: OtakuColors.modeEvent,
      ),
      _Quete(
        titre: 'Atteins le Niveau 3',
        recompense: '+40 XP',
        xpAmount: 40,
        progression: niveau.clamp(0, 3),
        objectif: 3,
        icon: Icons.trending_up_rounded,
        couleur: OtakuColors.pvHaut,
      ),
      _Quete(
        titre: 'Gagne 5 combats',
        recompense: '+80 XP',
        xpAmount: 80,
        progression: combatsGagnes.clamp(0, 5),
        objectif: 5,
        icon: Icons.local_fire_department_rounded,
        couleur: OtakuColors.modeDuel,
      ),
    ];
    _chargerQuetes();
  }

  Future<void> _chargerQuetes() async {
    try {
      final state = await _queteService.getQuetesState();
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _quetes.length; i++) {
          final q = _quetes[i];
          if (state.containsKey(q.titre)) {
            final savedProg = (state[q.titre]!['progression'] as num?)?.toInt() ?? 0;
            _quetes[i] = _Quete(
              titre: q.titre,
              recompense: q.recompense,
              xpAmount: q.xpAmount,
              progression: max(q.progression, savedProg).clamp(0, q.objectif),
              objectif: q.objectif,
              icon: q.icon,
              couleur: q.couleur,
              recupere: state[q.titre]!['recupere'] == true,
            );
          }
        }
        _chargement = false;
      });
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _recuperer(int index) async {
    final q = _quetes[index];
    if (q.recupere || q.progression < q.objectif) return;
    setState(() => _quetes[index] = q.copyRecupere());

    try {
      await _queteService.syncQuete(q.titre, q.progression, true);
      if (q.xpAmount > 0) {
        await _progressionService.mettreAJourApresComabat(
          xpGagne: q.xpAmount,
          victoire: false,
        );
      }
    } catch (_) {}
  }

  Future<void> _debloquerDefisBonus() async {
    if (_achatBonusEnCours) return;
    setState(() => _achatBonusEnCours = true);
    try {
      final msg = await _shopService.debloquerDefisBonusOc();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: OtakuColors.pvHaut),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _achatBonusEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('QUÊTES & DÉFIS', style: OtakuTypo.headlineLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _chargement
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  children: [
                    ...List.generate(
                      _quetes.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildQueteCard(_quetes[i], i),
                      ),
                    ),
                    // Recharge 3 Defis Bonus (50 OC — Test 31)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: OtakuColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF4CC9F0).withValues(alpha: 0.55)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.assignment_add, color: Color(0xFF4CC9F0), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('3 DÉFIS BONUS DU JOUR', style: OtakuTypo.headlineSmall.copyWith(fontSize: 13, color: const Color(0xFF4CC9F0))),
                                Text(
                                  'Ajoute 3 défis quotidiens supplémentaires (+30 XP par défi réussi) contre 50 OC.',
                                  style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CC9F0), foregroundColor: Colors.black),
                            onPressed: _achatBonusEnCours ? null : _debloquerDefisBonus,
                            child: const Text('50 OC', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildQueteCard(_Quete quete, int index) {
    final complete = quete.progression >= quete.objectif;
    final progress = quete.objectif > 0 ? quete.progression / quete.objectif : 0.0;

    return LiquidGlass(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      tintColor: complete ? quete.couleur : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: quete.couleur.withValues(alpha: complete ? 0.2 : 0.1),
              border: Border.all(color: quete.couleur.withValues(alpha: complete ? 0.5 : 0.3)),
            ),
            child: Icon(quete.icon, size: 22, color: quete.couleur),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quete.titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OtakuTypo.headlineSmall.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: OtakuColors.border,
                          valueColor: AlwaysStoppedAnimation(quete.couleur),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${quete.progression}/${quete.objectif}',
                      style: OtakuTypo.hud.copyWith(fontSize: 11, color: OtakuColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          if (complete && !quete.recupere)
            GestureDetector(
              onTap: () => _recuperer(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: quete.couleur.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: quete.couleur.withValues(alpha: 0.6)),
                ),
                child: Text(quete.recompense, style: OtakuTypo.headlineSmall.copyWith(fontSize: 11, color: quete.couleur)),
              ),
            )
          else if (quete.recupere)
            Icon(Icons.check_circle_rounded, size: 26, color: OtakuColors.pvHaut.withValues(alpha: 0.6))
          else
            Text(quete.recompense, style: OtakuTypo.headlineSmall.copyWith(fontSize: 11, color: OtakuColors.textMuted)),
        ],
      ),
    );
  }
}

class _Quete {
  final String titre;
  final String recompense;
  final int xpAmount;
  final int progression;
  final int objectif;
  final IconData icon;
  final Color couleur;
  final bool recupere;

  const _Quete({
    required this.titre,
    required this.recompense,
    required this.xpAmount,
    required this.progression,
    required this.objectif,
    required this.icon,
    required this.couleur,
    this.recupere = false,
  });

  _Quete copyRecupere() => _Quete(
        titre: titre,
        recompense: recompense,
        xpAmount: xpAmount,
        progression: progression,
        objectif: objectif,
        icon: icon,
        couleur: couleur,
        recupere: true,
      );
}
