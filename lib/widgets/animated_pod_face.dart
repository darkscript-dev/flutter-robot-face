import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import '../models/pod_status.dart';

class AnimatedPodFace extends StatefulWidget {
  final PodEmotionalState state;
  const AnimatedPodFace({required this.state, Key? key}) : super(key: key);

  @override
  State<AnimatedPodFace> createState() => _AnimatedPodFaceState();
}

class _AnimatedPodFaceState extends State<AnimatedPodFace>
    with TickerProviderStateMixin {
  // For continuous looping animations like sleeping Z's, pulsing icons, etc.
  late AnimationController _loopingController;
  // For the rapid flicker of the disconnected state
  late AnimationController _staticController;

  // For the happy state's eye movement
  Timer? _pupilTimer;
  Offset _pupilOffset = Offset.zero; // -1 for left, 0 for center, 1 for right

  double _faceSizeDivisor = 2.2;
  // Store the previous state to calculate tween start point correctly
  PodEmotionalState _previousState = PodEmotionalState.sleeping;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _previousState = widget.state;

    _loopingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _staticController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..repeat();

    // Start timers/animations based on the initial state
    _updateAnimations(null, widget.state);
  }

  @override
  void didUpdateWidget(AnimatedPodFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      setState(() {
        _previousState = oldWidget.state;
      });
      _updateAnimations(oldWidget.state, widget.state);
    }
  }

  void _updateAnimations(PodEmotionalState? oldState, PodEmotionalState newState) {
    // Pupil movement timer for Happy state
    if (newState == PodEmotionalState.happy) {
      _pupilTimer?.cancel(); // Cancel any existing timer
      _pupilTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        // Animate pupil movement smoothly instead of jumping
        setState(() {
          final random = Random().nextDouble();
          if (random < 0.4) {
            _pupilOffset = const Offset(-1, 0); // Look left
          } else if (random < 0.8) {
            _pupilOffset = const Offset(1, 0); // Look right
          } else {
            _pupilOffset = Offset.zero; // Look center
          }
        });
      });
    } else {
      _pupilTimer?.cancel();
      // Reset pupil position when not happy
      if (_pupilOffset != Offset.zero) {
        setState(() {
          _pupilOffset = Offset.zero;
        });
      }
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _faceSizeDivisor = prefs.getDouble('face_size_divisor') ?? 2.2;
      });
    }
  }

  @override
  void dispose() {
    _loopingController.dispose();
    _staticController.dispose();
    _pupilTimer?.cancel();
    super.dispose();
  }

  // Maps each emotional state to a numerical value for the Tween animation.
  double getStateValue(PodEmotionalState state) {
    switch (state) {
      case PodEmotionalState.sleeping:
        return 0.0;
      case PodEmotionalState.waking:
        return 1.0;
      case PodEmotionalState.happy:
        return 2.0;
      case PodEmotionalState.thirsty: // Water
        return 3.0;
      case PodEmotionalState.needsNutrients:
        return 4.0;
      case PodEmotionalState.hot:
        return 5.0;
      case PodEmotionalState.thirstySoil:
        return 6.0;
      case PodEmotionalState.hidingFromLight:
        return 7.0;
      case PodEmotionalState.sunbathing:
        return 8.0;
      case PodEmotionalState.disconnected:
        return 9.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: getStateValue(_previousState), end: getStateValue(widget.state)),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _FacePainter(
            emotionalValue: value,
            loopingAnimation: _loopingController,
            staticAnimation: _staticController,
            pupilOffset: _pupilOffset,
            faceSizeDivisor: _faceSizeDivisor,
            currentState: widget.state,
          ),
        );
      },
    );
  }
}

class _FacePainter extends CustomPainter {
  final double emotionalValue;
  final Animation<double> loopingAnimation;
  final Animation<double> staticAnimation;
  final Offset pupilOffset;
  final double faceSizeDivisor;
  final PodEmotionalState currentState;

  _FacePainter({
    required this.emotionalValue,
    required this.loopingAnimation,
    required this.staticAnimation,
    required this.pupilOffset,
    required this.faceSizeDivisor,
    required this.currentState,
  }) : super(repaint: Listenable.merge([loopingAnimation, staticAnimation]));

  // Helper to draw a 4-point star for sparkles
  void drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final double angle = pi / 4 * i;
      final double r = i.isEven ? radius : radius / 2.5;
      final offset = Offset(cos(angle) * r, sin(angle) * r);
      if (i == 0) {
        path.moveTo(center.dx + offset.dx, center.dy + offset.dy);
      } else {
        path.lineTo(center.dx + offset.dx, center.dy + offset.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // Helper to draw a "Z"
  void _drawZ(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx - size / 2, center.dy - size / 2)
      ..lineTo(center.dx + size / 2, center.dy - size / 2)
      ..lineTo(center.dx - size / 2, center.dy + size / 2)
      ..lineTo(center.dx + size / 2, center.dy + size / 2);
    canvas.drawPath(path, paint);
  }

  // Helper to draw a water drop shape
  void _drawWaterDrop(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size) // Top point
      ..quadraticBezierTo(center.dx + size * 1.1, center.dy, center.dx, center.dy + size * 1.1) // Right curve to bottom
      ..quadraticBezierTo(center.dx - size * 1.1, center.dy, center.dx, center.dy - size); // Left curve back to top
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / faceSizeDivisor;

    // --- PAINTS ---
    final whitePaint = Paint()..color = Colors.white;
    final blackPaint = Paint()..color = Colors.black;
    final pinkPaint = Paint()..color = const Color(0xFFFE9398);
    final yellowPaint = Paint()..color = const Color(0xFFFFD460);
    final bluePaint = Paint()..color = Colors.blue.shade300;
    final greyPaint = Paint()..color = Colors.grey[600]!;

    final errorPaint = Paint()
      ..color = greyPaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1
      ..strokeCap = StrokeCap.round;

    // --- Static effect for disconnected state ---
    if (currentState == PodEmotionalState.disconnected) {
      final staticPaint = Paint()..color = Colors.white.withOpacity(0.05);
      final random = Random(staticAnimation.value.hashCode);
      for (int i = 0; i < 15; i++) {
        final y1 = random.nextDouble() * size.height;
        final y2 = random.nextDouble() * size.height;
        canvas.drawLine(Offset(0, y1), Offset(size.width, y2), staticPaint);
      }
    }

    // --- STATE LOGIC ---

    // 0.0 -> 1.0: sleeping -> waking
    if (emotionalValue <= 1.0) {
      final t = emotionalValue; // 0.0 = sleeping, 1.0 = waking

      // --- Environment ---
      final zOpacity = 1.0 - t;
      if (zOpacity > 0) {
        final zPaint = Paint.from(whitePaint)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.05
          ..color = Colors.white.withOpacity(zOpacity);
        final loop = loopingAnimation.value;
        _drawZ(
            canvas,
            center + Offset(radius * 0.3, -radius * 0.8 - (radius * loop)),
            radius * 0.1,
            zPaint);
        _drawZ(
            canvas,
            center +
                Offset(radius * 0.6,
                    -radius * 0.7 - (radius * ((loop + 0.33) % 1.0))),
            radius * 0.12,
            zPaint);
      }

      // --- Face: NEW Sensible waking animation ---
      // This animation smoothly transitions the sleeping eye '^^' into an
      // opening eye that will become the happy circle eye in the next state.
      final eyeY = center.dy - radius * 0.2;
      final eyeOffsetX = radius * 0.45;
      final eyeSize = radius * 0.4;
      final strokeWidth = radius * 0.08;

      // Stage 1: Animate the sleeping eye '^^' to a flat line '--'
      // We do this by changing the control point of the bezier curve.
      final eyePaint = Paint.from(whitePaint)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // At t=0, controlY is negative (upward curve ^^).
      // At t=1, controlY is 0 (flat line --).
      final controlY = lerpDouble(-radius * 0.3, 0.0, t)!;
      final closedEyePath = Path()
        ..moveTo(-eyeSize / 2, 0)
        ..quadraticBezierTo(0, controlY, eyeSize / 2, 0);

      canvas.save();
      canvas.translate(center.dx - eyeOffsetX, eyeY);
      canvas.drawPath(closedEyePath, eyePaint);
      canvas.restore();
      canvas.save();
      canvas.translate(center.dx + eyeOffsetX, eyeY);
      canvas.drawPath(closedEyePath, eyePaint);
      canvas.restore();
    }
    // 1.0 -> 2.0: waking -> happy
    else if (emotionalValue <= 2.0) {
      final t = emotionalValue - 1.0;

      // --- Face ---
      final eyeY = center.dy - radius * 0.2;
      final eyeOffsetX = radius * 0.45;
      final eyeSize = radius * 0.4;
      final strokeWidth = radius * 0.08;

      final eyePaint = Paint()..color = Colors.white;

      final eyeHeight = lerpDouble(strokeWidth, eyeSize, t)!;

      final leftEyeRect = Rect.fromCenter(center: Offset(center.dx - eyeOffsetX, eyeY), width: eyeSize, height: eyeHeight);
      final rightEyeRect = Rect.fromCenter(center: Offset(center.dx + eyeOffsetX, eyeY), width: eyeSize, height: eyeHeight);

      canvas.drawOval(leftEyeRect, eyePaint);
      canvas.drawOval(rightEyeRect, eyePaint);

      // Pupil logic
      final pupilOpacity = (t * 1.2).clamp(0.0, 1.0);
      if (pupilOpacity > 0) {
        final pupilPaint = Paint()..color = blackPaint.color.withOpacity(pupilOpacity);
        final eyeRadius = eyeSize / 2;
        final pupilRadius = eyeRadius * 0.5;
        final pupilMaxOffset = eyeRadius - pupilRadius;

        final upwardGazeOffset = lerpDouble(0, eyeRadius * 0.3, t)!;

        final currentPupilOffset = Offset(
            lerpDouble(0, pupilOffset.dx * pupilMaxOffset, t)!,
            lerpDouble(0, pupilOffset.dy * pupilMaxOffset, t)!
        );

        final pupilLeftCenter = Offset(
            center.dx - eyeOffsetX + currentPupilOffset.dx,
            eyeY + currentPupilOffset.dy - upwardGazeOffset
        );
        final pupilRightCenter = Offset(
            center.dx + eyeOffsetX + currentPupilOffset.dx,
            eyeY + currentPupilOffset.dy - upwardGazeOffset
        );

        canvas.drawCircle(pupilLeftCenter, pupilRadius, pupilPaint);
        canvas.drawCircle(pupilRightCenter, pupilRadius, pupilPaint);
      }

      // --- NEW MOUTH LOGIC: Simple Happy Arc ---
      final mouthY = center.dy + radius * 0.4;
      final mouthWidth = lerpDouble(0, radius * 0.25, t)!; // Keep the same width as before
      final mouthCurve = lerpDouble(0, radius * 0.15, t)!; // This controls the "happiness" of the smile

      // Define a paint for the line
      final mouthPaint = Paint()
        ..color = pinkPaint.color.withOpacity(t)
        ..style = PaintingStyle.stroke // Use .stroke to draw a line
        ..strokeWidth = radius * 0.06    // Give the line some thickness
        ..strokeCap = StrokeCap.round;   // Makes the line ends look soft

      // Create the path for the simple arc
      final mouthPath = Path()
        ..moveTo(center.dx - mouthWidth / 2, mouthY) // Start on the left
        ..quadraticBezierTo(
            center.dx,                // Control point X (center)
            mouthY + mouthCurve,      // Control point Y (pulls the curve down to make a smile)
            center.dx + mouthWidth / 2, // End on the right
            mouthY
        );

      canvas.drawPath(mouthPath, mouthPaint);
    }

    // 2.0 -> 3.0: happy -> thirsty (water)
    else if (emotionalValue <= 3.0) {
      final t = emotionalValue - 2.0; // Animation progress from 0.0 to 1.0

      // --- Cross-Fade Logic ---
      // This smoothly transitions from the happy face to the new unimpressed face.

      // 1. Fade out the happy face elements
      final happyOpacity = 1.0 - t;
      if (happyOpacity > 0) {
        final eyeY = center.dy - radius * 0.2;
        final eyeOffsetX = radius * 0.45;
        final eyeSize = radius * 0.4;

        // Draw happy eyes (white circles) fading out
        final happyEyePaint = Paint()..color = Colors.white.withOpacity(happyOpacity);
        canvas.drawCircle(Offset(center.dx - eyeOffsetX, eyeY), eyeSize / 2, happyEyePaint);
        canvas.drawCircle(Offset(center.dx + eyeOffsetX, eyeY), eyeSize / 2, happyEyePaint);

        // Draw happy pupils fading out
        final pupilPaint = Paint()..color = Colors.black.withOpacity(happyOpacity);
        final eyeRadius = eyeSize / 2;
        final pupilRadius = eyeRadius * 0.5;
        final pupilMaxOffset = eyeRadius - pupilRadius;
        final upwardGazeOffset = eyeRadius * 0.3;
        final pupilLeftCenter = Offset(center.dx - eyeOffsetX + (pupilOffset.dx * pupilMaxOffset), eyeY + (pupilOffset.dy * pupilMaxOffset) - upwardGazeOffset);
        final pupilRightCenter = Offset(center.dx + eyeOffsetX + (pupilOffset.dx * pupilMaxOffset), eyeY + (pupilOffset.dy * pupilMaxOffset) - upwardGazeOffset);
        canvas.drawCircle(pupilLeftCenter, pupilRadius, pupilPaint);
        canvas.drawCircle(pupilRightCenter, pupilRadius, pupilPaint);

        // Draw happy mouth fading out
        final mouthPaint = Paint()
          ..color = pinkPaint.color.withOpacity(happyOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.06
          ..strokeCap = StrokeCap.round;
        final mouthY = center.dy + radius * 0.4;
        final mouthWidth = radius * 0.25;
        final mouthCurve = radius * 0.15;
        final mouthPath = Path()
          ..moveTo(center.dx - mouthWidth / 2, mouthY)
          ..quadraticBezierTo(center.dx, mouthY + mouthCurve, center.dx + mouthWidth / 2, mouthY);
        canvas.drawPath(mouthPath, mouthPaint);
      }

      // 2. Fade in the new "thirsty" face elements
      final thirstyOpacity = t;
      if (thirstyOpacity > 0) {
        final thirstyPaint = Paint()..color = Colors.white.withOpacity(thirstyOpacity);

        // --- Draw the new unimpressed eyes ---
        final eyeY = center.dy - radius * 0.15;
        final eyeOffsetX = radius * 0.45;
        final eyeWidth = lerpDouble(0, radius * 0.6, t)!;
        final eyeHeight = lerpDouble(0, radius * 0.25, t)!;

        // This path creates a filled, curved shape like the image
        final eyePath = Path()
          ..moveTo(-eyeWidth / 2, 0) // Left point
          ..quadraticBezierTo(0, eyeHeight, eyeWidth / 2, 0) // Bottom curve
          ..quadraticBezierTo(0, eyeHeight * 0.2, -eyeWidth / 2, 0) // Flatter top curve to add thickness
          ..close();

        canvas.save();
        canvas.translate(center.dx - eyeOffsetX, eyeY);
        canvas.drawPath(eyePath, thirstyPaint);
        canvas.restore();

        canvas.save();
        canvas.translate(center.dx + eyeOffsetX, eyeY);
        canvas.drawPath(eyePath, thirstyPaint);
        canvas.restore();

        // --- Draw the new "o" mouth ---
        final mouthY = center.dy + radius * 0.4;
        final mouthWidth = lerpDouble(0, radius * 0.1, t)!;
        final mouthHeight = lerpDouble(0, radius * 0.2, t)!;

        final mouthRect = Rect.fromCenter(
            center: Offset(center.dx, mouthY),
            width: mouthWidth,
            height: mouthHeight
        );
        canvas.drawOval(mouthRect, thirstyPaint);
      }
    }

    // 3.0 -> 4.0: thirsty (water) -> needsNutrients
    else if (emotionalValue <= 4.0) {
      final t = emotionalValue - 3.0;
      // --- Environment ---
      final loop = sin(loopingAnimation.value * 2 * pi); // For pulsing
      final pulse = 1.0 + loop * 0.1;

      // Define a new green paint for the icon
      final greenPaint = Paint()
        ..color = const Color(0xFF53E086).withOpacity(t) // A nice plant green
        ..style = PaintingStyle.fill;

      final iconCenter = center + Offset(radius * 0.8, -radius * 0.6);

      canvas.save();
      canvas.translate(iconCenter.dx, iconCenter.dy);
      canvas.scale(pulse); // Apply the pulsing effect

      // 1. Draw the background triangle (back layer)
      final triPath = Path()
        ..moveTo(0, -radius * 0.25) // Top point
        ..lineTo(radius * 0.2, radius * 0.2) // Bottom right
        ..lineTo(-radius * 0.2, radius * 0.2) // Bottom left
        ..close();
      canvas.drawPath(triPath, greenPaint);

      // 2. Draw the soil mound
      final soilRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, radius * 0.15),
          width: radius * 0.3,
          height: radius * 0.1,
        ),
        Radius.circular(radius * 0.1),
      );
      canvas.drawRRect(soilRect, greenPaint);

      // 3. Draw the plant stem (a thin rectangle)
      final stemRect = Rect.fromCenter(
        center: Offset(0, radius * 0.05),
        width: radius * 0.04,
        height: radius * 0.2,
      );
      canvas.drawRect(stemRect, greenPaint);

      // 4. Draw the leaves
      // A simple helper path for a leaf shape
      final leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(radius * 0.05, -radius * 0.08, 0, -radius * 0.15)
        ..quadraticBezierTo(-radius * 0.05, -radius * 0.08, 0, 0)
        ..close();

      // Top leaf
      canvas.save();
      canvas.translate(0, -radius * 0.08);
      canvas.drawPath(leafPath, greenPaint);
      canvas.restore();

      // Right leaf
      canvas.save();
      canvas.translate(0, -radius * 0.02);
      canvas.rotate(pi / 5);
      canvas.drawPath(leafPath, greenPaint);
      canvas.restore();

      // Left leaf
      canvas.save();
      canvas.translate(0, -radius * 0.02);
      canvas.rotate(-pi / 5);
      canvas.drawPath(leafPath, greenPaint);
      canvas.restore();

      canvas.restore();

      // --- Face ---
      // Eyes: Sad -> Worried (less droop)
      final eyeY = center.dy - radius * 0.15;
      final eyeOffsetX = radius * 0.45;
      final eyeWidth = radius * 0.4;
      final eyeControlY = lerpDouble(radius * 0.5, radius*0.2, t)!;
      final eyePaint = Paint.from(whitePaint)..style=PaintingStyle.stroke..strokeWidth=radius*0.08..strokeCap=StrokeCap.round;
      final eyePath = Path()..moveTo(-eyeWidth / 2, 0)..quadraticBezierTo(0, eyeControlY, eyeWidth / 2, 0);
      canvas.save(); canvas.translate(center.dx - eyeOffsetX, eyeY); canvas.drawPath(eyePath, eyePaint); canvas.restore();
      canvas.save(); canvas.translate(center.dx + eyeOffsetX, eyeY); canvas.drawPath(eyePath, eyePaint); canvas.restore();

      // Mouth: "o" -> Wavy "~~"
      final mouthY = center.dy + radius * 0.4;
      final mouthWidth = lerpDouble(0, radius*0.5, t)!;
      final mouthHeight = lerpDouble(0, radius*0.1, t)!;
      final mouthPath = Path()..moveTo(center.dx-mouthWidth/2, mouthY)..quadraticBezierTo(center.dx-mouthWidth/4, mouthY-mouthHeight, center.dx, mouthY)..quadraticBezierTo(center.dx+mouthWidth/4, mouthY+mouthHeight, center.dx+mouthWidth/2, mouthY);
      canvas.drawPath(mouthPath, eyePaint..color=Colors.white.withOpacity(t));
    }
    // And so on for all other states...
    // The following states are implemented directly without transitions for brevity
    // A full implementation would lerp every property like the examples above.

    // 4.0 -> 5.0: needsNutrients -> hot
    else if (emotionalValue <= 5.0) {
      final t = emotionalValue - 4.0;

      // --- Environment: NEW Heat haze effect ---
      final hazePaint = Paint()
        ..color = Colors.white.withOpacity(0.15 * t) // Fades in
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Use the looping animation to make the waves rise
      final loop = loopingAnimation.value;
      final startY = size.height * 0.4;
      final travelDist = size.height * 0.5;

      // Draw 3 wavy lines with slight variations
      for (int i = 0; i < 3; i++) {
        final path = Path();
        final yOffset = startY - ((loop + (i * 0.33)) % 1.0) * travelDist;
        path.moveTo(0, yOffset);
        for (double x = 0; x < size.width; x++) {
          final waveY = yOffset + sin((x * 0.02) + (loop * 5) + (i * 2)) * 8;
          path.lineTo(x, waveY);
        }
        canvas.drawPath(path, hazePaint);
      }

      // --- Face (remains the same) ---
      // Eyes: Droopy
      final eyeY = center.dy - radius * 0.2;
      final eyeOffsetX = radius * 0.4;
      final eyePath = Path()..moveTo(-radius*0.2,0)..quadraticBezierTo(0, radius*0.25, radius*0.2,0);
      final eyePaint = Paint.from(whitePaint)..style=PaintingStyle.stroke..strokeWidth=radius*0.1..strokeCap=StrokeCap.round;
      canvas.save(); canvas.translate(center.dx-eyeOffsetX, eyeY); canvas.drawPath(eyePath, eyePaint); canvas.restore();
      canvas.save(); canvas.translate(center.dx+eyeOffsetX, eyeY); canvas.drawPath(eyePath, eyePaint); canvas.restore();

      // Mouth: Panting
      final mouthRect = Rect.fromCenter(center: center.translate(0, radius*0.4), width: radius*0.6, height: radius*0.4);
      canvas.drawArc(mouthRect, 0, pi, true, whitePaint);
    }
    // 5.0 -> 6.0: hot -> thirstySoil
    else if (emotionalValue <= 6.0) {
      final t = emotionalValue - 5.0; // Animation progress from 0.0 to 1.0

      // --- Face ---
      // Eyes: > < shape, fading in
      final eyeY = center.dy - radius * 0.2;
      final eyeOffsetX = radius * 0.45;
      final eyeSize = radius * 0.3;
      final eyePaint = Paint.from(whitePaint)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lerpDouble(0, radius * 0.08, t)! // Animate stroke width
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(t); // Animate opacity

      // Left Eye (>)
      final leftEyePath = Path()
        ..moveTo(center.dx - eyeOffsetX - eyeSize/2, eyeY - eyeSize/2)
        ..lineTo(center.dx - eyeOffsetX + eyeSize/2, eyeY)
        ..lineTo(center.dx - eyeOffsetX - eyeSize/2, eyeY + eyeSize/2);
      canvas.drawPath(leftEyePath, eyePaint);

      // Right Eye (<)
      final rightEyePath = Path()
        ..moveTo(center.dx + eyeOffsetX + eyeSize/2, eyeY - eyeSize/2)
        ..lineTo(center.dx + eyeOffsetX - eyeSize/2, eyeY)
        ..lineTo(center.dx + eyeOffsetX + eyeSize/2, eyeY + eyeSize/2);
      canvas.drawPath(rightEyePath, eyePaint);


      // --- Mouth: Replaced with a cup and straw ---
      final cupY = center.dy + radius * 0.4;
      final cupWidth = lerpDouble(0, radius * 0.8, t)!;
      final cupHeight = lerpDouble(0, radius * 0.2, t)!;

      // The Cup
      final cupPaint = Paint.from(whitePaint)
        ..color = Colors.white.withOpacity(t);
      final cupRect = RRect.fromRectAndCorners(
        Rect.fromCenter(center: Offset(center.dx, cupY), width: cupWidth, height: cupHeight),
        topLeft: Radius.circular(cupHeight / 2),
        topRight: Radius.circular(cupHeight / 2),
      );
      canvas.drawRRect(cupRect, cupPaint);

      // The Straw (drawn as two colored lines)
      final strawStrokeWidth = lerpDouble(0, radius * 0.08, t)!;
      final strawPinkPaint = Paint.from(pinkPaint)
        ..strokeWidth = strawStrokeWidth
        ..strokeCap = StrokeCap.round
        ..color = pinkPaint.color.withOpacity(t);
      final strawBluePaint = Paint.from(bluePaint)
        ..strokeWidth = strawStrokeWidth
        ..strokeCap = StrokeCap.round
        ..color = bluePaint.color.withOpacity(t);

      // Define the points for the straw's bend
      final strawElbow = Offset(center.dx + radius * 0.1, cupY - cupHeight * 0.8);
      final strawBottom = Offset(center.dx, cupY + cupHeight * 0.2);

      // Draw the two segments of the straw
      canvas.drawLine(strawElbow, strawBottom, strawBluePaint);
      canvas.drawLine(strawElbow, strawElbow.translate(radius * 0.2, -radius * 0.2), strawPinkPaint);
    }
    // 6.0 -> 7.0: thirstySoil -> hidingFromLight
    else if (emotionalValue <= 7.0) {
      // Eyes: > <
      final eyeY = center.dy - radius * 0.2;
      final eyeOffsetX = radius * 0.4;
      final eyeSize = radius * 0.2;
      final eyePaint = Paint.from(whitePaint)..style=PaintingStyle.stroke..strokeWidth=radius*0.1..strokeCap=StrokeCap.round;

      final leftEyePath = Path()..moveTo(center.dx-eyeOffsetX+eyeSize/2, eyeY-eyeSize/2)..lineTo(center.dx-eyeOffsetX-eyeSize/2, eyeY+eyeSize/2);
      final rightEyePath = Path()..moveTo(center.dx+eyeOffsetX-eyeSize/2, eyeY-eyeSize/2)..lineTo(center.dx+eyeOffsetX+eyeSize/2, eyeY+eyeSize/2);

      canvas.drawPath(leftEyePath, eyePaint);
      canvas.drawPath(rightEyePath, eyePaint);

      // Mouth: Flat line
      canvas.drawLine(center.translate(-radius*0.2, radius*0.4), center.translate(radius*0.2, radius*0.4), eyePaint);
    }
    // 7.0 -> 8.0: hidingFromLight -> sunbathing
    else if (emotionalValue <= 8.0) {
      final t = emotionalValue - 7.0;

      // --- Environment: Pulsing Sun Icon ---
      final loop = sin(loopingAnimation.value * 2 * pi); // Value from -1 to 1
      final pulse = 1.0 + loop * 0.08; // Gentle pulse from 0.92 to 1.08
      final sunPaint = Paint()
        ..color = yellowPaint.color.withOpacity(t)
        ..style = PaintingStyle.fill;
      final sunStrokePaint = Paint.from(sunPaint)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.04
        ..strokeCap = StrokeCap.round;

      final sunCenter = center + Offset(radius * 0.8, -radius * 0.8); // Top right corner

      canvas.save();
      canvas.translate(sunCenter.dx, sunCenter.dy);
      canvas.scale(pulse); // Apply the pulsing animation

      // Draw sun body and rays
      final sunRadius = radius * 0.1;
      canvas.drawCircle(Offset.zero, sunRadius, sunPaint);
      for (int i = 0; i < 8; i++) {
        final angle = pi / 4 * i;
        final p1 = Offset(cos(angle) * sunRadius * 1.3, sin(angle) * sunRadius * 1.3);
        final p2 = Offset(cos(angle) * sunRadius * 1.9, sin(angle) * sunRadius * 1.9);
        canvas.drawLine(p1, p2, sunStrokePaint);
      }
      canvas.restore();


      // --- Face: New Happy Expression ---
      // Eyes: Happy ^^ arcs
      final eyeY = center.dy - radius * 0.25;
      final eyeOffsetX = radius * 0.45;
      final eyeSize = lerpDouble(0, radius * 0.4, t)!;
      final eyePaint = Paint.from(whitePaint)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.08
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(t);

      final happyEyePath = Path()
        ..moveTo(-eyeSize / 2, 0)
        ..quadraticBezierTo(0, -radius * 0.3, eyeSize / 2, 0);

      canvas.save();
      canvas.translate(center.dx - eyeOffsetX, eyeY);
      canvas.drawPath(happyEyePath, eyePaint);
      canvas.restore();
      canvas.save();
      canvas.translate(center.dx + eyeOffsetX, eyeY);
      canvas.drawPath(happyEyePath, eyePaint);
      canvas.restore();

      // Mouth: Big white D-smile
      final mouthY = center.dy + radius * 0.3;
      final mouthWidth = lerpDouble(0, radius * 0.9, t)!;
      final mouthHeight = lerpDouble(0, radius * 0.6, t)!;
      final mouthRect = Rect.fromCenter(
          center: Offset(center.dx, mouthY),
          width: mouthWidth,
          height: mouthHeight);
      canvas.drawArc(mouthRect, 0, pi, true, Paint()..color = Colors.white.withOpacity(t));

      // Blush
      final blushRadius = lerpDouble(0, radius * 0.15, t)!;
      final blushPaint = Paint()
        ..color = pinkPaint.color.withOpacity(t * 0.8);
      canvas.drawCircle(center + Offset(-radius * 0.6, radius * 0.15), blushRadius, blushPaint);
      canvas.drawCircle(center + Offset(radius * 0.6, radius * 0.15), blushRadius, blushPaint);
    }
    // 8.0 -> 9.0: sunbathing -> disconnected
    else {
      // Eyes: "X" shape
      final eyeY = center.dy - radius * 0.2;
      final eyeOffsetX = radius * 0.4;
      final eyeSize = radius * 0.15;

      final leftEyeCenter = Offset(center.dx - eyeOffsetX, eyeY);
      canvas.drawLine(leftEyeCenter - Offset(eyeSize, eyeSize), leftEyeCenter + Offset(eyeSize, eyeSize), errorPaint);
      canvas.drawLine(leftEyeCenter - Offset(eyeSize, -eyeSize), leftEyeCenter + Offset(eyeSize, -eyeSize), errorPaint);

      final rightEyeCenter = Offset(center.dx + eyeOffsetX, eyeY);
      canvas.drawLine(rightEyeCenter - Offset(eyeSize, eyeSize), rightEyeCenter + Offset(eyeSize, eyeSize), errorPaint);
      canvas.drawLine(rightEyeCenter - Offset(eyeSize, -eyeSize), rightEyeCenter + Offset(eyeSize, -eyeSize), errorPaint);

      // Mouth: Flat line
      final mouthY = center.dy + radius * 0.4;
      final mouthWidth = radius * 0.3;
      canvas.drawLine(Offset(center.dx - mouthWidth / 2, mouthY), Offset(center.dx + mouthWidth / 2, mouthY), errorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) {
    return oldDelegate.emotionalValue != emotionalValue ||
        oldDelegate.pupilOffset != pupilOffset ||
        oldDelegate.currentState != currentState;
  }
}