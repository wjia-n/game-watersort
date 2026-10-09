import 'package:flutter/material.dart';

import '../apothecary.dart';
import '../audio.dart';
import '../services/store.dart';
import '../settings.dart';
import '../widgets/cabinet.dart';

/// Single launch splash: game logo + name, animated loading line, and the
/// "Credits: WAJIHA" line with the company logo. While it shows, audio clips
/// are pre-warmed and the store is initialized, then menu music starts.
class SplashScreen extends StatefulWidget {
  final StoreService store;
  final VoidCallback onDone;

  const SplashScreen({super.key, required this.store, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    final audio = ApothecaryAudio.instance;
    audio.prewarm();
    // Store init is best-effort; splash never blocks on it.
    widget.store.init().catchError((_) {});
    audio.startMenuMusic();
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    widget.onDone();
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppSettings.instance.theme;
    return Scaffold(
      backgroundColor: t.bg,
      body: CabinetBackground(
        theme: t,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: t.metalLight, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/watersort_logo.png',
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 22),
              Text('WATER SORT',
                  style: ApothecaryText.display(44, color: t.parchment)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: t.metalBorder.withValues(alpha: 0.8)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'THE APOTHECARY CABINET',
                  style: ApothecaryText.plate(11, color: t.parchmentDim),
                ),
              ),
              const SizedBox(height: 30),
              // Animated loading line.
              SizedBox(
                width: 220,
                child: AnimatedBuilder(
                  animation: _loader,
                  builder: (_, _) => Column(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                              color: t.metalLight.withValues(alpha: 0.5)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _loader.value.clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: LinearGradient(
                                colors: [t.metalLight, t.metalDeep],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _loader.value < 1
                            ? 'Decanting the tinctures…'
                            : 'Ready!',
                        style: ApothecaryText.plate(13,
                            color: t.parchment.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/wajiha_logo.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Credits: WAJIHA',
                    style: ApothecaryText.engraved(14, color: t.ink),
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
