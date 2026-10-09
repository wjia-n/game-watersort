import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../apothecary.dart';
import '../audio.dart';
import '../levels.dart';
import '../progress.dart';
import '../settings.dart';
import '../widgets/brass.dart';
import '../widgets/cabinet.dart';

/// Level select: parchment recipe cards with star seals. Serves both the
/// classic recipe book and the Master Cabinet hard levels.
class SelectScreen extends StatelessWidget {
  final String title;
  final List<List<List<int>>> levels;
  final bool master;
  final void Function(int level) onPick;
  final VoidCallback onBack;

  const SelectScreen({
    super.key,
    required this.title,
    required this.levels,
    required this.master,
    required this.onPick,
    required this.onBack,
  });

  void _buzz() {
    if (AppSettings.instance.vibration) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressStore.instance;
    final t = AppSettings.instance.theme;
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
                  Expanded(
                    child: Text(title,
                        style: ApothecaryText.display(22, color: t.parchment)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ListenableBuilder(
                listenable: progress,
                builder: (_, _) {
                  final doneCount =
                      master ? progress.masterDone.length : progress.done.length;
                  return Text(
                    '$doneCount of ${levels.length} recipes bottled',
                    style:
                        ApothecaryText.plate(12, color: t.parchmentDim),
                  );
                },
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListenableBuilder(
                  listenable: progress,
                  builder: (_, _) => GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: levels.length,
                    itemBuilder: (_, i) {
                      final stars = master
                          ? progress.masterStars[i] ?? 0
                          : progress.stars[i] ?? 0;
                      final done = master
                          ? progress.masterDone.contains(i)
                          : progress.done.contains(i);
                      final colorCount = levelColorCount(levels[i]);
                      return GestureDetector(
                        onTap: () {
                          _buzz();
                          ApothecaryAudio.instance.click();
                          onPick(i);
                        },
                        child: ParchmentCard(
                          theme: t,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          radius: 10,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var s = 0; s < 3; s++)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 1.5),
                                      child: StarSeal(
                                          earned: stars > s,
                                          size: 20,
                                          theme: t),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Nº ${i + 1}',
                                  style: ApothecaryText.engraved(16,
                                      color: t.ink)),
                              Text('$colorCount tinctures',
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 11,
                                    color: t.ink.withValues(alpha: 0.7),
                                  )),
                              if (done)
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.check_circle,
                                      size: 15,
                                      color: Color(0xFF4E7A3A)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
