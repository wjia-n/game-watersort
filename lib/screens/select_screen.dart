import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../apothecary.dart';
import '../audio.dart';
import '../levels.dart';
import '../progress.dart';
import '../settings.dart';
import '../widgets/brass.dart';
import '../widgets/cabinet.dart';

/// Level select: parchment recipe cards with star seals.
class SelectScreen extends StatelessWidget {
  final void Function(int level) onPick;
  final VoidCallback onBack;

  const SelectScreen({super.key, required this.onPick, required this.onBack});

  void _buzz() {
    if (AppSettings.instance.vibration) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressStore.instance;
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
                  Text('RECIPE BOOK',
                      style: ApothecaryText.display(24)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${progress.done.length} of ${kLevels.length} recipes bottled',
                style: ApothecaryText.plate(12,
                    color: Apothecary.parchmentDim),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: kLevels.length,
                  itemBuilder: (_, i) {
                    final stars = progress.stars[i] ?? 0;
                    final done = progress.done.contains(i);
                    final colorCount = kLevels[i]
                        .where((v) => v.isNotEmpty)
                        .length;
                    return GestureDetector(
                      onTap: () {
                        _buzz();
                        ApothecaryAudio.instance.click();
                        onPick(i);
                      },
                      child: ParchmentCard(
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
                                        earned: stars > s, size: 20),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Nº ${i + 1}',
                                style: ApothecaryText.engraved(16)),
                            Text('$colorCount tinctures',
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 11,
                                  color: Color(0xFF6B5233),
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
            ],
          ),
        ),
      ),
    );
  }
}
