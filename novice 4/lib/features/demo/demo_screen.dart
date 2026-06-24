// Novice — CPR-AI Coach · Integrated Design
// GNU General Public License v3.0

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

// ── Data ─────────────────────────────────────────────────────

class _Module {
  const _Module({
    required this.id,
    required this.title,
    required this.desc,
    required this.color,
    required this.icon,
    required this.tag,
    required this.keyPoints,
    required this.steps,
  });
  final String id, title, desc, tag;
  final Color color;
  final IconData icon;
  final List<String> keyPoints;
  final List<_Step> steps;
}

class _Step {
  const _Step(this.title, this.detail);
  final String title, detail;
}

const _modules = [
  _Module(
    id: 'cpr', title: 'CPR', desc: 'Cardiopulmonary resuscitation',
    color: AppTheme.cprRed, icon: Icons.favorite_rounded, tag: 'Foundational',
    keyPoints: [
      'Call 112 / 911 before starting',
      'Push hard — at least 5 cm, 100–120 bpm',
      'Allow full chest recoil after each compression',
      '30 compressions : 2 rescue breaths',
    ],
    steps: [
      _Step('Check for response', 'Tap shoulders firmly, shout "Are you OK?". If unresponsive, call emergency services immediately.'),
      _Step('Open the airway', 'Head-tilt chin-lift: one hand on forehead, two fingers under chin. Tilt back to open airway.'),
      _Step('30 chest compressions', 'Heel of hand on centre of chest. Compress 5–6 cm at 100–120/min. Allow full recoil.'),
      _Step('2 rescue breaths', 'Pinch nose, seal mouth, breathe for 1 second. Watch chest rise. Give 2 breaths.'),
      _Step('Continue 30:2 cycle', 'Repeat until EMS arrives. Switch rescuers every 2 minutes to maintain quality.'),
    ],
  ),
  _Module(
    id: 'choking', title: 'Choking', desc: 'Heimlich manoeuvre & back blows',
    color: AppTheme.chokingAmber, icon: Icons.air_rounded, tag: 'Urgent',
    keyPoints: [
      'Ask "Are you choking?" first',
      '5 back blows between shoulder blades',
      '5 abdominal thrusts — above navel, inward and upward',
      'If victim collapses — start CPR immediately',
    ],
    steps: [
      _Step('Assess obstruction', 'If they can cough, encourage it. Only act if unable to speak, cough, or breathe.'),
      _Step('Lean forward', 'Support chest, tilt victim forward so expelled object falls out.'),
      _Step('5 back blows', 'Strike firmly between shoulder blades with heel of hand. 5 separate blows.'),
      _Step('5 abdominal thrusts', 'Fist above navel. Grasp fist. Pull sharply inward and upward.'),
      _Step('Alternate until clear', 'Repeat blows and thrusts. If victim collapses — begin CPR.'),
    ],
  ),
  _Module(
    id: 'stroke', title: 'Stroke — FAST', desc: 'Recognise & respond to stroke',
    color: AppTheme.strokePurple, icon: Icons.psychology_rounded, tag: 'Critical',
    keyPoints: [
      'Time is brain — every minute matters',
      'FAST: Face · Arms · Speech · Time',
      'Do NOT give aspirin — may worsen haemorrhagic stroke',
      'Keep victim calm and semi-sitting',
    ],
    steps: [
      _Step('F — Face', 'Ask them to smile. Does one side droop? Asymmetry is a warning sign.'),
      _Step('A — Arms', 'Eyes closed, both arms raised. Does one drift downward?'),
      _Step('S — Speech', 'Repeat a simple phrase. Slurred, strange, or impossible = stroke sign.'),
      _Step('T — Time', 'Note exact onset time. Call 112 immediately.'),
      _Step('Position & reassure', 'Semi-upright, calm, warm. No food, drink, or aspirin.'),
    ],
  ),
  _Module(
    id: 'recovery', title: 'Recovery', desc: 'Safe airway for unconscious victims',
    color: AppTheme.recoveryTeal, icon: Icons.airline_seat_flat_angled_rounded, tag: 'Essential',
    keyPoints: [
      'Only for unconscious but breathing victims',
      'Keeps airway open — prevents choking on vomit',
      'Check breathing every minute',
      'Start CPR if breathing stops',
    ],
    steps: [
      _Step('Confirm breathing', 'Check for up to 10 s — look, listen, feel. If absent, begin CPR.'),
      _Step('Position near arm', 'Right angle, elbow bent, palm up.'),
      _Step('Far hand to cheek', 'Back of far hand against near cheek.'),
      _Step('Bend far knee', 'Foot flat on ground — lever to roll.'),
      _Step('Roll', 'Roll toward you. Tilt head, mouth facing slightly down.'),
    ],
  ),
  _Module(
    id: 'aed', title: 'AED', desc: 'Automated defibrillator step by step',
    color: AppTheme.aedBlue, icon: Icons.bolt_rounded, tag: 'Device',
    keyPoints: [
      'Power on first — it talks you through everything',
      'Continue CPR until pads are attached',
      'Stand clear during shock — shout "Clear!"',
      'Resume CPR immediately after shock',
    ],
    steps: [
      _Step('Power on', 'Open case, press power. Follow spoken instructions.'),
      _Step('Attach pads', 'Right collarbone, left side below armpit. Remove clothing first.'),
      _Step('Let AED analyse', 'Nobody touches victim. AED analyses rhythm automatically.'),
      _Step('Deliver shock', 'If advised — shout clear, check, press shock button.'),
      _Step('Resume CPR', 'Begin 30 compressions immediately. AED re-analyses in 2 min.'),
    ],
  ),
];

// ── Screen ───────────────────────────────────────────────────

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});
  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen>
    with TickerProviderStateMixin {
  int _modIdx = 0;
  int _stepIdx = 0;
  late AnimationController _compressionCtrl;
  late Animation<double> _compression;

  @override
  void initState() {
    super.initState();
    _compressionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 545),
    )..repeat(reverse: true);
    _compression = CurvedAnimation(parent: _compressionCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _compressionCtrl.dispose(); super.dispose(); }

  _Module get _mod => _modules[_modIdx];
  _Step   get _step => _mod.steps[_stepIdx];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Procedures'),
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Module tab bar ────────────────────────────
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _modules.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final m = _modules[i];
                final selected = i == _modIdx;
                return GestureDetector(
                  onTap: () => setState(() { _modIdx = i; _stepIdx = 0; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? m.color.withOpacity(.15) : AppTheme.card,
                      borderRadius: BorderRadius.circular(AppTheme.rMd),
                      border: Border.all(
                        color: selected ? m.color : AppTheme.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(m.icon, color: selected ? m.color : AppTheme.textSecondary, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          m.title,
                          style: TextStyle(
                            color: selected ? m.color : AppTheme.textSecondary,
                            fontSize: 13, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Animation viewport ──────────────────
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(AppTheme.r),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Stack(
                      children: [
                        // Glow background
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTheme.r),
                              gradient: RadialGradient(
                                colors: [
                                  _mod.color.withOpacity(.08),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Animation
                        Center(
                          child: AnimatedBuilder(
                            animation: _compression,
                            builder: (_, __) => CustomPaint(
                              size: const Size(280, 180),
                              painter: _CprAnimationPainter(
                                compressionFraction: _mod.id == 'cpr'
                                    ? _compression.value
                                    : 0.5,
                                moduleColor: _mod.color,
                                stepIndex: _stepIdx,
                              ),
                            ),
                          ),
                        ),
                        // Step label bottom bar
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.surface.withOpacity(.9),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(AppTheme.r),
                                bottomRight: Radius.circular(AppTheme.r),
                              ),
                              border: Border(top: BorderSide(color: AppTheme.border)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 7, height: 7,
                                  decoration: BoxDecoration(
                                    color: _mod.color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _step.title,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Step ${_stepIdx + 1}/${_mod.steps.length}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Progress bar ────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (_stepIdx + 1) / _mod.steps.length,
                      backgroundColor: AppTheme.border,
                      color: _mod.color,
                      minHeight: 2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Step detail ─────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(AppTheme.rMd),
                      border: Border.all(color: AppTheme.border),
                      // left accent line
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3, height: 36,
                              decoration: BoxDecoration(
                                color: _mod.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_step.title,
                                      style: Theme.of(context).textTheme.titleMedium),
                                  Text(_step.detail,
                                      style: Theme.of(context).textTheme.bodyMedium
                                          ?.copyWith(height: 1.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Nav buttons ─────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _stepIdx > 0
                              ? () => setState(() => _stepIdx--)
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(color: AppTheme.border),
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.rMd),
                            ),
                          ),
                          child: const Text('← Prev'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _stepIdx < _mod.steps.length - 1
                              ? () => setState(() => _stepIdx++)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mod.color,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.rMd),
                            ),
                          ),
                          child: Text(_stepIdx == _mod.steps.length - 1
                              ? 'Done ✓'
                              : 'Next →'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Steps list ──────────────────────────
                  ...List.generate(_mod.steps.length, (i) {
                    final s = _mod.steps[i];
                    final cur = i == _stepIdx;
                    return GestureDetector(
                      onTap: () => setState(() => _stepIdx = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cur ? _mod.color.withOpacity(.06) : AppTheme.card,
                          borderRadius: BorderRadius.circular(AppTheme.rMd),
                          border: Border.all(
                            color: cur ? _mod.color : AppTheme.border,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: cur ? _mod.color : AppTheme.border,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: cur ? Colors.white : AppTheme.textSecondary,
                                    fontSize: 11, fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.title,
                                      style: TextStyle(
                                        color: cur ? AppTheme.textPrimary : AppTheme.textSecondary,
                                        fontSize: 13, fontWeight: FontWeight.w600,
                                      )),
                                  if (cur) ...[
                                    const SizedBox(height: 4),
                                    Text(s.detail,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontSize: 12, height: 1.5)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // ── Key points ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(AppTheme.rMd),
                      border: Border.all(color: _mod.color.withOpacity(.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded,
                                color: _mod.color, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'KEY POINTS',
                              style: TextStyle(
                                color: _mod.color, fontSize: 10,
                                fontWeight: FontWeight.w700, letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ..._mod.keyPoints.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('→ ', style: TextStyle(color: _mod.color, fontSize: 12)),
                              Expanded(
                                child: Text(p,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 12, height: 1.5)),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painter ──────────────────────────────────────────────────

class _CprAnimationPainter extends CustomPainter {
  const _CprAnimationPainter({
    required this.compressionFraction,
    required this.moduleColor,
    required this.stepIndex,
  });
  final double compressionFraction;
  final Color moduleColor;
  final int stepIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final surfacePaint = Paint()
      ..color = const Color(0xFF161C20)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0x14FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Manikin torso
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 35), width: 90, height: 120),
      const Radius.circular(10),
    );
    canvas.drawRRect(torsoRect, surfacePaint);
    canvas.drawRRect(torsoRect, borderPaint);

    // Target point on chest
    canvas.drawCircle(Offset(cx, cy + 15), 9,
        Paint()..color = moduleColor.withOpacity(.2));
    canvas.drawCircle(Offset(cx, cy + 15), 4, Paint()..color = moduleColor);

    // Hands — move down with compression
    final handY = cy - 22 + compressionFraction * 16;
    final handPaint = Paint()
      ..color = AppTheme.textPrimary.withOpacity(.75)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, handY), width: 40, height: 12),
        const Radius.circular(4),
      ),
      handPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, handY - 11), width: 34, height: 10),
        const Radius.circular(4),
      ),
      handPaint,
    );

    // Arms
    final armPaint = Paint()
      ..color = moduleColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final shoulderY = cy - 72;
    canvas.drawLine(Offset(cx - 52, shoulderY), Offset(cx - 16, handY - 40), armPaint);
    canvas.drawLine(Offset(cx - 16, handY - 40), Offset(cx - 8, handY - 6), armPaint);
    canvas.drawLine(Offset(cx + 52, shoulderY), Offset(cx + 16, handY - 40), armPaint);
    canvas.drawLine(Offset(cx + 16, handY - 40), Offset(cx + 8, handY - 6), armPaint);

    // Head
    canvas.drawCircle(Offset(cx, cy - 90), 20, surfacePaint);
    canvas.drawCircle(Offset(cx, cy - 90), 20, borderPaint);

    // Depth/rate label
    final depthCm = (compressionFraction * 6).clamp(0.0, 6.0);
    _drawLabel(canvas, cx + 52, handY - 6, '${depthCm.toStringAsFixed(1)}cm', moduleColor);
    _drawLabel(canvas, cx - 52, cy - 90, '110 BPM', moduleColor.withOpacity(.6));
  }

  void _drawLabel(Canvas canvas, double x, double y, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y));
  }

  @override
  bool shouldRepaint(_CprAnimationPainter old) =>
      old.compressionFraction != compressionFraction ||
      old.stepIndex != stepIndex;
}
