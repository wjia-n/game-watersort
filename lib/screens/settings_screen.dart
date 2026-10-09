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

/// Apothecary settings: parchment cards with brass toggles, walnut sliders,
/// player name, theme shortcut, difficulty tabs, reset progress, version plate.
class SettingsScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onThemes;
  final VoidCallback onPro;

  const SettingsScreen({
    super.key,
    required this.onBack,
    required this.onThemes,
    required this.onPro,
  });

  void _buzz() {
    if (AppSettings.instance.vibration) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    final t = s.theme;
    return CabinetBackground(
      theme: t,
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
                      theme: t,
                      onTap: () {
                        _buzz();
                        ApothecaryAudio.instance.click();
                        onBack();
                      }),
                  const SizedBox(width: 12),
                  Text('CABINET DRAWERS',
                      style:
                          ApothecaryText.display(22, color: t.parchment)),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListenableBuilder(
                  listenable: s,
                  builder: (context, child) {
                    final th = s.theme;
                    return ListView(
                      children: [
                        ParchmentCard(
                          theme: th,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _cardTitle(th, 'PLAYER'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(s.playerName,
                                        style: ApothecaryText.engraved(
                                            16, color: th.ink)),
                                  ),
                                  ParchmentTag(
                                    theme: th,
                                    label: 'Rename',
                                    icon: Icons.edit,
                                    onTap: () =>
                                        _renamePlayer(context, th),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ParchmentCard(
                          theme: th,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _cardTitle(th, 'CABINET STYLE'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(th.name,
                                        style: ApothecaryText.engraved(
                                            14, color: th.ink)),
                                  ),
                                  const SizedBox(width: 8),
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
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                        s.isPro
                                            ? 'PRO active'
                                            : 'Water Sort PRO',
                                        style: ApothecaryText.engraved(
                                            14, color: th.ink)),
                                  ),
                                  const SizedBox(width: 8),
                                  ParchmentTag(
                                    theme: th,
                                    label: s.isPro ? 'View' : 'Get PRO',
                                    icon: Icons.star,
                                    highlighted: !s.isPro,
                                    onTap: () {
                                      _buzz();
                                      ApothecaryAudio.instance.click();
                                      onPro();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ParchmentCard(
                          theme: th,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _cardTitle(th, 'MUSIC'),
                              _toggleRow(
                                th,
                                'Cabinet melodies',
                                s.musicOn,
                                (v) {
                                  s.setMusicOn(v);
                                  _buzz();
                                  ApothecaryAudio.instance.refresh();
                                },
                              ),
                              WalnutSlider(
                                theme: th,
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
                          theme: th,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _cardTitle(th, 'SOUND EFFECTS'),
                              _toggleRow(
                                th,
                                'Glass, glugs & corks',
                                s.sfxOn,
                                (v) {
                                  s.setSfxOn(v);
                                  _buzz();
                                  ApothecaryAudio.instance.refresh();
                                  if (v) {
                                    ApothecaryAudio.instance.click();
                                  }
                                },
                              ),
                              WalnutSlider(
                                theme: th,
                                value: s.sfxVol,
                                onChanged: (v) {
                                  s.setSfxVol(v);
                                  ApothecaryAudio.instance.refresh();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ParchmentCard(
                          theme: th,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _cardTitle(th, 'TOUCH'),
                              _toggleRow(
                                th,
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
                          theme: th,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _cardTitle(th, 'DIFFICULTY'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  for (final d in Difficulty.values)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        child: _diffTab(s, th, d),
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
                          theme: th,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _cardTitle(th, 'PROGRESS'),
                              const SizedBox(height: 8),
                              Center(
                                child: BrassButton(
                                  theme: th,
                                  label: 'Reset all recipes',
                                  fontSize: 13,
                                  onTap: () => _confirmReset(context, th),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'WATER SORT · v1.1.0 · WAJIHA',
                            style: ApothecaryText.plate(10,
                                color: th.parchmentDim),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardTitle(ApothecaryThemeDef t, String text) =>
      Text(text, style: ApothecaryText.engraved(14, color: t.ink));

  Widget _toggleRow(ApothecaryThemeDef t, String label, bool value,
      ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: ApothecaryText.bodyInk.copyWith(fontSize: 14)),
          ),
          BrassToggle(theme: t, value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _diffTab(AppSettings s, ApothecaryThemeDef t, Difficulty d) {
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
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [t.metalLight, t.metalDeep],
                )
              : null,
          color: active ? null : t.parchmentDim,
          border: Border.all(
              color: t.metalBorder, width: active ? 2 : 1),
        ),
        child: Text(
          name.toUpperCase(),
          textAlign: TextAlign.center,
          style: ApothecaryText.engraved(11, color: t.ink),
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

  void _renamePlayer(BuildContext context, ApothecaryThemeDef t) {
    final ctrl = TextEditingController(text: AppSettings.instance.playerName);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ParchmentCard(
          theme: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PLAYER NAME',
                  style: ApothecaryText.engraved(18, color: t.ink)),
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
                onSubmitted: (_) {
                  AppSettings.instance.setPlayerName(ctrl.text);
                  ApothecaryAudio.instance.pop();
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 10),
              Center(
                child: BrassButton(
                  theme: t,
                  label: 'Save',
                  fontSize: 13,
                  onTap: () {
                    AppSettings.instance.setPlayerName(ctrl.text);
                    ApothecaryAudio.instance.pop();
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

  void _confirmReset(BuildContext context, ApothecaryThemeDef t) {
    _buzz();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ParchmentCard(
          theme: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('EMPTY THE CABINET?',
                  style: ApothecaryText.engraved(18, color: t.ink)),
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
                    theme: t,
                    label: 'Pour it away',
                    fontSize: 13,
                    onTap: () {
                      ApothecaryAudio.instance.click();
                      ProgressStore.instance
                          .resetAll(kLevels.length, kMasterLevels.length);
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 10),
                  ParchmentTag(
                    theme: t,
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
