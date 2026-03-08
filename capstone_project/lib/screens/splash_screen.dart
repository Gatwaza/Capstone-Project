import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ecgController;
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    // Start fade after ECG animation
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _fadeController.forward();
    });

    // Navigate to home after splash
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ecgController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ECG line animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ecgController,
              builder: (_, __) => CustomPaint(
                painter: _EcgPainter(progress: _ecgController.value),
              ),
            ),
          ),
          // Logo + text
          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing heart icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentRed.withOpacity(0.15),
                        border: Border.all(color: AppColors.accentRed, width: 2),
                      ),
                      child: const Icon(Icons.favorite,
                          color: AppColors.accentRed, size: 40),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('CAPSTONE PROJECT',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w500,
                      )),
                  const SizedBox(height: 8),
                  const Text('CPR AI COACH',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    'Every bystander. Every second.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentRed.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  final double progress;
  _EcgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentRed.withOpacity(0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final w = size.width;
    final mid = size.height / 2;
    final drawn = w * progress;

    path.moveTo(0, mid);

    // Flat line
    if (drawn < w * 0.3) {
      path.lineTo(drawn, mid);
    } else {
      path.lineTo(w * 0.3, mid);
      // ECG spike
      final spikeX = w * 0.3;
      path.lineTo(spikeX + (drawn - w * 0.3).clamp(0, w * 0.05), mid);
      if (drawn > w * 0.35) {
        path.lineTo(spikeX + w * 0.05, mid - 60);
        if (drawn > w * 0.42) path.lineTo(spikeX + w * 0.08, mid + 40);
        if (drawn > w * 0.48) path.lineTo(spikeX + w * 0.12, mid);
        if (drawn > w * 0.55) path.lineTo(drawn, mid);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.progress != progress;
}
