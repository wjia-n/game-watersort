import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'apothecary.dart';
import 'audio.dart';
import 'levels.dart';
import 'progress.dart';
import 'settings.dart';
import 'screens/game_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/select_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);
  await AppSettings.instance.load();
  await ProgressStore.instance.load(kLevels.length);
  await ApothecaryAudio.instance.init();
  runApp(const WaterSortApp());
}

/// Water Sort — the Apothecary Cabinet. Stitch UI rebuild (batch 5):
/// pseudo-3D hand-blown glass vials, brass hardware, walnut shelves,
/// parchment recipe cards. No old shell variants, no neon.
class WaterSortApp extends StatelessWidget {
  const WaterSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Sort',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Apothecary.walnut,
        colorScheme: const ColorScheme.dark(
          primary: Apothecary.brassLight,
          surface: Apothecary.walnut,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Apothecary.parchment,
        ),
      ),
      home: const _Cabinet(),
    );
  }
}

enum _Screen { menu, levels, game, settings }

class _Cabinet extends StatefulWidget {
  const _Cabinet();

  @override
  State<_Cabinet> createState() => _CabinetState();
}

class _CabinetState extends State<_Cabinet> {
  _Screen _screen = _Screen.menu;
  _Screen _settingsReturn = _Screen.menu;
  int _gameLevel = 0;
  int _gameKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ApothecaryAudio.instance.playMusic('music_menu.wav');
    });
  }

  void _go(_Screen s, {int? level}) {
    setState(() {
      if (s == _Screen.game && level != null) {
        _gameLevel = level;
        _gameKey++; // fresh engine each entry
      }
      _screen = s;
    });
    ApothecaryAudio.instance.playMusic(
        s == _Screen.game ? 'music_game.wav' : 'music_menu.wav');
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
      case _Screen.menu:
        return true; // exit app
      case _Screen.levels:
        _go(_Screen.menu);
        return false;
      case _Screen.settings:
        _go(_settingsReturn);
        return false;
      case _Screen.game:
        _go(_Screen.levels);
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
        _Screen.menu => MenuScreen(
            onPlay: () =>
                _go(_Screen.game, level: ProgressStore.instance.current),
            onDailyMix: _dailyMix,
            onSettings: _openSettings,
            onLevels: () => _go(_Screen.levels),
          ),
        _Screen.levels => SelectScreen(
            onPick: (i) => _go(_Screen.game, level: i),
            onBack: () => _go(_Screen.menu),
          ),
        _Screen.game => GameScreen(
            key: ValueKey('game-$_gameKey'),
            level: _gameLevel,
            onExit: () => _go(_Screen.levels),
            onNextLevel: (n) => _go(_Screen.game, level: n),
          ),
        _Screen.settings => SettingsScreen(
            onBack: () => _go(_settingsReturn),
          ),
      },
    );
  }
}

extension on DateTime {
  int get dayOfYear =>
      difference(DateTime(year, 1, 1)).inDays;
}
