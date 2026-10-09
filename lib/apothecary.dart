import 'package:flutter/material.dart';

/// Apothecary Cabinet design tokens (Stitch project
/// "Water Sort — Apothecary Glassware UI", DESIGN.md is the visual source of
/// truth). Warm candlelit walnut + tarnished brass + parchment; liquids are
/// physical, matte, never neon/glowing.
class Apothecary {
  Apothecary._();

  // --- palette (DESIGN.md) ---
  static const walnut = Color(0xFF2B1D12); // screen background, cabinet
  static const timberInset = Color(0xFF22160D); // recessed troughs
  static const inkBrown = Color(0xFF1C120B); // text on brass/parchment
  static const parchment = Color(0xFFEAD9B8); // cards, labels, title text
  static const parchmentDim = Color(0xFFD8C49C);
  static const brassLight = Color(0xFFD3AA66); // button face, highlights
  static const brassDeep = Color(0xFF9B7036); // button base, hardware
  static const brassBorder = Color(0xFF5C401E); // outlines, engraving
  static const candleShadow = Color(0xBF0C0704); // long-throw cast shadows

  /// Physical liquid colors — matte, translucent, no glow.
  static const liquids = <Color>[
    Color(0xFFB46A1B), // amber
    Color(0xFF2E7D74), // teal
    Color(0xFF4E7A3A), // botanical green
    Color(0xFF6B3B5E), // plum
    Color(0xFFD9A441), // honey
    Color(0xFFA6533F), // clay red
    Color(0xFF35608A), // apothecary blue
    Color(0xFF8C4256), // rosewood
  ];

  static Color liquid(int i) => liquids[i % liquids.length];

  /// Darker refraction shade of a liquid (recessed edge).
  static Color liquidDark(int i) {
    final c = liquid(i);
    return Color.from(
      alpha: c.a,
      red: c.r * 0.55,
      green: c.g * 0.55,
      blue: c.b * 0.55,
    );
  }

  /// Lighter meniscus sheen of a liquid (lit surface).
  static Color liquidLight(int i) {
    final c = liquid(i);
    double up(double v) => v + (1 - v) * 0.35;
    return Color.from(
        alpha: c.a, red: up(c.r), green: up(c.g), blue: up(c.b));
  }
}

/// Typography: aged parchment serif, engraved look (system serif family);
/// tabular figures for HUD counters.
class ApothecaryText {
  ApothecaryText._();

  static TextStyle display(double size, {Color color = Apothecary.parchment}) =>
      TextStyle(
        fontFamily: 'serif',
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 3.0,
        color: color,
        shadows: const [
          Shadow(offset: Offset(0, 2), color: Color(0xAA000000), blurRadius: 2),
          Shadow(offset: Offset(0, -1), color: Color(0x44FFE9C4), blurRadius: 0),
        ],
      );

  static TextStyle engraved(double size,
          {Color color = Apothecary.inkBrown}) =>
      TextStyle(
        fontFamily: 'serif',
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: color,
        shadows: const [
          Shadow(offset: Offset(0, 1), color: Color(0x88FFF3D6), blurRadius: 0),
        ],
      );

  /// Sepia iron-gall body text for parchment cards.
  static const bodyInk = TextStyle(
    fontFamily: 'serif',
    fontSize: 15,
    height: 1.5,
    color: Color(0xFF4A3620),
  );

  static TextStyle plate(double size,
          {Color color = Apothecary.parchment}) =>
      TextStyle(
        fontFamily: 'monospace',
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: color,
        shadows: const [
          Shadow(offset: Offset(0, 1), color: Color(0x88000000), blurRadius: 0),
        ],
      );
}
