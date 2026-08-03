import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../features/combat/combat_setup_page.dart';
import '../features/profile/profile_page.dart';
import '../features/progression/progression_service.dart';
import '../features/rewards/boite_lettres_page.dart';
import '../features/skins/boutique_screen.dart';
import '../features/social/amis_screen.dart';
import '../features/social/friends_service.dart';
import 'otaku_tab_bar.dart';

/// === SHELL PRINCIPAL DE L'APP ===
/// 5 onglets : Accueil(0) - Boutique(1) - Jouer(2) - Quete(3) - Amis(4)
/// Profil accessible via icone avatar en haut de l'Accueil.
/// Boite a lettres accessible via icone en haut de l'Accueil.

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  int _indexActif = 0;
  bool _notifAmis = false;

  // Animation de transition Accueil <-> Jouer
  late AnimationController _transitionController;
  late Animation<Offset> _accueilSlide;
  late Animation<Offset> _jouerSlide;
  late Animation<double> _accueilFade;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _accueilSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(parent: _transitionController, curve: Curves.easeInOutCubic));
    _jouerSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _transitionController, curve: Curves.easeInOutCubic));
    _accueilFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _transitionController, curve: const Interval(0.0, 0.6)),
    );
    _verifierNotifAmis();
  }

  Future<void> _verifierNotifAmis() async {
    try {
      final demandes = await FriendsService().demandesRecues();
      if (mounted && demandes.isNotEmpty && _indexActif != 4) {
        setState(() => _notifAmis = true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: Stack(
        children: [
          _buildPage(),
          // Tab bar flottante en bas
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OtakuTabBar(
              indexActif: _indexActif,
              onTap: _onTabTap,
              notifAmis: _notifAmis,
            ),
          ),
        ],
      ),
    );
  }

  void _onTabTap(int index) {
    final ancienIndex = _indexActif;
    setState(() {
      _indexActif = index;
      // Quand on va sur Amis (index 4), le point rouge disparait
      if (index == 4) _notifAmis = false;
    });

    // Transition animee entre Accueil (0) et Jouer (2)
    if (ancienIndex == 0 && index == 2) {
      _transitionController.forward(from: 0);
    } else if (ancienIndex == 2 && index == 0) {
      _transitionController.reverse(from: 1);
    } else {
      if (index == 0) {
        _transitionController.value = 0;
      } else if (index == 2) {
        _transitionController.value = 1;
      }
    }
  }

  Widget _buildPage() {
    switch (_indexActif) {
      case 0:
      case 2:
        // Accueil et Jouer partagent la meme stack avec transition
        return Stack(
          children: [
            SlideTransition(
              position: _accueilSlide,
              child: FadeTransition(
                opacity: _accueilFade,
                child: const _AccueilPage(),
              ),
            ),
            SlideTransition(
              position: _jouerSlide,
              child: const _JouerHub(),
            ),
          ],
        );
      case 1:
        return const BoutiqueScreen();
      case 3:
        return const _QuetePage();
      case 4:
        return const AmisScreen();
      default:
        return const _AccueilPage();
    }
  }
}

/// === ECRAN ACCUEIL — Style Free Fire ===
/// Plein ecran immersif : skin 3D en arriere-plan (rotatif au drag),
/// overlays Liquid Glass : top bar, evenement flottant, barre d'action en bas.
class _AccueilPage extends StatefulWidget {
  const _AccueilPage();

  @override
  State<_AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<_AccueilPage>
    with SingleTickerProviderStateMixin {
  final _progressionService = ProgressionService();
  Map<String, dynamic>? _profil;
  double _skinRotation = 0;
  late AnimationController _idleRotation;

  @override
  void initState() {
    super.initState();
    _chargerProfil();
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

  Future<void> _chargerProfil() async {
    try {
      await _progressionService.creerProfilSiAbsent();
      final profil = await _progressionService.recupererProfil();
      if (mounted) setState(() => _profil = profil);
      FriendsService().mettreAJourPresence();
    } catch (_) {}
  }

  void _showModeDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
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
            // Poignee
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: OtakuColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 10),
            Text('SELECTIONNER LE MODE', style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
            const SizedBox(height: 10),
            // Modes dans un scroll
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeOption('SOLO — Affronte l\'IA', Icons.bolt_rounded, OtakuColors.modeSolo, true),
                    const SizedBox(height: 8),
                    _buildModeOption('DIVISION — Monte en rang', Icons.military_tech_rounded, OtakuColors.modeDivision, false),
                    const SizedBox(height: 8),
                    _buildModeOption('DUEL — Defi un ami', Icons.people_alt_rounded, OtakuColors.modeDuel, false),
                    const SizedBox(height: 8),
                    _buildModeOption('COOP — Faites equipe', Icons.group_work_rounded, OtakuColors.modeCoop, false),
                    const SizedBox(height: 8),
                    _buildModeOption('EVENEMENT — Defis limites', Icons.local_fire_department_rounded, OtakuColors.modeEvent, false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(String label, IconData icon, Color couleur, bool actif) {
    return GestureDetector(
      onTap: actif ? () => Navigator.pop(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: actif ? couleur.withValues(alpha: 0.12) : OtakuColors.glassBackground,
          border: Border.all(
            color: actif ? couleur.withValues(alpha: 0.6) : OtakuColors.glassBorder,
            width: actif ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: couleur.withValues(alpha: 0.15),
                border: Border.all(color: couleur.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, size: 18, color: couleur),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: OtakuTypo.headlineSmall.copyWith(fontSize: 12, color: actif ? OtakuColors.textPrimary : OtakuColors.textMuted)),
            ),
            if (actif)
              Icon(Icons.check_circle_rounded, size: 18, color: couleur)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: OtakuColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('BIENTOT', style: OtakuTypo.label.copyWith(fontSize: 7, color: OtakuColors.textMuted)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pseudo = _profil?['pseudo'] ?? 'Joueur';
    final niveau = _profil?['niveau'] ?? 1;
    final rang = _profil?['rang'] ?? 'Debutant';

    return Stack(
      children: [
        // === ARRIERE-PLAN : Skin rotatif plein ecran (drag pour tourner) ===
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (d) => setState(() => _skinRotation += d.delta.dx * 0.01),
            child: AnimatedBuilder(
              animation: _idleRotation,
              builder: (context, _) {
                final angle = _skinRotation + (_idleRotation.value * 2 * pi);
                return _SkinDisplay(rotation: angle);
              },
            ),
          ),
        ),
        // Vignette sombre pour lisibilite des overlays
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    Colors.transparent,
                    OtakuColors.background.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
        ),

        // === OVERLAY : Top bar ===
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: LiquidGlass(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                borderRadius: 20,
                child: Row(
                  children: [
                    // Avatar → ouvre le Profil
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      ),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: OtakuColors.accent, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: OtakuColors.accent.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person, color: OtakuColors.accent, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(pseudo, style: OtakuTypo.headlineSmall.copyWith(fontSize: 13)),
                        Text('Nv. $niveau — $rang', style: OtakuTypo.bodySmall.copyWith(fontSize: 10)),
                      ],
                    ),
                    const Spacer(),
                    // Boite a lettres
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BoiteLettresPage()),
                      ),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: OtakuColors.glassBackground,
                          border: Border.all(color: OtakuColors.glassBorder),
                        ),
                        child: const Icon(Icons.mail_rounded, color: OtakuColors.textSecondary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('OTAKU VERSE', style: OtakuTypo.displayLarge.copyWith(fontSize: 18)),
                  ],
                ),
              ),
            ),
          ),
        ),

        // === OVERLAY : Evenement flottant (haut gauche, sous la top bar) ===
        Positioned(
          top: 60,
          left: 12,
          child: SafeArea(
            child: LiquidGlass(
              tintColor: OtakuColors.modeEvent,
              borderRadius: 16,
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: OtakuColors.modeEvent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: OtakuColors.modeEvent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'EVENEMENT ACTIF',
                        style: OtakuTypo.label.copyWith(fontSize: 8, color: OtakuColors.modeEvent),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'GUERRE DES\nCLANS',
                      style: OtakuTypo.headlineLarge.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gagne des XP exclusives',
                      style: OtakuTypo.bodySmall.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // === OVERLAY : Barre d'action en bas (selecteur mode + bouton JOUER) ===
        Positioned(
          bottom: 72,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  OtakuColors.background,
                  OtakuColors.background.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 8),
                child: Row(
                  children: [
                    // Selecteur de mode (pill) — tap pour ouvrir le choix
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showModeDrawer(context),
                        child: LiquidGlass(
                          tintColor: OtakuColors.accent,
                          borderRadius: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: OtakuColors.accent.withValues(alpha: 0.2),
                                  border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.4)),
                                ),
                                child: const Icon(Icons.bolt_rounded, color: OtakuColors.accent, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('MODE ACTIF', style: OtakuTypo.label.copyWith(fontSize: 8, color: OtakuColors.textMuted)),
                                  Text('SOLO — Affronte l\'IA', style: OtakuTypo.headlineSmall.copyWith(fontSize: 12)),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.expand_less_rounded, color: OtakuColors.textMuted, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bouton JOUER (gros, accent, comme Free Fire)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CombatSetupPage()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [OtakuColors.accent, OtakuColors.accentDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: OtakuColors.accent.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                            const SizedBox(width: 6),
                            Text(
                              'JOUER',
                              style: OtakuTypo.headlineLarge.copyWith(fontSize: 18, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
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
}


/// Skin 3D style Free Fire — personnage sur piedestal lumineux, rotation au drag
class _SkinDisplay extends StatelessWidget {
  final double rotation;
  const _SkinDisplay({required this.rotation});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(rotation),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Personnage (placeholder stylise)
            Container(
              width: 140,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    OtakuColors.accent.withValues(alpha: 0.2),
                    OtakuColors.accentDark.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: OtakuColors.accent.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 80, color: OtakuColors.accent.withValues(alpha: 0.7)),
                  const SizedBox(height: 8),
                  Text('GUERRIER', style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.textMuted)),
                  Text('BASIQUE', style: OtakuTypo.label.copyWith(fontSize: 8, color: OtakuColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Piedestal lumineux
            Container(
              width: 160,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: RadialGradient(
                  colors: [
                    OtakuColors.accent.withValues(alpha: 0.4),
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

/// Hub Jouer — grille de cartes de modes avec animation d'entree stagger
class _JouerHub extends StatefulWidget {
  const _JouerHub();

  @override
  State<_JouerHub> createState() => _JouerHubState();
}

class _JouerHubState extends State<_JouerHub> with TickerProviderStateMixin {
  late AnimationController _staggerController;

  static const List<_ModeData> _modes = [
    _ModeData(nom: 'SOLO', sousTitre: 'Affronte l\'IA', couleur: OtakuColors.modeSolo, icon: Icons.bolt_rounded, actif: true),
    _ModeData(nom: 'DIVISION', sousTitre: 'Monte en rang', couleur: OtakuColors.modeDivision, icon: Icons.military_tech_rounded, actif: false),
    _ModeData(nom: 'EVENTS', sousTitre: 'Defis limites', couleur: OtakuColors.modeEvent, icon: Icons.local_fire_department_rounded, actif: false),
    _ModeData(nom: 'DUEL', sousTitre: 'Joue avec un ami', couleur: OtakuColors.modeDuel, icon: Icons.people_alt_rounded, actif: false),
    _ModeData(nom: 'COOP', sousTitre: 'Faites equipe', couleur: OtakuColors.modeCoop, icon: Icons.group_work_rounded, actif: false),
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CHOISIS TON MODE', style: OtakuTypo.headlineLarge.copyWith(fontSize: 22)),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: List.generate(_modes.length, (i) {
                  final debut = (i * 0.08).clamp(0.0, 0.6);
                  final fin = (debut + 0.5).clamp(0.0, 1.0);
                  final animation = CurvedAnimation(
                    parent: _staggerController,
                    curve: Interval(debut, fin, curve: Curves.easeOutCubic),
                  );

                  return Expanded(
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 40 * (1 - animation.value)),
                          child: Opacity(
                            opacity: animation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 6, right: i == _modes.length - 1 ? 0 : 6),
                        child: _buildModeCard(_modes[i]),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(_ModeData mode) {
    return GestureDetector(
      onTap: mode.actif
          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CombatSetupPage()))
          : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              mode.couleur.withValues(alpha: 0.25),
              mode.couleur.withValues(alpha: 0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: mode.actif ? mode.couleur.withValues(alpha: 0.6) : OtakuColors.border,
            width: 1.5,
          ),
          boxShadow: mode.actif
              ? [BoxShadow(color: mode.couleur.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))]
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: -10,
              right: -10,
              child: Icon(
                mode.icon,
                size: 80,
                color: mode.couleur.withValues(alpha: mode.actif ? 0.15 : 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(mode.icon, color: mode.actif ? mode.couleur : OtakuColors.textMuted, size: 28),
                  const Spacer(),
                  Text(
                    mode.nom,
                    style: OtakuTypo.headlineLarge.copyWith(
                      fontSize: 16,
                      color: mode.actif ? OtakuColors.textPrimary : OtakuColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mode.sousTitre,
                    style: OtakuTypo.bodySmall.copyWith(
                      fontSize: 9,
                      color: mode.actif ? OtakuColors.textSecondary : OtakuColors.textMuted,
                    ),
                  ),
                  if (!mode.actif)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: OtakuColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('BIENTOT', style: OtakuTypo.label.copyWith(fontSize: 8, color: OtakuColors.textMuted)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ecran Quetes — missions quotidiennes + pass de combat.
/// Chaque quete a une progression et une recompense a recuperer.
class _QuetePage extends StatefulWidget {
  const _QuetePage();

  @override
  State<_QuetePage> createState() => _QuetePageState();
}

class _QuetePageState extends State<_QuetePage> {
  // Placeholder statique — a brancher sur Supabase plus tard
  final List<_Quete> _quetes = [
    _Quete(titre: 'Joue 3 combats', recompense: '+30 XP', progression: 2, objectif: 3, icon: Icons.bolt_rounded, couleur: OtakuColors.modeSolo),
    _Quete(titre: 'Gagne 1 combat', recompense: '+50 XP', progression: 0, objectif: 1, icon: Icons.emoji_events_rounded, couleur: OtakuColors.modeEvent),
    _Quete(titre: 'Connecte-toi 3 jours', recompense: '+20 XP', progression: 3, objectif: 3, icon: Icons.calendar_today_rounded, couleur: OtakuColors.pvHaut),
    _Quete(titre: 'Fais un combo x3', recompense: 'Skin Rare', progression: 0, objectif: 1, icon: Icons.local_fire_department_rounded, couleur: OtakuColors.modeDuel),
    _Quete(titre: 'Ajoute 2 amis', recompense: '+25 XP', progression: 1, objectif: 2, icon: Icons.people_rounded, couleur: OtakuColors.modeCoop),
  ];

  void _recuperer(int index) {
    setState(() => _quetes[index] = _quetes[index].copyRecupere());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text('QUETES', style: OtakuTypo.headlineLarge.copyWith(fontSize: 22)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: OtakuColors.modeEvent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: OtakuColors.modeEvent.withValues(alpha: 0.3)),
                  ),
                  child: Text('Saison 1', style: OtakuTypo.hud.copyWith(fontSize: 10, color: OtakuColors.modeEvent)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Liste des quetes
            Expanded(
              child: ListView.separated(
                itemCount: _quetes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _buildQueteCard(_quetes[i], i),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueteCard(_Quete quete, int index) {
    final complete = quete.progression >= quete.objectif;
    final progress = quete.objectif > 0 ? quete.progression / quete.objectif : 0.0;

    return LiquidGlass(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      tintColor: complete ? quete.couleur : null,
      child: Row(
        children: [
          // Icone de quete
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: quete.couleur.withValues(alpha: complete ? 0.2 : 0.1),
              border: Border.all(color: quete.couleur.withValues(alpha: complete ? 0.5 : 0.3)),
            ),
            child: Icon(quete.icon, size: 18, color: quete.couleur),
          ),
          const SizedBox(width: 12),
          // Titre + barre de progression
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(quete.titre, style: OtakuTypo.headlineSmall.copyWith(fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: OtakuColors.border,
                          valueColor: AlwaysStoppedAnimation(quete.couleur),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${quete.progression}/${quete.objectif}',
                      style: OtakuTypo.hud.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Recompense / Bouton
          if (complete && !quete.recupere)
            GestureDetector(
              onTap: () => _recuperer(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: quete.couleur.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: quete.couleur.withValues(alpha: 0.6)),
                ),
                child: Text(quete.recompense, style: OtakuTypo.label.copyWith(fontSize: 9, color: quete.couleur)),
              ),
            )
          else if (quete.recupere)
            Icon(Icons.check_circle_rounded, size: 20, color: OtakuColors.pvHaut.withValues(alpha: 0.6))
          else
            Text(quete.recompense, style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.textMuted)),
        ],
      ),
    );
  }
}

class _Quete {
  final String titre;
  final String recompense;
  final int progression;
  final int objectif;
  final IconData icon;
  final Color couleur;
  final bool recupere;

  const _Quete({
    required this.titre,
    required this.recompense,
    required this.progression,
    required this.objectif,
    required this.icon,
    required this.couleur,
    this.recupere = false,
  });

  _Quete copyRecupere() => _Quete(
    titre: titre,
    recompense: recompense,
    progression: progression,
    objectif: objectif,
    icon: icon,
    couleur: couleur,
    recupere: true,
  );
}

class _ModeData {
  final String nom;
  final String sousTitre;
  final Color couleur;
  final IconData icon;
  final bool actif;

  const _ModeData({
    required this.nom,
    required this.sousTitre,
    required this.couleur,
    required this.icon,
    required this.actif,
  });
}
