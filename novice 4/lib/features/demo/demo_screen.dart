// Novice — CPR-AI Coach · Procedures Screen
// GNU General Public License v3.0
//
// This screen provides:
//   • CPR  — animated step-by-step preview (live AI training is in training_screen.dart)
//   • All other procedures — interactive animated 3D step-by-step guides
//
// Content sourced from: Rwanda Basic First Aid Training Manual
// (Emergency Safety and Health Services / Belgian Red Cross, Flanders)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
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
    this.isLiveAI = false,
  });
  final String id, title, desc, tag;
  final Color color;
  final IconData icon;
  final List<String> keyPoints;
  final List<_Step> steps;
  final bool isLiveAI;
}

class _Step {
  const _Step(this.title, this.detail);
  final String title, detail;
}

// ── Module content — aligned with Rwanda First Aid Training Manual ──

const _modules = [
  // ── CPR (Module 5 of manual) ──────────────────────────────
  _Module(
    id: 'cpr',
    title: 'CPR',
    desc: 'Cardiopulmonary resuscitation',
    color: AppTheme.cprRed,
    icon: Icons.monitor_heart_rounded,
    tag: '🤖 Live AI Training',
    isLiveAI: true,
    keyPoints: [
      'Call emergency services (912 ambulance / 112 police & fire) before starting',
      'Push hard — at least 5 cm deep, 100–120 compressions per minute',
      'Allow full chest recoil after every compression',
      '30 compressions to 2 rescue breaths — repeat until EMS arrives',
    ],
    steps: [
      _Step('Check for response',
          'Tap shoulders firmly, shout "Are you OK?". If unresponsive, shout for help and call 912 (ambulance) immediately.'),
      _Step('Open the airway',
          'Head-tilt chin-lift: one hand on forehead, two fingers under the bony part of the chin. Tilt head back to open airway. Check mouth and remove any visible foreign bodies or loose dental prostheses.'),
      _Step('Check breathing',
          'Place your cheek near the victim\'s mouth and nose for up to 10 seconds. Look for chest rise, listen for breath sounds, feel for exhaled air. If no breathing detected, proceed to compressions immediately.'),
      _Step('30 chest compressions',
          'Heel of hand on the centre of the chest. Second hand on top, fingers interlocked. Arms straight, shoulders directly above. Compress 5–6 cm at 100–120/min. Allow full recoil — hands do not leave chest.'),
      _Step('2 rescue breaths',
          'Pinch nose closed. Seal your mouth over victim\'s mouth. Breathe calmly for 1 second — watch chest rise. Remove mouth. Give 2 breaths then return immediately to compressions.'),
      _Step('Continue 30:2 cycle',
          'Alternate 30 compressions and 2 breaths. Do not stop unless the victim breathes normally, EMS arrives, or you are too exhausted. Switch rescuers every 2 minutes to maintain quality.'),
    ],
  ),

  // ── Choking (Module 6 of manual) ─────────────────────────
  _Module(
    id: 'choking',
    title: 'Choking',
    desc: 'Heimlich manoeuvre & back blows',
    color: AppTheme.chokingAmber,
    icon: Icons.air_rounded,
    tag: 'Animated demo',
    keyPoints: [
      'Ask "Are you choking?" — if they can cough, encourage it',
      '5 firm back blows between shoulder blades with heel of hand',
      '5 abdominal thrusts — fist above navel, inward and upward',
      'If victim collapses — begin CPR immediately (compressions may dislodge object)',
    ],
    steps: [
      _Step('Assess obstruction',
          'Ask "Are you choking?". Partial obstruction: victim can cough — encourage vigorous coughing, do nothing else. Act only if they cannot speak, cough, or breathe (total obstruction).'),
      _Step('Position victim forward',
          'Support the victim\'s chest with one hand and tilt them forward so any expelled object falls out rather than deeper into the airway.'),
      _Step('5 firm back blows',
          'Strike firmly between the shoulder blades with the heel of your free hand. Each blow is a separate, distinct attempt. Check the mouth after each blow for any dislodged object.'),
      _Step('5 abdominal thrusts (Heimlich)',
          'Stand behind the victim. Make a fist above the navel below the sternum. Grasp your fist with the other hand. Pull sharply inward and upward. For children under 1 year, use chest compressions instead.'),
      _Step('Alternate until clear',
          'If airway is still blocked, alternate 5 back blows with 5 abdominal thrusts. If victim loses consciousness, lower them gently, call 912, and begin CPR — chest compressions may dislodge the object.'),
    ],
  ),

  // ── Stroke / FAST (Module 9 of manual) ───────────────────
  _Module(
    id: 'stroke',
    title: 'Stroke — FAST',
    desc: 'Recognise & respond to stroke',
    color: AppTheme.strokePurple,
    icon: Icons.psychology_rounded,
    tag: 'Animated demo',
    keyPoints: [
      'Time is brain — every minute of delay worsens outcome',
      'FAST: Face · Arms · Speech · Time',
      'Do NOT give aspirin — may worsen haemorrhagic stroke',
      'Semi-sitting position — never lay flat (raises brain pressure)',
    ],
    steps: [
      _Step('F — Face',
          'Ask the person to smile or show their teeth. Does one side of the face droop or show asymmetry? A crooked smile is a key warning sign.'),
      _Step('A — Arms',
          'Ask them to close their eyes and raise both arms. Watch for 10 seconds. Does one arm drift downward or feel weak?'),
      _Step('S — Speech',
          'Ask them to repeat a simple phrase such as "The sun is shining". Is speech slurred, strange, or impossible?'),
      _Step('T — Time',
          'Note the exact time symptoms started — this is critical information for emergency responders. Call 912 immediately. Do not wait to see if symptoms resolve.'),
      _Step('Position & reassure',
          'Sit the victim in a semi-upright position — never lay flat. Keep them calm and warm. Do NOT give food, drink, or aspirin. Support any paralysed limb. If unconscious, place in lateral position.'),
    ],
  ),

  // ── Recovery Position (Module 3/4 of manual) ─────────────
  _Module(
    id: 'recovery',
    title: 'Recovery Position',
    desc: 'Safe airway for unconscious breathing victims',
    color: AppTheme.recoveryTeal,
    icon: Icons.airline_seat_flat_angled_rounded,
    tag: 'Animated demo',
    keyPoints: [
      'Use only for unconscious victims who are breathing normally',
      'Keeps airway open — prevents choking on vomit or secretions',
      'Check breathing continuously — start CPR if it stops',
      'Ensure head is tilted back and mouth faces downward',
    ],
    steps: [
      _Step('Confirm breathing',
          'Check for up to 10 seconds — look for chest rise, listen, feel airflow. If no breathing, begin CPR immediately. This position is only for victims who ARE breathing.'),
      _Step('Position near arm',
          'Remove victim\'s glasses if worn. Kneel beside them. Take the arm nearest to you and place at a right angle to the body. Bend the elbow so the palm faces upward.'),
      _Step('Far hand to cheek',
          'Bring the victim\'s far hand across and place the back of it against their near cheek. Hold it in place with your hand.'),
      _Step('Bend far knee',
          'With your free hand, pull up the far knee keeping the foot flat on the ground. This creates a lever for the roll.'),
      _Step('Roll & open mouth',
          'Roll the victim toward you using the knee as a lever. Adjust the upper leg so the hip and knee are at right angles. Tilt the head back to keep the airway open. Ensure the mouth is open and angled downward to allow drainage. Check breathing every minute.'),
    ],
  ),

  // ── Bleeding / Haemorrhage (Module 10 of manual) ─────────
  _Module(
    id: 'bleeding',
    title: 'Bleeding',
    desc: 'Haemorrhage control & wound care',
    color: const Color(0xFFC0395E),
    icon: Icons.water_drop_rounded,
    tag: 'Animated demo',
    keyPoints: [
      'Apply direct compression immediately — this can be done before calling 912',
      'Apply compressive dressing; if bandage becomes wet, add on top — do not remove',
      'Tourniquet is a last resort (amputation) — note the application time',
      'Lay victim down if at risk of shock; do not give food or drink',
    ],
    steps: [
      _Step('Control bleeding',
          'If victim is conscious, ask them to apply direct compression while you prepare. Wear latex gloves. Press firmly over the wound with a clean cloth or sterile gauze.'),
      _Step('Apply compressive dressing',
          'Wrap a bandage firmly over the wound to maintain pressure. Tight enough to stop bleeding but not so tight it cuts off circulation. If the limb changes colour, swells, or becomes numb, loosen slightly.'),
      _Step('Do not remove wet dressings',
          'If the dressing becomes saturated with blood, add more material on top — do not remove the original. Removing it disturbs the clot that is forming.'),
      _Step('Call 912 & manage shock',
          'For severe or internal bleeding, call 912 immediately. Lay the victim down and raise their legs (Trendelenburg position) to help perfusion of vital organs. Keep them warm.'),
      _Step('Tourniquet (extreme cases only)',
          'In cases of traumatic amputation or bleeding that cannot be controlled, apply a tourniquet. Note the time of application. This measure carries risk of limb loss and is only used to save life.'),
    ],
  ),

  // ── Burns (Module 14 of manual) ──────────────────────────
  _Module(
    id: 'burns',
    title: 'Burns',
    desc: 'Thermal, chemical & electrical burns',
    color: const Color(0xFFD4781A),
    icon: Icons.local_fire_department_rounded,
    tag: 'Animated demo',
    keyPoints: [
      'Cool with running water 10–20°C for 10–15 minutes — never ice water',
      'Do not remove clothing stuck to the burn — water it instead',
      'Remove jewellery (rings, watches) from the affected area promptly',
      '2nd degree and above, or burns to face/hands/genitals — always seek medical care',
    ],
    steps: [
      _Step('Ensure safety',
          'Identify and eliminate the burn source. If clothing is on fire, stop the victim from running — wrap in a blanket and roll on the floor. Remove clothing soaked with hot liquid or vapour, but do not remove anything stuck to skin.'),
      _Step('Cool the burn',
          'Flush with running water at 10–20°C for 10–15 minutes. For young children or large burns, limit to 5 minutes to prevent hypothermia. Never use ice water, butter, or any cream.'),
      _Step('Remove jewellery',
          'Remove rings, watches, and tight clothing from the affected area as soon as possible, before swelling makes removal impossible.'),
      _Step('Cover the burn',
          'Wrap the burn loosely with sterile gauze or a clean cloth moistened with water. Separate burned fingers with gauze. Do not burst blisters.'),
      _Step('Position & seek care',
          'Burns from 2nd degree onwards, burns covering large areas, or burns on the face, hands, feet, genitals, or airways require emergency medical care. Call 912. If victim is unconscious and breathing, use lateral position.'),
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
                  // ── Live AI / Animated mode banner ────
                  if (_mod.isLiveAI)
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.participantGate),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(.08),
                          borderRadius: BorderRadius.circular(AppTheme.rMd),
                          border: Border.all(color: AppTheme.accent.withOpacity(.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.smart_toy_rounded, color: AppTheme.accent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Live AI Training available',
                                      style: TextStyle(color: AppTheme.accent,
                                          fontSize: 13, fontWeight: FontWeight.w700)),
                                  Text('CPR is the only procedure assessed in real time by the TCN model. Tap to start your camera session.',
                                      style: Theme.of(context).textTheme.bodyMedium
                                          ?.copyWith(fontSize: 11, height: 1.4)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Start',
                                  style: TextStyle(color: Colors.black,
                                      fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(AppTheme.rMd),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.play_lesson_rounded,
                              color: AppTheme.textSecondary, size: 16),
                          const SizedBox(width: 10),
                          Text('Animated step-by-step guide — study at your own pace',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),

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
                        Center(
                          child: AnimatedBuilder(
                            animation: _compression,
                            builder: (_, __) => CustomPaint(
                              size: const Size(280, 180),
                              painter: _ProcedurePainter(
                                compressionFraction: _compression.value,
                                moduleColor: _mod.color,
                                moduleId: _mod.id,
                                stepIndex: _stepIdx,
                              ),
                            ),
                          ),
                        ),
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
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 3, height: 44,
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
                              const SizedBox(height: 4),
                              Text(_step.detail,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(height: 1.5)),
                            ],
                          ),
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

                  // ── CPR: CTA to live training ───────────
                  if (_mod.isLiveAI) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.participantGate),
                      icon: const Icon(Icons.smart_toy_rounded, size: 18),
                      label: const Text('Start Live AI CPR Training'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.rMd),
                        ),
                      ),
                    ),
                  ],

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

// ── Painter — unique scene per module ────────────────────────

class _ProcedurePainter extends CustomPainter {
  const _ProcedurePainter({
    required this.compressionFraction,
    required this.moduleColor,
    required this.moduleId,
    required this.stepIndex,
  });
  final double compressionFraction;
  final Color moduleColor;
  final String moduleId;
  final int stepIndex;

  @override
  void paint(Canvas canvas, Size size) {
    switch (moduleId) {
      case 'cpr':      _paintCPR(canvas, size); break;
      case 'choking':  _paintChoking(canvas, size); break;
      case 'stroke':   _paintStroke(canvas, size); break;
      case 'recovery': _paintRecovery(canvas, size); break;
      case 'bleeding': _paintBleeding(canvas, size); break;
      case 'burns':    _paintBurns(canvas, size); break;
      default:         _paintCPR(canvas, size); break;
    }
  }

  Paint get _surfacePaint => Paint()
    ..color = const Color(0xFF161C20)
    ..style = PaintingStyle.fill;

  Paint get _borderPaint => Paint()
    ..color = const Color(0x14FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  void _drawLabel(Canvas canvas, double x, double y, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y));
  }

  void _drawManikinTorso(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 35), width: 90, height: 120),
      const Radius.circular(10),
    );
    canvas.drawRRect(torsoRect, _surfacePaint);
    canvas.drawRRect(torsoRect, _borderPaint);
    canvas.drawCircle(Offset(cx, cy - 90), 20, _surfacePaint);
    canvas.drawCircle(Offset(cx, cy - 90), 20, _borderPaint);
  }

  void _paintCPR(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    _drawManikinTorso(canvas, size);

    // Chest target
    canvas.drawCircle(Offset(cx, cy + 15), 9,
        Paint()..color = moduleColor.withOpacity(.2));
    canvas.drawCircle(Offset(cx, cy + 15), 4, Paint()..color = moduleColor);

    // Hands compress animation
    final handY = cy - 22 + compressionFraction * 16;
    final handPaint = Paint()
      ..color = AppTheme.textPrimary.withOpacity(.75)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, handY), width: 40, height: 12),
      const Radius.circular(4)), handPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, handY - 11), width: 34, height: 10),
      const Radius.circular(4)), handPaint);

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

    final depthCm = (compressionFraction * 6).clamp(0.0, 6.0);
    _drawLabel(canvas, cx + 52, handY - 6, '${depthCm.toStringAsFixed(1)}cm', moduleColor);
    _drawLabel(canvas, cx - 52, cy - 90, '110 BPM', moduleColor.withOpacity(.6));
  }

  void _paintChoking(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    _drawManikinTorso(canvas, size);

    // Obstruction indicator in throat
    final obsPaint = Paint()..color = const Color(0xFFFF4D6D).withOpacity(.7)..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 60), width: 16, height: 10),
      const Radius.circular(4)), obsPaint);

    // Back blow hand (pulsing with compressionFraction)
    final blowX = cx - 60 + compressionFraction * 20;
    final handPaint = Paint()..color = moduleColor.withOpacity(.85)..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(blowX, cy + 10), width: 22, height: 14),
      const Radius.circular(5)), handPaint);

    _drawLabel(canvas, cx + 60, cy - 60, 'BLOCKED', const Color(0xFFFF4D6D));
    _drawLabel(canvas, cx - 66, cy + 24, '5 BLOWS', moduleColor);
  }

  void _paintStroke(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Face outline
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 20), width: 90, height: 110),
      _surfacePaint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 20), width: 90, height: 110),
      _borderPaint);

    // Drooping mouth — more droop animated
    final droop = compressionFraction * 14;
    final mouthPath = Path()
      ..moveTo(cx - 18, cy + 18)
      ..quadraticBezierTo(cx, cy + 26, cx + 18, cy + 18 + droop);
    canvas.drawPath(mouthPath, Paint()
      ..color = moduleColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // FAST label
    _drawLabel(canvas, cx, cy + 60, 'F A S T', moduleColor);
    _drawLabel(canvas, cx + 55, cy - 40, 'Face droop?', moduleColor.withOpacity(.7));
  }

  void _paintRecovery(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Victim lying on side
    final roll = compressionFraction * 0.3;
    canvas.save();
    canvas.translate(cx, cy + 10);
    canvas.rotate(math.pi / 2 + roll);
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 100, height: 40),
      const Radius.circular(8));
    canvas.drawRRect(torsoRect, _surfacePaint);
    canvas.drawRRect(torsoRect, _borderPaint);
    canvas.restore();

    canvas.drawCircle(Offset(cx - 50, cy - 30), 18, _surfacePaint);
    canvas.drawCircle(Offset(cx - 50, cy - 30), 18, _borderPaint);

    _drawLabel(canvas, cx + 60, cy - 30, 'LATERAL', moduleColor);
    _drawLabel(canvas, cx + 60, cy - 15, 'POSITION', moduleColor.withOpacity(.7));
  }

  void _paintBleeding(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    _drawManikinTorso(canvas, size);

    // Wound on arm
    final woundPaint = Paint()..color = const Color(0xFFFF4D6D).withOpacity(.6)..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 46, cy + 10), width: 18, height: 10), woundPaint);

    // Compression hand pulsing
    final pressFraction = (math.sin(compressionFraction * math.pi * 2) * 0.5 + 0.5);
    final handPaint = Paint()..color = moduleColor.withOpacity(.5 + pressFraction * .4)..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 46, cy + 6), width: 22, height: 14),
      const Radius.circular(4)), handPaint);

    _drawLabel(canvas, cx - 60, cy + 10, 'COMPRESS', moduleColor);
    _drawLabel(canvas, cx - 60, cy + 24, 'DIRECT', moduleColor.withOpacity(.7));
  }

  void _paintBurns(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    _drawManikinTorso(canvas, size);

    // Water flow animation
    for (int i = 0; i < 4; i++) {
      final offset = (compressionFraction + i * 0.25) % 1.0;
      final dropY = cy - 40 + offset * 100;
      canvas.drawCircle(
        Offset(cx + 52, dropY),
        3,
        Paint()..color = const Color(0xFF2B7FD4).withOpacity((1 - offset)));
    }

    // Burn area highlight on arm
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 44, cy + 10), width: 20, height: 30),
      Paint()..color = moduleColor.withOpacity(.25)..style = PaintingStyle.fill);

    _drawLabel(canvas, cx + 58, cy - 48, '10–15 min', const Color(0xFF2B7FD4));
    _drawLabel(canvas, cx + 58, cy - 34, 'COOL WATER', const Color(0xFF2B7FD4).withOpacity(.8));
  }

  @override
  bool shouldRepaint(_ProcedurePainter old) =>
      old.compressionFraction != compressionFraction ||
      old.moduleId != moduleId ||
      old.stepIndex != stepIndex;
}
