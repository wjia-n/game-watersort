import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../apothecary.dart';
import '../audio.dart';
import '../levels.dart';
import '../progress.dart';
import '../settings.dart';
import '../widgets/brass.dart';
import '../widgets/cabinet.dart';

/// Apothecary settings: parchment cards with brass toggles, walnut sliders,
/// difficulty tabs, reset progress, version plate.
class SettingsScreen extends StatelessWidget {
  final VoidCallback onBack;

  const SettingsScreen({super.key, required this.onBack});

  void _buzz() {
    if (AppSettings.instance.vibration) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    return CabinetBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  BrassIconButton(
                      icon: Icons.arrow_back,
                      size: 42,
                      onTap: () {
                        _buzz();
                        ApothecaryAudio.instance.click();
                        onBack();
                      }),
                  const SizedBox(width: 12),
                  Text('CABINET DRAWERS',
                      style: ApothecaryText.display(22)),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListenableBuilder(
                  listenable: s,
                  builder: (context, child) => ListView(
                    children: [
                      ParchmentCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardTitle('MUSIC'),
                            _toggleRow(
                              'Cabinet melodies',
                              s.musicOn,
                              (v) {
                                s.setMusicOn(v);
                                _buzz();
                                ApothecaryAudio.instance.refresh();
                              },
                            ),
                            WalnutSlider(
                              value: s.musicVol,
                              onChanged: (v) {
                                s.setMusicVol(v);
                                ApothecaryAudio.instance.refresh();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ParchmentCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardTitle('SOUND EFFECTS'),
                            _toggleRow(
                              'Glass, glugs & corks',
                              s.sfxOn,
                              (v) {
                                s.setSfxOn(v);
                                _buzz();
                                if (v) {
                                  ApothecaryAudio.instance.click();
                                }
                              },
                            ),
                            WalnutSlider(
                              value: s.sfxVol,
                              onChanged: (v) {
                                s.setSfxVol(v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ParchmentCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardTitle('TOUCH'),
                            _toggleRow(
                              'Vibration',
                              s.vibration,
                              (v) {
                                s.setVibration(v);
                                _buzz();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ParchmentCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardTitle('DIFFICULTY'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                for (final d in Difficulty.values)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: _diffTab(s, d),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _diffBlurb(s.difficulty),
                              style: ApothecaryText.bodyInk
                                  .copyWith(fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ParchmentCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardTitle('PROGRESS'),
                            const SizedBox(height: 8),
                            Center(
                              child: BrassButton(
                                label: 'Reset all recipes',
                                fontSize: 13,
                                onTap: () => _confirmReset(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'WATER SORT · v1.0.0 · WAJIHA',
                          style: ApothecaryText.plate(10,
                              color: Apothecary.parchmentDim),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardTitle(String t) => Text(t, style: ApothecaryText.engraved(14));

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style:
                    ApothecaryText.bodyInk.copyWith(fontSize: 14)),
          ),
          BrassToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _diffTab(AppSettings s, Difficulty d) {
    final active = s.difficulty == d;
    final name = switch (d) {
      Difficulty.gentle => 'Gentle',
      Difficulty.classic => 'Classic',
      Difficulty.master => 'Master',
    };
    return GestureDetector(
      onTap: () {
        _buzz();
        ApothecaryAudio.instance.click();
        s.setDifficulty(d);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Apothecary.brassLight,
                    Apothecary.brassDeep
                  ],
                )
              : null,
          color: active ? null : const Color(0xFFD8C49C),
          border: Border.all(
              color: Apothecary.brassBorder,
              width: active ? 2 : 1),
        ),
        child: Text(
          name.toUpperCase(),
          textAlign: TextAlign.center,
          style: ApothecaryText.engraved(11),
        ),
      ),
    );
  }

  String _diffBlurb(Difficulty d) => switch (d) {
        Difficulty.gentle =>
          'Fewer worries: two spare vials per recipe.',
        Difficulty.classic =>
          'The classic cabinet: one spare vial per recipe.',
        Difficulty.master =>
          'No spare vials. For steady hands only.',
      };

  void _confirmReset(BuildContext context) {
    _buzz();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ParchmentCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('EMPTY THE CABINET?',
                  style: ApothecaryText.engraved(18)),
              const SizedBox(height: 8),
              const Text(
                'All bottled recipes, stars and perfect pours will be '
                'poured away. This cannot be undone.',
                style: ApothecaryText.bodyInk,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BrassButton(
                    label: 'Pour it away',
                    fontSize: 13,
                    onTap: () {
                      ApothecaryAudio.instance.click();
                      ProgressStore.instance.resetAll(kLevels.length);
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 10),
                  ParchmentTag(
                    label: 'Keep',
                    icon: Icons.close,
                    onTap: () {
                      ApothecaryAudio.instance.click();
                      Navigator.of(context).pop();
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
}
