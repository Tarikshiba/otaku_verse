import 'package:flutter/material.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../progression/progression_service.dart';

/// === ECRAN PROFIL ===
/// Affiche les stats du joueur, son rang, son XP,
/// et un skin 3D rotatif (placeholder en V1).

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

    // Calcul de la barre d'XP vers le prochain niveau
    final xpDansNiveau = ProgressionService.xpDansNiveauActuel(xpTotale as int);
    final xpPourProchain = ProgressionService.xpRequise(niveau as int);
    final progressionXp = xpPourProchain > 0 ? xpDansNiveau / xpPourProchain : 0.0;

    // Taux de victoire
    final tauxVictoire = combatsJoues > 0
        ? ((combatsGagnes / combatsJoues) * 100).round()
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- COLONNE GAUCHE : Skin rotatif ---
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Bouton retour
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, color: OtakuColors.textSecondary, size: 20),
                        SizedBox(width: 8),
                        Text('RETOUR', style: OtakuTypo.label),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Skin rotatif (placeholder : silhouette stylisee)
                const _SkinRotatif(),

                const SizedBox(height: 12),

                // Rang sous le skin
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: OtakuColors.accent, width: 2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    rangActuel.toString().toUpperCase(),
                    style: OtakuTypo.label.copyWith(color: OtakuColors.accent),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // --- COLONNE DROITE : Stats ---
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PROFIL', style: OtakuTypo.headlineLarge),
                const SizedBox(height: 16),

                // Niveau + barre d'XP
                Row(
                  children: [
                    Text('NIVEAU $niveau', style: OtakuTypo.headlineSmall),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$xpDansNiveau / $xpPourProchain XP',
                            style: OtakuTypo.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progressionXp,
                              minHeight: 8,
                              backgroundColor: OtakuColors.border,
                              valueColor: const AlwaysStoppedAnimation(OtakuColors.accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stats en grille
                Row(
                  children: [
                    _buildStatCard('XP TOTALE', '$xpTotale'),
                    const SizedBox(width: 12),
                    _buildStatCard('COMBATS', '$combatsJoues'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard('VICTOIRES', '$combatsGagnes'),
                    const SizedBox(width: 12),
                    _buildStatCard('TAUX', '$tauxVictoire%'),
                  ],
                ),
                const SizedBox(height: 20),
                // Bouton deconnexion
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (!mounted) return;
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OtakuColors.error,
                      side: const BorderSide(color: OtakuColors.error),
                    ),
                    child: const Text('SE DECONNECTER'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carte de stat individuelle
  Widget _buildStatCard(String label, String valeur) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OtakuColors.surface,
          border: Border.all(color: OtakuColors.border),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: OtakuTypo.label.copyWith(
              fontSize: 10,
              color: OtakuColors.textMuted,
            )),
            const SizedBox(height: 4),
            Text(valeur, style: OtakuTypo.headlineSmall.copyWith(
              color: OtakuColors.accent,
            )),
          ],
        ),
      ),
    );
  }
}

/// Skin rotatif du joueur (placeholder V1 : silhouette stylisee avec rotation)
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
      duration: const Duration(seconds: 8),
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
      // Le joueur peut faire tourner le skin avec un drag horizontal
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
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(angle),
            child: child,
          );
        },
        child: Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            border: Border.all(color: OtakuColors.accent, width: 2),
            borderRadius: BorderRadius.circular(4),
            color: OtakuColors.surface,
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 60, color: OtakuColors.accent),
              SizedBox(height: 8),
              Text('SKIN V1', style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: OtakuColors.textMuted,
                letterSpacing: 1,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
