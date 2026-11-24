import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// === ANIMATION D'OUVERTURE OPTION B : COUPURE MANGA / SLASH (100 % FLUTTER 60 FPS) ===
/// - Jouee une seule fois au lancement de l'application (~1,85 s), cliquable pour passer
/// - 0.00 -> 0.28 : coupure lumineuse cyan/orange diagonale avec etincelles
/// - 0.24 -> 0.58 : surgissement du logo transparent `logo_icone.png` + onde de choc + micro-secousse
/// - 0.46 -> 0.84 : apparition du titre `OTAKU VERSE` et barre fine d'entree
/// - 0.84 -> 1.00 : fondu fluide vers l'ecran principal
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
      duration: const Duration(milliseconds: 1850),
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

              // Fondu de sortie final (0.84 -> 1.00)
              final double overlayOpacity = t < 0.84
                  ? 1.0
                  : (1.0 - ((t - 0.84) / 0.16)).clamp(0.0, 1.0);

              // Progression de la coupure manga diagonale (0.0 -> 0.30)
              final double slashProgress = Curves.easeOutQuart.transform((t / 0.30).clamp(0.0, 1.0));
              final double slashFade = t < 0.25
                  ? 1.0
                  : (1.0 - ((t - 0.25) / 0.25)).clamp(0.0, 1.0);

              // Apparition elastique du logo renard a l'impact (0.22 -> 0.56)
              final double logoT = ((t - 0.22) / 0.34).clamp(0.0, 1.0);
              final double logoScale = logoT == 0
                  ? 0.0
                  : Curves.easeOutBack.transform(logoT);
              final double logoOpacity = (logoT * 2.2).clamp(0.0, 1.0);

              // Micro-secousse d'impact (0.24 -> 0.40)
              double shakeX = 0;
              double shakeY = 0;
              if (t >= 0.24 && t <= 0.40) {
                final double decay = 1.0 - ((t - 0.24) / 0.16);
                shakeX = sin(t * 170) * 5.5 * decay;
                shakeY = cos(t * 140) * 3.5 * decay;
              }

              // Onde de choc autour du logo (0.24 -> 0.64)
              final double ringT = ((t - 0.24) / 0.40).clamp(0.0, 1.0);

              // Titre OTAKU VERSE + barre de chargement (0.44 -> 0.78)
              final double titleT = Curves.easeOutCubic.transform(((t - 0.44) / 0.30).clamp(0.0, 1.0));

              return Opacity(
                opacity: overlayOpacity,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        Color(0xFF1A1336),
                        Color(0xFF0B0A16),
                      ],
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Coupure manga diagonale + etincelles + onde de choc
                      CustomPaint(
                        painter: _MangaSlashPainter(
                          slashProgress: slashProgress,
                          slashFade: slashFade,
                          ringProgress: ringT,
                        ),
                      ),

                      // Centre : Logo renard transparent + Titre OTAKU VERSE
                      Transform.translate(
                        offset: Offset(shakeX, shakeY),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: logoOpacity,
                                child: Transform.scale(
                                  scale: logoScale,
                                  child: Container(
                                    width: 112,
                                    height: 112,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: OtakuColors.accent.withValues(alpha: 0.45 * logoOpacity),
                                          blurRadius: 32,
                                          spreadRadius: 4,
                                        ),
                                        BoxShadow(
                                          color: const Color(0xFFFF8A00).withValues(alpha: 0.28 * logoOpacity),
                                          blurRadius: 20,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/images/logos/logo_icone.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Opacity(
                                opacity: titleT,
                                child: Transform.translate(
                                  offset: Offset(0, (1.0 - titleT) * 14),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'OTAKU VERSE',
                                        style: OtakuTypo.headlineLarge.copyWith(
                                          fontSize: 28,
                                          color: Colors.white,
                                          letterSpacing: 3.0 + (1.0 - titleT) * 5.0,
                                          shadows: const [
                                            Shadow(color: OtakuColors.accent, blurRadius: 18),
                                            Shadow(color: Color(0xFFFF8A00), blurRadius: 8),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: 170,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: (t / 0.86).clamp(0.0, 1.0),
                                            minHeight: 3,
                                            backgroundColor: Colors.white.withValues(alpha: 0.14),
                                            valueColor: const AlwaysStoppedAnimation(OtakuColors.accent),
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

/// Dessine la coupure lumineuse diagonale (cyan + orange), les etincelles et l'onde d'impact
class _MangaSlashPainter extends CustomPainter {
  final double slashProgress;
  final double slashFade;
  final double ringProgress;

  _MangaSlashPainter({
    required this.slashProgress,
    required this.slashFade,
    required this.ringProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 20);

    // 1. Coupure diagonale brillante traversant tout l'ecran
    if (slashProgress > 0 && slashFade > 0) {
      final start = Offset(size.width * 0.12, size.height * 0.92);
      final endFull = Offset(size.width * 0.88, size.height * 0.08);
      final currentEnd = Offset.lerp(start, endFull, slashProgress)!;

      // Halo externe cyan
      final glowPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF00E5FF).withValues(alpha: 0.0),
            const Color(0xFF00E5FF).withValues(alpha: 0.65 * slashFade),
            const Color(0xFFFF8A00).withValues(alpha: 0.85 * slashFade),
          ],
        ).createShader(Rect.fromPoints(start, currentEnd))
        ..strokeWidth = 18 * slashFade
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawLine(start, currentEnd, glowPaint);

      // Coeur blanc incandescent de la lame
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.95 * slashFade)
        ..strokeWidth = 3.5 * slashFade
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, currentEnd, corePaint);

      // Etincelles d'impact jaillissant autour du centre
      if (slashProgress > 0.45) {
        final sparkAlpha = ((slashProgress - 0.45) / 0.55).clamp(0.0, 1.0) * slashFade;
        final sparkPaint = Paint()
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;

        for (int i = 0; i < 12; i++) {
          final angle = (i * pi / 6) + 0.35;
          final dist = 30.0 + (1.0 - slashFade) * 140.0 + (i % 3) * 24.0;
          final len = 14.0 + (i % 2) * 10.0;
          final p1 = Offset(center.dx + cos(angle) * dist, center.dy + sin(angle) * dist);
          final p2 = Offset(center.dx + cos(angle) * (dist + len), center.dy + sin(angle) * (dist + len));
          sparkPaint.color = (i.isEven ? const Color(0xFF00E5FF) : const Color(0xFFFF8A00))
              .withValues(alpha: sparkAlpha);
          canvas.drawLine(p1, p2, sparkPaint);
        }
      }
    }

    // 2. Onde de choc circulaire a l'apparition du logo
    if (ringProgress > 0 && ringProgress < 1.0) {
      final ringAlpha = (1.0 - ringProgress).clamp(0.0, 1.0);
      final ringRadius = 46.0 + ringProgress * 135.0;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * ringAlpha
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.65 * ringAlpha);
      canvas.drawCircle(center, ringRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MangaSlashPainter oldDelegate) =>
      oldDelegate.slashProgress != slashProgress ||
      oldDelegate.slashFade != slashFade ||
      oldDelegate.ringProgress != ringProgress;
}
