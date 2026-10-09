import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Level progress + per-level stars, persisted locally (RULES.md §8).
/// Stars are the max ever earned; a worse replay never reduces them (§12.10).
class ProgressStore extends ChangeNotifier {
  ProgressStore._();
  static final ProgressStore instance = ProgressStore._();

  static const _kCurrent = 'watersort_current';
  static const _kDone = 'watersort_done';
  static const _kStars = 'watersort_stars_';
  static const _kPerfect = 'watersort_perfect_';
  // Master Cabinet (hard levels) keeps its own book.
  static const _kMCurrent = 'watersort_m_current';
  static const _kMDone = 'watersort_m_done';
  static const _kMStars = 'watersort_m_stars_';
  static const _kMPerfect = 'watersort_m_perfect_';

  SharedPreferences? _prefs;
  int current = 0;
  Set<int> done = {};
  final Map<int, int> stars = {};
  final Set<int> perfect = {};

  int masterCurrent = 0;
  Set<int> masterDone = {};
  final Map<int, int> masterStars = {};
  final Set<int> masterPerfect = {};

  Future<void> load(int levelCount, int masterCount) async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    current = (p.getInt(_kCurrent) ?? 0).clamp(0, levelCount - 1);
    done = (p.getStringList(_kDone) ?? []).map(int.parse).toSet();
    for (var i = 0; i < levelCount; i++) {
      final s = p.getInt('$_kStars$i') ?? 0;
      if (s > 0) stars[i] = s;
      if (p.getBool('$_kPerfect$i') ?? false) perfect.add(i);
    }
    masterCurrent = (p.getInt(_kMCurrent) ?? 0).clamp(0, masterCount - 1);
    masterDone = (p.getStringList(_kMDone) ?? []).map(int.parse).toSet();
    for (var i = 0; i < masterCount; i++) {
      final s = p.getInt('$_kMStars$i') ?? 0;
      if (s > 0) masterStars[i] = s;
      if (p.getBool('$_kMPerfect$i') ?? false) masterPerfect.add(i);
    }
    notifyListeners();
  }

  Future<void> _saveDone() async {
    await _prefs?.setStringList(_kDone, done.map((e) => '$e').toList());
  }

  /// Record a level completion. Returns true if this set a new star record.
  Future<bool> recordCompletion(
      int level, int starCount, bool isPerfect) async {
    done.add(level);
    var newRecord = false;
    if (starCount > (stars[level] ?? 0)) {
      stars[level] = starCount;
      await _prefs?.setInt('$_kStars$level', starCount);
      newRecord = true;
    }
    if (isPerfect && !perfect.contains(level)) {
      perfect.add(level);
      await _prefs?.setBool('$_kPerfect$level', true);
    }
    await _saveDone();
    notifyListeners();
    return newRecord;
  }

  Future<void> setCurrent(int level) async {
    current = level;
    await _prefs?.setInt(_kCurrent, level);
    notifyListeners();
  }

  /// Record a Master Cabinet completion. Returns true on a new star record.
  Future<bool> recordMasterCompletion(
      int level, int starCount, bool isPerfect) async {
    masterDone.add(level);
    var newRecord = false;
    if (starCount > (masterStars[level] ?? 0)) {
      masterStars[level] = starCount;
      await _prefs?.setInt('$_kMStars$level', starCount);
      newRecord = true;
    }
    if (isPerfect && !masterPerfect.contains(level)) {
      masterPerfect.add(level);
      await _prefs?.setBool('$_kMPerfect$level', true);
    }
    await _prefs?.setStringList(
        _kMDone, masterDone.map((e) => '$e').toList());
    notifyListeners();
    return newRecord;
  }

  Future<void> setMasterCurrent(int level) async {
    masterCurrent = level;
    await _prefs?.setInt(_kMCurrent, level);
    notifyListeners();
  }

  Future<void> resetAll(int levelCount, [int masterCount = 0]) async {
    final p = _prefs;
    if (p != null) {
      await p.remove(_kCurrent);
      await p.remove(_kDone);
      for (var i = 0; i < levelCount; i++) {
        await p.remove('$_kStars$i');
        await p.remove('$_kPerfect$i');
      }
      await p.remove(_kMCurrent);
      await p.remove(_kMDone);
      for (var i = 0; i < masterCount; i++) {
        await p.remove('$_kMStars$i');
        await p.remove('$_kMPerfect$i');
      }
    }
    current = 0;
    done = {};
    stars.clear();
    perfect.clear();
    masterCurrent = 0;
    masterDone = {};
    masterStars.clear();
    masterPerfect.clear();
    notifyListeners();
  }
}
