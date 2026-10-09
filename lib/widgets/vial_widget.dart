import 'dart:math';
import 'package:flutter/material.dart';

import '../apothecary.dart';
import '../themes.dart';

/// Hand-blown glass vial with real liquid depth, per DESIGN.md:
/// thick walls, optical refraction, amber specular on the lit (right) edge,
/// dark refraction shade on the recessed (left) edge, curved meniscus on
/// every liquid surface, caustic under-shadow, subtle artisanal irregularity.
/// A brass collar marks locked (completed) vials; decorative vials can wear
/// a cork stopper.
///
/// [palette] selects the liquid colors; [glass] selects the hand-blown
/// silhouette (Flute, Jar, Flask, Decanter, Coupe).
class VialWidget extends StatelessWidget {
  final List<int> units;
  final bool locked;
  final bool cork;
  final double width;
  final double height;
  final LiquidPalette palette;
  final GlassStyle glass;

  const VialWidget({
    super.key,
    required this.units,
    required this.width,
    required this.height,
    this.locked = false,
    this.cork = false,
    this.palette = const LiquidPalette(
      id: 'apothecary',
      name: 'Apothecary Classics',
      colors: [
        Color(0xFFB46A1B),
        Color(0xFF2E7D74),
        Color(0xFF4E7A3A),
        Color(0xFF6B3B5E),
        Color(0xFFD9A441),
        Color(0xFFA6533F),
        Color(0xFF35608A),
        Color(0xFF8C4256),
      ],
    ),
    this.glass = GlassStyle.flute,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _VialPainter(
          units: units,
          locked: locked,
          cork: cork,
          palette: palette,
          glass: glass,
        ),
      ),
    );
  }
}

/// Geometry of one glass silhouette: body path, liquid rect, rim rect.
class _Geom {
  final Path body;
  final Rect liquid;
  final Rect rim;
  final double wall;
  _Geom(this.body, this.liquid, this.rim, this.wall);
}

_Geom _geom(GlassStyle style, double w, double h, double wob) {
  final wall = w * 0.075;
  switch (style) {
    case GlassStyle.jar:
      final bodyTop = h * 0.10;
      final body = Path()
        ..moveTo(w * 0.30 + wob, bodyTop)
        ..lineTo(w * 0.30, h * 0.22)
        ..quadraticBezierTo(w * 0.28, h * 0.34, w * 0.10, h * 0.40)
        ..quadraticBezierTo(w * 0.04, h * 0.60, w * 0.06, h * 0.80)
        ..quadraticBezierTo(w * 0.08, h * 0.92, w * 0.25, h * 0.94)
        ..lineTo(w * 0.75, h * 0.94)
        ..quadraticBezierTo(w * 0.92, h * 0.92, w * 0.94, h * 0.80)
        ..quadraticBezierTo(w * 0.96, h * 0.60, w * 0.90, h * 0.40)
        ..quadraticBezierTo(w * 0.72, h * 0.34, w * 0.70, h * 0.22)
        ..lineTo(w * 0.70 - wob, bodyTop)
        ..close();
      return _Geom(
        body,
        Rect.fromLTRB(w * 0.12, h * 0.42, w * 0.88, h * 0.90),
        Rect.fromCenter(
            center: Offset(w / 2, bodyTop), width: w * 0.44, height: h * 0.05),
        wall,
      );
    case GlassStyle.flask:
      final body = Path()
        ..addOval(Rect.fromLTRB(w * 0.12, h * 0.28, w * 0.88, h * 0.94))
        ..addRect(Rect.fromLTRB(w * 0.42, h * 0.06, w * 0.58, h * 0.34));
      return _Geom(
        body,
        Rect.fromLTRB(w * 0.24, h * 0.44, w * 0.76, h * 0.88),
        Rect.fromCenter(
            center: Offset(w / 2, h * 0.06), width: w * 0.20, height: h * 0.045),
        wall,
      );
    case GlassStyle.decanter:
      final body = Path()
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTRB(w * 0.12, h * 0.24, w * 0.88, h * 0.94),
            Radius.circular(w * 0.05)))
        ..addRect(Rect.fromLTRB(w * 0.40, h * 0.08, w * 0.60, h * 0.28));
      return _Geom(
        body,
        Rect.fromLTRB(w * 0.17, h * 0.32, w * 0.83, h * 0.90),
        Rect.fromCenter(
            center: Offset(w / 2, h * 0.08), width: w * 0.24, height: h * 0.045),
        wall,
      );
    case GlassStyle.coupe:
      final body = Path()
        ..moveTo(w * 0.04, h * 0.30)
        ..quadraticBezierTo(w * 0.10, h * 0.66, w * 0.50, h * 0.70)
        ..quadraticBezierTo(w * 0.90, h * 0.66, w * 0.96, h * 0.30)
        ..close()
        ..addRect(Rect.fromLTRB(w * 0.47, h * 0.70, w * 0.53, h * 0.88))
        ..addOval(Rect.fromCenter(
            center: Offset(w * 0.50, h * 0.90), width: w * 0.34, height: h * 0.05));
      return _Geom(
        body,
        Rect.fromLTRB(w * 0.12, h * 0.34, w * 0.88, h * 0.64),
        Rect.fromLTRB(w * 0.04, h * 0.295, w * 0.96, h * 0.305),
        wall,
      );
    case GlassStyle.flute:
      final rimH = h * 0.075;
      final bodyTop = rimH + 2;
      final body = Path()
        ..moveTo(w * 0.08 + wob, bodyTop)
        ..quadraticBezierTo(w * 0.05, h * 0.55, w * 0.09 - wob, h - w * 0.30)
        ..quadraticBezierTo(w * 0.10, h - w * 0.10, w * 0.30, h - w * 0.09)
        ..lineTo(w * 0.70, h - w * 0.09)
        ..quadraticBezierTo(w * 0.90, h - w * 0.10, w * 0.91 + wob, h - w * 0.30)
        ..quadraticBezierTo(w * 0.95, h * 0.55, w * 0.92 - wob, bodyTop)
        ..close();
      return _Geom(
        body,
        Rect.fromLTRB(w * 0.08 + wall * 0.9, bodyTop + wall * 0.7,
            w * 0.92 - wall * 0.9, h - w * 0.09 - wall * 0.6),
        Rect.fromCenter(
            center: Offset(w / 2, bodyTop), width: w * 0.88, height: rimH * 1.5),
        wall,
      );
  }
}

class _VialPainter extends CustomPainter {
  final List<int> units;
  final bool locked;
  final bool cork;
  final LiquidPalette palette;
  final GlassStyle glass;

  _VialPainter({
    required this.units,
    required this.locked,
    required this.cork,
    required this.palette,
    required this.glass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final seed = units.fold<int>(7, (a, u) => a * 31 + u + 3);
    final rnd = Random(seed);
    final wob = (rnd.nextDouble() - 0.5) * w * 0.03;
    final g = _geom(glass, w, h, wob);
    final liq = g.liquid;

    // ---- contact shadow + caustic light on the shelf ----
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, h - 2), width: w * 1.05, height: 14),
      shadowPaint,
    );
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

    // ---- glass body ----
    canvas.drawPath(g.body, Paint()..color = const Color(0x1AFFE9C4));
    canvas.drawPath(
      g.body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = g.wall
        ..color = const Color(0x55B99B5F),
    );

    // ---- liquids ----
    final innerW = liq.width;
    final unitH = liq.height / 4;
    for (var k = 0; k < units.length && k < 4; k++) {
      final colorIdx = units[k];
      final top = liq.bottom - (k + 1) * unitH;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(liq.left, top + 1, innerW, unitH - 2),
        Radius.circular(min(innerW * 0.18, (unitH - 2) / 2)),
      );
      canvas.drawRRect(rect, Paint()..color = palette.of(colorIdx));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(liq.left, top + 1, innerW * 0.22, unitH - 2),
          const Radius.circular(4),
        ),
        Paint()..color = palette.dark(colorIdx).withValues(alpha: 0.55),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(liq.right - innerW * 0.20, top + 3, innerW * 0.20,
              unitH - 6),
          const Radius.circular(4),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.16),
      );
      final meniscus = Path()
        ..moveTo(liq.left + 2, top + unitH * 0.16)
        ..quadraticBezierTo(
            (liq.left + liq.right) / 2, top - unitH * 0.10,
            liq.right - 2, top + unitH * 0.16);
      canvas.drawPath(
        meniscus,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = palette.light(colorIdx),
      );
      canvas.drawLine(
        Offset(liq.left + 3, top + unitH * 0.22),
        Offset(liq.right - 3, top + unitH * 0.22),
        Paint()
          ..strokeWidth = 1
          ..color = palette.dark(colorIdx).withValues(alpha: 0.6),
      );
    }

    // ---- glass edge work: lit specular (right) + refraction shade (left) ----
    canvas.drawLine(
      Offset(w * 0.885, liq.top),
      Offset(w * 0.885, liq.bottom),
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x8CC89E58),
    );
    canvas.drawLine(
      Offset(w * 0.115, liq.top),
      Offset(w * 0.115, liq.bottom),
      Paint()
        ..strokeWidth = 4
        ..color = const Color(0x55140B05),
    );

    // ---- rim (glass lip) ----
    if (glass == GlassStyle.coupe) {
      canvas.drawLine(
        Offset(g.rim.left, g.rim.top),
        Offset(g.rim.right, g.rim.top),
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x99C8A06A),
      );
    } else {
      canvas.drawOval(
        g.rim,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0x99C8A06A),
      );
      canvas.drawArc(
        g.rim.deflate(1),
        -0.9,
        1.1,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xAAE8C886),
      );
    }

    // ---- brass collar on locked (completed) vials ----
    if (locked) {
      final collarTop = liq.top - h * 0.055;
      final collarRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(liq.left - w * 0.04, collarTop, liq.width + w * 0.08,
            h * 0.045),
        const Radius.circular(4),
      );
      final brassGrad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Apothecary.brassLight, Apothecary.brassDeep],
      );
      canvas.drawRRect(collarRect,
          Paint()..shader = brassGrad.createShader(collarRect.outerRect));
      canvas.drawRRect(
        collarRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Apothecary.brassBorder,
      );
      final dotPaint = Paint()..color = Apothecary.brassBorder;
      for (var i = 0; i < 5; i++) {
        canvas.drawCircle(
          Offset(liq.left + liq.width * (0.1 + i * 0.2),
              collarTop + h * 0.0225),
          1.6,
          dotPaint,
        );
      }
    }

    // ---- cork stopper (decorative vials) ----
    if (cork) {
      final rimTop = g.rim.top;
      final corkTop = rimTop - h * 0.11;
      final cw = g.rim.width * 0.62;
      final corkPath = Path()
        ..moveTo(w / 2 - cw / 2, corkTop)
        ..lineTo(w / 2 + cw / 2, corkTop)
        ..lineTo(w / 2 + cw / 2 * 0.9, rimTop - 2)
        ..lineTo(w / 2 - cw / 2 * 0.9, rimTop - 2)
        ..close();
      canvas.drawPath(corkPath, Paint()..color = const Color(0xFFB98A52));
      canvas.drawPath(
        corkPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF7A5A30),
      );
      final speck = Paint()..color = const Color(0xFF8A6536);
      final srnd = Random(seed + 99);
      for (var i = 0; i < 8; i++) {
        canvas.drawCircle(
          Offset(w / 2 - cw / 2 + srnd.nextDouble() * cw,
              corkTop + srnd.nextDouble() * h * 0.09),
          1.2,
          speck,
        );
      }
      canvas.drawLine(
        Offset(w / 2 - cw / 2, corkTop + h * 0.02),
        Offset(w / 2 + cw / 2, corkTop + h * 0.02),
        Paint()
          ..strokeWidth = 2
          ..color = const Color(0xFF6E4F2A),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VialPainter old) =>
      old.units != units ||
      old.locked != locked ||
      old.cork != cork ||
      old.palette != palette ||
      old.glass != glass;
}
