import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watersort/settings.dart';

/// Regression test for the 2026-10-09 batch-1 player-name bug class.
///
/// In several games, player names were persisted with
/// SharedPreferences.setStringList, which Android backs with an UNORDERED
/// StringSet — so name order was scrambled on every app restart
/// (fixed in ludo via a single JSON string; MASTER_RULES.md now bans
/// setStringList for names).
///
/// Water Sort was checked and does NOT have the bug: its single player name
/// is stored as one plain string ('watersort_player_name' via setString),
/// which is inherently order-preserving, so no JSON migration was needed.
/// These tests pin that the name round-trips through prefs exactly as typed,
/// using the mock prefs backend (no platform channels needed).
void main() {
  test('player name persists as one order-preserving string, never a list',
      () async {
    // Simulate a rename saved by a previous app run.
    SharedPreferences.setMockInitialValues(
        {'watersort_player_name': 'Zara the Great'});

    final s = AppSettings.instance;
    await s.load();
    // Read path: the exact stored string comes back, nothing reordered.
    expect(s.playerName, 'Zara the Great');

    // Write path: rename, then flush the fire-and-forget _save().
    s.setPlayerName('Wajiha');
    expect(s.playerName, 'Wajiha');
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final p = await SharedPreferences.getInstance();
    expect(p.getString('watersort_player_name'), 'Wajiha');
    // The unordered-list storage banned by MASTER_RULES.md must not be used
    // for the player name.
    expect(p.getStringList('watersort_player_name'), isNull);
  });

  test('blank rename falls back to the default name', () async {
    final s = AppSettings.instance;
    await s.load();
    s.setPlayerName('   ');
    expect(s.playerName, 'Player');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final p = await SharedPreferences.getInstance();
    expect(p.getString('watersort_player_name'), 'Player');
  });
}
