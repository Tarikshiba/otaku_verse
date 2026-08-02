import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'classement_service.dart';
import 'profil_public_page.dart';

/// Ecran classement — 3 onglets : Mondial, National, Amis.
/// Accessible depuis l'accueil (bouton raccourci).
class ClassementScreen extends StatefulWidget {
  const ClassementScreen({super.key});

  @override
  State<ClassementScreen> createState() => _ClassementScreenState();
}

class _ClassementScreenState extends State<ClassementScreen> {
  final _service = ClassementService();

  // 0 = Mondial, 1 = National, 2 = Amis
  int _tabActive = 0;
  List<Map<String, dynamic>> _classement = [];
  bool _chargement = true;
  int _maPosition = 0;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      List<Map<String, dynamic>> data;
      switch (_tabActive) {
        case 0:
          data = await _service.classementMondial();
          _maPosition = await _service.maPositionMondiale();
          break;
        case 1:
          data = await _service.classementNational();
          _maPosition = 0;
          break;
        default:
          data = await _service.classementAmis();
          _maPosition = 0;
      }
      if (mounted) {
        setState(() {
          _classement = data;
          _chargement = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _changerTab(int index) {
    setState(() => _tabActive = index);
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: OtakuColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: OtakuColors.border),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: OtakuColors.textPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('CLASSEMENT', style: OtakuTypo.headlineLarge.copyWith(fontSize: 20)),
                  const Spacer(),
                  if (_maPosition > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: OtakuColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Toi : #$_maPosition',
                        style: OtakuTypo.hud.copyWith(fontSize: 12, color: OtakuColors.accent),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Tabs
              Row(
                children: [
                  _buildTab('Mondial', 0, Icons.public_rounded),
                  const SizedBox(width: 8),
                  _buildTab('National', 1, Icons.flag_rounded),
                  const SizedBox(width: 8),
                  _buildTab('Amis', 2, Icons.people_rounded),
                ],
              ),
              const SizedBox(height: 14),

              // Liste
              Expanded(child: _buildListe()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final actif = _tabActive == index;
    return GestureDetector(
      onTap: () => _changerTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: actif ? OtakuColors.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: actif ? OtakuColors.accent.withValues(alpha: 0.5) : OtakuColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: actif ? OtakuColors.accent : OtakuColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: OtakuTypo.label.copyWith(
                fontSize: 11,
                color: actif ? OtakuColors.accent : OtakuColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calcule les positions avec ex aequo
  /// (meme XP = meme position, le suivant saute)
  List<int> _calculerPositions() {
    final positions = <int>[];
    int posActuelle = 1;
    for (int i = 0; i < _classement.length; i++) {
      if (i == 0) {
        positions.add(1);
      } else {
        final xpActuel = _classement[i]['xp_totale'] ?? 0;
        final xpPrecedent = _classement[i - 1]['xp_totale'] ?? 0;
        if (xpActuel == xpPrecedent) {
          // Ex aequo : meme position
          positions.add(positions[i - 1]);
        } else {
          // Position = index + 1 (saute les ex aequo)
          positions.add(i + 1);
        }
      }
    }
    return positions;
  }

  Widget _buildListe() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: OtakuColors.accent));
    }
    if (_classement.isEmpty) {
      return Center(
        child: Text('Aucun joueur trouve', style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted)),
      );
    }

    final myId = _service.monId;
    final positions = _calculerPositions();

    return ListView.separated(
      itemCount: _classement.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, index) {
        final joueur = _classement[index];
        final position = positions[index];
        final estMoi = joueur['id'] == myId;

        return GestureDetector(
          onTap: estMoi ? null : () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfilPublicPage(
                userId: joueur['id'],
                pseudo: joueur['pseudo'] ?? '???',
                niveau: joueur['niveau'] ?? 1,
                rang: joueur['rang'] ?? 'Debutant',
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: estMoi
                  ? OtakuColors.accent.withValues(alpha: 0.1)
                  : OtakuColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: estMoi
                    ? OtakuColors.accent.withValues(alpha: 0.4)
                    : OtakuColors.border.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Position
                SizedBox(
                  width: 32,
                  child: Text(
                    _positionText(position),
                    style: OtakuTypo.hud.copyWith(
                      fontSize: position <= 3 ? 18 : 14,
                      color: _positionColor(position),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Avatar
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: OtakuColors.surface,
                    border: Border.all(
                      color: estMoi
                          ? OtakuColors.accent.withValues(alpha: 0.6)
                          : OtakuColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(Icons.person, size: 16, color: estMoi ? OtakuColors.accent : OtakuColors.textMuted),
                ),
                const SizedBox(width: 10),
                // Pseudo + rang
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estMoi ? '${joueur['pseudo']} (toi)' : joueur['pseudo'] ?? '???',
                        style: OtakuTypo.headlineSmall.copyWith(
                          fontSize: 13,
                          color: estMoi ? OtakuColors.accent : OtakuColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Nv.${joueur['niveau']} · ${joueur['rang']}',
                        style: OtakuTypo.bodySmall.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                // XP
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${joueur['xp_totale']} XP',
                      style: OtakuTypo.hud.copyWith(fontSize: 12, color: OtakuColors.accent),
                    ),
                    Text(
                      '${joueur['combats_gagnes'] ?? 0} W',
                      style: OtakuTypo.bodySmall.copyWith(fontSize: 9, color: OtakuColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Top 3 avec medailles emoji-style
  String _positionText(int pos) {
    if (pos == 1) return '1st';
    if (pos == 2) return '2nd';
    if (pos == 3) return '3rd';
    return '#$pos';
  }

  Color _positionColor(int pos) {
    if (pos == 1) return const Color(0xFFFFD700); // Or
    if (pos == 2) return const Color(0xFFC0C0C0); // Argent
    if (pos == 3) return const Color(0xFFCD7F32); // Bronze
    return OtakuColors.textMuted;
  }
}
