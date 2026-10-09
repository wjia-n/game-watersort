import 'levels.dart';

/// Result of a pour attempt.
enum PourOutcome { ok, emptySource, fullDest, colorMismatch, lockedSource, sameVial }

/// Pure, deterministic Water Sort engine. Implements RULES.md exactly:
/// - pour = top contiguous run, partial pours when the destination is tight
/// - completed (locked) vials can never be a pour source
/// - unlimited undo, one snapshot per pour
class WaterSortEngine {
  final List<List<int>> initial;
  late List<List<int>> vials;
  final List<List<List<int>>> _history = [];
  int moves = 0;
  int undosUsed = 0;
  int illegalAttempts = 0;

  WaterSortEngine(List<List<int>> level)
      : initial = level.map((v) => List<int>.of(v)).toList() {
    reset();
  }

  void reset() {
    vials = initial.map((v) => List<int>.of(v)).toList();
    _history.clear();
    moves = 0;
    undosUsed = 0;
    illegalAttempts = 0;
  }

  /// Add an empty vial (Daily Mix / Add Vial escape hatch).
  void addVial() {
    vials.add(<int>[]);
  }

  int get vialCount => vials.length;

  bool isCompleteVial(int i) {
    final v = vials[i];
    return v.length == kCapacity && v.every((u) => u == v.first);
  }

  /// Length of the top contiguous run of one color in vial [i].
  int topRun(int i) {
    final v = vials[i];
    if (v.isEmpty) return 0;
    final c = v.last;
    var n = 0;
    for (var k = v.length - 1; k >= 0 && v[k] == c; k--) {
      n++;
    }
    return n;
  }

  PourOutcome legality(int s, int d) {
    if (s == d) return PourOutcome.sameVial;
    if (vials[s].isEmpty) return PourOutcome.emptySource;
    if (isCompleteVial(s)) return PourOutcome.lockedSource;
    if (vials[d].length >= kCapacity) return PourOutcome.fullDest;
    if (vials[d].isNotEmpty && vials[d].last != vials[s].last) {
      return PourOutcome.colorMismatch;
    }
    return PourOutcome.ok;
  }

  /// How many units would move for a legal pour s -> d.
  int pourAmount(int s, int d) {
    if (legality(s, d) != PourOutcome.ok) return 0;
    final run = topRun(s);
    final free = kCapacity - vials[d].length;
    return run.clamp(1, free);
  }

  /// Applies a legal pour. Returns units moved, or 0 if illegal (state
  /// unchanged; caller increments [illegalAttempts] and plays feedback).
  int pour(int s, int d) {
    final n = pourAmount(s, d);
    if (n == 0) {
      illegalAttempts++;
      return 0;
    }
    _history.add(_snapshot());
    if (_history.length > 200) _history.removeAt(0);
    for (var k = 0; k < n; k++) {
      vials[d].add(vials[s].removeLast());
    }
    moves++;
    return n;
  }

  bool get canUndo => _history.isNotEmpty;

  /// Reverses exactly one pour; decrements the move counter (RULES.md §7).
  void undo() {
    if (!canUndo) return;
    vials = _history.removeLast();
    moves = (moves - 1).clamp(0, 1 << 30);
    undosUsed++;
  }

  bool get isWon {
    for (final v in vials) {
      if (v.isEmpty) continue;
      if (v.length != kCapacity || v.any((u) => u != v.first)) return false;
    }
    return true;
  }

  List<List<int>> _snapshot() => vials.map((v) => List<int>.of(v)).toList();

  // ---------------- hint engine (RULES.md §11) ----------------
  /// Heuristic hint: ranked legal pours. Returns (source, dest) or null.
  /// Ranking per §11.3: complete a vial > free a vial > longest run onto a
  /// match; never suggest a direct reversal of the last pour unless it
  /// completes a vial; avoid fragmenting a color onto an empty vial.
  (int, int)? hint({int? lastFrom, int? lastTo}) {
    (int, int)? best;
    var bestScore = -1 << 30;
    for (var s = 0; s < vials.length; s++) {
      if (vials[s].isEmpty || isCompleteVial(s)) continue;
      for (var d = 0; d < vials.length; d++) {
        if (legality(s, d) != PourOutcome.ok) continue;
        final n = pourAmount(s, d);
        final color = vials[s].last;
        var score = 0;
        // completes the destination vial
        if (vials[d].length + n == kCapacity) score += 1000;
        // empties the source vial (frees a vial)
        if (vials[s].length - n == 0) score += 500;
        // longer runs onto matching colors are good
        if (vials[d].isNotEmpty) score += n * 20 + topRun(d) * 5;
        // pouring onto an empty vial is fine only if the run is the whole
        // color block below (no fragmentation)
        if (vials[d].isEmpty) {
          final wholeBlock = vials[s].every((u) => u == color) || n == topRun(s) &&
              vials[s].sublist(0, vials[s].length - n).every((u) => u != color);
          score += wholeBlock ? 60 : -200;
        }
        // never suggest the direct reversal of the last pour (no 2-cycles)
        if (lastFrom != null &&
            lastTo != null &&
            s == lastTo &&
            d == lastFrom &&
            score < 1000) {
          score -= 5000;
        }
        if (score > bestScore) {
          bestScore = score;
          best = (s, d);
        }
      }
    }
    return best;
  }

  /// Stars per RULES.md §8: 3 if moves <= par, 2 if within +25%, else 1.
  static int starsFor(int moves, int par) {
    if (moves <= par) return 3;
    if (moves <= (par * 1.25).ceil()) return 2;
    return 1;
  }
}
