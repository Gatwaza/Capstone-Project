// Novice — CPR-AI Coach
// GNU General Public License v3.0
//
// tilt_3d.dart — Hover feedback for clickable cards, ported to match
// web/index.html's `.mod-card` hover/active style exactly:
//   .mod-card:hover        { transform:translateY(-3px); box-shadow:var(--shadow-md); border-color:var(--border-m) }
//   .mod-card.active       { border-color:var(--card-accent); box-shadow:0 0 0 1px var(--card-accent), var(--shadow-md) }
//
// This used to be a pointer-tracked 3D tilt, then a hover zoom-out — both
// caused unwanted side-to-side or shrinking motion. This version only
// lifts the card slightly and highlights its border/ring in the card's
// accent color, matching the "What do you want to practise?" screen's
// selected-card look (e.g. the CPR card's colored outline) for every
// clickable card, on hover, for consistency across the app.
//
// Mouse/trackpad only (matches `if (e.pointerType === 'touch') return;`
// in the HTML) — on touch devices this is a no-op passthrough so taps
// aren't affected.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class Tilt3D extends StatefulWidget {
  const Tilt3D({
    super.key,
    required this.child,
    this.borderRadius,
    this.accentColor,
    this.lift = 3,
  });

  final Widget child;
  final BorderRadius? borderRadius;

  /// Border/ring color shown on hover, matching the web version's
  /// `--card-accent`. Falls back to a neutral highlight if omitted.
  final Color? accentColor;

  /// How far (in logical pixels) the card lifts on hover.
  final double lift;

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      value: 0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(PointerHoverEvent event) {
    if (_hovering) return;
    setState(() => _hovering = true);
    _controller.animateTo(1, duration: const Duration(milliseconds: 120));
  }

  void _onExit() {
    setState(() => _hovering = false);
    _controller.animateTo(0, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? Colors.white.withOpacity(0.24);

    return MouseRegion(
      onHover: _onHover,
      onExit: (_) => _onExit(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;

          return Transform.translate(
            offset: Offset(0, -widget.lift * t),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                boxShadow: [
                  // Ring highlight (only visible once hovered, like
                  // `box-shadow:0 0 0 1px var(--card-accent)`).
                  if (t > 0)
                    BoxShadow(
                      color: accent.withOpacity(0.9 * t),
                      spreadRadius: 1 * t,
                      blurRadius: 0,
                    ),
                  // Soft elevation shadow (`var(--shadow-md)`), present at
                  // rest and slightly stronger on hover.
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08 + 0.06 * t),
                    blurRadius: 12 + 10 * t,
                    offset: Offset(0, 4 + 4 * t),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}