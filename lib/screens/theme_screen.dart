import 'package:flutter/material.dart';

import '../apothecary.dart';
import '../audio.dart';
import '../settings.dart';
import '../themes.dart';
import '../widgets/brass.dart';
import '../widgets/cabinet.dart';
import '../widgets/vial_widget.dart';

/// Theme atelier: cabinet themes, liquid palettes, glass styles, and the
/// PRO custom theme creator. Everything is previewed live in the
/// apothecary material world.
class ThemeScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onPro;

  const ThemeScreen({super.key, required this.onBack, required this.onPro});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  // Custom creator draft.
  final _nameCtrl = TextEditingController();
  String _draftBase = 'classic';
  String _draftPalette = 'apothecary';
  String _draftGlass = 'flute';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    final t = s.theme;
    return CabinetBackground(
      theme: t,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  BrassIconButton(
                    icon: Icons.arrow_back,
                    size: 42,
                    theme: t,
                    onTap: () {
                      ApothecaryAudio.instance.click();
                      widget.onBack();
                    },
                  ),
                  const SizedBox(width: 12),
                  Text('THEME ATELIER',
                      style: ApothecaryText.display(22, color: t.parchment)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListenableBuilder(
                listenable: s,
                builder: (_, _) => ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  children: [
                    _sectionTitle(t, 'CABINET THEMES'),
                    const SizedBox(height: 8),
                    _themeGrid(s, t),
                    const SizedBox(height: 18),
                    _sectionTitle(t, 'LIQUID PALETTES'),
                    const SizedBox(height: 8),
                    _paletteList(s, t),
                    const SizedBox(height: 18),
                    _sectionTitle(t, 'GLASS STYLES'),
                    const SizedBox(height: 8),
                    _glassList(s, t),
                    const SizedBox(height: 18),
                    _sectionTitle(t, 'CUSTOM BLEND (PRO)'),
                    const SizedBox(height: 8),
                    _customCreator(s, t),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ApothecaryThemeDef t, String text) => Text(text,
      style: ApothecaryText.engraved(15, color: t.parchment));

  bool _lockedFor(bool proOnly) =>
      proOnly && !AppSettings.instance.isPro;

  void _needPro() {
    ApothecaryAudio.instance.clink();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('That one is PRO — unlock the full cabinet.',
            style: ApothecaryText.engraved(13, color: _t.ink)),
        backgroundColor: _t.parchment,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'PRO',
          onPressed: widget.onPro,
        ),
      ),
    );
  }

  ApothecaryThemeDef get _t => AppSettings.instance.theme;

  // ------------------------------------------------------------ themes grid
  Widget _themeGrid(AppSettings s, ApothecaryThemeDef t) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemCount: ApothecaryThemes.all.length,
      itemBuilder: (_, i) {
        final th = ApothecaryThemes.all[i];
        final active = s.themeId == th.id && !s.customEnabled;
        final locked = _lockedFor(th.proOnly);
        return GestureDetector(
          onTap: () {
            if (locked) {
              _needPro();
              return;
            }
            ApothecaryAudio.instance.click();
            s.setTheme(th.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: th.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? th.metalLight : th.metalBorder,
                width: active ? 2.5 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 6,
                    offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    for (var k = 0; k < 4; k++)
                      Container(
                        width: 16,
                        height: 22,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: th.palette.of(k),
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: th.metalBorder, width: 1),
                        ),
                      ),
                    const Spacer(),
                    if (locked)
                      Icon(Icons.lock, size: 15, color: th.parchmentDim),
                    if (active)
                      Icon(Icons.check_circle,
                          size: 16, color: th.metalLight),
                  ],
                ),
                Text(th.name,
                    style: ApothecaryText.engraved(12, color: th.parchment)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------ palettes
  Widget _paletteList(AppSettings s, ApothecaryThemeDef t) {
    return Column(
      children: [
        for (final p in LiquidPalettes.all)
          _paletteRow(s, t, p),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Palettes recolor the tinctures inside your current cabinet.',
            style: ApothecaryText.plate(11, color: t.parchmentDim),
          ),
        ),
      ],
    );
  }

  Widget _paletteRow(AppSettings s, ApothecaryThemeDef t, LiquidPalette p) {
    final active = s.theme.paletteId == p.id;
    final locked = _lockedFor(p.proOnly);
    return GestureDetector(
      onTap: () {
        if (locked) {
          _needPro();
          return;
        }
        ApothecaryAudio.instance.click();
        // Keep the current cabinet, swap only the tincture palette via the
        // custom blend (free for the two free palettes).
        s.setCustomTheme(
          name: s.customEnabled ? s.customName : '',
          baseId: s.customEnabled ? s.customBaseId : s.themeId,
          paletteId: p.id,
          glassId: s.theme.glassId,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.bgDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? t.metalLight : t.metalBorder.withValues(alpha: 0.5),
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            for (var k = 0; k < 8; k++)
              Expanded(
                child: Container(
                  height: 26,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: p.of(k),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Text(p.name,
                  style: ApothecaryText.engraved(11, color: t.parchment)),
            ),
            if (locked) Icon(Icons.lock, size: 15, color: t.parchmentDim),
            if (active) Icon(Icons.check_circle, size: 16, color: t.metalLight),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ glass styles
  Widget _glassList(AppSettings s, ApothecaryThemeDef t) {
    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final g in GlassStyle.values) _glassCard(s, t, g),
        ],
      ),
    );
  }

  Widget _glassCard(AppSettings s, ApothecaryThemeDef t, GlassStyle g) {
    final active = s.theme.glassId == g.id;
    final locked = _lockedFor(g.proOnly);
    return GestureDetector(
      onTap: () {
        if (locked) {
          _needPro();
          return;
        }
        ApothecaryAudio.instance.click();
        s.setCustomTheme(
          name: s.customEnabled ? s.customName : '',
          baseId: s.customEnabled ? s.customBaseId : s.themeId,
          paletteId: s.theme.paletteId,
          glassId: g.id,
        );
      },
      child: Container(
        width: 92,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: t.bgDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? t.metalLight : t.metalBorder.withValues(alpha: 0.5),
            width: active ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 74,
              child: Opacity(
                opacity: locked ? 0.45 : 1,
                child: VialWidget(
                  units: const [0, 1, 2, 1],
                  width: 40,
                  height: 74,
                  palette: s.theme.palette,
                  glass: g,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (locked)
                  Icon(Icons.lock, size: 11, color: t.parchmentDim),
                Flexible(
                  child: Text(g.name,
                      overflow: TextOverflow.ellipsis,
                      style: ApothecaryText.engraved(9, color: t.parchment)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ custom blend
  Widget _customCreator(AppSettings s, ApothecaryThemeDef t) {
    if (!s.isPro) {
      return ParchmentCard(
        theme: t,
        child: Column(
          children: [
            Text('Blend your own cabinet',
                style: ApothecaryText.engraved(14, color: t.ink)),
            const SizedBox(height: 6),
            const Text(
              'Pick any base cabinet, any tincture palette and any glass — '
              'then bottle it under your own name.',
              textAlign: TextAlign.center,
              style: ApothecaryText.bodyInk,
            ),
            const SizedBox(height: 10),
            BrassButton(
              theme: t,
              label: 'Unlock with PRO',
              fontSize: 13,
              onTap: () {
                ApothecaryAudio.instance.click();
                widget.onPro();
              },
            ),
          ],
        ),
      );
    }
    return ParchmentCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR BLEND', style: ApothecaryText.engraved(14, color: t.ink)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'Name your cabinet…',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: ApothecaryText.bodyInk,
          ),
          const SizedBox(height: 10),
          _draftPicker(t, 'Base cabinet',
              ApothecaryThemes.all.map((e) => e.id).toList(),
              (id) => ApothecaryThemes.byId(id).name, _draftBase,
              (v) => setState(() => _draftBase = v)),
          const SizedBox(height: 8),
          _draftPicker(t, 'Tinctures',
              LiquidPalettes.all.map((e) => e.id).toList(),
              (id) => LiquidPalettes.byId(id).name, _draftPalette,
              (v) => setState(() => _draftPalette = v)),
          const SizedBox(height: 8),
          _draftPicker(t, 'Glass',
              GlassStyle.values.map((e) => e.id).toList(),
              (id) => GlassStyle.byId(id).name, _draftGlass,
              (v) => setState(() => _draftGlass = v)),
          const SizedBox(height: 12),
          Center(
            child: BrassButton(
              theme: t,
              label: 'Bottle this blend',
              fontSize: 13,
              onTap: () {
                ApothecaryAudio.instance.pop();
                s.setCustomTheme(
                  name: _nameCtrl.text,
                  baseId: _draftBase,
                  paletteId: _draftPalette,
                  glassId: _draftGlass,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Your blend is on the shelf.',
                        style:
                            ApothecaryText.engraved(13, color: t.ink)),
                    backgroundColor: t.parchment,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _draftPicker(
      ApothecaryThemeDef t,
      String label,
      List<String> ids,
      String Function(String) nameOf,
      String value,
      ValueChanged<String> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(label,
              style: ApothecaryText.engraved(11, color: t.ink)),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: t.metalBorder),
              borderRadius: BorderRadius.circular(8),
              color: t.parchmentDim.withValues(alpha: 0.4),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              style: ApothecaryText.bodyInk.copyWith(fontSize: 13),
              dropdownColor: t.parchment,
              items: [
                for (final id in ids)
                  DropdownMenuItem(value: id, child: Text(nameOf(id))),
              ],
              onChanged: (v) {
                if (v != null) {
                  ApothecaryAudio.instance.click();
                  onChanged(v);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
