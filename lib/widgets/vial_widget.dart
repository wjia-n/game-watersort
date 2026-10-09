import 'dart:math';
import 'package:flutter/material.dart';

import '../apothecary.dart';

/// Hand-blown glass vial with real liquid depth, per DESIGN.md:
/// thick walls, optical refraction, amber specular on the lit (right) edge,
/// dark refraction shade on the recessed (left) edge, curved meniscus on
/// every liquid surface, caustic under-shadow, subtle artisanal irregularity.
/// A brass collar marks locked (completed) vials; decorative vials can wear
/// a cork stopper.
class VialWidget extends StatelessWidget {
  final List<int> units;
  final bool locked;
  final bool cork;
  final double width;
  final double height;

  const VialWidget({
    super.key,
    required this.units,
    required this.width,
    required this.height,
    this.locked = false,
    this.cork = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _VialPainter(units: units, locked: locked, cork: cork),
      ),
    );
  }
}

class _VialPainter extends CustomPainter {
  final List<int> units;
  final bool locked;
  final bool cork;

  _VialPainter({required this.units, required this.locked, required this.cork});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final seed = units.fold<int>(7, (a, u) => a * 31 + u + 3);

    // ---- contact shadow + caustic light on the shelf ----
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, h - 2), width: w * 1.05, height: 14),
      shadowPaint,
    );
    // warm caustic streak to the left of the base (candlelight from right)
    final caustic = Paint()
      ..color = const Color(0x40D3AA66)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(w * 0.28, h - 3), width: w * 0.35, height: 5),
          const Radius.circular(2.5)),
      caustic,
    );

    // ---- glass body path (slight artisanal irregularity) ----
    final rimH = h * 0.075;
    final bodyTop = rimH + 2;
    final wall = w * 0.075;
    final rnd = Random(seed);
    final wob = (rnd.nextDouble() - 0.5) * w * 0.03;
    final body = Path()
      ..moveTo(w * 0.08 + wob, bodyTop)
      ..quadraticBezierTo(w * 0.05, h * 0.55, w * 0.09 - wob, h - w * 0.30)
      ..quadraticBezierTo(w * 0.10, h - w * 0.10, w * 0.30, h - w * 0.09)
      ..lineTo(w * 0.70, h - w * 0.09)
      ..quadraticBezierTo(w * 0.90, h - w * 0.10, w * 0.91 + wob, h - w * 0.30)
      ..quadraticBezierTo(w * 0.95, h * 0.55, w * 0.92 - wob, bodyTop)
      ..close();

    // glass body fill: faint warm translucency
    canvas.drawPath(body, Paint()..color = const Color(0x1AFFE9C4));
    // thick wall stroke
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = wall
        ..color = const Color(0x55B99B5F),
    );

    // ---- liquids ----
    final innerLeft = w * 0.08 + wall * 0.9;
    final innerRight = w * 0.92 - wall * 0.9;
    final innerW = innerRight - innerLeft;
    final innerTop = bodyTop + wall * 0.7;
    final innerBottom = h - w * 0.09 - wall * 0.6;
    final innerH = innerBottom - innerTop;
    const cap = 4;
    final unitH = innerH / cap;

    for (var k = 0; k < units.length && k < cap; k++) {
      final colorIdx = units[k];
      final top = innerBottom - (k + 1) * unitH;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(innerLeft, top + 1, innerW, unitH - 2),
        Radius.circular(min(innerW * 0.18, (unitH - 2) / 2)),
      );
      // liquid body
      canvas.drawRRect(rect, Paint()..color = Apothecary.liquid(colorIdx));
      // translucent depth: darker shade on recessed (left) edge
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(innerLeft, top + 1, innerW * 0.22, unitH - 2),
          const Radius.circular(4),
        ),
        Paint()..color = Apothecary.liquidDark(colorIdx).withValues(alpha: 0.55),
      );
      // refraction light band on lit (right) edge
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(innerRight - innerW * 0.20, top + 3, innerW * 0.20,
              unitH - 6),
          const Radius.circular(4),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.16),
      );
      // curved meniscus on the surface
      final meniscus = Path()
        ..moveTo(innerLeft + 2, top + unitH * 0.16)
        ..quadraticBezierTo(
            (innerLeft + innerRight) / 2, top - unitH * 0.10,
            innerRight - 2, top + unitH * 0.16);
      canvas.drawPath(
        meniscus,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = Apothecary.liquidLight(colorIdx),
      );
      // settle line under the meniscus
      canvas.drawLine(
        Offset(innerLeft + 3, top + unitH * 0.22),
        Offset(innerRight - 3, top + unitH * 0.22),
        Paint()
          ..strokeWidth = 1
          ..color = Apothecary.liquidDark(colorIdx).withValues(alpha: 0.6),
      );
    }

    // ---- glass edge work: lit specular (right) + refraction shade (left) ----
    final specPaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x8CC89E58);
    canvas.drawLine(
      Offset(w * 0.885, bodyTop + 6),
      Offset(w * 0.885, h - w * 0.35),
      specPaint,
    );
    final shadePaint = Paint()
      ..strokeWidth = 4
      ..color = const Color(0x55140B05);
    canvas.drawLine(
      Offset(w * 0.115, bodyTop + 8),
      Offset(w * 0.115, h - w * 0.35),
      shadePaint,
    );

    // ---- rim (glass lip) ----
    final rimRect = Rect.fromCenter(
        center: Offset(w / 2, bodyTop), width: w * 0.88, height: rimH * 1.5);
    canvas.drawOval(
      rimRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0x99C8A06A),
    );
    // rim specular on the candle side
    canvas.drawArc(
      rimRect.deflate(1),
      -0.9,
      1.1,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xAAE8C886),
    );

    // ---- brass collar on locked (completed) vials ----
    if (locked) {
      final collarTop = bodyTop + h * 0.045;
      final collarRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.10, collarTop, w * 0.80, h * 0.045),
        const Radius.circular(4),
      );
      final brassGrad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Apothecary.brassLight, Apothecary.brassDeep],
      );
      canvas.drawRRect(
          collarRect, Paint()..shader = brassGrad.createShader(collarRect.outerRect));
      canvas.drawRRect(
        collarRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Apothecary.brassBorder,
      );
      // engraved dots
      final dotPaint = Paint()..color = Apothecary.brassBorder;
      for (var i = 0; i < 5; i++) {
        canvas.drawCircle(
          Offset(w * (0.2 + i * 0.15), collarTop + h * 0.0225),
          1.6,
          dotPaint,
        );
      }
    }

    // ---- cork stopper (decorative vials) ----
    if (cork) {
      final corkTop = bodyTop - h * 0.11;
      final corkPath = Path()
        ..moveTo(w * 0.34, corkTop)
        ..lineTo(w * 0.66, corkTop)
        ..lineTo(w * 0.62, bodyTop - 2)
        ..lineTo(w * 0.38, bodyTop - 2)
        ..close();
      canvas.drawPath(
          corkPath, Paint()..color = const Color(0xFFB98A52));
      canvas.drawPath(
        corkPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF7A5A30),
      );
      // cork grain speckle
      final speck = Paint()..color = const Color(0xFF8A6536);
      final srnd = Random(seed + 99);
      for (var i = 0; i < 8; i++) {
        canvas.drawCircle(
          Offset(w * (0.38 + srnd.nextDouble() * 0.24),
              corkTop + srnd.nextDouble() * h * 0.09),
          1.2,
          speck,
        );
      }
      // twine tie
      canvas.drawLine(
        Offset(w * 0.355, corkTop + h * 0.02),
        Offset(w * 0.645, corkTop + h * 0.02),
        Paint()
          ..strokeWidth = 2
          ..color = const Color(0xFF6E4F2A),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VialPainter old) =>
      old.units != units || old.locked != locked || old.cork != cork;
}
