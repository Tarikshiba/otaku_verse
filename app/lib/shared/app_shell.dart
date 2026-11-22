import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../features/combat/combat_setup_page.dart';
import '../features/core/feature_flags_service.dart';
import '../features/economy/economy_v92_service.dart';
import '../features/verse/verse_division_page.dart';
import '../features/verse/verse_duel_setup_page.dart';
import '../features/verse/verse_coop_page.dart';
import '../features/verse/verse_v3_hub_page.dart';
import '../features/verse/verse_battle_royale_page.dart';
import '../features/verse/verse_communaute_page.dart';
import '../features/verse/verse_guildes_page.dart';
import '../features/profile/profile_page.dart';
import '../features/progression/progression_service.dart';
import '../features/rewards/boite_lettres_page.dart';
import '../features/rewards/mailbox_service.dart';
import '../features/skins/boutique_screen.dart';
import '../features/skins/skin_service.dart';
import '../features/social/amis_screen.dart';
import '../features/social/friends_service.dart';
import '../features/tutorial/tutorial_service.dart';
import 'rank_badge.dart';
import 'textures.dart';
import '../features/progression/quete_service.dart';

/// === SHELL PRINCIPAL DE L'APP (V9.2 + DA LIQUID GLASS) ===
/// Hub central facon Free Fire avec :
/// - Compteurs separes OC et VC (ECO-01)
/// - Badge de Rang officiel permanent (ECO-04)
/// - Pilotage a distance des modes par paliers via `app_feature_flags` (LAUNCH-01/03)
/// - Goodies central non coupe (UI-01) et anti-overflow sur petits ecrans (UI-02)
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

class _AccueilPageState extends State<_AccueilPage> with SingleTickerProviderStateMixin {
  final _progressionService = ProgressionService();
  final _skinService = SkinService();
  final _economyService = EconomyV92Service();
  final _flagsService = FeatureFlagsService();
  final _mailboxService = MailboxService();
  final _tutorialService = TutorialService();

  Map<String, dynamic>? _profil;
  WalletV92 _wallet = const WalletV92();
  String _skinImageKey = 'skin_default';
  double _skinRotation = 0;
  late AnimationController _idleRotation;
  bool _notifAmis = false;
  int _unreadMails = 0;
  String _modeActif = 'SOLO';
  List<int> _phaseBSteps = [];
  bool _phaseBClaimed = true;

  @override
  void initState() {
    super.initState();
    _initialiserHub();
    _idleRotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _idleRotation.dispose();
    super.dispose();
  }

  /// Charge toutes les donnees du Hub en parallele (flags, profil, portefeuille, mails, amis, tutoriel)
  Future<void> _initialiserHub() async {
    final msgPhaseA = await _tutorialService.synchroniserPhaseASiEnAttente();
    await Future.wait([
      _flagsService.chargerFlags(),
      _chargerProfilEtPortefeuille(),
      _verifierNotifAmis(),
      _chargerMailsNonLus(),
      _chargerTutorielPhaseB(),
    ]);
    if (mounted) {
      setState(() {});
      if (msgPhaseA != null && msgPhaseA.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msgPhaseA), backgroundColor: OtakuColors.pvHaut),
        );
      }
    }
  }

  Future<void> _chargerTutorielPhaseB() async {
    final state = await _tutorialService.recupererEtatPhaseB();
    if (!mounted) return;
    setState(() {
      _phaseBSteps = List<int>.from(state['steps'] as List? ?? []);
      _phaseBClaimed = state['claimed'] == true;
    });
  }

  void _ouvrirParcoursInitiationModal() {
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
                  width: 460,
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
                          'Valide les 6 etapes de decouverte pour debloquer +25 VC, +100 OC et le Titre "Initie du Verse".',
                          style: OtakuTypo.bodySmall.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                        ),
                        const SizedBox(height: 10),
                        ...TutorialService.phaseBSteps.map((s) {
                          final int stepNum = s['step'] as int;
                          final bool done = _phaseBSteps.contains(stepNum);
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
                                  done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  color: done ? OtakuColors.pvHaut : OtakuColors.accent,
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
                                const SizedBox(width: 8),
                                if (!done)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: OtakuColors.accent,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    onPressed: () async {
                                      try {
                                        final res = await _tutorialService.validerEtapePhaseB(stepNum);
                                        final newSteps = (res['steps'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [..._phaseBSteps, stepNum];
                                        final claimed = res['reward_claimed'] == true || _phaseBClaimed;
                                        if (mounted) {
                                          setState(() {
                                            _phaseBSteps = newSteps;
                                            _phaseBClaimed = claimed;
                                          });
                                          setModalState(() {});
                                          if (res['reward_claimed'] == true) {
                                            _chargerProfilEtPortefeuille();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(res['message']?.toString() ?? 'Parcours termine !'),
                                                backgroundColor: OtakuColors.pvHaut,
                                              ),
                                            );
                                          }
                                        }
                                      } catch (_) {}
                                    },
                                    child: const Text('COMPRIS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                                  ),
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
      if (mounted) {
        setState(() {
          _profil = profil;
          _wallet = wallet;
          if (equipe != null && equipe.imageKey.isNotEmpty) {
            _skinImageKey = equipe.imageKey;
          }
        });
      }
      FriendsService().mettreAJourPresence();
    } catch (_) {}
  }

  /// FIX-02 : Charge le vrai nombre de recompenses non reclamees dans la boite a lettres
  Future<void> _chargerMailsNonLus() async {
    try {
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
        return 'assets/images/modes/mode_solo.png';
      case 'DIVISION':
        return 'assets/images/modes/mode_division.png';
      case 'DUEL':
        return 'assets/images/modes/mode_duel.png';
      case 'COOP':
        return 'assets/images/modes/mode_coop.png';
      case 'EVENTS':
        return 'assets/images/modes/mode_events.png';
      case 'BATTLE_ROYALE':
        return 'assets/images/modes/mode_br.png';
      default:
        return 'assets/images/modes/mode_solo.png';
    }
  }

  /// Fait le lien entre un mode UI et sa cle dans la table Supabase `app_feature_flags`
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
      default:
        return 'mode_solo';
    }
  }

  /// Popup affichee quand le joueur clique sur un mode verrouille (LAUNCH-01 / LAUNCH-03)
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
                child: Text(
                  titreMode,
                  style: OtakuTypo.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
                child: Text(
                  label,
                  style: OtakuTypo.label.copyWith(color: OtakuColors.modeEvent),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ce mode arrive progressivement par paliers pour garantir zero lag et des matchs equilibres. Active une alerte pour etre prevenu des son ouverture.',
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
                        setDialogState(() => dejaInscrit = true);
                      }
                    },
              icon: Icon(dejaInscrit ? Icons.check_rounded : Icons.notifications_active_rounded, size: 16),
              label: Text(dejaInscrit ? 'ALERTE ACTIVEE' : "M'ALERTER"),
            ),
          ],
        ),
      ),
    );
  }

  void _showModeDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: OtakuColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: OtakuColors.glassBorder),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: OtakuColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 10),
            Text('SELECTIONNER LE MODE', style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeOption('SOLO : Affronte l\'IA (350 PV / 40 Q)', Icons.bolt_rounded, OtakuColors.modeSolo, 'SOLO'),
                    const SizedBox(height: 8),
                    _buildModeOption('DIVISION : Classement Mondial', Icons.military_tech_rounded, OtakuColors.modeDivision, 'DIVISION'),
                    const SizedBox(height: 8),
                    _buildModeOption('DUEL : Defie un ami (1v1)', Icons.people_alt_rounded, OtakuColors.modeDuel, 'DUEL'),
                    const SizedBox(height: 8),
                    _buildModeOption('COOP : Duo 2vIA & 2v2', Icons.group_work_rounded, OtakuColors.modeCoop, 'COOP'),
                    const SizedBox(height: 8),
                    _buildModeOption('EVENEMENT : Saisons & Tournois', Icons.local_fire_department_rounded, OtakuColors.modeEvent, 'EVENTS'),
                    const SizedBox(height: 8),
                    _buildModeOption('BATTLE ROYALE : Survie 10 joueurs', Icons.whatshot_rounded, Colors.deepOrangeAccent, 'BATTLE_ROYALE'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(String label, IconData icon, Color couleur, String mode) {
    final String flagKey = _flagKeyPourMode(mode);
    final bool ouvert = _flagsService.estOuvert(flagKey);
    final String launchLabel = _flagsService.labelLancement(flagKey);
    final bool estSelectionne = _modeActif == mode && ouvert;
    final String imgPath = _modeAssetPath(mode);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (ouvert) {
          setState(() => _modeActif = mode);
        } else {
          _afficherTeaserModeVerrouille(label, flagKey);
        }
      },
      child: Container(
        height: 68,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: OtakuColors.surface,
          border: Border.all(
            color: estSelectionne
                ? couleur
                : (ouvert ? couleur.withValues(alpha: 0.45) : OtakuColors.modeEvent.withValues(alpha: 0.35)),
            width: estSelectionne ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: ouvert ? 1.0 : 0.4,
              child: Image.asset(
                imgPath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    OtakuColors.background.withValues(alpha: 0.94),
                    OtakuColors.background.withValues(alpha: 0.72),
                    couleur.withValues(alpha: ouvert ? 0.25 : 0.1),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: couleur.withValues(alpha: 0.22),
                      border: Border.all(color: couleur.withValues(alpha: 0.6)),
                    ),
                    child: Icon(ouvert ? icon : Icons.lock_rounded, size: 20, color: ouvert ? couleur : OtakuColors.modeEvent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: OtakuTypo.headlineSmall.copyWith(
                            fontSize: 13,
                            color: ouvert ? OtakuColors.textPrimary : OtakuColors.textSecondary,
                          ),
                        ),
                        if (!ouvert)
                          Text(
                            launchLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.modeEvent),
                          ),
                      ],
                    ),
                  ),
                  if (!ouvert)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: OtakuColors.modeEvent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: OtakuColors.modeEvent.withValues(alpha: 0.6)),
                      ),
                      child: Text('BIENTOT', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.modeEvent)),
                    )
                  else if (estSelectionne)
                    Icon(Icons.check_circle_rounded, size: 22, color: couleur)
                  else
                    Icon(Icons.chevron_right_rounded, size: 20, color: couleur.withValues(alpha: 0.8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pseudo = _profil?['pseudo']?.toString() ?? 'Joueur';
    final niveau = (_profil?['niveau'] as num?)?.toInt() ?? 1;
    final divisionId = (_profil?['division_id'] as num?)?.toInt() ?? 10;
    final bool guildesOuvertes = _flagsService.estOuvert('mode_guildes');
    final bool eventsOuverts = _flagsService.estOuvert('mode_events_tournois');

    return Stack(
      children: [
        Positioned.fill(child: Container(color: OtakuColors.background)),
        Positioned.fill(
          child: SectionTexture(
            type: TextureType.speedlines,
            opacity: 0.06,
            child: const SizedBox.expand(),
          ),
        ),

        // === ARRIERE-PLAN : Skin rotatif plein ecran (UI-01 non coupe) ===
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (d) => setState(() => _skinRotation += d.delta.dx * 0.01),
            child: AnimatedBuilder(
              animation: _idleRotation,
              builder: (context, _) {
                final angle = _skinRotation + (_idleRotation.value * 2 * pi);
                return _SkinDisplay(rotation: angle, imageKey: _skinImageKey);
              },
            ),
          ),
        ),

        // Vignette sombre
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    Colors.transparent,
                    OtakuColors.background.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
          ),
        ),

        // === TOP BAR V9.2 : Profil + Badge de Rang Permanent + Compteurs OC & VC separes ===
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  // Profil + Badge de Rang officiel (anti-overflow UI-02)
                  Flexible(
                    flex: 5,
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfilePage()),
                        );
                        _chargerProfilEtPortefeuille();
                      },
                      child: LiquidGlass(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        borderRadius: 18,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SafeAvatarBox(
                              assetPath: 'assets/images/skins/$_skinImageKey.png',
                              width: 36,
                              height: 36,
                              topPadding: 3,
                              borderRadius: 12,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    pseudo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: OtakuTypo.headlineSmall.copyWith(fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  OfficialRankBadge(
                                    niveau: niveau,
                                    divisionId: divisionId,
                                    compact: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Compteurs OC et VC separes + Boite a lettres (UI-02 Flexible)
                  Flexible(
                    flex: 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Compteur Otaku Coins (OC)
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
                        const SizedBox(width: 8),
                        // Compteur Verse Coins (VC) + bouton '+'
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
                        const SizedBox(width: 8),
                        // Boite a lettres avec pastille dynamique (FIX-02)
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BoiteLettresPage()),
                            );
                            _chargerMailsNonLus();
                            _chargerProfilEtPortefeuille();
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const LiquidGlass(
                                padding: EdgeInsets.all(9),
                                borderRadius: 16,
                                child: Icon(Icons.mail_rounded, color: OtakuColors.textSecondary, size: 20),
                              ),
                              if (_unreadMails > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$_unreadMails',
                                      style: OtakuTypo.label.copyWith(fontSize: 9, color: Colors.white),
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
        ),

        // === COLONNE GAUCHE ===
        Positioned(
          left: 16,
          top: 96,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSideNavButton('Boutique', Icons.store_rounded, () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const BoutiqueScreen(showBack: true)));
                  _chargerProfilEtPortefeuille();
                }),
                const SizedBox(height: 10),
                _buildSideNavButton('Quetes', Icons.assignment_rounded, () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => _QuetePage(profil: _profil)));
                  _chargerProfilEtPortefeuille();
                }),
                const SizedBox(height: 10),
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
                  const SizedBox(height: 10),
                  _buildSideNavButton(
                    'Init. ${_phaseBSteps.length}/6',
                    Icons.school_rounded,
                    _ouvrirParcoursInitiationModal,
                  ),
                ],
              ],
            ),
          ),
        ),

        // === COLONNE DROITE ===
        Positioned(
          right: 16,
          top: 96,
          child: SafeArea(
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
                        left: -5,
                        top: -5,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 10),
                _buildSideNavButton(
                  'Salons',
                  (_flagsService.estOuvert('mode_salon_live') || _flagsService.estOuvert('mode_donjons'))
                      ? Icons.groups_rounded
                      : Icons.lock_rounded,
                  () {
                    if (_flagsService.estOuvert('mode_salon_live') || _flagsService.estOuvert('mode_donjons')) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseCommunautePage()));
                    } else {
                      _afficherTeaserModeVerrouille('Salons Live JKLM & Donjons', 'mode_salon_live');
                    }
                  },
                  isRight: true,
                  locked: !(_flagsService.estOuvert('mode_salon_live') || _flagsService.estOuvert('mode_donjons')),
                ),
              ],
            ),
          ),
        ),

        // === BOUTON JOUER ===
        Positioned(
          bottom: 20,
          right: 20,
          child: SafeArea(
            child: GestureDetector(
              onTap: () async {
                final flagKey = _flagKeyPourMode(_modeActif);
                if (!_flagsService.estOuvert(flagKey)) {
                  _afficherTeaserModeVerrouille(_modeActif, flagKey);
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
                }
                _chargerProfilEtPortefeuille();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [OtakuColors.accent, OtakuColors.accentDark],
                  ),
                  boxShadow: [
                    BoxShadow(color: OtakuColors.accent.withValues(alpha: 0.55), blurRadius: 22, spreadRadius: 3),
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      'JOUER',
                      style: OtakuTypo.headlineLarge.copyWith(fontSize: 24, color: Colors.white, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // === SELECTEUR DE MODE ===
        Positioned(
          bottom: 20,
          left: 20,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => _showModeDrawer(context),
              child: LiquidGlass(
                tintColor: OtakuColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                borderRadius: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        _modeAssetPath(_modeActif),
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(width: 42, height: 42),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('MODE SELECTIONNE', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.textMuted)),
                            const SizedBox(width: 4),
                            const Icon(Icons.expand_less_rounded, color: OtakuColors.textMuted, size: 14),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(_modeActif, style: OtakuTypo.headlineLarge.copyWith(fontSize: 15)),
                      ],
                    ),
                  ],
                ),
              ),
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
    return Flexible(
      child: GestureDetector(
        onTap: onTap,
        child: LiquidGlass(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          borderRadius: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OtakuTypo.hud.copyWith(fontSize: 11, color: color),
                ),
              ),
              if (showPlus) ...[
                const SizedBox(width: 4),
                Icon(Icons.add_circle_rounded, color: color, size: 14),
              ],
            ],
          ),
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
  }) {
    final iconColor = locked ? OtakuColors.modeEvent : OtakuColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        borderRadius: 14,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: isRight
              ? [
                  Text(label, style: OtakuTypo.headlineSmall.copyWith(fontSize: 13)),
                  const SizedBox(width: 10),
                  Icon(icon, color: iconColor, size: 20),
                ]
              : [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 10),
                  Text(label, style: OtakuTypo.headlineSmall.copyWith(fontSize: 13)),
                ],
        ),
      ),
    );
  }
}

/// Affichage central du Goodies (UI-01 : BoxFit.contain + Alignment.topCenter + padding >= 12px)
class _SkinDisplay extends StatelessWidget {
  final double rotation;
  final String imageKey;
  const _SkinDisplay({required this.rotation, required this.imageKey});

  @override
  Widget build(BuildContext context) {
    final double oscillation = sin(rotation) * 0.22;
    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(oscillation),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SafeAvatarBox(
              assetPath: 'assets/images/skins/$imageKey.png',
              width: 210,
              height: 250,
              topPadding: 14,
              borderRadius: 24,
              borderColor: OtakuColors.accent,
            ),
            const SizedBox(height: 12),
            Container(
              width: 220,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: RadialGradient(
                  colors: [
                    OtakuColors.accent.withValues(alpha: 0.55),
                    OtakuColors.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ecran Quetes corrige (FIX-03 : progressions reelles depuis le profil + vrai credit XP)
class _QuetePage extends StatefulWidget {
  final Map<String, dynamic>? profil;
  const _QuetePage({this.profil});

  @override
  State<_QuetePage> createState() => _QuetePageState();
}

class _QuetePageState extends State<_QuetePage> {
  final QueteService _queteService = QueteService();
  final ProgressionService _progressionService = ProgressionService();
  bool _chargement = true;
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
        title: Text('QUETES', style: OtakuTypo.headlineLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _chargement
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.only(top: 12, bottom: 16),
                  itemCount: _quetes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildQueteCard(_quetes[i], i),
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
