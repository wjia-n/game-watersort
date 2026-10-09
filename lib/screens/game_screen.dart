import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../apothecary.dart';
import '../audio.dart';
import '../engine.dart';
import '../levels.dart';
import '../progress.dart';
import '../settings.dart';
import '../widgets/brass.dart';
import '../widgets/cabinet.dart';
import '../widgets/vial_widget.dart';

/// Apothecary gameplay screen: brass HUD, vials on carved walnut shelves,
/// pour animation with weight, pause / victory overlays.
class GameScreen extends StatefulWidget {
  final int level;
  final VoidCallback onExit;
  final void Function(int nextLevel) onNextLevel;

  const GameScreen({
    super.key,
    required this.level,
    required this.onExit,
    required this.onNextLevel,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _BoardGeom {
  final double boardW, boardH;
  final int vials, perRow, rows;
  late final double cellW, vialW, vialH, rowH;
  _BoardGeom(this.boardW, this.boardH, this.vials)
      : perRow = vials <= 4 ? vials : (vials / 2).ceil(),
        rows = vials <= 4 ? 1 : 2 {
    cellW = boardW / perRow;
    vialW = min(cellW * 0.64, 78.0);
    rowH = boardH / rows;
    vialH = min(rowH * 0.80, 236.0).clamp(150.0, 236.0);
  }

  Offset vialCenter(int i) {
    final row = i ~/ perRow;
    final col = i % perRow;
    // center the last row if it is short
    final inRow = row == rows - 1 ? vials - row * perRow : perRow;
    final x0 = (boardW - inRow * cellW) / 2;
    return Offset(x0 + (col + 0.5) * cellW, row * rowH + rowH * 0.44);
  }

  /// Shelf plank rect for a row (the vial sits on it).
  Rect shelfRect(int row) => Rect.fromLTWH(
      8, row * rowH + rowH * 0.44 + vialH / 2 - 6, boardW - 16, 22);
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late WaterSortEngine _engine;
  late int _par;
  int _selected = -1;
  int? _lastFrom, _lastTo;

  // pour animation
  bool _pouring = false;
  int _pourFrom = 0, _pourTo = 0, _pourUnits = 0, _pourColor = 0;
  List<int> _animFromUnits = const [];
  List<int> _animToUnits = const [];
  AnimationController? _pourCtrl;

  // invalid shake
  int _shakeIndex = -1;
  late AnimationController _shakeCtrl;

  // hint
  int _hintFrom = -1, _hintTo = -1;
  Timer? _hintTimer;

  bool _paused = false;
  bool _pauseDialogOpen = false;
  bool _over = false;
  int _addVialUses = 1;
  int _extraVials = 0;
  int _stars = 0;
  bool _perfect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _shakeCtrl.addListener(() => setState(() {}));
    _startLevel(widget.level);
    ApothecaryAudio.instance.playMusic('music_game.wav');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pourCtrl?.dispose();
    _shakeCtrl.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_pouring) _finishPour(instant: true);
      _showPause();
    }
  }

  /// Shows the pause dialog (idempotent); blocks board input while open.
  void _showPause() {
    if (_pauseDialogOpen || _over || _pouring || !mounted) return;
    _pauseDialogOpen = true;
    setState(() => _paused = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _pauseCard(),
    ).then((_) {
      _pauseDialogOpen = false;
      if (mounted) setState(() => _paused = false);
    });
  }

  void _startLevel(int level) {
    _engine = WaterSortEngine(kLevels[level]);
    _par = parForLevel(kLevels[level]);
    _selected = -1;
    _lastFrom = _lastTo = null;
    _pouring = false;
    _over = false;
    _paused = false;
    _stars = 0;
    _perfect = false;
    _extraVials = 0;
    _addVialUses = AppSettings.instance.addVialUsesPerLevel;
    _hintFrom = _hintTo = -1;
    ApothecaryAudio.instance.start();
  }

  void _buzz([bool heavy = false]) {
    if (!AppSettings.instance.vibration) return;
    if (heavy) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  // ---------------- input ----------------
  void _tapVial(int i) {
    if (_pouring || _over || _paused) return;
    final audio = ApothecaryAudio.instance;
    if (_selected == -1) {
      if (_engine.vials[i].isEmpty) return; // nothing to lift
      if (_engine.isCompleteVial(i)) {
        // RULES.md §4.4 / test #3: locked vials reject selection
        _engine.illegalAttempts++;
        _invalidFeedback(i);
        return;
      }
      setState(() => _selected = i);
      _buzz();
      audio.click();
      return;
    }
    if (_selected == i) {
      setState(() => _selected = -1);
      audio.click();
      return;
    }
    final s = _selected, d = i;
    setState(() => _selected = -1);
    if (_engine.legality(s, d) != PourOutcome.ok) {
      _engine.illegalAttempts++;
      _invalidFeedback(d);
      return;
    }
    _beginPour(s, d);
  }

  void _invalidFeedback(int vial) {
    _buzz(true);
    ApothecaryAudio.instance.clink();
    setState(() => _shakeIndex = vial);
    _shakeCtrl.forward(from: 0);
  }

  void _beginPour(int s, int d) {
    final n = _engine.pourAmount(s, d);
    if (n == 0) {
      _engine.illegalAttempts++;
      _invalidFeedback(d);
      return;
    }
    _animFromUnits = List<int>.of(_engine.vials[s]);
    _animToUnits = List<int>.of(_engine.vials[d]);
    _pourColor = _engine.vials[s].last;
    _engine.pour(s, d); // state -> final; visuals interpolate below
    _lastFrom = s;
    _lastTo = d;
    _pourFrom = s;
    _pourTo = d;
    _pourUnits = n;
    _buzz();
    setState(() => _pouring = true);
    _pourCtrl?.dispose();
    _pourCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 420 + n * 170),
    )..addListener(_onPourTick);
    _pourCtrl!.addStatusListener((st) {
      if (st == AnimationStatus.completed) _finishPour();
    });
    _pourCtrl!.forward();
  }

  int _landedUnits() {
    final p = _pourCtrl?.value ?? 1.0;
    if (p <= 0.22) return 0;
    if (p >= 0.85) return _pourUnits;
    return (((p - 0.22) / 0.63) * _pourUnits).floor().clamp(0, _pourUnits);
  }

  int _lastLanded = 0;

  void _onPourTick() {
    final landed = _landedUnits();
    if (landed > _lastLanded) {
      _lastLanded = landed;
      // glug per landed unit; pitch bends with destination fill
      final fill = (_animToUnits.length + landed) / kCapacity;
      ApothecaryAudio.instance.pour(fill.clamp(0.0, 1.0));
    }
    setState(() {});
  }

  void _finishPour({bool instant = false}) {
    if (!_pouring) return;
    _pourCtrl?.stop();
    setState(() {
      _pouring = false;
      _lastLanded = 0;
    });
    if (_engine.isWon) {
      Future.delayed(
          Duration(milliseconds: instant ? 50 : 350), _onWin);
    }
  }

  void _undo() {
    if (_pouring || _over || _paused || !_engine.canUndo) return;
    _engine.undo();
    _lastFrom = _lastTo = null;
    setState(() => _selected = -1);
    _buzz();
    ApothecaryAudio.instance.undo();
  }

  void _restart() {
    if (_pouring) return;
    _pourCtrl?.stop();
    setState(() => _pouring = false);
    _startLevel(widget.level);
    setState(() => _paused = false);
    _buzz();
  }

  void _addVial() {
    if (_pouring || _over || _paused) return;
    final audio = ApothecaryAudio.instance;
    if (_extraVials >= 2) {
      _showNote('The shelf holds no more vials.');
      audio.clink();
      return;
    }
    if (_addVialUses <= 0) {
      _showNote('No spare vials left for this recipe.');
      audio.clink();
      return;
    }
    _engine.addVial();
    _extraVials++;
    _addVialUses--;
    setState(() {});
    _buzz();
    audio.pop();
  }

  void _hint() {
    if (_pouring || _over || _paused) return;
    final h = _engine.hint(lastFrom: _lastFrom, lastTo: _lastTo);
    final audio = ApothecaryAudio.instance;
    if (h == null) {
      _showNote('No helpful pour found — trust your nose.');
      audio.clink();
      return;
    }
    setState(() {
      _hintFrom = h.$1;
      _hintTo = h.$2;
    });
    _buzz();
    audio.click();
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hintFrom = _hintTo = -1);
    });
  }

  void _showNote(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: ApothecaryText.bodyInk),
        backgroundColor: Apothecary.parchment,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onWin() async {
    if (_over || !mounted) return;
    setState(() => _over = true);
    _stars = WaterSortEngine.starsFor(_engine.moves, _par);
    _perfect = _engine.undosUsed == 0 && _engine.illegalAttempts == 0;
    _buzz(true);
    final audio = ApothecaryAudio.instance;
    await audio.pop();
    if (_stars == 3) await audio.chime();
    final progress = ProgressStore.instance;
    await progress.recordCompletion(widget.level, _stars, _perfect);
    if (widget.level + 1 < kLevels.length) {
      await progress.setCurrent(widget.level + 1);
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _victoryCard(),
    );
  }

  // ---------------- build ----------------
  @override
  Widget build(BuildContext context) {
    return CabinetBackground(
      child: SafeArea(
        child: Column(
          children: [
            _hud(),
            const SizedBox(height: 4),
            Expanded(child: _boardArea()),
            _actionBar(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _hud() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          BrassPlate(
            child: Text('Nº ${widget.level + 1}',
                style: ApothecaryText.engraved(15)),
          ),
          const SizedBox(width: 8),
          BrassPlate(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_engine.moves}',
                    style: ApothecaryText.plate(15)),
                const SizedBox(width: 6),
                Text('MOVES',
                    style: ApothecaryText.plate(10,
                        color: Apothecary.inkBrown
                            .withValues(alpha: 0.75))),
              ],
            ),
          ),
          const Spacer(),
          BrassIconButton(
              icon: Icons.pause,
              size: 44,
              onTap: _pouring || _over
                  ? null
                  : () {
                      _buzz();
                      ApothecaryAudio.instance.click();
                      _showPause();
                    }),
          const SizedBox(width: 8),
          BrassIconButton(
              icon: Icons.refresh,
              size: 44,
              onTap: _pouring || _over ? null : _restart),
        ],
      ),
    );
  }

  Widget _boardArea() {
    return LayoutBuilder(
      builder: (context, c) {
        final geom = _BoardGeom(
            c.maxWidth, c.maxHeight, _engine.vialCount);
        return Stack(
          children: [
            // carved shelf planks
            for (var r = 0; r < geom.rows; r++)
              Positioned.fromRect(
                rect: geom.shelfRect(r),
                child: CustomPaint(painter: _ShelfPainter()),
              ),
            // vials
            for (var i = 0; i < _engine.vialCount; i++)
              _positionedVial(geom, i),
            // pour stream overlay
            if (_pouring && _pourCtrl != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _StreamPainter(
                    from: _mouth(geom, _pourFrom, true),
                    to: _mouth(geom, _pourTo, false),
                    progress: _pourCtrl!.value,
                    colorIdx: _pourColor,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Mouth position of a vial in board coordinates (tilted while pouring).
  Offset _mouth(_BoardGeom geom, int i, bool isSource) {
    final c = geom.vialCenter(i);
    var dx = 0.0;
    if (_pouring && isSource && i == _pourFrom) {
      final dir = (_pourTo > _pourFrom) ? 1.0 : -1.0;
      dx = dir * geom.vialW * 0.45 * _tiltAmount();
    }
    return Offset(c.dx + dx, c.dy - geom.vialH / 2 + 6);
  }

  double _tiltAmount() {
    final p = _pourCtrl?.value ?? 0.0;
    if (p < 0.25) return p / 0.25;
    if (p > 0.85) return (1 - p) / 0.15;
    return 1.0;
  }

  Widget _positionedVial(_BoardGeom geom, int i) {
    final c = geom.vialCenter(i);
    // visual unit counts (interpolated during pour)
    List<int> units = _engine.vials[i];
    if (_pouring) {
      if (i == _pourFrom) {
        units = _animFromUnits.sublist(
            0, (_animFromUnits.length - _landedUnits()).clamp(0, 99));
      } else if (i == _pourTo) {
        units = [
          ..._animToUnits,
          ...List.filled(_landedUnits(), _pourColor),
        ];
      }
    }
    final locked = _engine.isCompleteVial(i) &&
        !(_pouring && (i == _pourFrom || i == _pourTo));
    final selected = _selected == i;
    final hinted = i == _hintFrom || i == _hintTo;

    var dx = 0.0, dy = 0.0, rot = 0.0;
    if (selected) dy = -18;
    if (_pouring && i == _pourFrom) {
      final dir = (_pourTo > _pourFrom) ? 1.0 : -1.0;
      final t = _tiltAmount();
      dy = -26 * t;
      dx = dir * geom.vialW * 0.42 * t;
      rot = dir * 0.5 * t;
    }
    if (i == _shakeIndex && _shakeCtrl.isAnimating) {
      final p = _shakeCtrl.value;
      dx += sin(p * pi * 3) * 9 * (1 - p);
    }

    return Positioned(
      left: c.dx - geom.vialW / 2,
      top: c.dy - geom.vialH / 2,
      child: GestureDetector(
        onTap: () => _tapVial(i),
        child: Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: rot,
            alignment: const Alignment(0, -0.9),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: hinted ? const EdgeInsets.all(3) : EdgeInsets.zero,
              decoration: hinted
                  ? BoxDecoration(
                      border: Border.all(
                          color: Apothecary.brassLight, width: 2.5),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: VialWidget(
                units: units,
                width: geom.vialW,
                height: geom.vialH,
                locked: locked,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBar() {
    final canAdd = _extraVials < 2 && _addVialUses > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ParchmentTag(
            label: 'Undo',
            icon: Icons.undo,
            onTap: _engine.canUndo && !_pouring && !_over && !_paused
                ? _undo
                : null,
          ),
          const SizedBox(width: 10),
          // brass spoon hint
          GestureDetector(
            onTap: _pouring || _over || _paused ? null : _hint,
            child: Opacity(
              opacity: _pouring || _over || _paused ? 0.4 : 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Apothecary.brassLight,
                      Apothecary.brassDeep
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Apothecary.brassBorder, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 6,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.restaurant_menu,
                        size: 18, color: Apothecary.inkBrown),
                    const SizedBox(width: 6),
                    Text('HINT',
                        style: ApothecaryText.engraved(12)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ParchmentTag(
            label: _addVialUses > 0
                ? 'Add Vial ($_addVialUses)'
                : 'Add Vial',
            icon: Icons.add,
            onTap: canAdd ? _addVial : null,
          ),
        ],
      ),
    );
  }

  Widget _pauseCard() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ParchmentCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PAUSED', style: ApothecaryText.engraved(24)),
            const SizedBox(height: 6),
            Text('The tinctures wait patiently.',
                style: ApothecaryText.bodyInk.copyWith(fontSize: 13)),
            const SizedBox(height: 16),
            BrassButton(
              label: 'Resume',
              onTap: () {
                ApothecaryAudio.instance.click();
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ParchmentTag(
                    label: 'Restart',
                    icon: Icons.refresh,
                    onTap: () {
                      Navigator.of(context).pop();
                      _restart();
                    }),
                const SizedBox(width: 10),
                ParchmentTag(
                    label: 'Cabinet',
                    icon: Icons.home,
                    onTap: () {
                      ApothecaryAudio.instance.click();
                      Navigator.of(context).pop();
                      widget.onExit();
                    }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _victoryCard() {
    final isLast = widget.level + 1 >= kLevels.length;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ParchmentCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('RECIPE COMPLETE',
                textAlign: TextAlign.center,
                style: ApothecaryText.engraved(24)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var s = 0; s < 3; s++)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    child: StarSeal(earned: _stars > s, size: 52),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text('${_engine.moves} moves  ·  par $_par',
                style: ApothecaryText.plate(14,
                    color: Apothecary.inkBrown)),
            if (_perfect)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Apothecary.brassBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('✦ PERFECT POUR ✦',
                      style: ApothecaryText.engraved(12)),
                ),
              ),
            const SizedBox(height: 16),
            if (!isLast)
              BrassButton(
                label: 'Next Recipe',
                onTap: () {
                  ApothecaryAudio.instance.click();
                  Navigator.of(context).pop();
                  widget.onNextLevel(widget.level + 1);
                },
              )
            else
              Text('Every recipe bottled. The cabinet bows to you.',
                  textAlign: TextAlign.center,
                  style: ApothecaryText.bodyInk
                      .copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ParchmentTag(
                    label: 'Replay',
                    icon: Icons.replay,
                    onTap: () {
                      ApothecaryAudio.instance.click();
                      Navigator.of(context).pop();
                      _restart();
                    }),
                const SizedBox(width: 10),
                ParchmentTag(
                    label: 'Cabinet',
                    icon: Icons.home,
                    onTap: () {
                      ApothecaryAudio.instance.click();
                      Navigator.of(context).pop();
                      widget.onExit();
                    }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Carved walnut shelf plank with inner-shadow mortise and slots.
class _ShelfPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final plank = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(8));
    canvas.drawRRect(
        plank, Paint()..color = const Color(0xFF1E130B));
    // top edge highlight (carved lip catches candlelight)
    canvas.drawLine(
      const Offset(6, 2),
      Offset(size.width - 6, 2),
      Paint()
        ..strokeWidth = 2
        ..color = const Color(0x66D3AA66),
    );
    // inner shadow for depth
    canvas.drawRRect(
      plank,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.black.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Liquid stream with weight: tapered bezier + falling droplet.
class _StreamPainter extends CustomPainter {
  final Offset from, to;
  final double progress;
  final int colorIdx;

  _StreamPainter({
    required this.from,
    required this.to,
    required this.progress,
    required this.colorIdx,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // stream visible during the middle of the pour
    if (progress < 0.22 || progress > 0.9) return;
    final t = ((progress - 0.22) / 0.68).clamp(0.0, 1.0);
    final mid = Offset(
      (from.dx + to.dx) / 2,
      max(from.dy, to.dy) + 26,
    );
    final path = Path()..moveTo(from.dx, from.dy);
    // draw partial curve for a growing-stream feel
    const steps = 16;
    final drawTo = (steps * t).round().clamp(1, steps);
    Offset? prev;
    for (var i = 1; i <= drawTo; i++) {
      final u = i / steps;
      final p = _quad(from, mid, to, u);
      if (prev == null) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
      prev = p;
    }
    final width = 7 * (1 - t * 0.35);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = Apothecary.liquid(colorIdx).withValues(alpha: 0.92),
    );
    // droplet at the leading edge
    if (prev != null && t < 0.98) {
      canvas.drawCircle(
          prev,
          width * 0.55,
          Paint()..color = Apothecary.liquidLight(colorIdx));
    }
  }

  Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * b.dx + t * t * c.dx,
      u * u * a.dy + 2 * u * t * b.dy + t * t * c.dy,
    );
  }

  @override
  bool shouldRepaint(covariant _StreamPainter old) =>
      old.progress != progress || old.from != from || old.to != to;
}
