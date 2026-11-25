import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// === ANIMATION D'OUVERTURE : PLANCHE & CASES DE MANGA (100 % FLUTTER 60 FPS) ===
/// - Jouee une seule fois au lancement de l'application (~2,1 s), cliquable pour passer
/// - 0.00 -> 0.42 : trace a l'encre des cases de manga (cages / cadres decoupes façon planche shonen)
/// - 0.28 -> 0.66 : lignes de vitesse radiales (shuchu-sen) + traits d'encre accentues sur la case centrale
/// - 0.36 -> 0.76 : surgissement du logo renard + micro-secousse + titre OTAKU VERSE (sans barre generique)
/// - 0.80 -> 1.00 : ouverture / ecartement des cases revelant l'ecran principal
class SplashIntroOverlay extends StatefulWidget {
  final Widget child;
  const SplashIntroOverlay({super.key, required this.child});

  @override
  State<SplashIntroOverlay> createState() => _SplashIntroOverlayState();
}

class _SplashIntroOverlayState extends State<SplashIntroOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _termine = false;

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
    if (_isTestEnv) {
      _termine = true;
      _controller = AnimationController(vsync: this, duration: Duration.zero);
      return;
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _termine = true);
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _passerIntro() {
    if (!_termine && mounted) {
      _controller.stop();
      setState(() => _termine = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_termine) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        GestureDetector(
          onTap: _passerIntro,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;

              // Progression du trace des cases de manga (0.00 -> 0.42)
              final double cageProgress = Curves.easeOutCubic.transform(
                (t / 0.42).clamp(0.0, 1.0),
              );

              // Progression des lignes de vitesse shonen (0.28 -> 0.68)
              final double speedLinesProgress = Curves.easeOutQuart.transform(
                ((t - 0.28) / 0.32).clamp(0.0, 1.0),
              );

              // Impact + apparition du logo renard dans la case centrale (0.36 -> 0.68)
              final double logoT = ((t - 0.36) / 0.30).clamp(0.0, 1.0);
              final double logoScale = logoT == 0
                  ? 0.0
                  : Curves.easeOutBack.transform(logoT);
              final double logoOpacity = (logoT * 2.4).clamp(0.0, 1.0);

              // Micro-secousse seche a l'impact de la case centrale (0.38 -> 0.52)
              double shakeX = 0;
              double shakeY = 0;
              if (t >= 0.38 && t <= 0.52) {
                final double decay = 1.0 - ((t - 0.38) / 0.14);
                shakeX = sin(t * 210) * 6.0 * decay;
                shakeY = cos(t * 175) * 4.0 * decay;
              }

              // Flash bref a l'encrage de la case hero (0.36 -> 0.48)
              final double flashOpacity = (t >= 0.36 && t <= 0.48)
                  ? (1.0 - ((t - 0.36) / 0.12)) * 0.22
                  : 0.0;

              // Titre OTAKU VERSE estampille sous le logo (0.50 -> 0.78)
              final double titleT = Curves.easeOutCubic.transform(
                ((t - 0.50) / 0.24).clamp(0.0, 1.0),
              );

              // Ouverture finale des cases vers l'exterieur + fondu (0.80 -> 1.00)
              final double exitT = Curves.easeInCubic.transform(
                ((t - 0.80) / 0.20).clamp(0.0, 1.0),
              );
              final double overlayOpacity = (1.0 - exitT).clamp(0.0, 1.0);

              return Opacity(
                opacity: overlayOpacity,
                child: Container(
                  color: const Color(0xFF09090D),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Planche de cases manga + trames d'encre + lignes de vitesse shonen
                      Transform.translate(
                        offset: Offset(shakeX * 0.5, shakeY * 0.5),
                        child: CustomPaint(
                          painter: _MangaPanelsPainter(
                            cageProgress: cageProgress,
                            speedLinesProgress: speedLinesProgress,
                            exitProgress: exitT,
                          ),
                        ),
                      ),

                      // Flash bref d'impact encre/papier
                      if (flashOpacity > 0)
                        Container(
                          color: const Color(0xFFF4F1EA).withValues(alpha: flashOpacity),
                        ),

                      // Centre : Logo renard + Titre OTAKU VERSE estampille dans la case hero
                      Transform.translate(
                        offset: Offset(shakeX, shakeY),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: logoOpacity,
                                child: Transform.scale(
                                  scale: logoScale * (1.0 + exitT * 0.14),
                                  child: SizedBox(
                                    width: 110,
                                    height: 110,
                                    child: Image.asset(
                                      'assets/images/logos/logo_icone.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Opacity(
                                opacity: titleT,
                                child: Transform.translate(
                                  offset: Offset(0, (1.0 - titleT) * 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF09090D),
                                      border: Border.all(
                                        color: const Color(0xFFF4F1EA),
                                        width: 2.2,
                                      ),
                                    ),
                                    child: Text(
                                      'OTAKU VERSE',
                                      style: OtakuTypo.headlineLarge.copyWith(
                                        fontSize: 24,
                                        color: const Color(0xFFF4F1EA),
                                        letterSpacing: 3.5 + (1.0 - titleT) * 4.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Dessine une veritable planche de cases manga (cages inclinees a l'encre),
/// leurs hachures de trame et les lignes de vitesse shonen (shuchu-sen).
class _MangaPanelsPainter extends CustomPainter {
  final double cageProgress;
  final double speedLinesProgress;
  final double exitProgress;

  _MangaPanelsPainter({
    required this.cageProgress,
    required this.speedLinesProgress,
    required this.exitProgress,
  });

  /// Trace progressivement un chemin (Path) de 0 % a 100 % comme un coup de plume manga
  void _drawAnimatedPath(Canvas canvas, Path path, double progress, Paint paint) {
    if (progress <= 0) return;
    final p = progress.clamp(0.0, 1.0);
    for (final ui.PathMetric metric in path.computeMetrics()) {
      final extract = metric.extractPath(0, metric.length * p);
      canvas.drawPath(extract, paint);
    }
  }

  /// Construit un polygone ferme a partir d'une liste de points
  Path _polygonPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final pad = 16.0;
    final spread = exitProgress * 65.0;

    // 1. Quatre cases exterieures de planche manga (trapezes dynamiques inclines)
    final topLeftPanel = _polygonPath([
      Offset(pad - spread, pad - spread),
      Offset(w * 0.44 - spread, pad - spread),
      Offset(w * 0.36 - spread, h * 0.43 - spread),
      Offset(pad - spread, h * 0.50 - spread),
    ]);

    final topRightPanel = _polygonPath([
      Offset(w * 0.47 + spread, pad - spread),
      Offset(w - pad + spread, pad - spread),
      Offset(w - pad + spread, h * 0.44 - spread),
      Offset(w * 0.62 + spread, h * 0.38 - spread),
    ]);

    final bottomLeftPanel = _polygonPath([
      Offset(pad - spread, h * 0.55 + spread),
      Offset(w * 0.36 - spread, h * 0.49 + spread),
      Offset(w * 0.43 - spread, h - pad + spread),
      Offset(pad - spread, h - pad + spread),
    ]);

    final bottomRightPanel = _polygonPath([
      Offset(w * 0.63 + spread, h * 0.44 + spread),
      Offset(w - pad + spread, h * 0.50 + spread),
      Offset(w - pad + spread, h - pad + spread),
      Offset(w * 0.47 + spread, h - pad + spread),
    ]);

    // Case centrale hero (cage inclinée façon case d'action shonen)
    final heroHalfW = min(w * 0.23, 185.0);
    final heroHalfH = min(h * 0.34, 130.0);
    final skew = 22.0;
    final centerHeroPanel = _polygonPath([
      Offset(center.dx - heroHalfW + skew, center.dy - heroHalfH),
      Offset(center.dx + heroHalfW + skew, center.dy - heroHalfH),
      Offset(center.dx + heroHalfW - skew, center.dy + heroHalfH),
      Offset(center.dx - heroHalfW - skew, center.dy + heroHalfH),
    ]);

    final panels = [topLeftPanel, topRightPanel, bottomLeftPanel, bottomRightPanel];

    // Remplissage gris encre tres subtil + hachures manga dans les cases exterieures
    if (cageProgress > 0.25) {
      final fillAlpha = ((cageProgress - 0.25) / 0.75).clamp(0.0, 1.0);
      final panelFillPaint = Paint()
        ..color = const Color(0xFF13131B).withValues(alpha: 0.9 * fillAlpha)
        ..style = PaintingStyle.fill;

      final hatchPaint = Paint()
        ..color = const Color(0xFFF4F1EA).withValues(alpha: 0.05 * fillAlpha)
        ..strokeWidth = 1.1;

      for (final panel in panels) {
        canvas.drawPath(panel, panelFillPaint);
        canvas.save();
        canvas.clipPath(panel);
        for (double x = -h; x < w + h; x += 14) {
          canvas.drawLine(Offset(x, 0), Offset(x + h * 0.45, h), hatchPaint);
        }
        canvas.restore();
      }
    }

    // Traits d'encre blanc casse dessinant les 4 cages exterieures en cascade
    final outerInkPaint = Paint()
      ..color = const Color(0xFFF4F1EA).withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.miter;

    for (int i = 0; i < panels.length; i++) {
      final localP = ((cageProgress - i * 0.09) / 0.65).clamp(0.0, 1.0);
      _drawAnimatedPath(canvas, panels[i], localP, outerInkPaint);
    }

    // 2. Lignes de vitesse radiales (shuchu-sen) convergeant vers la case centrale
    if (speedLinesProgress > 0) {
      final lineCount = 44;
      final maxRadius = hypot(w, h) * 0.62;
      final innerBase = min(w, h) * 0.29;
      final speedPaint = Paint()
        ..strokeCap = StrokeCap.butt;

      for (int i = 0; i < lineCount; i++) {
        final angle = (i * 2 * pi / lineCount) + (i.isEven ? 0.015 : -0.012);
        final innerR = innerBase + ((i * 29) % 48);
        final outerR = innerR + (maxRadius - innerR) * speedLinesProgress;
        final isAccent = i % 7 == 0;

        speedPaint
          ..color = (isAccent ? const Color(0xFFFF5A1F) : const Color(0xFFF4F1EA))
              .withValues(alpha: (isAccent ? 0.42 : 0.22) * speedLinesProgress)
          ..strokeWidth = isAccent ? 2.2 : (i % 3 == 0 ? 1.8 : 1.0);

        canvas.drawLine(
          Offset(center.dx + cos(angle) * innerR, center.dy + sin(angle) * innerR),
          Offset(center.dx + cos(angle) * outerR, center.dy + sin(angle) * outerR),
          speedPaint,
        );
      }
    }

    // 3. Case centrale hero : fond sombre net + double encadrement manga (blanc + orange vif)
    final heroP = ((cageProgress - 0.22) / 0.78).clamp(0.0, 1.0);
    if (heroP > 0) {
      final heroBgPaint = Paint()
        ..color = const Color(0xFF09090D).withValues(alpha: heroP)
        ..style = PaintingStyle.fill;
      canvas.drawPath(centerHeroPanel, heroBgPaint);

      final heroAccentPaint = Paint()
        ..color = const Color(0xFFFF5A1F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeJoin = StrokeJoin.miter;
      _drawAnimatedPath(canvas, centerHeroPanel, heroP, heroAccentPaint);

      final heroWhitePaint = Paint()
        ..color = const Color(0xFFF4F1EA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.miter;
      _drawAnimatedPath(canvas, centerHeroPanel, heroP, heroWhitePaint);
    }
  }

  double hypot(double a, double b) => sqrt(a * a + b * b);

  @override
  bool shouldRepaint(covariant _MangaPanelsPainter oldDelegate) =>
      oldDelegate.cageProgress != cageProgress ||
      oldDelegate.speedLinesProgress != speedLinesProgress ||
      oldDelegate.exitProgress != exitProgress;
}
