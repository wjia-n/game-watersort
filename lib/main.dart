import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio.dart';
import 'levels.dart';
import 'progress.dart';
import 'services/store.dart';
import 'settings.dart';
import 'screens/game_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/pro_screen.dart';
import 'screens/select_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/theme_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await AppSettings.instance.load();
  await ProgressStore.instance.load(kLevels.length, kMasterLevels.length);
  await ApothecaryAudio.instance.init();
  runApp(const WaterSortApp());
}

/// Water Sort — the Apothecary Cabinet. Stitch UI rebuild:
/// pseudo-3D hand-blown glass vials, brass hardware, walnut shelves,
/// parchment recipe cards. 14 cabinet themes, 10 tincture palettes,
/// 5 glass styles, PRO store, Master Cabinet hard levels.
class WaterSortApp extends StatelessWidget {
  const WaterSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole app when settings (theme) change.
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final t = AppSettings.instance.theme;
        return MaterialApp(
          title: 'Water Sort',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: t.bg,
            colorScheme: ColorScheme.dark(
              primary: t.metalLight,
              surface: t.bg,
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: t.parchment,
            ),
          ),
          home: const _Cabinet(),
        );
      },
    );
  }
}

enum _Screen { splash, menu, levels, master, game, settings, themes, pro }

class _Cabinet extends StatefulWidget {
  const _Cabinet();

  @override
  State<_Cabinet> createState() => _CabinetState();
}

class _CabinetState extends State<_Cabinet> with WidgetsBindingObserver {
  _Screen _screen = _Screen.splash;
  _Screen _settingsReturn = _Screen.menu;
  int _gameLevel = 0;
  bool _gameMaster = false;
  int _gameKey = 0;
  final StoreService _store = StoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store.dispose();
    super.dispose();
  }

  /// App-level lifecycle: music pauses (never stops) on backgrounding and
  /// resumes exactly where it left off. Game-screen pour state snaps to the
  /// post-pour result via the screen's own observer.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audio = ApothecaryAudio.instance;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      audio.onAppResumed();
    }
  }

  void _go(_Screen s, {int? level, bool master = false}) {
    setState(() {
      if (s == _Screen.game && level != null) {
        _gameLevel = level;
        _gameMaster = master;
        _gameKey++; // fresh engine each entry
      }
      _screen = s;
    });
    ApothecaryAudio.instance.refresh();
    if (s == _Screen.game) {
      ApothecaryAudio.instance.startGameMusic();
    } else if (s != _Screen.splash) {
      ApothecaryAudio.instance.startMenuMusic();
    }
  }

  void _openSettings() {
    setState(() => _settingsReturn = _screen);
    _go(_Screen.settings);
  }

  void _dailyMix() {
    final day = DateTime.now();
    final seed = day.year * 1000 + day.dayOfYear;
    final level = Random(seed).nextInt(kLevels.length);
    _go(_Screen.game, level: level);
  }

  Future<bool> _onBack() async {
    switch (_screen) {
      case _Screen.splash:
        return true; // let the system handle it
      case _Screen.menu:
        return true; // exit app
      case _Screen.levels:
      case _Screen.master:
        _go(_Screen.menu);
        return false;
      case _Screen.settings:
        _go(_settingsReturn);
        return false;
      case _Screen.themes:
      case _Screen.pro:
        _go(_Screen.menu);
        return false;
      case _Screen.game:
        _go(_gameMaster ? _Screen.master : _Screen.levels);
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _onBack() && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: switch (_screen) {
        _Screen.splash => SplashScreen(
            store: _store,
            onDone: () => _go(_Screen.menu),
          ),
        _Screen.menu => MenuScreen(
            onPlay: () => _go(_Screen.game,
                level: ProgressStore.instance.current),
            onRecipes: () => _go(_Screen.levels),
            onMaster: () => _go(_Screen.master),
            onDailyMix: _dailyMix,
            onThemes: () => _go(_Screen.themes),
            onPro: () => _go(_Screen.pro),
            onSettings: _openSettings,
          ),
        _Screen.levels => SelectScreen(
            title: 'RECIPE BOOK',
            levels: kLevels,
            master: false,
            onPick: (i) => _go(_Screen.game, level: i),
            onBack: () => _go(_Screen.menu),
          ),
        _Screen.master => SelectScreen(
            title: 'MASTER CABINET',
            levels: kMasterLevels,
            master: true,
            onPick: (i) => _go(_Screen.game, level: i, master: true),
            onBack: () => _go(_Screen.menu),
          ),
        _Screen.game => GameScreen(
            key: ValueKey('game-$_gameKey'),
            level: _gameLevel,
            levels: _gameMaster ? kMasterLevels : kLevels,
            master: _gameMaster,
            onExit: () =>
                _go(_gameMaster ? _Screen.master : _Screen.levels),
            onNextLevel: (n) =>
                _go(_Screen.game, level: n, master: _gameMaster),
          ),
        _Screen.settings => SettingsScreen(
            onBack: () => _go(_settingsReturn),
            onThemes: () => _go(_Screen.themes),
            onPro: () => _go(_Screen.pro),
          ),
        _Screen.themes => ThemeScreen(
            onBack: () => _go(_Screen.menu),
            onPro: () => _go(_Screen.pro),
          ),
        _Screen.pro => ProScreen(
            store: _store,
            onBack: () => _go(_Screen.menu),
          ),
      },
    );
  }
}

extension on DateTime {
  int get dayOfYear => difference(DateTime(year, 1, 1)).inDays;
}
