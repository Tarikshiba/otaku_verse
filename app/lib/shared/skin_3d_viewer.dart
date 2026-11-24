import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../core/theme.dart';
import '../features/skins/skin_3d_cache_service.dart';

/// === VIEWER 3D (.glb) INTERACTIF 360° AVEC REPLI INSTANTANE 2D ===
/// - Affiche immediatement le portrait transparent 2D (zero attente / zero ecran vide)
/// - Charge le modele .glb compresse (embarque pour Kio, streame + mis en cache R2 pour les autres)
/// - Bouton discret 3D / 2D pour permettre au joueur de basculer a tout moment (economie batterie)
/// - Compatible 100% avec `flutter test` (desactive le WebView natif pendant les tests unitaires)
class OtakuSkin3DViewer extends StatefulWidget {
  final String imageKey;
  final Color accentColor;
  final double? width;
  final double? height;
  final bool enable3DByDefault;
  final bool showModeToggle;
  final String? characterName;
  final String? characterSubtitle;

  const OtakuSkin3DViewer({
    super.key,
    required this.imageKey,
    this.accentColor = OtakuColors.accent,
    this.width,
    this.height,
    this.enable3DByDefault = true,
    this.showModeToggle = true,
    this.characterName,
    this.characterSubtitle,
  });

  @override
  State<OtakuSkin3DViewer> createState() => _OtakuSkin3DViewerState();
}

class _OtakuSkin3DViewerState extends State<OtakuSkin3DViewer>
    with SingleTickerProviderStateMixin {
  final _cache = Skin3DCacheService.instance;
  late AnimationController _idleController;

  String? _modelSrc;
  bool _loading3D = false;
  bool _mode3DActif = true;
  double _dragAngle = 0;

  bool get _isTestEnv {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _mode3DActif = widget.enable3DByDefault && !_isTestEnv;
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _resoudreModele3D();
  }

  @override
  void didUpdateWidget(covariant OtakuSkin3DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageKey != widget.imageKey) {
      _modelSrc = null;
      _resoudreModele3D();
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  Future<void> _resoudreModele3D() async {
    if (_isTestEnv || !_cache.aModele3D(widget.imageKey)) {
      if (mounted) {
        setState(() {
          _modelSrc = null;
          _loading3D = false;
        });
      }
      return;
    }

    setState(() => _loading3D = true);
    final src = await _cache.obtenirSource3D(widget.imageKey);
    if (!mounted) return;
    setState(() {
      _modelSrc = src;
      _loading3D = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canShow3D = _mode3DActif && _modelSrc != null && !_isTestEnv;
    final bool has3DCapability = _cache.aModele3D(widget.imageKey) && !_isTestEnv;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Ombre de contact sombre + halo lumineux ancres pile sous les pieds
          Positioned(
            bottom: 14,
            left: 24,
            right: 24,
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.78),
                    widget.accentColor.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // 2. Scene centrale pleine hauteur : pieds ancres sur le cercle d'arene + autoPlay pret pour Mixamo
          Positioned.fill(
            bottom: 4,
            child: canShow3D
                ? Transform.translate(
                    offset: const Offset(0, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: ModelViewer(
                        key: ValueKey('glb_${widget.imageKey}_$_modelSrc'),
                        src: _modelSrc!,
                        alt: widget.characterName ?? widget.imageKey,
                        backgroundColor: Colors.transparent,
                        autoPlay: true,
                        autoRotate: false,
                        cameraControls: true,
                        cameraOrbit: '0deg 83deg 104%',
                        fieldOfView: '28deg',
                        disablePan: true,
                        disableZoom: false,
                        shadowIntensity: 0.9,
                        shadowSoftness: 0.8,
                        exposure: 1.05,
                        interactionPrompt: InteractionPrompt.none,
                      ),
                    ),
                  )
                : _buildFallback2D(),
          ),

          // 3. Cartouche nom + pouvoir discret en bas sans soulever le personnage
          if (widget.characterName != null)
            Positioned(
              bottom: 0,
              left: 16,
              right: 16,
              child: IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.characterName!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OtakuTypo.headlineSmall.copyWith(
                        fontSize: 12.5,
                        color: Colors.white,
                        letterSpacing: 1.3,
                        shadows: [
                          const Shadow(color: Colors.black, blurRadius: 8),
                          Shadow(color: widget.accentColor.withValues(alpha: 0.85), blurRadius: 10),
                        ],
                      ),
                    ),
                    if (widget.characterSubtitle != null && widget.characterSubtitle!.isNotEmpty)
                      Text(
                        widget.characterSubtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OtakuTypo.label.copyWith(
                          fontSize: 8.5,
                          color: widget.accentColor,
                          shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // 4. Indicateur discret telechargement 3D ou toggle 3D / 2D
          if (widget.showModeToggle && has3DCapability)
            Positioned(
              top: 4,
              right: 6,
              child: GestureDetector(
                onTap: () {
                  setState(() => _mode3DActif = !_mode3DActif);
                  if (_mode3DActif && _modelSrc == null && !_loading3D) {
                    _resoudreModele3D();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: canShow3D
                          ? widget.accentColor.withValues(alpha: 0.85)
                          : OtakuColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_loading3D) ...[
                        SizedBox(
                          width: 9,
                          height: 9,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: widget.accentColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('3D...', style: OtakuTypo.label.copyWith(fontSize: 8, color: Colors.white70)),
                      ] else ...[
                        Icon(
                          canShow3D ? Icons.view_in_ar_rounded : Icons.image_rounded,
                          size: 11,
                          color: canShow3D ? widget.accentColor : Colors.white70,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          canShow3D ? '3D' : '2D',
                          style: OtakuTypo.label.copyWith(
                            fontSize: 8.5,
                            color: canShow3D ? widget.accentColor : Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Repli 2D fluide avec legere parallaxe au doigt (UI-01 : jamais coupe)
  Widget _buildFallback2D() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: (d) => setState(() => _dragAngle += d.delta.dx * 0.01),
      child: AnimatedBuilder(
        animation: _idleController,
        builder: (context, child) {
          final angle = sin(_dragAngle + (_idleController.value * 2 * pi)) * 0.16;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 10, left: 6, right: 6, bottom: 4),
          child: Image.asset(
            'assets/images/skins/${widget.imageKey}.png',
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            errorBuilder: (_, _, _) => Center(
              child: Icon(
                Icons.person_rounded,
                size: 72,
                color: widget.accentColor.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
