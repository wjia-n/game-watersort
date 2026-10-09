import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../apothecary.dart';
import '../audio.dart';
import '../levels.dart';
import '../progress.dart';
import '../settings.dart';
import '../themes.dart';
import '../widgets/brass.dart';
import '../widgets/cabinet.dart';
import '../widgets/vial_widget.dart';

/// Apothecary main menu: logo emblem → player plate → hero vials →
/// Play knob → mode tags → settings gear.
class MenuScreen extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onRecipes;
  final VoidCallback onMaster;
  final VoidCallback onDailyMix;
  final VoidCallback onThemes;
  final VoidCallback onPro;
  final VoidCallback onSettings;

  const MenuScreen({
    super.key,
    required this.onPlay,
    required this.onRecipes,
    required this.onMaster,
    required this.onDailyMix,
    required this.onThemes,
    required this.onPro,
    required this.onSettings,
  });

  void _buzz() {
    if (AppSettings.instance.vibration) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressStore.instance;
    final s = AppSettings.instance;
    final t = s.theme;
    return CabinetBackground(
      theme: t,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: s,
          builder: (_, _) {
            final th = s.theme;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      BrassIconButton(
                        icon: Icons.settings,
                        theme: th,
                        onTap: () {
                          _buzz();
                          ApothecaryAudio.instance.click();
                          onSettings();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // game logo emblem
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: th.metalLight, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/watersort_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 10),
                  Text('WATER SORT',
                      textAlign: TextAlign.center,
                      style: ApothecaryText.display(38, color: th.parchment)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: th.metalBorder.withValues(alpha: 0.8)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'THE APOTHECARY CABINET',
                      style:
                          ApothecaryText.plate(11, color: th.parchmentDim),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // player plate (tap to rename)
                  GestureDetector(
                    onTap: () => _renamePlayer(context, th),
                    child: BrassPlate(
                      theme: th,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person,
                              size: 16, color: th.ink),
                          const SizedBox(width: 8),
                          Text(s.playerName,
                              style:
                                  ApothecaryText.engraved(14, color: th.ink)),
                          const SizedBox(width: 6),
                          Icon(Icons.edit, size: 13, color: th.ink),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // hero vials still life
                  SizedBox(
                    height: 190,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        VialWidget(
                            units: const [0, 0, 1, 1],
                            width: 70,
                            height: 172,
                            cork: true,
                            palette: th.palette,
                            glass: th.glass),
                        const SizedBox(width: 16),
                        VialWidget(
                            units: const [2, 3, 2, 3],
                            width: 80,
                            height: 188,
                            cork: true,
                            palette: th.palette,
                            glass: th.glass),
                        const SizedBox(width: 16),
                        VialWidget(
                            units: const [4, 4, 4, 4],
                            width: 70,
                            height: 172,
                            cork: true,
                            locked: true,
                            palette: th.palette,
                            glass: th.glass),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${progress.done.length} of ${kLevels.length + kMasterLevels.length} recipes bottled',
                    style: ApothecaryText.plate(12, color: th.parchmentDim),
                  ),
                  const SizedBox(height: 16),
                  // Play knob
                  BrassButton(
                    theme: th,
                    label: 'Play',
                    fontSize: 20,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 64, vertical: 17),
                    onTap: () {
                      _buzz();
                      ApothecaryAudio.instance.start();
                      onPlay();
                    },
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ParchmentTag(
                        theme: th,
                        label: 'Recipes',
                        icon: Icons.grid_view,
                        onTap: () {
                          _buzz();
                          ApothecaryAudio.instance.click();
                          onRecipes();
                        },
                      ),
                      ParchmentTag(
                        theme: th,
                        label: 'Master',
                        icon: Icons.workspace_premium,
                        onTap: () {
                          _buzz();
                          ApothecaryAudio.instance.click();
                          onMaster();
                        },
                      ),
                      ParchmentTag(
                        theme: th,
                        label: 'Daily Mix',
                        icon: Icons.local_drink,
                        onTap: () {
                          _buzz();
                          ApothecaryAudio.instance.click();
                          onDailyMix();
                        },
                      ),
                      ParchmentTag(
                        theme: th,
                        label: 'Themes',
                        icon: Icons.palette,
                        onTap: () {
                          _buzz();
                          ApothecaryAudio.instance.click();
                          onThemes();
                        },
                      ),
                      ParchmentTag(
                        theme: th,
                        label: s.isPro ? 'PRO ✓' : 'PRO',
                        icon: Icons.star,
                        highlighted: !s.isPro,
                        onTap: () {
                          _buzz();
                          ApothecaryAudio.instance.click();
                          onPro();
                        },
                      ),
                      ParchmentTag(
                        theme: th,
                        label: 'How to Play',
                        icon: Icons.menu_book,
                        onTap: () {
                          _buzz();
                          ApothecaryAudio.instance.click();
                          _showHowTo(context, th);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _renamePlayer(BuildContext context, ApothecaryThemeDef th) {
    final ctrl =
        TextEditingController(text: AppSettings.instance.playerName);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ParchmentCard(
          theme: th,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PLAYER NAME',
                  style: ApothecaryText.engraved(18, color: th.ink)),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                maxLength: 18,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: ApothecaryText.bodyInk,
                // Save on every keystroke: focus loss, tap-outside dismissal,
                // or the back button can never lose the rename.
                onChanged: (v) => AppSettings.instance.setPlayerName(v),
                onSubmitted: (_) => _saveName(context, ctrl.text),
              ),
              const SizedBox(height: 10),
              Center(
                child: BrassButton(
                  theme: th,
                  label: 'Save',
                  fontSize: 13,
                  onTap: () => _saveName(context, ctrl.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveName(BuildContext context, String name) {
    AppSettings.instance.setPlayerName(name);
    ApothecaryAudio.instance.pop();
    Navigator.of(context).pop();
  }

  void _showHowTo(BuildContext context, ApothecaryThemeDef th) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ParchmentCard(
          theme: th,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HOW TO PLAY',
                    style: ApothecaryText.engraved(20, color: th.ink)),
                const SizedBox(height: 10),
                const Text(
                  '• Tap a vial to lift it, then tap another vial to pour.\n'
                  '• Pour only onto the same liquid — or into an empty vial.\n'
                  '• Only the top layer of matching liquid pours at once.\n'
                  '• A full vial of one liquid seals itself with a brass '
                  'collar and can no longer be poured from.\n'
                  '• Sort every vial: full of one liquid, or empty.\n'
                  '• Undo is unlimited. Stuck? Add a vial or ask the brass '
                  'spoon for a hint.',
                  style: ApothecaryText.bodyInk,
                ),
                const SizedBox(height: 14),
                Center(
                  child: BrassButton(
                    theme: th,
                    label: 'Back to the cabinet',
                    fontSize: 13,
                    onTap: () {
                      ApothecaryAudio.instance.click();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
