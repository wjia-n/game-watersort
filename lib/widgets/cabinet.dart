import 'package:flutter/material.dart';

import '../themes.dart';

/// Dark walnut cabinet backdrop: plank seams, soft vignette, warm candle-side
/// light raking from the right. Purely material lighting, no decoration.
/// Colors follow the active cabinet theme.
class CabinetBackground extends StatelessWidget {
  final Widget child;
  final ApothecaryThemeDef? theme;

  const CabinetBackground({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? ApothecaryThemes.byId('classic');
    return Container(
      color: t.bg,
      child: Stack(
        children: [
          // plank seams
          Positioned.fill(
            child: CustomPaint(painter: _PlankPainter(t.bgDeep)),
          ),
          // candlelight wash from the right
          Positioned.fill(
            child: CustomPaint(painter: _CandlePainter(t.metalLight)),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _PlankPainter extends CustomPainter {
  final Color deep;
  _PlankPainter(this.deep);
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
      ..color = deep.withValues(alpha: 0.55);
    for (var i = 0; i < 24; i++) {
      final x = (i * 97 % 100) / 100 * size.width;
      final y0 = (i * 53 % 100) / 100 * size.height;
      canvas.drawLine(Offset(x, y0), Offset(x + 8, y0 + 90), grain);
    }
  }

  @override
  bool shouldRepaint(covariant _PlankPainter old) => old.deep != deep;
}

class _CandlePainter extends CustomPainter {
  final Color metal;
  _CandlePainter(this.metal);
  @override
  void paint(Canvas canvas, Size size) {
    // warm wash on the right side, tinted by the theme's metal
    final wash = Paint()
      ..shader = RadialGradient(
        center: const Alignment(1.0, 0.35),
        radius: 1.1,
        colors: [metal.withValues(alpha: 0.18), const Color(0x00000000)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);
    // vignette
    final vig = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.5, 0.5),
        radius: 1.05,
        colors: [const Color(0x00000000), Colors.black.withValues(alpha: 0.42)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vig);
  }

  @override
  bool shouldRepaint(covariant _CandlePainter old) => old.metal != metal;
}

/// Engraved brass nameplate (HUD plates, level plates).
class BrassPlate extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final ApothecaryThemeDef? theme;

  const BrassPlate({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme ?? ApothecaryThemes.byId('classic');
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.metalLight, t.metalDeep],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.metalBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x88000000), blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}
