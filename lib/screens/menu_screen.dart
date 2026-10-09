import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../apothecary.dart';
import '../audio.dart';
import '../levels.dart';
import '../progress.dart';
import '../settings.dart';
import '../widgets/brass.dart';
import '../widgets/cabinet.dart';
import '../widgets/vial_widget.dart';

/// Apothecary main menu: title emblem → hero vials → Play knob →
/// How-to-Play / Daily Mix tags + settings gear.
class MenuScreen extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onDailyMix;
  final VoidCallback onSettings;
  final VoidCallback onLevels;

  const MenuScreen({
    super.key,
    required this.onPlay,
    required this.onDailyMix,
    required this.onSettings,
    required this.onLevels,
  });

  void _buzz() {
    if (AppSettings.instance.vibration) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressStore.instance;
    return CabinetBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  BrassIconButton(
                    icon: Icons.settings,
                    onTap: () {
                      _buzz();
                      ApothecaryAudio.instance.click();
                      onSettings();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // title emblem
              Text('WATER SORT',
                  textAlign: TextAlign.center,
                  style: ApothecaryText.display(40)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Apothecary.brassBorder.withValues(alpha: 0.8)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'THE APOTHECARY CABINET',
                  style: ApothecaryText.plate(11,
                      color: Apothecary.parchmentDim),
                ),
              ),
              const SizedBox(height: 18),
              // hero vials still life
              SizedBox(
                height: 210,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const VialWidget(
                        units: [0, 0, 1, 1],
                        width: 74,
                        height: 190,
                        cork: true),
                    const SizedBox(width: 18),
                    const VialWidget(
                        units: [2, 3, 2, 3],
                        width: 84,
                        height: 208,
                        cork: true),
                    const SizedBox(width: 18),
                    const VialWidget(
                        units: [4, 4, 4, 4],
                        width: 74,
                        height: 190,
                        cork: true,
                        locked: true),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${progress.done.length} of ${kLevels.length} recipes bottled',
                style: ApothecaryText.plate(12,
                    color: Apothecary.parchmentDim),
              ),
              const Spacer(),
              // Play knob
              BrassButton(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ParchmentTag(
                    label: 'Recipes',
                    icon: Icons.grid_view,
                    onTap: () {
                      _buzz();
                      ApothecaryAudio.instance.click();
                      onLevels();
                    },
                  ),
                  const SizedBox(width: 10),
                  ParchmentTag(
                    label: 'Daily Mix',
                    icon: Icons.local_drink,
                    onTap: () {
                      _buzz();
                      ApothecaryAudio.instance.click();
                      onDailyMix();
                    },
                  ),
                  const SizedBox(width: 10),
                  ParchmentTag(
                    label: 'How to Play',
                    icon: Icons.menu_book,
                    onTap: () {
                      _buzz();
                      ApothecaryAudio.instance.click();
                      _showHowTo(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHowTo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ParchmentCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HOW TO PLAY',
                  style: ApothecaryText.engraved(20)),
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
    );
  }
}
