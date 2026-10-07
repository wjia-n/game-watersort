import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Water Sort — pour the rainbow back into perfect tubes. 🧪
class WaterSortScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const WaterSortScreen(
      {super.key, required this.players, required this.callbacks});

  @override
  State<WaterSortScreen> createState() => _WaterSortScreenState();
}

class _WaterSortScreenState extends State<WaterSortScreen> {
  static const int _cap = 4;

  int? _level; // null => level select
  List<List<int>> _tubes = [];
  int _selected = -1;
  final List<List<List<int>>> _history = [];
  bool _pouring = false;
  int _pourStep = 0;
  int _pourFrom = 0, _pourTo = 0, _pourUnits = 0;
  int _moves = 0;
  bool _over = false;
  Set<int> _done = {};
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      _prefs = p;
      setState(() {
        _done = (p.getStringList('watersort_done') ?? [])
            .map(int.parse)
            .toSet();
      });
      final cur = p.getInt('watersort_current');
      if (cur != null && cur >= 0 && cur < _wsLevels.length) {
        _openLevel(cur, silent: true);
      }
    });
  }

  List<Color> _palette(GameTheme t) {
    final base = HSLColor.fromColor(t.primary);
    return List.generate(8, (i) {
      final h = (base.hue + i * (360 / 8) + 360) % 360;
      return HSLColor.fromAHSL(1, h, 0.68, t.dark ? 0.58 : 0.52).toColor();
    });
  }

  void _openLevel(int i, {bool silent = false}) {
    setState(() {
      _level = i;
      _tubes = _wsLevels[i].map((t) => List<int>.of(t)).toList();
      _selected = -1;
      _history.clear();
      _moves = 0;
      _over = false;
      _pouring = false;
    });
    _prefs?.setInt('watersort_current', i);
    if (!silent) Sfx.click();
  }

  void _backToSelect() {
    setState(() => _level = null);
    Sfx.tap();
  }

  List<List<int>> _snap() => _tubes.map((t) => List<int>.of(t)).toList();

  bool _canPour(int s, int d) {
    if (s == d || _tubes[s].isEmpty || _tubes[d].length >= _cap) return false;
    return _tubes[d].isEmpty || _tubes[d].last == _tubes[s].last;
  }

  void _tapTube(int i) {
    if (_pouring || _over || _level == null) return;
    if (_selected == -1) {
      if (_tubes[i].isEmpty) return;
      setState(() => _selected = i);
      Sfx.tap();
      return;
    }
    if (_selected == i) {
      setState(() => _selected = -1);
      Sfx.tap();
      return;
    }
    final s = _selected, d = i;
    setState(() => _selected = -1);
    if (!_canPour(s, d)) {
      Sfx.click();
      return;
    }
    _history.add(_snap());
    if (_history.length > 60) _history.removeAt(0);
    // how many units will move
    final c = _tubes[s].last;
    var n = 0;
    for (var k = _tubes[s].length - 1; k >= 0 && _tubes[s][k] == c; k--) {
      n++;
    }
    n = n.clamp(1, _cap - _tubes[d].length);
    setState(() {
      _pouring = true;
      _pourFrom = s;
      _pourTo = d;
      _pourUnits = n;
      _pourStep = 0;
      _moves++;
    });
  }

  void _dropLanded() {
    if (!mounted || !_pouring) return;
    setState(() {
      final unit = _tubes[_pourFrom].removeLast();
      _tubes[_pourTo].add(unit);
      Sfx.move();
      if (_pourStep + 1 < _pourUnits) {
        _pourStep++;
      } else {
        _pouring = false;
        _checkWin();
      }
    });
  }

  void _undo() {
    if (_pouring || _over || _history.isEmpty) return;
    setState(() {
      _tubes = _history.removeLast();
      _selected = -1;
      _moves = (_moves - 1).clamp(0, 9999);
    });
    Sfx.tap();
  }

  bool _isWin() {
    for (final t in _tubes) {
      if (t.isEmpty) continue;
      if (t.length != _cap || t.any((x) => x != t.first)) return false;
    }
    return true;
  }

  void _checkWin() {
    if (!_isWin() || _over) return;
    setState(() => _over = true);
    Sfx.win();
    final lv = _level!;
    _done.add(lv);
    _prefs?.setStringList(
        'watersort_done', _done.map((e) => e.toString()).toList());
    _prefs?.setInt('watersort_current',
        lv + 1 < _wsLevels.length ? lv + 1 : lv);
    final isLast = lv == _wsLevels.length - 1;
    widget.callbacks.finish(
      headline: 'Level ${lv + 1} sorted! 🧪✨',
      subline: isLast
          ? 'You beautiful chemist, you sorted them ALL! 🏆'
          : 'Squeaky clean! Level ${lv + 2} is waiting for you 👀',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    if (_level == null) return _selectScreen(t);
    return _gameScreen(t);
  }

  // ---------------- level select ----------------
  Widget _selectScreen(GameTheme t) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pick your potion 🧪',
              style: TextStyle(
                  color: t.text, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('${_done.length}/${_wsLevels.length} tubes tamed',
              style: TextStyle(color: t.muted, fontSize: 14)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12),
              itemCount: _wsLevels.length,
              itemBuilder: (_, i) {
                final done = _done.contains(i);
                final colors = _wsLevels[i].length - 2;
                return GestureDetector(
                  onTap: () => _openLevel(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: done
                          ? t.primary.withValues(alpha: 0.22)
                          : t.surface,
                      borderRadius: t.radius,
                      border: Border.all(
                          color: t.primary.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(done ? '✅' : '🧪',
                            style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text('Level ${i + 1}',
                            style: TextStyle(
                                color: t.text,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                        Text('$colors colors',
                            style:
                                TextStyle(color: t.muted, fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- game ----------------
  Widget _gameScreen(GameTheme t) {
    final pal = _palette(t);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              _iconBtn(t, '◀️', _backToSelect),
              const SizedBox(width: 8),
              Text('Level ${_level! + 1}',
                  style: TextStyle(
                      color: t.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const Spacer(),
              Text('$_moves moves',
                  style: TextStyle(color: t.muted, fontSize: 13)),
              const SizedBox(width: 8),
              _iconBtn(t, '↩️', _history.isEmpty ? null : _undo,
                  disabled: _history.isEmpty),
              const SizedBox(width: 8),
              _iconBtn(t, '🔄', () => _openLevel(_level!)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Tap a tube, then tap where it goes 💧',
              style: TextStyle(color: t.muted, fontSize: 13)),
          const SizedBox(height: 8),
          Expanded(child: _board(t, pal)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _iconBtn(GameTheme t, String emoji, VoidCallback? onTap,
      {bool disabled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.35 : 1,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: t.surface,
              borderRadius: t.radius,
              border:
                  Border.all(color: t.primary.withValues(alpha: 0.3))),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }

  Widget _board(GameTheme t, List<Color> pal) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = _tubes.length;
        final cellW = c.maxWidth / n;
        final tubeW = (cellW - 10).clamp(34.0, 58.0);
        const tubeH = 208.0;
        const unitH = 46.0;
        double cx(int i) => cellW * (i + 0.5);
        const mouthY = 44.0; // droplet flight height above tubes
        return Stack(
          children: [
            Positioned.fill(
              child: Row(
                children: [
                  for (var i = 0; i < n; i++)
                    SizedBox(
                      width: cellW,
                      child: Center(child: _tube(i, t, pal, tubeW, tubeH, unitH)),
                    ),
                ],
              ),
            ),
            if (_pouring)
              TweenAnimationBuilder<double>(
                key: ValueKey(_pourStep),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 170),
                onEnd: _dropLanded,
                builder: (_, v, _) {
                  final x0 = cx(_pourFrom);
                  final x1 = cx(_pourTo);
                  final x = x0 + (x1 - x0) * v;
                  final y = mouthY - 30 * (1 - (2 * v - 1) * (2 * v - 1));
                  return Positioned(
                    left: x - 9,
                    top: y,
                    child: Container(
                      width: 18,
                      height: 22,
                      decoration: BoxDecoration(
                        color: pal[_tubes[_pourFrom].last],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(9),
                          bottomRight: Radius.circular(9),
                          topLeft: Radius.circular(9),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _tube(int i, GameTheme t, List<Color> pal, double w, double h,
      double unitH) {
    final units = _tubes[i];
    final sel = _selected == i;
    return GestureDetector(
      onTap: () => _tapTube(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, sel ? -18 : 0, 0),
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: t.surface.withValues(alpha: 0.55),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(26),
            bottomRight: Radius.circular(26),
          ),
          border: Border.all(
            color: sel ? t.accent : t.primary.withValues(alpha: 0.35),
            width: sel ? 3 : 2,
          ),
          boxShadow: sel
              ? [
                  BoxShadow(
                      color: t.accent.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6))
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (var k = 0; k < units.length; k++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  height: unitH,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 3, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: pal[units[k]],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              SizedBox(height: (_cap - units.length) * (unitH + 3)),
            ],
          ),
        ),
      ),
    );
  }
}
// ===== WATER SORT LEVELS =====
const _wsLevels = <List<List<int>>>[
  [[1,2,2,0],[2,1,0,2],[1,0,1,0],[],[]], // 3 colors
  [[1,1,2,1],[1,2,2,0],[0,0,2,0],[],[]], // 3 colors
  [[0,0,2,2],[1,3,3,3],[0,3,2,1],[1,2,0,1],[],[]], // 4 colors
  [[3,2,0,1],[3,0,2,2],[3,1,3,1],[2,0,1,0],[],[]], // 4 colors
  [[2,1,3,2],[4,0,0,3],[4,0,1,2],[3,2,0,4],[3,4,1,1],[],[]], // 5 colors
  [[4,0,2,4],[0,4,1,2],[0,3,2,0],[3,4,1,1],[3,3,1,2],[],[]], // 5 colors
  [[5,2,1,4],[1,5,5,1],[3,3,3,0],[0,3,4,2],[5,4,0,2],[2,1,0,4],[],[]], // 6 colors
  [[0,5,2,4],[3,4,5,2],[3,1,0,1],[3,4,5,1],[2,5,0,0],[4,3,1,2],[],[]], // 6 colors
  [[0,5,2,6],[5,1,5,6],[1,0,4,5],[3,6,6,3],[2,1,4,4],[1,3,3,4],[2,0,2,0],[],[]], // 7 colors
  [[4,2,4,5],[1,2,0,1],[6,0,1,4],[0,6,0,3],[4,6,1,5],[6,3,5,2],[2,3,3,5],[],[]], // 7 colors
  [[0,3,5,3],[4,0,7,2],[1,6,6,2],[4,0,6,7],[2,3,5,1],[5,6,5,7],[0,7,3,1],[4,1,2,4],[],[]], // 8 colors
  [[0,0,6,3],[7,5,2,1],[3,7,6,0],[4,3,4,2],[3,5,1,6],[0,7,5,2],[1,4,5,2],[4,1,6,7],[],[]], // 8 colors
];
