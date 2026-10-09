import 'package:flutter/material.dart';

import '../apothecary.dart';

/// Dark walnut cabinet backdrop: plank seams, soft vignette, warm candle-side
/// light raking from the right. Purely material lighting, no decoration.
class CabinetBackground extends StatelessWidget {
  final Widget child;

  const CabinetBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Apothecary.walnut,
      child: Stack(
        children: [
          // plank seams
          Positioned.fill(
            child: CustomPaint(painter: _PlankPainter()),
          ),
          // candlelight wash from the right
          Positioned.fill(
            child: CustomPaint(painter: _CandlePainter()),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _PlankPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final seam = Paint()
      ..strokeWidth = 2
      ..color = Colors.black.withValues(alpha: 0.35);
    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), seam);
    }
    // faint grain streaks
    final grain = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xFF1A0F08).withValues(alpha: 0.5);
    for (var i = 0; i < 24; i++) {
      final x = (i * 97 % 100) / 100 * size.width;
      final y0 = (i * 53 % 100) / 100 * size.height;
      canvas.drawLine(
          Offset(x, y0), Offset(x + 8, y0 + 90), grain);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // warm wash on the right side
    final wash = Paint()
      ..shader = const RadialGradient(
        center: Alignment(1.0, 0.35),
        radius: 1.1,
        colors: [Color(0x2ED3AA66), Color(0x00000000)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);
    // vignette
    final vig = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.5, 0.5),
        radius: 1.05,
        colors: [
          const Color(0x00000000),
          Colors.black.withValues(alpha: 0.42)
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vig);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Engraved brass nameplate (HUD plates, level plates).
class BrassPlate extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const BrassPlate({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Apothecary.brassLight, Apothecary.brassDeep],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Apothecary.brassBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x88000000), blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}
