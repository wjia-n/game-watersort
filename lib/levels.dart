/// Water Sort level definitions (kept from the original working build).
///
/// Each level: list of vials; each vial is a bottom-to-top list of color
/// indices. Empty list = empty vial. Every color index 0..C-1 appears exactly
/// 4 times across the level. Capacity is 4 everywhere (see [kCapacity]).
library;

import 'dart:math';

import 'engine.dart';

const kLevels = <List<List<int>>>[
  [
    [1, 2, 2, 0],
    [2, 1, 0, 2],
    [1, 0, 1, 0],
    [],
    []
  ], // 3 colors
  [
    [1, 1, 2, 1],
    [1, 2, 2, 0],
    [0, 0, 2, 0],
    [],
    []
  ], // 3 colors
  [
    [0, 0, 2, 2],
    [1, 3, 3, 3],
    [0, 3, 2, 1],
    [1, 2, 0, 1],
    [],
    []
  ], // 4 colors
  [
    [3, 2, 0, 1],
    [3, 0, 2, 2],
    [3, 1, 3, 1],
    [2, 0, 1, 0],
    [],
    []
  ], // 4 colors
  [
    [2, 1, 3, 2],
    [4, 0, 0, 3],
    [4, 0, 1, 2],
    [3, 2, 0, 4],
    [3, 4, 1, 1],
    [],
    []
  ], // 5 colors
  [
    [4, 0, 2, 4],
    [0, 4, 1, 2],
    [0, 3, 2, 0],
    [3, 4, 1, 1],
    [3, 3, 1, 2],
    [],
    []
  ], // 5 colors
  [
    [5, 2, 1, 4],
    [1, 5, 5, 1],
    [3, 3, 3, 0],
    [0, 3, 4, 2],
    [5, 4, 0, 2],
    [2, 1, 0, 4],
    [],
    []
  ], // 6 colors
  [
    [1, 5, 2, 1],
    [3, 4, 0, 1],
    [5, 1, 2, 0],
    [2, 5, 4, 2],
    [3, 3, 3, 4],
    [0, 0, 4, 5],
    [],
  ], // 6 colors (replaced 2026-10-09: the previous shuffle was proven
  // unsolvable by exhaustive search — only 28 reachable states, no solution.
  // This is a solver-verified 6-color / 1-empty replacement, seed=1.)
  [
    [0, 5, 2, 6],
    [5, 1, 5, 6],
    [1, 0, 4, 5],
    [3, 6, 6, 3],
    [2, 1, 4, 4],
    [1, 3, 3, 4],
    [2, 0, 2, 0],
    [],
    []
  ], // 7 colors
  [
    [4, 2, 4, 5],
    [1, 2, 0, 1],
    [6, 0, 1, 4],
    [0, 6, 0, 3],
    [4, 6, 1, 5],
    [6, 3, 5, 2],
    [2, 3, 3, 5],
    [],
    []
  ], // 7 colors
  [
    [0, 3, 5, 3],
    [4, 0, 7, 2],
    [1, 6, 6, 2],
    [4, 0, 6, 7],
    [2, 3, 5, 1],
    [5, 6, 5, 7],
    [0, 7, 3, 1],
    [4, 1, 2, 4],
    [],
    []
  ], // 8 colors
  [
    [0, 0, 6, 3],
    [7, 5, 2, 1],
    [3, 7, 6, 0],
    [4, 3, 4, 2],
    [3, 5, 1, 6],
    [0, 7, 5, 2],
    [1, 4, 5, 2],
    [4, 1, 6, 7],
    [],
    []
  ], // 8 colors
];

/// Master Cabinet levels: 9 colors, 2 spare empties, tighter shuffles.
/// Generated offline by tools/gen_master_levels.dart (seeded shuffle-deal,
/// solver-verified per RULES.md §11.5, no tube starts complete).
const kMasterLevels = <List<List<int>>>[
  [
    [8, 8, 1, 7],
    [6, 4, 0, 1],
    [2, 3, 3, 5],
    [2, 4, 0, 6],
    [5, 7, 6, 0],
    [1, 8, 3, 0],
    [5, 7, 4, 2],
    [5, 6, 8, 7],
    [3, 2, 4, 1],
    [],
    [],
  ],
  [
    [0, 8, 2, 7],
    [4, 1, 7, 3],
    [0, 5, 2, 3],
    [5, 0, 6, 3],
    [5, 7, 7, 3],
    [4, 2, 4, 1],
    [0, 8, 4, 8],
    [1, 6, 1, 2],
    [5, 6, 6, 8],
    [],
    [],
  ],
  [
    [4, 6, 0, 8],
    [7, 7, 4, 2],
    [8, 5, 1, 4],
    [6, 2, 3, 8],
    [7, 3, 0, 0],
    [6, 3, 1, 2],
    [5, 2, 1, 0],
    [8, 4, 5, 3],
    [1, 6, 7, 5],
    [],
    [],
  ],
  [
    [4, 7, 8, 0],
    [3, 4, 5, 8],
    [7, 4, 4, 0],
    [1, 6, 0, 5],
    [0, 6, 5, 2],
    [6, 2, 5, 7],
    [7, 3, 6, 1],
    [1, 8, 3, 2],
    [3, 2, 1, 8],
    [],
    [],
  ],
  [
    [7, 1, 8, 5],
    [8, 3, 2, 1],
    [1, 4, 3, 5],
    [7, 3, 0, 2],
    [8, 4, 5, 6],
    [5, 6, 3, 0],
    [6, 4, 0, 6],
    [1, 2, 4, 8],
    [7, 7, 0, 2],
    [],
    [],
  ],
  [
    [7, 8, 4, 4],
    [8, 8, 1, 2],
    [1, 0, 3, 6],
    [3, 1, 2, 0],
    [1, 3, 5, 7],
    [5, 7, 2, 6],
    [7, 6, 2, 4],
    [0, 0, 5, 3],
    [4, 6, 8, 5],
    [],
    [],
  ],
  [
    [0, 3, 5, 0],
    [1, 2, 4, 5],
    [7, 0, 5, 3],
    [7, 7, 8, 3],
    [1, 7, 2, 8],
    [4, 6, 8, 6],
    [8, 2, 1, 6],
    [4, 1, 4, 5],
    [2, 0, 6, 3],
    [],
    [],
  ],
  [
    [1, 6, 0, 4],
    [8, 6, 8, 0],
    [6, 3, 2, 7],
    [5, 6, 2, 7],
    [2, 0, 1, 1],
    [3, 2, 8, 3],
    [7, 3, 4, 8],
    [0, 5, 4, 7],
    [4, 1, 5, 5],
    [],
    [],
  ],
];

/// Deterministic par for a level: a fair-but-tight target derived from the
/// shuffle. Units already resting in a correct bottom run count as settled;
/// every other unit needs at least one move, plus slack for staging.
int parForLevel(List<List<int>> level) {
  var total = 0;
  var settled = 0;
  for (final vial in level) {
    total += vial.length;
    if (vial.isEmpty) continue;
    final bottom = vial.first;
    var run = 0;
    for (final u in vial) {
      if (u == bottom) {
        run++;
      } else {
        break;
      }
    }
    settled += run;
  }
  final colors = <int>{};
  for (final vial in level) {
    colors.addAll(vial);
  }
  final moves = (total - settled) + (total ~/ 2) + colors.length * 2;
  return moves.clamp(8, 400);
}

/// Number of distinct colors in a level.
int levelColorCount(List<List<int>> level) {
  final colors = <int>{};
  for (final vial in level) {
    colors.addAll(vial);
  }
  return colors.length;
}

/// Shuffle-deal level generator (RULES.md §2 / §11.5).
///
/// Colors are dealt into `colors` tubes (4 layers each, deterministic per
/// [seed]); `empties` tubes start empty. A deal is kept only if no tube
/// starts complete AND the solver ([WaterSortEngine.solvePlies]) completes
/// it — unsolvable shuffles are discarded at build time, exactly as the
/// rules require. Deterministic for a given seed.
List<List<int>> generateLevel({
  required int colors,
  int empties = 2,
  required int seed,
}) {
  final rnd = newRandom(seed);
  for (var attempt = 0; attempt < 500; attempt++) {
    // 4 copies of each color, dealt into `colors` tubes of 4 layers.
    final deck = <int>[
      for (var c = 0; c < colors; c++) ...[c, c, c, c],
    ];
    deck.shuffle(rnd);
    final vials = <List<int>>[
      for (var t = 0; t < colors; t++) deck.sublist(t * 4, t * 4 + 4),
      for (var e = 0; e < empties; e++) <int>[],
    ];
    // No tube may start complete (§2 / §12).
    if (_hasComplete(vials)) continue;
    // Keep only solver-verified shuffles (§11.5).
    if (WaterSortEngine.solvePlies(vials) < 0) continue;
    return vials;
  }
  throw StateError('generateLevel: no solvable shuffle found (seed=$seed)');
}

bool _hasComplete(List<List<int>> vials) => vials.any(
    (v) => v.length == kCapacity && v.every((u) => u == v.first));

/// Deterministic Random factory (kept separate for testability).
Random newRandom(int seed) => Random(seed);
