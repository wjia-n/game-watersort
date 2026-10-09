import 'package:flutter_test/flutter_test.dart';
import 'package:watersort/engine.dart';
import 'package:watersort/levels.dart';
import 'package:watersort/themes.dart';

/// RULES.md §13 test cases against the engine.
void main() {
  test('pour moves the whole top run into an empty vial', () {
    final e = WaterSortEngine([
      [1, 0, 0, 0], // top run: 0 x3
      [],
    ]);
    expect(e.pour(0, 1), 3);
    expect(e.vials[0], [1]);
    expect(e.vials[1], [0, 0, 0]);
    expect(e.moves, 1);
  });

  test('partial pour when destination is tight; remainder stays', () {
    final e = WaterSortEngine([
      [1, 0, 0, 0], // top run 0 x3
      [0, 0], // 2 free
    ]);
    expect(e.pour(0, 1), 2);
    expect(e.vials[1], [0, 0, 0, 0]);
    expect(e.vials[0], [1, 0]);
    expect(e.moves, 1);
    expect(e.isCompleteVial(1), isTrue);
  });

  test('locked (complete) vial rejects selection as source', () {
    final e = WaterSortEngine([
      [0, 0, 0, 0],
      [],
    ]);
    expect(e.legality(0, 1), PourOutcome.lockedSource);
    expect(e.pour(0, 1), 0);
    expect(e.moves, 0);
  });

  test('color mismatch and full destination are rejected', () {
    final e = WaterSortEngine([
      [1],
      [0],
      [2, 2, 2, 2],
    ]);
    expect(e.legality(0, 1), PourOutcome.colorMismatch);
    expect(e.legality(0, 2), PourOutcome.fullDest);
    expect(e.legality(0, 0), PourOutcome.sameVial);
    expect(e.pour(0, 1), 0);
    expect(e.moves, 0);
  });

  test('empty source is rejected', () {
    final e = WaterSortEngine([
      [],
      [0],
    ]);
    expect(e.legality(0, 1), PourOutcome.emptySource);
  });

  test('only the top run pours; layers below stay', () {
    final e = WaterSortEngine([
      [1, 1, 0, 0], // top run 0 x2 over 1 x2
      [],
    ]);
    expect(e.pour(0, 1), 2);
    expect(e.vials[0], [1, 1]);
    expect(e.vials[1], [0, 0]);
  });

  test('undo restores the exact pre-pour state and decrements moves', () {
    final e = WaterSortEngine([
      [1, 0, 0, 0],
      [],
    ]);
    e.pour(0, 1);
    e.undo();
    expect(e.vials[0], [1, 0, 0, 0]);
    expect(e.vials[1], isEmpty);
    expect(e.moves, 0);
    expect(e.canUndo, isFalse);
  });

  test('win detection: all vials complete or empty', () {
    final e = WaterSortEngine([
      [0, 0, 0, 0],
      [1, 1, 1, 1],
      [],
    ]);
    expect(e.isWon, isTrue);
    final e2 = WaterSortEngine([
      [0, 0, 0, 1],
      [],
    ]);
    expect(e2.isWon, isFalse);
  });

  test('complete vial stays locked even with an empty destination (RULES 4.4/7)',
      () {
    // NOTE: RULES.md §13 #13 describes pouring a "top run x4", but in a
    // capacity-4 vial that IS a complete tube, which §4.4, §7 and §13 #3
    // all lock against being a pour source. The lock rule (three
    // attestations) governs; #13 as literally written is unsatisfiable.
    final e = WaterSortEngine([
      [0, 0, 0, 0],
      [],
    ]);
    expect(e.pour(0, 1), 0);
    expect(e.vials[0], [0, 0, 0, 0]);
    expect(e.vials[1], isEmpty);
    expect(e.moves, 0);
  });

  test('hint suggests a legal move on a fresh level', () {
    final e = WaterSortEngine(kLevels[0]);
    final h = e.hint();
    expect(h, isNotNull);
    expect(e.legality(h!.$1, h.$2), PourOutcome.ok);
  });

  test('hint does not suggest the direct reversal of the last pour', () {
    final e = WaterSortEngine(kLevels[2]);
    final h1 = e.hint();
    expect(h1, isNotNull);
    e.pour(h1!.$1, h1.$2);
    final h2 = e.hint(lastFrom: h1.$1, lastTo: h1.$2);
    if (h2 != null) {
      expect(
          h2.$1 == h1.$2 && h2.$2 == h1.$1, isFalse,
          reason: 'hint suggested the direct reversal');
    }
  });

  test('par is deterministic and stars follow the 3/2/1 bands', () {
    final p1 = parForLevel(kLevels[0]);
    final p2 = parForLevel(kLevels[0]);
    expect(p1, p2);
    expect(WaterSortEngine.starsFor(p1, p1), 3);
    expect(WaterSortEngine.starsFor(p1 + (p1 * 0.25).ceil(), p1), 2);
    expect(WaterSortEngine.starsFor(p1 * 3, p1), 1);
  });

  test('every bundled level is solvable-shaped: colors x4 each, >=1 empty',
      () {
    for (final level in [...kLevels, ...kMasterLevels]) {
      final counts = <int, int>{};
      var empties = 0;
      var complete = 0;
      for (final v in level) {
        if (v.isEmpty) {
          empties++;
          continue;
        }
        for (final u in v) {
          counts[u] = (counts[u] ?? 0) + 1;
        }
        if (v.length == kCapacity && v.every((u) => u == v.first)) {
          complete++;
        }
      }
      expect(empties, greaterThanOrEqualTo(1));
      expect(complete, 0, reason: 'no vial may start complete');
      for (final c in counts.values) {
        expect(c, 4);
      }
    }
  });

  test('solver completes every bundled level (RULES.md §11.5)', () {
    for (var i = 0; i < kLevels.length; i++) {
      final plies = WaterSortEngine.solvePlies(kLevels[i]);
      expect(plies, greaterThan(0), reason: 'classic level $i unsolvable');
    }
  });

  test('solver completes every master level (RULES.md §11.5)', () {
    for (var i = 0; i < kMasterLevels.length; i++) {
      final plies = WaterSortEngine.solvePlies(kMasterLevels[i]);
      expect(plies, greaterThan(0), reason: 'master level $i unsolvable');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('generator is deterministic and emits solvable shuffles', () {
    final a = generateLevel(colors: 6, seed: 42);
    final b = generateLevel(colors: 6, seed: 42);
    expect(a, b);
    final counts = <int, int>{};
    var empties = 0;
    for (final v in a) {
      if (v.isEmpty) {
        empties++;
        continue;
      }
      expect(v.length, kCapacity);
      for (final u in v) {
        counts[u] = (counts[u] ?? 0) + 1;
      }
    }
    expect(empties, 2);
    expect(counts.length, 6);
    for (final c in counts.values) {
      expect(c, 4);
    }
    expect(WaterSortEngine.isSolvable(a), isTrue);
  });

  test('theme catalogs meet the breadth bar', () {
    expect(ApothecaryThemes.all.length, greaterThanOrEqualTo(12));
    expect(LiquidPalettes.all.length, greaterThanOrEqualTo(8));
    expect(GlassStyle.values.length, greaterThanOrEqualTo(3));
    expect(ApothecaryThemes.freeIds.length, 4);
    expect(LiquidPalettes.freeIds.length, 2);
    for (final p in LiquidPalettes.all) {
      expect(p.colors.length, 8);
    }
    // Every theme resolves a palette and a glass style.
    for (final t in ApothecaryThemes.all) {
      expect(t.palette.colors.length, 8);
      expect(GlassStyle.values, contains(t.glass));
    }
    // Custom blend resolution.
    final custom = ApothecaryThemes.custom(
      name: 'Mine',
      baseId: 'classic',
      paletteId: 'berry',
      glassId: 'flask',
    );
    expect(custom.name, 'Mine');
    expect(custom.paletteId, 'berry');
    expect(custom.glassId, 'flask');
    expect(custom.bg, ApothecaryThemes.byId('classic').bg);
  });
}
