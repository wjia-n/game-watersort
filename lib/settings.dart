import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'themes.dart';

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

  /// Renameable player profile (persisted).
  String playerName = 'Player';

  /// Active cabinet theme id, or 'custom' for the player's own blend.
  String themeId = 'classic';

  /// Custom theme (PRO): name + base theme + palette + glass overrides.
  String customName = '';
  String customBaseId = 'classic';
  String customPaletteId = 'apothecary';
  String customGlassId = 'flute';
  bool customEnabled = false;

  /// Water Sort PRO unlock (persisted; set by the store on purchase).
  bool isPro = false;

  SharedPreferences? _prefs;
  bool _loaded = false;

  static const _kMusic = 'watersort_music';
  static const _kSfx = 'watersort_sfx';
  static const _kMusicVol = 'watersort_music_vol';
  static const _kSfxVol = 'watersort_sfx_vol';
  static const _kVib = 'watersort_vibration';
  static const _kDiff = 'watersort_difficulty';
  static const _kName = 'watersort_player_name';
  static const _kTheme = 'watersort_theme';
  static const _kCustomName = 'watersort_custom_name';
  static const _kCustomBase = 'watersort_custom_base';
  static const _kCustomPalette = 'watersort_custom_palette';
  static const _kCustomGlass = 'watersort_custom_glass';
  static const _kCustomOn = 'watersort_custom_on';
  static const _kPro = 'watersort_pro';

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
    playerName = p.getString(_kName) ?? 'Player';
    themeId = p.getString(_kTheme) ?? 'classic';
    customName = p.getString(_kCustomName) ?? '';
    customBaseId = p.getString(_kCustomBase) ?? 'classic';
    customPaletteId = p.getString(_kCustomPalette) ?? 'apothecary';
    customGlassId = p.getString(_kCustomGlass) ?? 'flute';
    customEnabled = p.getBool(_kCustomOn) ?? false;
    isPro = p.getBool(_kPro) ?? false;
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
    await p.setString(_kName, playerName);
    await p.setString(_kTheme, themeId);
    await p.setString(_kCustomName, customName);
    await p.setString(_kCustomBase, customBaseId);
    await p.setString(_kCustomPalette, customPaletteId);
    await p.setString(_kCustomGlass, customGlassId);
    await p.setBool(_kCustomOn, customEnabled);
    await p.setBool(_kPro, isPro);
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

  void setPlayerName(String v) {
    playerName = v.trim().isEmpty ? 'Player' : v.trim();
    _save();
    notifyListeners();
  }

  void setTheme(String id) {
    themeId = id;
    customEnabled = false;
    _save();
    notifyListeners();
  }

  /// Save the player's custom blend (PRO) and activate it.
  void setCustomTheme({
    required String name,
    required String baseId,
    required String paletteId,
    required String glassId,
  }) {
    customName = name.trim();
    customBaseId = baseId;
    customPaletteId = paletteId;
    customGlassId = glassId;
    customEnabled = true;
    themeId = 'custom';
    _save();
    notifyListeners();
  }

  void setPro(bool v) {
    isPro = v;
    _save();
    notifyListeners();
  }

  /// The resolved cabinet theme for the current settings.
  ApothecaryThemeDef get theme {
    if (customEnabled || themeId == 'custom') {
      return ApothecaryThemes.custom(
        name: customName,
        baseId: customBaseId,
        paletteId: customPaletteId,
        glassId: customGlassId,
      );
    }
    return ApothecaryThemes.byId(themeId);
  }

  bool get canUseProContent => isPro;

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
