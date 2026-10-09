/// Pure, deterministic Water Sort engine. Implements RULES.md exactly:
///
/// - pour = top contiguous run, partial pours when the destination is tight
/// - completed (locked) vials can never be a pour source
/// - unlimited undo, one snapshot per pour
///
/// Vial capacity shared by the engine and level definitions.
const kCapacity = 4;

/// Result of a pour attempt.
enum PourOutcome { ok, emptySource, fullDest, colorMismatch, lockedSource, sameVial }

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
    // Undo is unlimited per RULES.md §7 — no cap on the history stack.
    _history.add(_snapshot());
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

  // ---------------- solver (RULES.md §11) ----------------
  /// Best-first search over legal pours (§4), used to verify that a level
  /// shuffle is solvable (generator validation) and to back the hint engine.
  ///
  /// - Symmetry pruning: pouring into any of several identical empty tubes
  ///   is one move (only the first empty tube is a legal destination).
  /// - Run-normalization: states are canonicalized (tube order irrelevant).
  /// - Returns the solution length in plies, or -1 if none was found within
  ///   [cap] plies or [stateCap] visited states.
  static int solvePlies(List<List<int>> level,
      {int cap = 400, int stateCap = 600000}) {
    bool goal(List<List<int>> st) {
      for (final v in st) {
        if (v.isEmpty) continue;
        if (v.length != kCapacity || v.any((u) => u != v.first)) return false;
      }
      return true;
    }

    String key(List<List<int>> st) {
      final tubes = st.map((v) => v.join(',')).toList()..sort();
      return tubes.join('|');
    }

    int heuristic(List<List<int>> st) {
      // 4 plies per incomplete color: optimistic but effective ordering.
      final colors = <int>{};
      for (final v in st) {
        colors.addAll(v);
      }
      var incomplete = 0;
      for (final c in colors) {
        var total = 0;
        var inCompleteTube = false;
        for (final v in st) {
          if (v.isNotEmpty && v.every((u) => u == c)) total += v.length;
          if (v.length == kCapacity && v.every((u) => u == c)) {
            inCompleteTube = true;
          }
        }
        if (!inCompleteTube && total > 0) incomplete++;
      }
      return incomplete * 4;
    }

    final start = level.map((v) => List<int>.of(v)).toList();
    if (goal(start)) return 0;
    final seen = <String>{key(start)};
    // Minimal binary heap on (depth + heuristic).
    final heap = <_SearchNode>[];
    void push(_SearchNode n) {
      heap.add(n);
      var i = heap.length - 1;
      while (i > 0) {
        final p = (i - 1) >> 1;
        if (heap[p].f <= heap[i].f) break;
        final t = heap[p];
        heap[p] = heap[i];
        heap[i] = t;
        i = p;
      }
    }

    _SearchNode pop() {
      final top = heap.first;
      final last = heap.removeLast();
      if (heap.isNotEmpty) {
        heap[0] = last;
        var i = 0;
        for (;;) {
          final l = i * 2 + 1, r = l + 1;
          var m = i;
          if (l < heap.length && heap[l].f < heap[m].f) m = l;
          if (r < heap.length && heap[r].f < heap[m].f) m = r;
          if (m == i) break;
          final t = heap[m];
          heap[m] = heap[i];
          heap[i] = t;
          i = m;
        }
      }
      return top;
    }

    push(_SearchNode(0 + heuristic(start), 0, start));
    var visited = 0;
    while (heap.isNotEmpty) {
      final node = pop();
      if (node.depth >= cap) continue;
      final st = node.state;
      // Enumerate legal pours.
      for (var s = 0; s < st.length; s++) {
        final src = st[s];
        if (src.isEmpty) continue;
        if (src.length == kCapacity && src.every((u) => u == src.first)) {
          continue; // locked source (§4.4 / §7)
        }
        // top run
        final color = src.last;
        var run = 0;
        for (var k = src.length - 1; k >= 0 && src[k] == color; k--) {
          run++;
        }
        var usedEmpty = false;
        for (var d = 0; d < st.length; d++) {
          if (d == s) continue;
          final dst = st[d];
          if (dst.length >= kCapacity) continue;
          if (dst.isEmpty) {
            if (usedEmpty) continue; // symmetry pruning
            usedEmpty = true;
          } else if (dst.last != color) {
            continue;
          }
          final n = run < kCapacity - dst.length ? run : kCapacity - dst.length;
          final next = st.map((v) => List<int>.of(v)).toList();
          for (var k = 0; k < n; k++) {
            next[d].add(next[s].removeLast());
          }
          final depth = node.depth + 1;
          if (goal(next)) return depth;
          final k = key(next);
          if (seen.add(k)) {
            if (++visited > stateCap) return -1;
            push(_SearchNode(depth + heuristic(next), depth, next));
          }
        }
      }
    }
    return -1;
  }

  /// Convenience: is this level solvable within the search budget?
  static bool isSolvable(List<List<int>> level) => solvePlies(level) >= 0;
}

/// Search node for the best-first solver.
class _SearchNode {
  final int f; // depth + heuristic
  final int depth;
  final List<List<int>> state;
  _SearchNode(this.f, this.depth, this.state);
}
