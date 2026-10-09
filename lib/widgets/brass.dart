import 'package:flutter/material.dart';

import '../apothecary.dart';

/// Tarnished-brass push button: brass face, 1px engraved border, pressed =
/// inset shadow (physical resistance), never a glow.
class BrassButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const BrassButton({
    super.key,
    required this.label,
    required this.onTap,
    this.fontSize = 17,
    this.padding = const EdgeInsets.symmetric(horizontal: 34, vertical: 15),
  });

  @override
  State<BrassButton> createState() => _BrassButtonState();
}

class _BrassButtonState extends State<BrassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTap: enabled
          ? () {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: _pressed
                ? const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Apothecary.brassDeep, Apothecary.brassLight],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Apothecary.brassLight, Apothecary.brassDeep],
                  ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Apothecary.brassBorder, width: 1.5),
            boxShadow: _pressed
                ? [
                    const BoxShadow(
                      color: Color(0x88000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                      // pressed: inset feel via dark top shade
                    ),
                    const BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 4,
                      offset: Offset(0, -2),
                      spreadRadius: -2,
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Color(0x99000000),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                    const BoxShadow(
                      color: Color(0x66FFE9C4),
                      blurRadius: 1,
                      offset: Offset(0, -1),
                    ),
                  ],
          ),
          child: Text(
            widget.label.toUpperCase(),
            textAlign: TextAlign.center,
            style: ApothecaryText.engraved(widget.fontSize),
          ),
        ),
      ),
    );
  }
}

/// Small circular brass icon button (HUD controls), 44px+ touch target.
class BrassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const BrassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Apothecary.brassLight, Apothecary.brassDeep],
            ),
            border: Border.all(color: Apothecary.brassBorder, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x99000000), blurRadius: 5, offset: Offset(0, 3)),
            ],
          ),
          child: Icon(icon, color: Apothecary.inkBrown, size: size * 0.48),
        ),
      ),
    );
  }
}

/// Parchment card with deckled-edge feel: warm drop shadow, sepia ink text.
class ParchmentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const ParchmentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Apothecary.parchment,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFB89B62), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Twine-tied parchment tag: secondary actions (Undo / Add Vial / Replay).
class ParchmentTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool highlighted;

  const ParchmentTag({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: highlighted
                ? Apothecary.brassLight.withValues(alpha: 0.35)
                : Apothecary.parchment,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlighted
                  ? Apothecary.brassBorder
                  : const Color(0xFFB89B62),
              width: highlighted ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Apothecary.inkBrown),
              const SizedBox(width: 6),
              Text(label.toUpperCase(),
                  style: ApothecaryText.engraved(12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Physical brass toggle switch.
class BrassToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const BrassToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 58,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: value ? Apothecary.brassDeep : const Color(0xFF4A3A26),
          border: Border.all(color: Apothecary.brassBorder, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Color(0x88000000), blurRadius: 3, offset: Offset(0, 2)),
          ],
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Apothecary.brassLight, Apothecary.brassDeep],
              ),
              boxShadow: [
                BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 2,
                    offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Walnut slider track with brass knob thumb.
class WalnutSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const WalnutSlider({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 10,
        activeTrackColor: const Color(0xFF3A2818),
        inactiveTrackColor: Apothecary.timberInset,
        thumbColor: Apothecary.brassLight,
        overlayColor: Apothecary.brassLight.withValues(alpha: 0.2),
        thumbShape: const _BrassThumb(),
        trackShape: const _WalnutTrack(),
      ),
      child: Slider(value: value, onChanged: onChanged),
    );
  }
}

class _BrassThumb extends SliderComponentShape {
  const _BrassThumb();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(26, 26);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final canvas = context.canvas;
    final grad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Apothecary.brassLight, Apothecary.brassDeep],
    );
    canvas.drawCircle(
        center, 13, Paint()..shader = grad.createShader(Rect.fromCircle(center: center, radius: 13)));
    canvas.drawCircle(
      center,
      13,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Apothecary.brassBorder,
    );
    canvas.drawCircle(center, 4,
        Paint()..color = Apothecary.brassBorder.withValues(alpha: 0.7));
  }
}

class _WalnutTrack extends RoundedRectSliderTrackShape {
  const _WalnutTrack();
  @override
  void paint(PaintingContext context, Offset offset,
      {required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required Animation<double> enableAnimation,
      required TextDirection textDirection,
      required Offset thumbCenter,
      Offset? secondaryOffset,
      bool isDiscrete = false,
      bool isEnabled = false,
      double additionalActiveTrackHeight = 2}) {
    super.paint(context, offset,
        parentBox: parentBox,
        sliderTheme: sliderTheme,
        enableAnimation: enableAnimation,
        textDirection: textDirection,
        thumbCenter: thumbCenter,
        isDiscrete: isDiscrete,
        isEnabled: isEnabled,
        additionalActiveTrackHeight: additionalActiveTrackHeight);
    // inner shadow line for mortise depth
    final canvas = context.canvas;
    final trackRect = Rect.fromCenter(
        center: Offset(thumbCenter.dx, thumbCenter.dy),
        width: parentBox.size.width - 32,
        height: 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, const Radius.circular(1)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
  }
}

/// Brass star seal for the victory recipe card.
class StarSeal extends StatelessWidget {
  final bool earned;
  final double size;

  const StarSeal({super.key, required this.earned, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: earned
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Apothecary.brassLight, Apothecary.brassDeep],
              )
            : null,
        color: earned ? null : const Color(0xFF3A2C1C),
        border: Border.all(
            color: earned ? Apothecary.brassBorder : const Color(0xFF2A2016),
            width: 2),
        boxShadow: earned
            ? const [
                BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 5,
                    offset: Offset(0, 3))
              ]
            : null,
      ),
      child: Icon(
        Icons.star,
        color: earned ? Apothecary.inkBrown : const Color(0xFF241A10),
        size: size * 0.55,
      ),
    );
  }
}
