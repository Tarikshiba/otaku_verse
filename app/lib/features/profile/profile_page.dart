import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/theme.dart';
import '../progression/progression_service.dart';
import '../skins/boutique_screen.dart';
import 'parametres_page.dart';

/// === ECRAN PROFIL — DA V2.1 ===
/// Capsule verre pour le skin, stats en cartes Liquid Glass,
/// typo HUD, texture seigaiha en fond (gere par AppShell).

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProgressionService _progressionService = ProgressionService();

  Map<String, dynamic>? _profil;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  Future<void> _chargerProfil() async {
    try {
      await _progressionService.creerProfilSiAbsent();
      final profil = await _progressionService.recupererProfil();
      if (!mounted) return;
      setState(() {
        _profil = profil;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: _chargement
            ? const Center(child: CircularProgressIndicator())
            : _buildContenu(),
      ),
    );
  }

  Widget _buildContenu() {
    final xpTotale = _profil?['xp_totale'] ?? 0;
    final niveau = _profil?['niveau'] ?? 1;
    final rangActuel = _profil?['rang'] ?? 'Debutant';
    final combatsJoues = _profil?['combats_joues'] ?? 0;
    final combatsGagnes = _profil?['combats_gagnes'] ?? 0;

    final xpDansNiveau = ProgressionService.xpDansNiveauActuel(xpTotale as int);
    final xpPourProchain = ProgressionService.xpRequise(niveau as int);
    final progressionXp = xpPourProchain > 0 ? xpDansNiveau / xpPourProchain : 0.0;

    final tauxVictoire = combatsJoues > 0
        ? ((combatsGagnes / combatsJoues) * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 72),
      child: Row(
        children: [
          // === COLONNE GAUCHE : Capsule verre + skin ===
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: LiquidGlass(
                    tintColor: OtakuColors.accent,
                    borderRadius: 20,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Skin rotatif dans la capsule
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BoutiqueScreen()),
                            ),
                            child: const _SkinRotatif(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Bouton collection
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BoutiqueScreen()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: OtakuColors.modeDuel.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: OtakuColors.modeDuel.withValues(alpha: 0.4)),
                            ),
                            child: Text('COLLECTION', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.modeDuel)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Rang
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: OtakuColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            rangActuel.toString().toUpperCase(),
                            style: OtakuTypo.label.copyWith(color: OtakuColors.accent, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // === COLONNE DROITE : Stats ===
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text('PROFIL', style: OtakuTypo.headlineLarge.copyWith(fontSize: 22)),
                    const Spacer(),
                    // Bouton parametres
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ParametresPage(
                          profil: _profil,
                          onProfilChange: _chargerProfil,
                        )),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: OtakuColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: OtakuColors.border),
                        ),
                        child: const Icon(Icons.settings_rounded, size: 18, color: OtakuColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Pseudo + pays (affichage simple)
                Row(
                  children: [
                    if (_profil?['pseudo'] != null)
                      Text('@${_profil!['pseudo']}', style: OtakuTypo.hud.copyWith(fontSize: 12, color: OtakuColors.textPrimary))
                    else
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ParametresPage(
                            profil: _profil,
                            onProfilChange: _chargerProfil,
                          )),
                        ),
                        child: Text('Definis ton pseudo >', style: OtakuTypo.hud.copyWith(fontSize: 12, color: OtakuColors.accent)),
                      ),
                    if (_profil?['country'] != null) ...[
                      const SizedBox(width: 10),
                      Text(_profil!['country'], style: OtakuTypo.label.copyWith(fontSize: 10, color: OtakuColors.textMuted)),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Niveau + barre XP
                LiquidGlass(
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Text('Nv.$niveau', style: OtakuTypo.hud.copyWith(fontSize: 18, color: OtakuColors.accent)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$xpDansNiveau / $xpPourProchain XP',
                              style: OtakuTypo.hud.copyWith(fontSize: 10, color: OtakuColors.textMuted),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressionXp,
                                minHeight: 6,
                                backgroundColor: OtakuColors.border,
                                valueColor: const AlwaysStoppedAnimation(OtakuColors.accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Stats en grille 2x2
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: _buildStatCard('XP TOTALE', '$xpTotale', OtakuColors.accent)),
                            const SizedBox(height: 8),
                            Expanded(child: _buildStatCard('VICTOIRES', '$combatsGagnes', OtakuColors.victoire)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: _buildStatCard('COMBATS', '$combatsJoues', OtakuColors.modeDuel)),
                            const SizedBox(height: 8),
                            Expanded(child: _buildStatCard('TAUX', '$tauxVictoire%', OtakuColors.pvMoyen)),
                          ],
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
    );
  }

  Widget _buildStatCard(String label, String valeur, Color couleur) {
    return LiquidGlass(
      borderRadius: 12,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.textMuted)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(valeur, style: OtakuTypo.hud.copyWith(fontSize: 18, color: couleur)),
          ),
        ],
      ),
    );
  }
}

/// Skin rotatif — capsule verre, rotation douce + drag
class _SkinRotatif extends StatefulWidget {
  const _SkinRotatif();

  @override
  State<_SkinRotatif> createState() => _SkinRotatifState();
}

class _SkinRotatifState extends State<_SkinRotatif> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotation = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _rotation += details.delta.dx * 0.01;
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _rotation + (_controller.value * 2 * pi);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: child,
          );
        },
        child: Container(
          width: 100,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                OtakuColors.accent.withValues(alpha: 0.15),
                OtakuColors.accentDark.withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: OtakuColors.accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 50, color: OtakuColors.accent.withValues(alpha: 0.7)),
              const SizedBox(height: 6),
              Text('SKIN V1', style: OtakuTypo.label.copyWith(fontSize: 9, color: OtakuColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
