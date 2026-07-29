import 'dart:math';
import 'package:flutter/material.dart';

/// Textures de fond par section — CustomPainter (placeholder avant les vrais SVG)
/// Opacite stricte 4-8%, blend overlay, cout de rendu quasi nul.

/// Widget wrapper qui affiche une texture en fond
class SectionTexture extends StatelessWidget {
  final Widget child;
  final TextureType type;
  final double opacity;

  const SectionTexture({
    super.key,
    required this.child,
    required this.type,
    this.opacity = 0.06,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _getpainter(),
          ),
        ),
        child,
      ],
    );
  }

  CustomPainter _getpainter() {
    switch (type) {
      case TextureType.speedlines:
        return _SpeedlinesPainter(opacity: opacity);
      case TextureType.seigaiha:
        return _SeigaihaPainter(opacity: opacity);
      case TextureType.eclats:
        return _EclatsPainter(opacity: opacity);
      case TextureType.bulles:
        return _BullesPainter(opacity: opacity);
      case TextureType.electrique:
        return _ElectriquePainter(opacity: opacity);
    }
  }
}

enum TextureType {
  speedlines, // Combat
  seigaiha, // Profil (motif japonais)
  eclats, // Defis / Missions
  bulles, // Amis
  electrique, // Division
}

/// Speedlines radiales — pour l'ecran de combat
class _SpeedlinesPainter extends CustomPainter {
  final double opacity;
  _SpeedlinesPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final random = Random(42);

    for (int i = 0; i < 24; i++) {
      final angle = (i * 15.0) * pi / 180;
      final startDist = 60.0 + random.nextDouble() * 40;
      final endDist = startDist + 80 + random.nextDouble() * 120;
      final start = Offset(
        center.dx + cos(angle) * startDist,
        center.dy + sin(angle) * startDist,
      );
      final end = Offset(
        center.dx + cos(angle) * endDist,
        center.dy + sin(angle) * endDist,
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Seigaiha (vagues japonaises) — pour le profil
class _SeigaihaPainter extends CustomPainter {
  final double opacity;
  _SeigaihaPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const spacing = 28.0;
    const radius = 14.0;

    for (double y = -radius; y < size.height + spacing; y += spacing * 0.75) {
      final offsetX = ((y / (spacing * 0.75)).floor() % 2 == 0) ? 0.0 : spacing / 2;
      for (double x = -radius + offsetX; x < size.width + spacing; x += spacing) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(x, y), radius: radius),
          pi,
          pi,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Eclats manga — pour les defis/missions
class _EclatsPainter extends CustomPainter {
  final double opacity;
  _EclatsPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final random = Random(77);

    for (int i = 0; i < 12; i++) {
      final cx = random.nextDouble() * size.width;
      final cy = random.nextDouble() * size.height;
      final points = <Offset>[];
      final spikes = 4 + random.nextInt(3);
      final outerR = 6.0 + random.nextDouble() * 10;
      final innerR = outerR * 0.4;

      for (int j = 0; j < spikes * 2; j++) {
        final angle = (j * pi) / spikes - pi / 2;
        final r = j.isEven ? outerR : innerR;
        points.add(Offset(cx + cos(angle) * r, cy + sin(angle) * r));
      }

      final path = Path()..addPolygon(points, true);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bulles de dialogue — pour l'ecran amis
class _BullesPainter extends CustomPainter {
  final double opacity;
  _BullesPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final random = Random(33);

    for (int i = 0; i < 8; i++) {
      final cx = random.nextDouble() * size.width;
      final cy = random.nextDouble() * size.height;
      final rx = 16.0 + random.nextDouble() * 20;
      final ry = 12.0 + random.nextDouble() * 14;

      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Eclairs electriques — pour division
class _ElectriquePainter extends CustomPainter {
  final double opacity;
  _ElectriquePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final random = Random(55);

    for (int i = 0; i < 6; i++) {
      final path = Path();
      var x = random.nextDouble() * size.width;
      var y = random.nextDouble() * size.height * 0.3;
      path.moveTo(x, y);

      for (int seg = 0; seg < 4; seg++) {
        x += (random.nextDouble() - 0.5) * 30;
        y += 15 + random.nextDouble() * 20;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
