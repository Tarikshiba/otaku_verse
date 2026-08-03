import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'skin_model.dart';
import 'skin_service.dart';

/// Ecran Boutique — 4 categories : Skins, Articles, Booster XP, Promos.
/// Utilise comme onglet direct dans la tab bar (pas de bouton retour).
/// La Collection (skins possedes) reste accessible depuis le Profil.
class BoutiqueScreen extends StatefulWidget {
  final bool showBack;
  const BoutiqueScreen({super.key, this.showBack = false});

  @override
  State<BoutiqueScreen> createState() => _BoutiqueScreenState();
}

class _BoutiqueScreenState extends State<BoutiqueScreen> {
  final _skinService = SkinService();
  List<Skin> _skins = [];
  bool _chargement = true;
  int _tabActive = 0; // 0=Skins, 1=Articles, 2=Booster XP, 3=Promos
  String? _message;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      await _skinService.donnerSkinGratuit();
      final skins = await _skinService.tousLesSkins();
      if (mounted) setState(() { _skins = skins; _chargement = false; });
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  List<Skin> get _skinsAchetables => _skins.where((s) => !s.owned).toList();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Bouton retour si ouvert en push (depuis profil par ex)
                if (widget.showBack) ...[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: OtakuColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: OtakuColors.border),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: OtakuColors.textPrimary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text('BOUTIQUE', style: OtakuTypo.headlineLarge.copyWith(fontSize: 20)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: OtakuColors.modeEvent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: OtakuColors.modeEvent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: OtakuColors.modeEvent),
                      const SizedBox(width: 4),
                      Text('Reset 12h', style: OtakuTypo.hud.copyWith(fontSize: 10, color: OtakuColors.modeEvent)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab('Skins', 0, Icons.person_rounded),
                  const SizedBox(width: 8),
                  _buildTab('Articles', 1, Icons.shopping_bag_rounded),
                  const SizedBox(width: 8),
                  _buildTab('Booster XP', 2, Icons.bolt_rounded),
                  const SizedBox(width: 8),
                  _buildTab('Promos', 3, Icons.local_fire_department_rounded),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Message feedback
            if (_message != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: OtakuColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_message!, style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.accent)),
              ),

            // Contenu selon la categorie
            Expanded(child: _buildContenu()),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator(color: OtakuColors.accent));
    }

    switch (_tabActive) {
      case 0:
        // Skins achetables
        final skins = _skinsAchetables;
        if (skins.isEmpty) {
          return Center(child: Text('Tu as tout debloque !', style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted)));
        }
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: skins.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => _buildSkinCard(skins[i]),
        );
      case 1:
        // Articles (placeholder)
        return _buildPlaceholder('ARTICLES', 'Arenes, badges et accessoires\narrivent bientot.', Icons.shopping_bag_rounded);
      case 2:
        // Booster XP (placeholder)
        return _buildPlaceholder('BOOSTER XP', 'Double XP, triple XP...\nBientot disponible.', Icons.bolt_rounded);
      case 3:
        // Promos (placeholder)
        return _buildPlaceholder('PROMOS SPECIALES', 'Des offres limitees\napparaitront ici.', Icons.local_fire_department_rounded);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlaceholder(String titre, String description, IconData icon) {
    return Center(
      child: LiquidGlass(
        padding: const EdgeInsets.all(28),
        borderRadius: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: OtakuColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(titre, style: OtakuTypo.headlineSmall.copyWith(color: OtakuColors.textSecondary)),
            const SizedBox(height: 6),
            Text(description, style: OtakuTypo.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final actif = _tabActive == index;
    return GestureDetector(
      onTap: () => setState(() => _tabActive = index),
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
            Text(label, style: OtakuTypo.label.copyWith(fontSize: 11, color: actif ? OtakuColors.accent : OtakuColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkinCard(Skin skin) {
    final couleur = _couleurRarete(skin.rarity);
    final largeur = MediaQuery.of(context).size.width * 0.3;

    return GestureDetector(
      onTap: () => _ouvrirDetail(skin),
      child: Container(
        width: largeur,
        decoration: BoxDecoration(
          color: OtakuColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: skin.equipped ? OtakuColors.accent : couleur.withValues(alpha: 0.4),
            width: skin.equipped ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Visuel du skin
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                  gradient: LinearGradient(
                    colors: [couleur.withValues(alpha: 0.08), OtakuColors.surface],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_iconRarete(skin.rarity), size: 36, color: couleur),
                    if (skin.equipped) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: OtakuColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('EQUIPE', style: OtakuTypo.label.copyWith(fontSize: 7, color: OtakuColors.accent)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Nom + rarete
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                children: [
                  Text(skin.name, style: OtakuTypo.headlineSmall.copyWith(fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(skin.rarity.toUpperCase(), style: OtakuTypo.label.copyWith(fontSize: 8, color: couleur)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvre l'ecran detail d'un skin (apercu 3D, description, bouton action)
  void _ouvrirDetail(Skin skin) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _SkinDetailPage(
        skin: skin,
        onAction: () {
          _charger();
          Navigator.pop(context);
        },
      )),
    );
  }

  Color _couleurRarete(String rarity) {
    switch (rarity) {
      case 'commun': return OtakuColors.textMuted;
      case 'rare': return const Color(0xFF4FC3F7);
      case 'epique': return OtakuColors.accent;
      case 'legendaire': return const Color(0xFFFFD700);
      default: return OtakuColors.textMuted;
    }
  }

  IconData _iconRarete(String rarity) {
    switch (rarity) {
      case 'commun': return Icons.person_rounded;
      case 'rare': return Icons.auto_awesome_rounded;
      case 'epique': return Icons.whatshot_rounded;
      case 'legendaire': return Icons.military_tech_rounded;
      default: return Icons.person_rounded;
    }
  }
}

/// Ecran detail d'un skin — apercu 3D rotatif, description, bouton acheter/equiper
class _SkinDetailPage extends StatefulWidget {
  final Skin skin;
  final VoidCallback onAction;

  const _SkinDetailPage({required this.skin, required this.onAction});

  @override
  State<_SkinDetailPage> createState() => _SkinDetailPageState();
}

class _SkinDetailPageState extends State<_SkinDetailPage> with SingleTickerProviderStateMixin {
  final _skinService = SkinService();
  late AnimationController _rotationController;
  double _dragRotation = 0;
  String? _erreur;
  bool _chargement = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _action() async {
    setState(() => _chargement = true);

    if (widget.skin.owned) {
      // Equiper
      await _skinService.equiper(widget.skin.id);
      widget.onAction();
    } else {
      // Debloquer
      final erreur = await _skinService.debloquer(widget.skin);
      if (erreur != null) {
        setState(() { _erreur = erreur; _chargement = false; });
        return;
      }
      widget.onAction();
    }
  }

  Color get _couleur {
    switch (widget.skin.rarity) {
      case 'commun': return OtakuColors.textMuted;
      case 'rare': return const Color(0xFF4FC3F7);
      case 'epique': return OtakuColors.accent;
      case 'legendaire': return const Color(0xFFFFD700);
      default: return OtakuColors.textMuted;
    }
  }

  IconData get _icon {
    switch (widget.skin.rarity) {
      case 'commun': return Icons.person_rounded;
      case 'rare': return Icons.auto_awesome_rounded;
      case 'epique': return Icons.whatshot_rounded;
      case 'legendaire': return Icons.military_tech_rounded;
      default: return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;

    return Scaffold(
      backgroundColor: OtakuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              // Gauche : apercu 3D rotatif
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() => _dragRotation += details.delta.dx * 0.01);
                  },
                  child: AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      final angle = _dragRotation + (_rotationController.value * 2 * pi);
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: child,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            _couleur.withValues(alpha: 0.12),
                            OtakuColors.surface,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: _couleur.withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: Icon(_icon, size: 80, color: _couleur.withValues(alpha: 0.8)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Droite : infos + bouton
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bouton retour
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_rounded, color: OtakuColors.textPrimary, size: 22),
                    ),
                    const SizedBox(height: 12),

                    // Nom
                    Text(skin.name, style: OtakuTypo.headlineLarge.copyWith(fontSize: 22)),
                    const SizedBox(height: 6),

                    // Rarete
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _couleur.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _couleur.withValues(alpha: 0.4)),
                      ),
                      child: Text(skin.rarity.toUpperCase(), style: OtakuTypo.label.copyWith(fontSize: 10, color: _couleur)),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(skin.description, style: OtakuTypo.bodySmall.copyWith(color: OtakuColors.textMuted)),
                    const SizedBox(height: 16),

                    // Condition
                    if (!skin.owned) ...[
                      Row(
                        children: [
                          Icon(
                            skin.unlockType == 'level' ? Icons.trending_up_rounded : Icons.star_rounded,
                            size: 16,
                            color: _couleur,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Condition : ${skin.conditionTexte}',
                            style: OtakuTypo.hud.copyWith(fontSize: 12, color: _couleur),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Erreur
                    if (_erreur != null) ...[
                      Text(_erreur!, style: TextStyle(color: OtakuColors.error, fontSize: 11)),
                      const SizedBox(height: 10),
                    ],

                    const Spacer(),

                    // Bouton action
                    if (!skin.equipped)
                      GestureDetector(
                        onTap: _chargement ? null : _action,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: skin.owned
                                ? OtakuColors.accent.withValues(alpha: 0.15)
                                : _couleur.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: skin.owned
                                  ? OtakuColors.accent.withValues(alpha: 0.5)
                                  : _couleur.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Center(
                            child: _chargement
                                ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _couleur))
                                : Text(
                                    skin.owned ? 'EQUIPER' : 'DEBLOQUER',
                                    style: OtakuTypo.label.copyWith(
                                      color: skin.owned ? OtakuColors.accent : _couleur,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: OtakuColors.pvHaut.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: OtakuColors.pvHaut.withValues(alpha: 0.4)),
                        ),
                        child: Center(
                          child: Text('EQUIPE ACTUELLEMENT', style: OtakuTypo.label.copyWith(color: OtakuColors.pvHaut, fontSize: 11)),
                        ),
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
}
