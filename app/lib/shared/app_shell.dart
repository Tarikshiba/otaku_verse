import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../features/combat/combat_setup_page.dart';
import '../features/profile/profile_page.dart';
import 'otaku_tab_bar.dart';

/// === SHELL PRINCIPAL DE L'APP ===
/// Contient la tab bar Liquid Glass et gere la navigation entre les sections.
/// L'ecran de combat reste en dehors de ce shell (mode paysage separe).

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  int _indexActif = 0;

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
          // Contenu de la page active
          _buildPage(),

          // Tab bar flottante en bas
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OtakuTabBar(
              indexActif: _indexActif,
              onTap: _onTabTap,
            ),
          ),
        ],
      ),
    );
  }

  void _onTabTap(int index) {
    final ancienIndex = _indexActif;
    setState(() => _indexActif = index);

    // Transition animee entre Accueil (0) et Jouer (1)
    if (ancienIndex == 0 && index == 1) {
      _transitionController.forward(from: 0);
    } else if (ancienIndex == 1 && index == 0) {
      _transitionController.reverse(from: 1);
    } else {
      // Pour les autres tabs, reset la transition
      if (index == 0) {
        _transitionController.value = 0;
      } else if (index == 1) {
        _transitionController.value = 1;
      }
    }
  }

  Widget _buildPage() {
    switch (_indexActif) {
      case 0:
      case 1:
        // Accueil et Jouer sont superposes avec transition animee
        return Stack(
          children: [
            SlideTransition(
              position: _accueilSlide,
              child: FadeTransition(
                opacity: _accueilFade,
                child: const _AccueilPlaceholder(),
              ),
            ),
            SlideTransition(
              position: _jouerSlide,
              child: const _JouerHub(),
            ),
          ],
        );
      case 2:
        return const _AmisPlaceholder();
      case 3:
        return const ProfilePage();
      default:
        return const _AccueilPlaceholder();
    }
  }
}

/// Placeholder Accueil en PAYSAGE (sera remplace par le vrai hub dans l'etape 2)
class _AccueilPlaceholder extends StatelessWidget {
  const _AccueilPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 72),
        child: Column(
          children: [
            // Top bar en verre
            LiquidGlass(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: 20,
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: OtakuColors.accent, width: 2),
                    ),
                    child: const Icon(Icons.person, color: OtakuColors.accent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Joueur', style: OtakuTypo.headlineSmall.copyWith(fontSize: 13)),
                      Text('Nv. 1 — Debutant', style: OtakuTypo.bodySmall.copyWith(fontSize: 10)),
                    ],
                  ),
                  const Spacer(),
                  Text('OTAKU VERSE', style: OtakuTypo.displayLarge.copyWith(fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Zone principale : banniere + raccourcis cote a cote (paysage)
            Expanded(
              child: Row(
                children: [
                  // Banniere evenement (grande, a gauche)
                  Expanded(
                    flex: 3,
                    child: LiquidGlass(
                      tintColor: OtakuColors.accent,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('EVENEMENT', style: OtakuTypo.label.copyWith(color: OtakuColors.modeEvent)),
                          const SizedBox(height: 8),
                          Text('GUERRE DES CLANS', style: OtakuTypo.headlineLarge.copyWith(fontSize: 26)),
                          const SizedBox(height: 6),
                          Text(
                            'Participe et gagne des recompenses exclusives.',
                            style: OtakuTypo.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Raccourcis (a droite, en colonne)
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: LiquidGlass(
                            tintColor: OtakuColors.modeSolo,
                            borderRadius: 14,
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bolt_rounded, color: OtakuColors.modeSolo, size: 22),
                                const SizedBox(width: 8),
                                Text('Combat', style: OtakuTypo.label),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LiquidGlass(
                            tintColor: OtakuColors.modeEvent,
                            borderRadius: 14,
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.emoji_events_rounded, color: OtakuColors.modeEvent, size: 22),
                                const SizedBox(width: 8),
                                Text('Defis', style: OtakuTypo.label),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LiquidGlass(
                            tintColor: OtakuColors.victoire,
                            borderRadius: 14,
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.card_giftcard_rounded, color: OtakuColors.victoire, size: 22),
                                const SizedBox(width: 8),
                                Text('Rewards', style: OtakuTypo.label),
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

  // Definition des modes de jeu
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
                  // Stagger : chaque carte demarre 40ms apres la precedente
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
            // Icone en fond (grande, subtile)
            Positioned(
              bottom: -10,
              right: -10,
              child: Icon(
                mode.icon,
                size: 80,
                color: mode.couleur.withValues(alpha: mode.actif ? 0.15 : 0.06),
              ),
            ),
            // Contenu
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

/// Placeholder Amis (sera fait a l'etape 5)
class _AmisPlaceholder extends StatelessWidget {
  const _AmisPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 72),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_rounded, size: 48, color: OtakuColors.textMuted),
              const SizedBox(height: 12),
              Text('AMIS', style: OtakuTypo.headlineLarge),
              const SizedBox(height: 6),
              Text('Bientot disponible...', style: OtakuTypo.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
