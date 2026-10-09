/// Water Sort level definitions (kept from the original working build).
///
/// Each level: list of vials; each vial is a bottom-to-top list of color
/// indices. Empty list = empty vial. Every color index 0..C-1 appears exactly
/// 4 times across the level. Capacity is 4 everywhere.
const kCapacity = 4;

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
    [0, 5, 2, 4],
    [3, 4, 5, 2],
    [3, 1, 0, 1],
    [3, 4, 5, 1],
    [2, 5, 0, 0],
    [4, 3, 1, 2],
    [],
  ], // 6 colors
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
