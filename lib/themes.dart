import 'package:flutter/material.dart';

/// Cabinet theme, liquid-palette and glass-style catalogs for Water Sort.
///
/// Everything stays inside the apothecary material world (dark woods, aged
/// metals, parchment, matte physical liquids) — the variety comes from
/// different woods, metal accents, parchment tones and tincture palettes.
/// No neon, no glow, no generic Material look.
///
/// Free vs Pro: the first 4 themes, 2 palettes and 2 glass styles are free;
/// the rest unlock with Water Sort PRO (or the custom theme creator).

// ---------------------------------------------------------------- palettes
/// A named set of 8 physical liquid colors.
class LiquidPalette {
  final String id;
  final String name;
  final List<Color> colors;
  final bool proOnly;

  const LiquidPalette({
    required this.id,
    required this.name,
    required this.colors,
    this.proOnly = false,
  });

  Color of(int i) => colors[i % colors.length];

  Color dark(int i) {
    final c = of(i);
    return Color.from(
        alpha: c.a, red: c.r * 0.55, green: c.g * 0.55, blue: c.b * 0.55);
  }

  Color light(int i) {
    final c = of(i);
    double up(double v) => v + (1 - v) * 0.35;
    return Color.from(
        alpha: c.a, red: up(c.r), green: up(c.g), blue: up(c.b));
  }
}

class LiquidPalettes {
  static const List<String> freeIds = ['apothecary', 'candlelight'];

  static const List<LiquidPalette> all = [
    LiquidPalette(
      id: 'apothecary',
      name: 'Apothecary Classics',
      colors: [
        Color(0xFFB46A1B), // amber
        Color(0xFF2E7D74), // teal
        Color(0xFF4E7A3A), // botanical green
        Color(0xFF6B3B5E), // plum
        Color(0xFFD9A441), // honey
        Color(0xFFA6533F), // clay red
        Color(0xFF35608A), // apothecary blue
        Color(0xFF8C4256), // rosewood
      ],
    ),
    LiquidPalette(
      id: 'candlelight',
      name: 'Candlelight',
      colors: [
        Color(0xFFC08A3E),
        Color(0xFF9C5A2E),
        Color(0xFF8C3B2A),
        Color(0xFF6B6B35),
        Color(0xFF4A5D3A),
        Color(0xFF4A5A66),
        Color(0xFF5C4326),
        Color(0xFFD8BE96),
      ],
    ),
    LiquidPalette(
      id: 'herb',
      name: 'Herb Garden',
      proOnly: true,
      colors: [
        Color(0xFF7A8B5A),
        Color(0xFF5A7A4A),
        Color(0xFF3E6B3A),
        Color(0xFF6BA583),
        Color(0xFF7A6BA5),
        Color(0xFFD9C07A),
        Color(0xFF4A6B3A),
        Color(0xFF2E5D3A),
      ],
    ),
    LiquidPalette(
      id: 'berry',
      name: 'Berry Cellar',
      proOnly: true,
      colors: [
        Color(0xFF4A2B4A),
        Color(0xFF8C2B4A),
        Color(0xFF7A2B2B),
        Color(0xFF6B1F2B),
        Color(0xFFD8C8A8),
        Color(0xFF3A2B4A),
        Color(0xFF6B7A3A),
        Color(0xFF5C1F3A),
      ],
    ),
    LiquidPalette(
      id: 'mineral',
      name: 'Mineral Cabinet',
      proOnly: true,
      colors: [
        Color(0xFFC8953A),
        Color(0xFF3E7A5A),
        Color(0xFF2E4A7A),
        Color(0xFF9C3A2A),
        Color(0xFFD8D0B8),
        Color(0xFF5C3A3A),
        Color(0xFF4A7A6B),
        Color(0xFF8C5A1F),
      ],
    ),
    LiquidPalette(
      id: 'spice',
      name: 'Spiced Market',
      proOnly: true,
      colors: [
        Color(0xFFD9A03A),
        Color(0xFF9C4A2A),
        Color(0xFF7A8B4A),
        Color(0xFFE0B83A),
        Color(0xFF5C3A2A),
        Color(0xFF8C5A3A),
        Color(0xFF4A4A5A),
        Color(0xFF3A3A3A),
      ],
    ),
    LiquidPalette(
      id: 'meadow',
      name: 'Meadow Morning',
      proOnly: true,
      colors: [
        Color(0xFF6B9AB8),
        Color(0xFFD8D8D0),
        Color(0xFF5A8B3A),
        Color(0xFFE0C83A),
        Color(0xFFB84A3A),
        Color(0xFF5A6BA8),
        Color(0xFF4A7A4A),
        Color(0xFF7AB8C8),
      ],
    ),
    LiquidPalette(
      id: 'dusk',
      name: 'Dusk Tinctures',
      proOnly: true,
      colors: [
        Color(0xFF3A3A6B),
        Color(0xFF7A5A7A),
        Color(0xFF9C5A3A),
        Color(0xFFC89A4A),
        Color(0xFF2E4A3A),
        Color(0xFF5A5A5A),
        Color(0xFF6B2B4A),
        Color(0xFF8A8A80),
      ],
    ),
    LiquidPalette(
      id: 'ocean',
      name: 'Ocean Remedies',
      proOnly: true,
      colors: [
        Color(0xFF3A5A4A),
        Color(0xFFD8C8B8),
        Color(0xFFA85A4A),
        Color(0xFF1F3A5A),
        Color(0xFFC8D8D8),
        Color(0xFFB8A88A),
        Color(0xFF2E6B7A),
        Color(0xFFC8A86B),
      ],
    ),
    LiquidPalette(
      id: 'orchard',
      name: 'Orchard',
      proOnly: true,
      colors: [
        Color(0xFF7A9B3A),
        Color(0xFFC88A3A),
        Color(0xFF6B3A5A),
        Color(0xFFA8B85A),
        Color(0xFFD8B83A),
        Color(0xFF5A3A4A),
        Color(0xFF8C2B3A),
        Color(0xFF4A7A3A),
      ],
    ),
  ];

  static LiquidPalette byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => all.first);
}

// ------------------------------------------------------------- glass styles
/// Hand-blown glass silhouettes for the vials.
enum GlassStyle {
  flute('flute', 'Tall Flute', false),
  jar('jar', 'Apothecary Jar', false),
  flask('flask', 'Round Flask', true),
  decanter('decanter', 'Square Decanter', true),
  coupe('coupe', 'Wide Coupe', true);

  final String id;
  final String name;
  final bool proOnly;
  const GlassStyle(this.id, this.name, this.proOnly);

  static GlassStyle byId(String id) =>
      GlassStyle.values.firstWhere((g) => g.id == id,
          orElse: () => GlassStyle.flute);
}

// ------------------------------------------------------------------- themes
/// A full cabinet theme: woods, metal, parchment, ink + default palette and
/// glass style.
class ApothecaryThemeDef {
  final String id;
  final String name;
  final Color bg;
  final Color bgDeep;
  final Color shelf;
  final Color metalLight;
  final Color metalDeep;
  final Color metalBorder;
  final Color parchment;
  final Color parchmentDim;
  final Color ink;
  final String paletteId;
  final String glassId;
  final bool proOnly;

  const ApothecaryThemeDef({
    required this.id,
    required this.name,
    required this.bg,
    required this.bgDeep,
    required this.shelf,
    required this.metalLight,
    required this.metalDeep,
    required this.metalBorder,
    required this.parchment,
    required this.parchmentDim,
    required this.ink,
    required this.paletteId,
    required this.glassId,
    this.proOnly = false,
  });

  LiquidPalette get palette => LiquidPalettes.byId(paletteId);
  GlassStyle get glass => GlassStyle.byId(glassId);
}

class ApothecaryThemes {
  static const List<String> freeIds = [
    'classic',
    'mahogany',
    'ebony',
    'oak',
  ];

  static const List<ApothecaryThemeDef> all = [
    ApothecaryThemeDef(
      id: 'classic',
      name: 'Classic Walnut',
      bg: Color(0xFF2B1D12),
      bgDeep: Color(0xFF1C120B),
      shelf: Color(0xFF1E130B),
      metalLight: Color(0xFFD3AA66),
      metalDeep: Color(0xFF9B7036),
      metalBorder: Color(0xFF5C401E),
      parchment: Color(0xFFEAD9B8),
      parchmentDim: Color(0xFFD8C49C),
      ink: Color(0xFF1C120B),
      paletteId: 'apothecary',
      glassId: 'flute',
    ),
    ApothecaryThemeDef(
      id: 'mahogany',
      name: 'Royal Mahogany',
      bg: Color(0xFF3A1E12),
      bgDeep: Color(0xFF241009),
      shelf: Color(0xFF2A140C),
      metalLight: Color(0xFFC89A5A),
      metalDeep: Color(0xFF8C6428),
      metalBorder: Color(0xFF4E3517),
      parchment: Color(0xFFE5D0A8),
      parchmentDim: Color(0xFFD0B88E),
      ink: Color(0xFF241009),
      paletteId: 'berry',
      glassId: 'jar',
    ),
    ApothecaryThemeDef(
      id: 'ebony',
      name: 'Ebony Night',
      bg: Color(0xFF1A1512),
      bgDeep: Color(0xFF0E0B08),
      shelf: Color(0xFF14100C),
      metalLight: Color(0xFFC0C6D4),
      metalDeep: Color(0xFF7E8698),
      metalBorder: Color(0xFF3A3F4A),
      parchment: Color(0xFFD8D0C0),
      parchmentDim: Color(0xFFBEB6A4),
      ink: Color(0xFF0E0B08),
      paletteId: 'mineral',
      glassId: 'flask',
    ),
    ApothecaryThemeDef(
      id: 'oak',
      name: 'Honey Oak',
      bg: Color(0xFF4A2E18),
      bgDeep: Color(0xFF2E1C0E),
      shelf: Color(0xFF33200F),
      metalLight: Color(0xFFD9B86B),
      metalDeep: Color(0xFFA87F3A),
      metalBorder: Color(0xFF6B4E1E),
      parchment: Color(0xFFF0E0C0),
      parchmentDim: Color(0xFFDCC9A2),
      ink: Color(0xFF2E1C0E),
      paletteId: 'candlelight',
      glassId: 'jar',
    ),
    ApothecaryThemeDef(
      id: 'copper',
      name: 'Copper Still',
      proOnly: true,
      bg: Color(0xFF2E1A10),
      bgDeep: Color(0xFF1C0E08),
      shelf: Color(0xFF221209),
      metalLight: Color(0xFFD08A5A),
      metalDeep: Color(0xFF9C5A2E),
      metalBorder: Color(0xFF5C3A1E),
      parchment: Color(0xFFEAD3B0),
      parchmentDim: Color(0xFFD4B98E),
      ink: Color(0xFF1C0E08),
      paletteId: 'spice',
      glassId: 'decanter',
    ),
    ApothecaryThemeDef(
      id: 'silver',
      name: 'Silver Alchemist',
      proOnly: true,
      bg: Color(0xFF22242A),
      bgDeep: Color(0xFF14161B),
      shelf: Color(0xFF181A20),
      metalLight: Color(0xFFC8CCD8),
      metalDeep: Color(0xFF8A90A0),
      metalBorder: Color(0xFF4A4E58),
      parchment: Color(0xFFDCDCE0),
      parchmentDim: Color(0xFFC2C2C8),
      ink: Color(0xFF14161B),
      paletteId: 'ocean',
      glassId: 'flask',
    ),
    ApothecaryThemeDef(
      id: 'forest',
      name: 'Forest Apothecary',
      proOnly: true,
      bg: Color(0xFF1E2A1A),
      bgDeep: Color(0xFF121A0E),
      shelf: Color(0xFF16200F),
      metalLight: Color(0xFFB89A5A),
      metalDeep: Color(0xFF7A6230),
      metalBorder: Color(0xFF463A18),
      parchment: Color(0xFFE2D6B4),
      parchmentDim: Color(0xFFC8BA94),
      ink: Color(0xFF121A0E),
      paletteId: 'herb',
      glassId: 'jar',
    ),
    ApothecaryThemeDef(
      id: 'desert',
      name: 'Desert Caravan',
      proOnly: true,
      bg: Color(0xFF3A2415),
      bgDeep: Color(0xFF241408),
      shelf: Color(0xFF2A1A0C),
      metalLight: Color(0xFFD9A45A),
      metalDeep: Color(0xFF9C6E2E),
      metalBorder: Color(0xFF5C4218),
      parchment: Color(0xFFF0DCB8),
      parchmentDim: Color(0xFFD8C096),
      ink: Color(0xFF241408),
      paletteId: 'spice',
      glassId: 'coupe',
    ),
    ApothecaryThemeDef(
      id: 'plum',
      name: 'Plum Cellar',
      proOnly: true,
      bg: Color(0xFF2A1A24),
      bgDeep: Color(0xFF180E14),
      shelf: Color(0xFF1E1218),
      metalLight: Color(0xFFB88A6B),
      metalDeep: Color(0xFF7A5440),
      metalBorder: Color(0xFF463026),
      parchment: Color(0xFFE4D2C4),
      parchmentDim: Color(0xFFC8B4A4),
      ink: Color(0xFF180E14),
      paletteId: 'berry',
      glassId: 'decanter',
    ),
    ApothecaryThemeDef(
      id: 'seaglass',
      name: 'Sea Glass',
      proOnly: true,
      bg: Color(0xFF16242A),
      bgDeep: Color(0xFF0C1418),
      shelf: Color(0xFF101A1E),
      metalLight: Color(0xFF9AB8B0),
      metalDeep: Color(0xFF5E7A74),
      metalBorder: Color(0xFF35463F),
      parchment: Color(0xFFD8DCD2),
      parchmentDim: Color(0xFFBCC0B4),
      ink: Color(0xFF0C1418),
      paletteId: 'ocean',
      glassId: 'flask',
    ),
    ApothecaryThemeDef(
      id: 'hearth',
      name: 'Winter Hearth',
      proOnly: true,
      bg: Color(0xFF241A14),
      bgDeep: Color(0xFF140D08),
      shelf: Color(0xFF1A120C),
      metalLight: Color(0xFFC89A6B),
      metalDeep: Color(0xFF8C6238),
      metalBorder: Color(0xFF503A1E),
      parchment: Color(0xFFE8D8C0),
      parchmentDim: Color(0xFFCCB89E),
      ink: Color(0xFF140D08),
      paletteId: 'dusk',
      glassId: 'jar',
    ),
    ApothecaryThemeDef(
      id: 'verdant',
      name: 'Verdant Conservatory',
      proOnly: true,
      bg: Color(0xFF1A2A1E),
      bgDeep: Color(0xFF0E180F),
      shelf: Color(0xFF121E12),
      metalLight: Color(0xFFA8B86B),
      metalDeep: Color(0xFF6E7A3E),
      metalBorder: Color(0xFF424A24),
      parchment: Color(0xFFE6DCB8),
      parchmentDim: Color(0xFFCAC096),
      ink: Color(0xFF0E180F),
      paletteId: 'meadow',
      glassId: 'coupe',
    ),
    ApothecaryThemeDef(
      id: 'library',
      name: 'Old Library',
      proOnly: true,
      bg: Color(0xFF2E2015),
      bgDeep: Color(0xFF1C1209),
      shelf: Color(0xFF221608),
      metalLight: Color(0xFFB89A5A),
      metalDeep: Color(0xFF7A6230),
      metalBorder: Color(0xFF463A18),
      parchment: Color(0xFFEADCB4),
      parchmentDim: Color(0xFFD0BE94),
      ink: Color(0xFF1C1209),
      paletteId: 'orchard',
      glassId: 'decanter',
    ),
    ApothecaryThemeDef(
      id: 'distillery',
      name: 'Midnight Distillery',
      proOnly: true,
      bg: Color(0xFF141420),
      bgDeep: Color(0xFF0A0A12),
      shelf: Color(0xFF0E0E16),
      metalLight: Color(0xFF8A90B8),
      metalDeep: Color(0xFF54587A),
      metalBorder: Color(0xFF2E3046),
      parchment: Color(0xFFD2D2DC),
      parchmentDim: Color(0xFFB4B4BE),
      ink: Color(0xFF0A0A12),
      paletteId: 'dusk',
      glassId: 'flute',
    ),
  ];

  static ApothecaryThemeDef byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);

  /// Builds the player's custom theme on top of a base theme (custom name,
  /// palette and glass overrides).
  static ApothecaryThemeDef custom({
    required String name,
    required String baseId,
    required String paletteId,
    required String glassId,
  }) {
    final base = byId(baseId);
    return ApothecaryThemeDef(
      id: 'custom',
      name: name.isEmpty ? 'My Cabinet' : name,
      bg: base.bg,
      bgDeep: base.bgDeep,
      shelf: base.shelf,
      metalLight: base.metalLight,
      metalDeep: base.metalDeep,
      metalBorder: base.metalBorder,
      parchment: base.parchment,
      parchmentDim: base.parchmentDim,
      ink: base.ink,
      paletteId: paletteId,
      glassId: glassId,
    );
  }
}
