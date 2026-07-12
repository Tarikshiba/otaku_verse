import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'rewards_service.dart';

/// === ECRAN DES RECOMPENSES ===
/// Affiche la recompense de connexion, les defis quotidiens et les badges.

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final RewardsService _rewardsService = RewardsService();

  bool _chargement = true;
  bool _connexionReclamee = false;
  bool _connexionDejaPrise = false;
  int _serieJours = 0;
  List<Map<String, dynamic>> _defis = [];
  List<String> _badgesDebloques = [];

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    try {
      final defis = await _rewardsService.recupererDefisQuotidiens();
      final badges = await _rewardsService.recupererBadges();
      final serie = await _rewardsService.serieConnexion();
      final dejaPrise = await _rewardsService.connexionDejaPrise();
      if (!mounted) return;
      setState(() {
        _defis = defis;
        _badgesDebloques = badges;
        _serieJours = serie;
        _connexionDejaPrise = dejaPrise;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _reclamerConnexion() async {
    final reussi = await _rewardsService.reclamerConnexionQuotidienne();
    if (!mounted) return;
    setState(() {
      if (reussi) {
        _connexionReclamee = true;
      } else {
        _connexionDejaPrise = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: _chargement
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bouton retour
                    GestureDetector(
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
                    const SizedBox(height: 20),

                    // --- CONNEXION QUOTIDIENNE ---
                    _buildSectionConnexion(),
                    const SizedBox(height: 24),

                    // --- DEFIS QUOTIDIENS ---
                    _buildSectionDefis(),
                    const SizedBox(height: 24),

                    // --- BADGES ---
                    _buildSectionBadges(),
                  ],
                ),
              ),
      ),
    );
  }

  /// Section connexion quotidienne
  Widget _buildSectionConnexion() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OtakuColors.surface,
        border: Border.all(color: OtakuColors.accent),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          // Icone + serie
          Column(
            children: [
              const Icon(Icons.local_fire_department, color: OtakuColors.warning, size: 28),
              const SizedBox(height: 4),
              Text(
                '$_serieJours j.',
                style: OtakuTypo.label.copyWith(color: OtakuColors.warning),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CONNEXION QUOTIDIENNE', style: OtakuTypo.label),
                const SizedBox(height: 4),
                Text(
                  '+${RewardsService.xpConnexionQuotidienne} XP',
                  style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.accent),
                ),
              ],
            ),
          ),
          // Bouton reclamer
          if (_connexionReclamee || _connexionDejaPrise)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: OtakuColors.success.withValues(alpha: 0.1),
                border: Border.all(color: OtakuColors.success),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                _connexionReclamee ? '+15 XP !' : 'DEJA PRIS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: OtakuColors.success,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _reclamerConnexion,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: OtakuColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'RECLAMER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Section defis quotidiens
  Widget _buildSectionDefis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('DEFIS DU JOUR', style: OtakuTypo.headlineSmall),
            const SizedBox(width: 8),
            Text(
              '+${RewardsService.xpDefiComplete} XP chacun',
              style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.accent),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._defis.map((defi) => _buildDefiCard(defi)),
      ],
    );
  }

  /// Carte d'un defi individuel
  Widget _buildDefiCard(Map<String, dynamic> defi) {
    final complete = defi['complete'] == true;
    final progres = defi['progres'] as int;
    final objectif = defi['objectif'] as int;
    final progression = (progres / objectif).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: complete ? OtakuColors.success.withValues(alpha: 0.05) : OtakuColors.surface,
        border: Border.all(
          color: complete ? OtakuColors.success : OtakuColors.border,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          // Icone complete ou en cours
          Icon(
            complete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: complete ? OtakuColors.success : OtakuColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 12),
          // Description + progression
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  defi['description'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: complete ? OtakuColors.success : OtakuColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progression,
                    minHeight: 4,
                    backgroundColor: OtakuColors.border,
                    valueColor: AlwaysStoppedAnimation(
                      complete ? OtakuColors.success : OtakuColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Compteur
          Text(
            '$progres/$objectif',
            style: OtakuTypo.label.copyWith(
              color: complete ? OtakuColors.success : OtakuColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// Section badges
  Widget _buildSectionBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BADGES', style: OtakuTypo.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RewardsService.badgesDisponibles.map((badge) {
            final debloque = _badgesDebloques.contains(badge['id']);
            return _buildBadge(badge, debloque);
          }).toList(),
        ),
      ],
    );
  }

  /// Un badge individuel
  Widget _buildBadge(Map<String, String> badge, bool debloque) {
    return Tooltip(
      message: badge['description'] ?? '',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: debloque ? OtakuColors.accent.withValues(alpha: 0.1) : OtakuColors.surface,
          border: Border.all(
            color: debloque ? OtakuColors.accent : OtakuColors.border,
            width: debloque ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          badge['nom'] ?? '',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: debloque ? OtakuColors.accent : OtakuColors.textMuted,
          ),
        ),
      ),
    );
  }
}
