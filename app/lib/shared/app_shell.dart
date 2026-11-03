import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../features/combat/combat_setup_page.dart';
import '../features/verse/verse_division_page.dart';
import '../features/verse/verse_duel_setup_page.dart';
import '../features/verse/verse_coop_page.dart';
import '../features/verse/verse_v3_hub_page.dart';
import '../features/profile/profile_page.dart';
import '../features/progression/progression_service.dart';
import '../features/rewards/boite_lettres_page.dart';
import '../features/skins/boutique_screen.dart';
import '../features/social/amis_screen.dart';
import '../features/social/friends_service.dart';
import 'textures.dart';
import '../features/progression/quete_service.dart';

/// === SHELL PRINCIPAL DE L'APP ===
/// Hub central (Accueil) facon Free Fire
/// Pas de bottom nav bar. Navigation par boutons superposes.

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
  Map<String, dynamic>? _profil;
  double _skinRotation = 0;
  late AnimationController _idleRotation;
  bool _notifAmis = false;
  int _unreadMails = 0; // Pastille boite de reception
  String _modeActif = 'SOLO';

  @override
  void initState() {
    super.initState();
    _chargerProfil();
    _verifierNotifAmis();
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

  Future<void> _verifierNotifAmis() async {
    try {
      final demandes = await FriendsService().demandesRecues();
      if (mounted) {
        setState(() => _notifAmis = demandes.isNotEmpty);
      }
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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: OtakuColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 10),
            Text('SELECTIONNER LE MODE', style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeOption('SOLO — Affronte l\'IA', Icons.bolt_rounded, OtakuColors.modeSolo, true, 'SOLO'),
                    const SizedBox(height: 8),
                    _buildModeOption('DIVISION — Monte en rang', Icons.military_tech_rounded, OtakuColors.modeDivision, true, 'DIVISION'),
                    const SizedBox(height: 8),
                    _buildModeOption('DUEL — Defi un ami', Icons.people_alt_rounded, OtakuColors.modeDuel, true, 'DUEL'),
                    const SizedBox(height: 8),
                    _buildModeOption('COOP — Faites equipe', Icons.group_work_rounded, OtakuColors.modeCoop, true, 'COOP'),
                    const SizedBox(height: 8),
                    _buildModeOption('EVENEMENT — Defis limites', Icons.local_fire_department_rounded, OtakuColors.modeEvent, true, 'EVENTS'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(String label, IconData icon, Color couleur, bool actif, String mode) {
    return GestureDetector(
      onTap: actif ? () {
        setState(() => _modeActif = mode);
        Navigator.pop(context);
      } : null,
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
                decoration: BoxDecoration(color: OtakuColors.border, borderRadius: BorderRadius.circular(4)),
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

    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: OtakuColors.background),
        ),
        Positioned.fill(
          child: SectionTexture(
            type: TextureType.speedlines,
            opacity: 0.1,
            child: const SizedBox.expand(),
          ),
        ),
        
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
                    OtakuColors.background.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
        ),

        // === TOP BAR (Reduite, sans texte superflu) ===
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  // Profil (reduit)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    ),
                    child: LiquidGlass(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      borderRadius: 20,
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: OtakuColors.accent, width: 2),
                            ),
                            child: const Icon(Icons.person, color: OtakuColors.accent, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(pseudo, style: OtakuTypo.headlineSmall.copyWith(fontSize: 13)),
                              Text('Nv. $niveau', style: OtakuTypo.bodySmall.copyWith(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  
                  // Boite a lettres avec pastille rouge dynamique
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BoiteLettresPage()),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        LiquidGlass(
                          padding: const EdgeInsets.all(10),
                          borderRadius: 20,
                          child: const Icon(Icons.mail_rounded, color: OtakuColors.textSecondary, size: 22),
                        ),
                        if (_unreadMails > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$_unreadMails',
                                style: OtakuTypo.label.copyWith(fontSize: 10, color: Colors.white),
                              ),
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

        // === COLONNE GAUCHE (Menus facon Free Fire) ===
        Positioned(
          left: 16,
          top: 100,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSideNavButton('Boutique', Icons.store_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BoutiqueScreen(showBack: true)))),
                const SizedBox(height: 12),
                _buildSideNavButton('Quetes', Icons.assignment_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _QuetePage()))),
                const SizedBox(height: 12),
                _buildSideNavButton('Saison V3', Icons.emoji_events_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseV3HubPage()))),
              ],
            ),
          ),
        ),

        // === COLONNE DROITE (Amis) ===
        Positioned(
          right: 16,
          top: 100,
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
                          width: 12, height: 12,
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // === BOUTON JOUER ===
        Positioned(
          bottom: 24,
          right: 24,
          child: SafeArea(
            child: GestureDetector(
              onTap: () {
                if (_modeActif == 'SOLO') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CombatSetupPage()));
                } else if (_modeActif == 'DIVISION') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseDivisionPage()));
                } else if (_modeActif == 'DUEL') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseDuelSetupPage()));
                } else if (_modeActif == 'COOP') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseCoopPage()));
                } else if (_modeActif == 'EVENTS') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VerseV3HubPage(initialTab: 1)));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [OtakuColors.accent, OtakuColors.accentDark],
                  ),
                  boxShadow: [
                    BoxShadow(color: OtakuColors.accent.withValues(alpha: 0.6), blurRadius: 24, spreadRadius: 4),
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 12),
                    Text(
                      'JOUER',
                      style: OtakuTypo.headlineLarge.copyWith(fontSize: 26, color: Colors.white, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // === MODE DE JEU ===
        Positioned(
          bottom: 24,
          left: 24,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => _showModeDrawer(context),
              child: LiquidGlass(
                tintColor: OtakuColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('MODE SELECTIONNE', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.textMuted)),
                        const SizedBox(width: 8),
                        const Icon(Icons.expand_less_rounded, color: OtakuColors.textMuted, size: 14),
                      ]
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _modeActif == 'SOLO'
                              ? Icons.bolt_rounded
                              : _modeActif == 'DIVISION'
                                  ? Icons.military_tech_rounded
                                  : _modeActif == 'DUEL'
                                      ? Icons.people_alt_rounded
                                      : _modeActif == 'COOP'
                                          ? Icons.group_work_rounded
                                          : Icons.local_fire_department_rounded,
                          color: _modeActif == 'SOLO'
                              ? OtakuColors.modeSolo
                              : _modeActif == 'DIVISION'
                                  ? OtakuColors.modeDivision
                                  : _modeActif == 'DUEL'
                                      ? OtakuColors.modeDuel
                                      : _modeActif == 'COOP'
                                          ? OtakuColors.modeCoop
                                          : OtakuColors.modeEvent,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(_modeActif, style: OtakuTypo.headlineLarge.copyWith(fontSize: 16)),
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

  Widget _buildSideNavButton(String label, IconData icon, VoidCallback onTap, {bool isRight = false}) {
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        borderRadius: 16,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: isRight ? [
            Text(label, style: OtakuTypo.headlineSmall.copyWith(fontSize: 14)),
            const SizedBox(width: 12),
            Icon(icon, color: OtakuColors.textSecondary, size: 22),
          ] : [
            Icon(icon, color: OtakuColors.textSecondary, size: 22),
            const SizedBox(width: 12),
            Text(label, style: OtakuTypo.headlineSmall.copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

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
            Container(
              width: 180,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    OtakuColors.accent.withValues(alpha: 0.1),
                    OtakuColors.accentDark.withValues(alpha: 0.3),
                  ],
                ),
                border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.4), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: OtakuColors.accent.withValues(alpha: 0.15),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 120, color: OtakuColors.accent.withValues(alpha: 0.8)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 240,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: RadialGradient(
                  colors: [
                    OtakuColors.accent.withValues(alpha: 0.6),
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

class _QuetePage extends StatefulWidget {
  const _QuetePage();

  @override
  State<_QuetePage> createState() => _QuetePageState();
}

class _QuetePageState extends State<_QuetePage> {
  final QueteService _queteService = QueteService();
  bool _chargement = true;

  List<_Quete> _quetes = [
    _Quete(titre: 'Joue 3 combats', recompense: '+30 XP', progression: 2, objectif: 3, icon: Icons.bolt_rounded, couleur: OtakuColors.modeSolo),
    _Quete(titre: 'Gagne 1 combat', recompense: '+50 XP', progression: 0, objectif: 1, icon: Icons.emoji_events_rounded, couleur: OtakuColors.modeEvent),
    _Quete(titre: 'Connecte-toi 3 jours', recompense: '+20 XP', progression: 3, objectif: 3, icon: Icons.calendar_today_rounded, couleur: OtakuColors.pvHaut),
    _Quete(titre: 'Fais un combo x3', recompense: 'Skin Rare', progression: 0, objectif: 1, icon: Icons.local_fire_department_rounded, couleur: OtakuColors.modeDuel),
    _Quete(titre: 'Ajoute 2 amis', recompense: '+25 XP', progression: 1, objectif: 2, icon: Icons.people_rounded, couleur: OtakuColors.modeCoop),
  ];

  @override
  void initState() {
    super.initState();
    _chargerQuetes();
  }

  Future<void> _chargerQuetes() async {
    final state = await _queteService.getQuetesState();
    if (!mounted) return;
    
    setState(() {
      for (int i = 0; i < _quetes.length; i++) {
        final q = _quetes[i];
        if (state.containsKey(q.titre)) {
          _quetes[i] = _Quete(
            titre: q.titre,
            recompense: q.recompense,
            progression: state[q.titre]!['progression'] ?? q.progression,
            objectif: q.objectif,
            icon: q.icon,
            couleur: q.couleur,
            recupere: state[q.titre]!['recupere'] ?? false,
          );
        }
      }
      _chargement = false;
    });
  }

  void _recuperer(int index) {
    final q = _quetes[index];
    setState(() => _quetes[index] = q.copyRecupere());
    
    // Sync with Supabase in background
    _queteService.syncQuete(q.titre, q.progression, true);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _chargement ? const Center(child: CircularProgressIndicator()) : Expanded(
                child: ListView.separated(
                  itemCount: _quetes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildQueteCard(_quetes[i], i),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(quete.titre, style: OtakuTypo.headlineSmall.copyWith(fontSize: 14)),
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
          const SizedBox(width: 16),
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
            Icon(Icons.check_circle_rounded, size: 28, color: OtakuColors.pvHaut.withValues(alpha: 0.6))
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
