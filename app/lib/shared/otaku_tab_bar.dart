import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// === TAB BAR LIQUID GLASS ===
/// Flottante, verre, bouton JOUER central surelevee avec glow violet.
/// 4 onglets : Accueil - JOUER (central) - Amis - Profil

class OtakuTabBar extends StatefulWidget {
  final int indexActif;
  final ValueChanged<int> onTap;
  // Si true, affiche un point rouge anime sur l'icone Amis
  final bool notifAmis;

  const OtakuTabBar({
    super.key,
    required this.indexActif,
    required this.onTap,
    this.notifAmis = false,
  });

  @override
  State<OtakuTabBar> createState() => _OtakuTabBarState();
}

class _OtakuTabBarState extends State<OtakuTabBar>
    with SingleTickerProviderStateMixin {
  // Pulse du bouton JOUER (glow qui respire)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: OtakuColors.glassBackground,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: OtakuColors.glassBorder, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: OtakuColors.glassShadow,
                  blurRadius: 32,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Accueil (index 0)
                _buildTabItem(
                  icon: Icons.home_rounded,
                  label: 'Accueil',
                  index: 0,
                ),
                // JOUER (index 1) — bouton central surelevee
                _buildJouerButton(),
                // Amis (index 2) — avec point rouge si notification
                _buildTabItem(
                  icon: Icons.people_rounded,
                  label: 'Amis',
                  index: 2,
                  showNotif: widget.notifAmis,
                ),
                // Profil (index 3)
                _buildTabItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Onglet classique (pas le bouton central)
  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required int index,
    bool showNotif = false,
  }) {
    final actif = widget.indexActif == index;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: actif ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    color: actif ? OtakuColors.accent : OtakuColors.textMuted,
                    size: 24,
                  ),
                ),
                // Point rouge anime (energie occulte)
                if (showNotif && !actif)
                  Positioned(
                    right: -4,
                    top: -2,
                    child: _NotifDot(),
                  ),
              ],
            ),
            // Le label apparait seulement si actif
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: actif
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        label,
                        style: OtakuTypo.tabLabel.copyWith(
                          color: OtakuColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  /// Bouton central JOUER — surelevee, glow violet
  Widget _buildJouerButton() {
    final actif = widget.indexActif == 1;

    return GestureDetector(
      onTap: () => widget.onTap(1),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 56,
            height: 56,
            transform: Matrix4.translationValues(0, -8, 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [OtakuColors.accent, OtakuColors.accentDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: OtakuColors.accent.withValues(
                    alpha: actif ? 0.7 : _pulseAnimation.value,
                  ),
                  blurRadius: actif ? 20 : 14,
                  spreadRadius: actif ? 2 : 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 28,
            ),
          );
        },
      ),
    );
  }
}

/// Point rouge anime — pulse comme une energie occulte
class _NotifDot extends StatefulWidget {
  @override
  State<_NotifDot> createState() => _NotifDotState();
}

class _NotifDotState extends State<_NotifDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OtakuColors.error,
              boxShadow: [
                BoxShadow(
                  color: OtakuColors.error.withValues(alpha: 0.7),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
