// ignore_for_file: avoid_print
// Offline helper: sanity-check the solver, then generate + verify the
// Master Cabinet levels (9 colors, tighter shuffles). Run with:
//   dart run tools/gen_master_levels.dart
// Paste the printed Dart literal into levels.dart as kMasterLevels.
import 'package:watersort/engine.dart';
import 'package:watersort/levels.dart';

void main() {
  // 1) Solver sanity on the hardest bundled level.
  var t0 = DateTime.now();
  final plies = WaterSortEngine.solvePlies(kLevels[11]);
  print(
      'bundled hardest level: plies=$plies elapsed=${DateTime.now().difference(t0)}');

  // 2) Generate 8 master levels (9 colors, 2 spare empties).
  for (var m = 0; m < 8; m++) {
    final seed = 901 + m;
    final lvl = generateLevel(colors: 9, empties: 2, seed: seed);
    // Shape checks (mirror the unit tests).
    final counts = <int, int>{};
    var empties = 0;
    var complete = 0;
    for (final v in lvl) {
      if (v.isEmpty) {
        empties++;
        continue;
      }
      for (final u in v) {
        counts[u] = (counts[u] ?? 0) + 1;
      }
      if (v.length == kCapacity && v.every((u) => u == v.first)) complete++;
    }
    assert(empties >= 1 && complete == 0);
    assert(counts.length == 9 && counts.values.every((c) => c == 4));
    t0 = DateTime.now();
    final p = WaterSortEngine.solvePlies(lvl);
    final par = parForLevel(lvl);
    final buf = StringBuffer('[\n');
    for (final v in lvl) {
      buf.write('    [${v.join(', ')}],\n');
    }
    buf.write('  ],');
    print(
        'seed=$seed par=$par solverPlies=$p elapsed=${DateTime.now().difference(t0)}');
    print(buf.toString());
  }
}
