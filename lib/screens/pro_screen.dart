import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../apothecary.dart';
import '../audio.dart';
import '../services/store.dart';
import '../settings.dart';
import '../themes.dart';
import '../widgets/brass.dart';
import '../widgets/cabinet.dart';

/// Water Sort PRO: Free-vs-Pro comparison, real purchase, restore, tip jar.
/// All prices come from the store — never hardcoded, never placeholders.
class ProScreen extends StatefulWidget {
  final StoreService store;
  final VoidCallback onBack;

  const ProScreen({super.key, required this.store, required this.onBack});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  ApothecaryThemeDef get _t => AppSettings.instance.theme;

  @override
  void initState() {
    super.initState();
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      AppSettings.instance.setPro(true);
      ApothecaryAudio.instance.chime();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — the full cabinet is yours!',
              style: ApothecaryText.engraved(14, color: _t.ink)),
          backgroundColor: _t.parchment,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
    }
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    ApothecaryAudio.instance.chime();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: ApothecaryText.engraved(14, color: _t.ink)),
        backgroundColor: _t.parchment,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = AppSettings.instance;
    final store = widget.store;
    return CabinetBackground(
      theme: t,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  BrassIconButton(
                    icon: Icons.arrow_back,
                    size: 42,
                    theme: t,
                    onTap: () {
                      ApothecaryAudio.instance.click();
                      widget.onBack();
                    },
                  ),
                  const SizedBox(width: 12),
                  Text('WATER SORT PRO',
                      style: ApothecaryText.display(22, color: t.parchment)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListenableBuilder(
                listenable: s,
                builder: (_, _) => ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  children: [
                    _ComparisonCard(theme: t, isPro: s.isPro),
                    const SizedBox(height: 14),
                    _BuyCard(theme: t, settings: s, store: store),
                    const SizedBox(height: 14),
                    _TipsCard(theme: t, store: store),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Free vs Pro comparison table — buyers see the big difference.
class _ComparisonCard extends StatelessWidget {
  final ApothecaryThemeDef theme;
  final bool isPro;
  const _ComparisonCard({required this.theme, required this.isPro});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Complete water sort game', true, true),
      ('All official rules', true, true),
      ('Recipe progression + Daily Mix', true, true),
      ('Master Cabinet hard levels', true, true),
      ('Undo, hints, add-vial', true, true),
      ('Music & sound effects', true, true),
      ('Renameable player profile', true, true),
      ('Cabinet themes', '4', '14'),
      ('Liquid tincture palettes', '2', '10'),
      ('Glass vial styles', '2', '5'),
      ('Custom theme creator', false, true),
      ('Support the indie apothecary', false, true),
    ];
    return ParchmentCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FREE vs PRO', style: ApothecaryText.engraved(16, color: theme.ink)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              SizedBox(
                  width: 64,
                  child: Text('FREE',
                      textAlign: TextAlign.center,
                      style: ApothecaryText.engraved(11, color: theme.ink))),
              SizedBox(
                  width: 64,
                  child: Text('PRO',
                      textAlign: TextAlign.center,
                      style: ApothecaryText.engraved(11, color: theme.ink))),
            ],
          ),
          const SizedBox(height: 4),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(r.$1,
                        style: ApothecaryText.bodyInk.copyWith(fontSize: 13)),
                  ),
                  SizedBox(width: 64, child: Center(child: _cell(r.$2, theme))),
                  SizedBox(width: 64, child: Center(child: _cell(r.$3, theme))),
                ],
              ),
            ),
          if (isPro)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text('✦ PRO ACTIVE ✦',
                    style: ApothecaryText.engraved(13, color: theme.ink)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(Object v, ApothecaryThemeDef theme) {
    if (v is bool) {
      return Icon(
        v ? Icons.check_circle : Icons.remove_circle_outline,
        size: 18,
        color: v ? const Color(0xFF4E7A3A) : theme.parchmentDim,
      );
    }
    return Text('$v',
        style: ApothecaryText.engraved(12, color: theme.ink));
  }
}

/// The actual buy button — real store price, or an honest "after store
/// setup" note when the products are not configured yet.
class _BuyCard extends StatelessWidget {
  final ApothecaryThemeDef theme;
  final AppSettings settings;
  final StoreService store;
  const _BuyCard(
      {required this.theme, required this.settings, required this.store});

  @override
  Widget build(BuildContext context) {
    return ParchmentCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UNLOCK PRO', style: ApothecaryText.engraved(16, color: theme.ink)),
          const SizedBox(height: 6),
          Text(
            'One-time purchase. Yours forever, on every device.',
            style: ApothecaryText.bodyInk.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: store.purchaseInProgress,
            builder: (_, busy, _) {
              final p = store.proProduct;
              if (!store.storeReady || p == null) {
                return _setupNote(theme, store.error);
              }
              return Center(
                child: BrassButton(
                  theme: theme,
                  label: settings.isPro
                      ? 'PRO active'
                      : 'Get PRO — ${p.price}',
                  onTap: settings.isPro || busy ? null : store.buyPro,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Center(
            child: ParchmentTag(
              theme: theme,
              label: 'Restore purchase',
              icon: Icons.restore,
              onTap: store.storeReady ? store.restore : null,
            ),
          ),
          ValueListenableBuilder<String?>(
            valueListenable: store.purchaseError,
            builder: (_, err, _) => err == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(err,
                        textAlign: TextAlign.center,
                        style: ApothecaryText.bodyInk
                            .copyWith(fontSize: 12, color: const Color(0xFF8C3B2A))),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tip jar: coffee & chocolate consumables. Real products only.
class _TipsCard extends StatelessWidget {
  final ApothecaryThemeDef theme;
  final StoreService store;
  const _TipsCard({required this.theme, required this.store});

  @override
  Widget build(BuildContext context) {
    return ParchmentCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TIP JAR', style: ApothecaryText.engraved(16, color: theme.ink)),
          const SizedBox(height: 6),
          Text(
            'Water Sort is free forever. A tip keeps the candle lit.',
            style: ApothecaryText.bodyInk.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            _setupNote(theme, store.error)
          else
            Row(
              children: [
                Expanded(
                    child: _tipButton(theme, store, store.coffeeProduct,
                        Icons.local_cafe, 'Coffee')),
                const SizedBox(width: 10),
                Expanded(
                    child: _tipButton(theme, store, store.chocolateProduct,
                        Icons.cookie, 'Chocolate')),
              ],
            ),
        ],
      ),
    );
  }

  Widget _tipButton(ApothecaryThemeDef theme, StoreService store,
      ProductDetails? p, IconData icon, String label) {
    if (p == null) return const SizedBox.shrink();
    return ParchmentTag(
      theme: theme,
      label: '$label · ${p.price}',
      icon: icon,
      onTap: () {
        ApothecaryAudio.instance.click();
        store.buyTip(p);
      },
    );
  }
}

/// Honest placeholder shown while the Play Console products are not yet
/// created — never a fake buy button.
Widget _setupNote(ApothecaryThemeDef theme, String? error) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(color: theme.metalBorder),
      borderRadius: BorderRadius.circular(10),
      color: theme.parchmentDim.withValues(alpha: 0.35),
    ),
    child: Text(
      'Purchases ${error ?? 'are being set up'} — the full game stays free '
      'meanwhile.',
      textAlign: TextAlign.center,
      style: ApothecaryText.bodyInk.copyWith(fontSize: 13),
    ),
  );
}
