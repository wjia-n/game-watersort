import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Difficulty presets (RULES.md §2).
enum Difficulty { gentle, classic, master }

/// App-wide settings, persisted in shared_preferences. Singleton
/// ChangeNotifier so toggles/sliders update the UI and audio live.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  bool musicOn = true;
  bool sfxOn = true;
  double musicVol = 0.7;
  double sfxVol = 0.8;
  bool vibration = true;
  Difficulty difficulty = Difficulty.classic;

  SharedPreferences? _prefs;
  bool _loaded = false;

  static const _kMusic = 'watersort_music';
  static const _kSfx = 'watersort_sfx';
  static const _kMusicVol = 'watersort_music_vol';
  static const _kSfxVol = 'watersort_sfx_vol';
  static const _kVib = 'watersort_vibration';
  static const _kDiff = 'watersort_difficulty';

  Future<void> load() async {
    if (_loaded) return;
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    musicVol = p.getDouble(_kMusicVol) ?? 0.7;
    sfxVol = p.getDouble(_kSfxVol) ?? 0.8;
    vibration = p.getBool(_kVib) ?? true;
    difficulty =
        Difficulty.values[p.getInt(_kDiff) ?? Difficulty.classic.index];
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kMusicVol, musicVol);
    await p.setDouble(_kSfxVol, sfxVol);
    await p.setBool(_kVib, vibration);
    await p.setInt(_kDiff, difficulty.index);
  }

  void setMusicOn(bool v) {
    musicOn = v;
    _save();
    notifyListeners();
  }

  void setSfxOn(bool v) {
    sfxOn = v;
    _save();
    notifyListeners();
  }

  void setMusicVol(double v) {
    musicVol = v.clamp(0.0, 1.0);
    _save();
    notifyListeners();
  }

  void setSfxVol(double v) {
    sfxVol = v.clamp(0.0, 1.0);
    _save();
    notifyListeners();
  }

  void setVibration(bool v) {
    vibration = v;
    _save();
    notifyListeners();
  }

  void setDifficulty(Difficulty d) {
    difficulty = d;
    _save();
    notifyListeners();
  }

  /// Add-Vial uses granted per level by difficulty (RULES.md §7).
  int get addVialUsesPerLevel => switch (difficulty) {
        Difficulty.gentle => 2,
        Difficulty.classic => 1,
        Difficulty.master => 0,
      };

  String get difficultyName => switch (difficulty) {
        Difficulty.gentle => 'Gentle',
        Difficulty.classic => 'Classic',
        Difficulty.master => 'Master',
      };
}
