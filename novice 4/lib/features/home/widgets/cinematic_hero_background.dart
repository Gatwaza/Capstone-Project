// Novice — CPR-AI Coach
// GNU General Public License v3.0
//
// cinematic_hero_background.dart — Flutter port of web/index.html's
// .hero-left-bg / .hero-left-grade / .hero-left-reflection trio.
// Same source photo (web/images/hero-left.webp, served as a relative web
// asset — no pubspec change needed since Flutter web already serves
// everything under web/ from the app's base href), same slow 22s
// scale+pan "Ken Burns" drift, same colour-graded gradient wash, same
// flipped/blurred/masked "reflection" strip along the bottom edge.
// Sits behind the home screen's scrollable content as the very back layer
// of a Stack — see home_screen.dart.

import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class CinematicHeroBackground extends StatefulWidget {
  const CinematicHeroBackground({super.key, required this.isDark});

  final bool isDark;

  @override
  State<CinematicHeroBackground> createState() =>
      _CinematicHeroBackgroundState();
}

class _CinematicHeroBackgroundState extends State<CinematicHeroBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const String _imagePath = 'images/hero-left.webp';

  // web/images/hero-left.webp is served as a relative web asset (same
  // file web/index.html already points at) rather than a Flutter
  // pubspec asset — no bundling step needed on web. On non-web targets
  // there's no equivalent bundled photo yet, so this just degrades to
  // the gradient/vignette layers below with no image.
  Widget _heroImage() {
    if (!kIsWeb) return const SizedBox.shrink();
    return Image.network(
      _imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stack) => const SizedBox.shrink(),
    );
  }

  @override
  void initState() {
    super.initState();
    // Mirrors @keyframes heroKenBurns { 0%..100% } ease-in-out infinite
    // alternate, 22s per leg.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDark;

    // Same duplicated-per-theme gradient stops as the CSS.
    final List<Color> gradeColors = dark
        ? [
            const Color(0xF00A0D0F),
            const Color(0xD10A0D0F),
            const Color(0x660A0D0F),
            const Color(0x1A0A0D0F),
          ]
        : [
            const Color(0xE6F7F8F6),
            const Color(0xCCF7F8F6),
            const Color(0x59F7F8F6),
            const Color(0x14F7F8F6),
          ];

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Blurred, slowly drifting hero photo ──────────────
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_controller.value);
              final scale = lerpDouble(1.08, 1.16, t)!;
              final dx = lerpDouble(0, -0.012, t)!;
              final dy = lerpDouble(0, -0.01, t)!;
              return FractionalTranslation(
                translation: Offset(dx, dy),
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              );
            },
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: _heroImage(),
            ),
          ),

          // ── Colour-grade wash (linear gradient towards bg) ───
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0.0, 0.3, 0.6, 1.0],
                colors: gradeColors,
                transform: const GradientRotation(0.17), // ~100deg in CSS
              ),
            ),
          ),

          // ── Mint + vignette colour grade (radial highlights + dark
          //    corner + bottom fade), same stacking as .hero-left-grade
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.7, -0.6),
                radius: 1.1,
                colors: [
                  const Color(0xFF00E5A0)
                      .withOpacity(dark ? 0.14 : 0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.0, 1.0),
                radius: 1.3,
                colors: [
                  Colors.black.withOpacity(dark ? 0.55 : 0.32),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.55, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(dark ? 0.45 : 0.22),
                ],
              ),
            ),
          ),

          // ── Mirrored "reflection" strip along the bottom edge ─
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.34,
              widthFactor: 1.0,
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x8C000000), Colors.transparent],
                  stops: [0.0, 0.85],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Opacity(
                  opacity: 0.35,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                    child: Transform.flip(
                      flipY: true,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                        child: _heroImage(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
