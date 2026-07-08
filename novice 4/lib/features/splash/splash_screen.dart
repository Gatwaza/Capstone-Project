// Novice — CPR-AI Coach · Integrated Design
// GNU General Public License v3.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 28, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    // Home is now the single entry point Flutter falls back to once booted
    // (the landing page's own CTAs all target /home too — see index.html's
    // ROUTE_MAP). This only fires if nothing else has already navigated
    // away from splash by the time it elapses.
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) context.go(AppRoutes.home);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: AnimatedBuilder(
            animation: _slide,
            builder: (_, child) =>
                Transform.translate(offset: Offset(0, _slide.value), child: child),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(.2),
                        blurRadius: 32,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.monitor_heart_rounded,
                      color: AppTheme.accent,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text('Novice',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          letterSpacing: -1.5,
                        )),
                const SizedBox(height: 8),
                Text(
                  'FIRST AID · CPR COACH',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.accent,
                    letterSpacing: 4,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 56),
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      backgroundColor: AppTheme.border,
                      color: AppTheme.accent,
                      minHeight: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}