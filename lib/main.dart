import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const WaterSortApp());

class WaterSortApp extends StatelessWidget {
  const WaterSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.candyShop,
      title: 'Water Sort',
      tagline: 'Pour colorful liquids and sort every tube perfectly',
      emoji: '🧪',
      slug: 'watersort',
      howToPlay:
          '• Tap a tube to lift it, then tap another tube to pour.\n• You can only pour onto the same color — or into an empty tube.\n• Win when every tube holds a single color (or nothing at all).\n• Made a splashy mistake? Smash that undo button. ↩️',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          WaterSortScreen(players: players, callbacks: cb),
    );
  }
}
