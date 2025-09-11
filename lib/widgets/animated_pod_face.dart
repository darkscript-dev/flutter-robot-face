import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import '../models/pod_status.dart';
import '../services/sound_manager.dart';

//90% ai generated file

class AnimatedPodFace extends StatefulWidget {
  final PodEmotionalState state;
  const AnimatedPodFace({required this.state, Key? key}) : super(key: key);

  @override
  State<AnimatedPodFace> createState() => _AnimatedPodFaceState();
}

class _AnimatedPodFaceState extends State<AnimatedPodFace>
    with TickerProviderStateMixin {
  late AnimationController _loopingController;
  late AnimationController _staticController;
  late AnimationController _blinkController;
  Timer? _idleAnimationTimer;

  double _lookOffsetX = 0.0;
  double _lookOffsetY = 0.0;
  double _eyeTilt = 0.0;

  double _faceSizeDivisor = 2.8;
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

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

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
    bool isAwakeAndActive = newState != PodEmotionalState.sleeping &&
        newState != PodEmotionalState.waking &&
        newState != PodEmotionalState.disconnected;

    if (isAwakeAndActive) {
      _idleAnimationTimer?.cancel();
      _idleAnimationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        SoundManager().play(Sound.eyeMove);

        if (widget.state == PodEmotionalState.happy) {
          SoundManager().play(Sound.blink);
          _blinkController.forward(from: 0.0);
        }

        setState(() {
          final random = Random();
          final animationType = random.nextInt(5);

          switch (animationType) {
            case 0: // Look left or right
              _lookOffsetX = (random.nextBool() ? 1.0 : -1.0) * (0.5 + random.nextDouble() * 0.5);
              _lookOffsetY = 0.0;
              _eyeTilt = 0.0;
              break;
            case 1: // Look up or down
              _lookOffsetX = 0.0;
              _lookOffsetY = (random.nextBool() ? 1.0 : -1.0) * (0.4 + random.nextDouble() * 0.4);
              _eyeTilt = 0.0;
              break;
            case 2: // Look in a corner
              _lookOffsetX = (random.nextBool() ? 1.0 : -1.0) * (0.5 + random.nextDouble() * 0.5);
              _lookOffsetY = (random.nextBool() ? 1.0 : -1.0) * (0.4 + random.nextDouble() * 0.4);
              _eyeTilt = 0.0;
              break;
            case 3: // Tilt
              _lookOffsetX = (random.nextBool() ? 1.0 : -1.0) * 0.3;
              _lookOffsetY = 0.0;
              _eyeTilt = (random.nextBool() ? 1.0 : -1.0) * (pi / 32);
              break;
            default: // Reset to center
              _lookOffsetX = 0.0;
              _lookOffsetY = 0.0;
              _eyeTilt = 0.0;
              break;
          }
        });
      });
    } else {
      _idleAnimationTimer?.cancel();
      if (_lookOffsetX != 0.0 || _lookOffsetY != 0.0 || _eyeTilt != 0.0) {
        setState(() {
          _lookOffsetX = 0.0;
          _lookOffsetY = 0.0;
          _eyeTilt = 0.0;
        });
      }
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _faceSizeDivisor = prefs.getDouble('face_size_divisor') ?? 2.8;
      });
    }
  }

  @override
  void dispose() {
    _loopingController.dispose();
    _staticController.dispose();
    _blinkController.dispose();
    _idleAnimationTimer?.cancel();
    super.dispose();
  }

  double getStateValue(PodEmotionalState state) {
    switch (state) {
      case PodEmotionalState.sleeping: return 0.0;
      case PodEmotionalState.waking: return 1.0;
      case PodEmotionalState.happy: return 2.0;
      case PodEmotionalState.thirsty: return 3.0;
      case PodEmotionalState.needsNutrients: return 4.0;
      case PodEmotionalState.hot: return 5.0;
      case PodEmotionalState.thirstySoil: return 6.0;
      case PodEmotionalState.hidingFromLight: return 7.0;
      case PodEmotionalState.sunbathing: return 8.0;
      case PodEmotionalState.disconnected: return 9.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: getStateValue(_previousState), end: getStateValue(widget.state)),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) {
        return TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(begin: Offset(_lookOffsetX, _lookOffsetY), end: Offset(_lookOffsetX, _lookOffsetY)),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, lookOffset, child) {
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: _eyeTilt, end: _eyeTilt),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, tilt, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _FacePainter(
                    emotionalValue: value,
                    loopingAnimation: _loopingController,
                    staticAnimation: _staticController,
                    blinkAnimation: _blinkController,
                    lookOffset: lookOffset,
                    eyeTilt: tilt,
                    faceSizeDivisor: _faceSizeDivisor,
                    currentState: widget.state,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// =========================================================================
// FINAL, STABLE, HIGH-PERFORMANCE ROBOT FACE PAINTER
// =========================================================================
class _FacePainter extends CustomPainter {
  final double emotionalValue;
  final Animation<double> loopingAnimation;
  final Animation<double> staticAnimation;
  final Animation<double> blinkAnimation;
  final Offset lookOffset;
  final double eyeTilt;
  final double faceSizeDivisor;
  final PodEmotionalState currentState;

  final Paint solidCyanPaint;
  final Paint solidRedPaint;
  final Paint solidPinkPaint;
  final Paint strokeCyanPaint;

  _FacePainter({
    required this.emotionalValue,
    required this.loopingAnimation,
    required this.staticAnimation,
    required this.blinkAnimation,
    required this.lookOffset,
    required this.eyeTilt,
    required this.faceSizeDivisor,
    required this.currentState,
  }) : solidCyanPaint = Paint()..color = const Color(0xFF22DDDD),
        solidRedPaint = Paint()..color = const Color(0xFFF44336),
        solidPinkPaint = Paint()..color = const Color(0xFFE91E63),
        strokeCyanPaint = Paint()
          ..color = const Color(0xFF22DDDD)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
        super(repaint: Listenable.merge([loopingAnimation, staticAnimation, blinkAnimation]));

  RRect _getNeutralRRect(Offset center, double size) {
    return RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size, height: size * 0.6),
      Radius.circular(size * 0.1),
    );
  }

  RRect _getBlinkingNeutralRRect(Offset center, double size, {required double blinkValue}) {
    final curveAmount = sin(blinkValue * pi);
    final openHeight = size * 0.6;
    final closedHeight = size * 0.2;
    final currentHeight = lerpDouble(openHeight, closedHeight, curveAmount)!;
    return RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size, height: currentHeight),
      Radius.circular(size * 0.1),
    );
  }

  Path _getSadPath(Offset center, double size, {bool reflect = false}) {
    final multiplier = reflect ? -1.0 : 1.0;
    return Path()
      ..moveTo(center.dx - (size/2 * multiplier), center.dy - size/2)
      ..lineTo(center.dx - (size/2 * multiplier), center.dy + size/2)
      ..quadraticBezierTo(center.dx, center.dy + size * 0.2, center.dx + (size/2 * multiplier), center.dy - size/2)
      ..close();
  }

  Path _getDenyingPath(Offset center, double size, {bool reflect = false}) {
    final multiplier = reflect ? -1.0 : 1.0;
    return Path()
      ..moveTo(center.dx + (size/2 * multiplier), center.dy - size/2)
      ..lineTo(center.dx - (size/2 * multiplier), center.dy)
      ..lineTo(center.dx + (size/2 * multiplier), center.dy + size/2);
  }

  Path _getAngryPath(Offset center, double size, {bool reflect = false}) {
    final multiplier = reflect ? -1.0 : 1.0;
    return Path()
      ..moveTo(center.dx - (size/2 * multiplier), center.dy + size/2)
      ..lineTo(center.dx + (size/2 * multiplier), center.dy + size/2)
      ..lineTo(center.dx + (size/2 * multiplier), center.dy - size/2)
      ..close();
  }

  Path _getTiredPath(Offset center, double size) {
    return Path()
      ..moveTo(center.dx - size / 2, center.dy - size * 0.1)
      ..quadraticBezierTo(center.dx, center.dy + size * 0.5, center.dx + size / 2, center.dy - size * 0.1);
  }

  Path _getHeartPath(Offset center, double size) {
    return Path()
      ..moveTo(center.dx, center.dy + size * 0.1)
      ..cubicTo(center.dx + size * 0.4, center.dy - size * 0.5, center.dx + size * 0.8, center.dy, center.dx, center.dy + size * 0.6)
      ..cubicTo(center.dx - size * 0.8, center.dy, center.dx - size * 0.4, center.dy - size * 0.5, center.dx, center.dy + size * 0.1)
      ..close();
  }

  void _drawZ(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx - size / 2, center.dy - size / 2)
      ..lineTo(center.dx + size / 2, center.dy - size / 2)
      ..lineTo(center.dx - size / 2, center.dy + size / 2)
      ..lineTo(center.dx + size / 2, center.dy + size / 2);
    canvas.drawPath(path, paint);
  }

  void _drawEyePair(Canvas canvas, Offset center, double eyeSize, double eyeOffsetX, double maxLookX, double maxLookY, void Function(Canvas canvas, Offset center) drawLeftEye, [void Function(Canvas canvas, Offset center)? drawRightEye]) {
    drawRightEye ??= drawLeftEye;

    canvas.save();
    final leftCenter = center.translate(-eyeOffsetX, 0);
    canvas.translate(leftCenter.dx + (lookOffset.dx * maxLookX), leftCenter.dy + (lookOffset.dy * maxLookY));
    canvas.rotate(eyeTilt);
    drawLeftEye(canvas, Offset.zero);
    canvas.restore();

    canvas.save();
    final rightCenter = center.translate(eyeOffsetX, 0);
    canvas.translate(rightCenter.dx + (lookOffset.dx * maxLookX), rightCenter.dy + (lookOffset.dy * maxLookY));
    canvas.rotate(eyeTilt);
    drawRightEye(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / faceSizeDivisor;

    final eyeOffsetX = radius * 0.6;
    final eyeSize = radius * 0.7;
    final maxLookOffsetX = radius * 0.15;
    final maxLookOffsetY = radius * 0.1;

    if (currentState == PodEmotionalState.disconnected) {
      final random = Random(staticAnimation.value.hashCode);
      for (int i = 0; i < 15; i++) {
        final y1 = random.nextDouble() * size.height;
        final y2 = random.nextDouble() * size.height;
        canvas.drawLine(Offset(0, y1), Offset(size.width, y2), Paint()..color = Colors.white.withOpacity(0.05));
      }
    }

    // --- STATE LOGIC ---

    if (emotionalValue <= 1.0) { // sleeping -> waking
      final t = emotionalValue;
      if (t < 1.0) { // Only show Z's during sleep
        final zOpacity = 1.0 - t;
        final zPaint = strokeCyanPaint..color = solidCyanPaint.color.withOpacity(zOpacity)..strokeWidth=radius*0.06;
        _drawZ(canvas, center + Offset(radius * 0.8, -radius * 1.2 - (loopingAnimation.value * radius)), radius * 0.15, zPaint);
      }

      final eyeHeight = lerpDouble(eyeSize * 0.2, eyeSize * 0.6, t)!;
      final rectLeft = RRect.fromRectAndRadius(Rect.fromCenter(center: center.translate(-eyeOffsetX, 0), width: eyeSize, height: eyeHeight), Radius.circular(eyeSize * 0.1));
      final rectRight = RRect.fromRectAndRadius(Rect.fromCenter(center: center.translate(eyeOffsetX, 0), width: eyeSize, height: eyeHeight), Radius.circular(eyeSize * 0.1));

      canvas.drawRRect(rectLeft, solidCyanPaint);
      canvas.drawRRect(rectRight, solidCyanPaint);
    }
    else if (emotionalValue <= 2.0) { // happy
      _drawEyePair(canvas, center, eyeSize, eyeOffsetX, maxLookOffsetX, maxLookOffsetY, (ctx, eyeCenter) {
        final eye = _getBlinkingNeutralRRect(eyeCenter, eyeSize, blinkValue: blinkAnimation.value);
        ctx.drawRRect(eye, solidCyanPaint);
      });
    }
    else if (emotionalValue <= 3.0) { // happy -> thirsty
      final t = emotionalValue - 2.0;
      final fromOpacity = 1.0 - t;
      final toOpacity = t;

      _drawEyePair(canvas, center, eyeSize, eyeOffsetX, maxLookOffsetX, maxLookOffsetY, (ctx, eyeCenter) {
        // Draw both eyes on top of each other, fading in/out
        final fromEye = _getNeutralRRect(eyeCenter, eyeSize);
        final toPathLeft = _getSadPath(eyeCenter, eyeSize);
        final toPathRight = _getSadPath(eyeCenter, eyeSize, reflect: true);

        ctx.drawRRect(fromEye, solidCyanPaint..color = solidCyanPaint.color.withOpacity(fromOpacity));
        ctx.drawPath(toPathLeft, solidCyanPaint..color = solidCyanPaint.color.withOpacity(toOpacity));
        ctx.drawPath(toPathRight, solidCyanPaint..color = solidCyanPaint.color.withOpacity(toOpacity));
      });
    }
    else if (emotionalValue <= 4.0) { // thirsty -> needsNutrients
      final t = emotionalValue - 3.0;
      final fromOpacity = 1.0 - t;
      final toOpacity = t;

      _drawEyePair(canvas, center, eyeSize, eyeOffsetX, maxLookOffsetX, maxLookOffsetY,
              (ctx, eyeCenter) { // Left eye
            ctx.drawPath(_getSadPath(eyeCenter, eyeSize), solidCyanPaint..color = solidCyanPaint.color.withOpacity(fromOpacity));
            ctx.drawPath(_getDenyingPath(eyeCenter, eyeSize), strokeCyanPaint..color = solidCyanPaint.color.withOpacity(toOpacity)..strokeWidth=radius*0.12);
          },
              (ctx, eyeCenter) { // Right eye
            ctx.drawPath(_getSadPath(eyeCenter, eyeSize, reflect: true), solidCyanPaint..color = solidCyanPaint.color.withOpacity(fromOpacity));
            ctx.drawPath(_getDenyingPath(eyeCenter, eyeSize, reflect: true), strokeCyanPaint..color = solidCyanPaint.color.withOpacity(toOpacity)..strokeWidth=radius*0.12);
          }
      );
    }
    else if (emotionalValue <= 5.0) { // needsNutrients -> hot
      final t = emotionalValue - 4.0;
      final angryColor = Color.lerp(solidCyanPaint.color, solidRedPaint.color, t)!;
      _drawEyePair(canvas, center, eyeSize, eyeOffsetX, maxLookOffsetX, maxLookOffsetY,
              (ctx, eyeCenter) => ctx.drawPath(_getAngryPath(eyeCenter, eyeSize), Paint()..color=angryColor),
              (ctx, eyeCenter) => ctx.drawPath(_getAngryPath(eyeCenter, eyeSize, reflect: true), Paint()..color=angryColor)
      );
    }
    else if (emotionalValue <= 6.0) { // hot -> thirstySoil
      final paint = strokeCyanPaint..strokeWidth=radius*0.12;
      _drawEyePair(canvas, center, eyeSize, eyeOffsetX, maxLookOffsetX, maxLookOffsetY,
              (ctx, eyeCenter) => ctx.drawPath(_getTiredPath(eyeCenter, eyeSize), paint)
      );
    }
    else if (emotionalValue <= 7.0) { // thirstySoil -> hidingFromLight
      final paint = strokeCyanPaint..strokeWidth=radius*0.12;
      _drawEyePair(canvas, center, eyeSize, eyeOffsetX, maxLookOffsetX, maxLookOffsetY,
              (ctx, eyeCenter) => ctx.drawPath(_getDenyingPath(eyeCenter, eyeSize), paint),
              (ctx, eyeCenter) => ctx.drawPath(_getDenyingPath(eyeCenter, eyeSize, reflect: true), paint)
      );
    }
    else if (emotionalValue <= 8.0) { // hidingFromLight -> sunbathing
      final t = emotionalValue - 7.0;
      final loveColor = Color.lerp(solidCyanPaint.color, solidPinkPaint.color, t)!;
      final paint = Paint()..color = loveColor;
      _drawEyePair(canvas, center, eyeSize, eyeOffsetX, maxLookOffsetX, maxLookOffsetY,
              (ctx, eyeCenter) => ctx.drawPath(_getHeartPath(eyeCenter, eyeSize), paint)
      );
    }
    else { // disconnected
      final paint = strokeCyanPaint..strokeWidth=radius*0.15;
      final leftCenter = center.translate(-eyeOffsetX, 0);
      final rightCenter = center.translate(eyeOffsetX, 0);

      canvas.drawLine(leftCenter - Offset(eyeSize/2, eyeSize/2), leftCenter + Offset(eyeSize/2, eyeSize/2), paint);
      canvas.drawLine(leftCenter - Offset(eyeSize/2, -eyeSize/2), leftCenter + Offset(eyeSize/2, -eyeSize/2), paint);
      canvas.drawLine(rightCenter - Offset(eyeSize/2, eyeSize/2), rightCenter + Offset(eyeSize/2, eyeSize/2), paint);
      canvas.drawLine(rightCenter - Offset(eyeSize/2, -eyeSize/2), rightCenter + Offset(eyeSize/2, -eyeSize/2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) {
    return oldDelegate.emotionalValue != emotionalValue ||
        oldDelegate.currentState != currentState ||
        oldDelegate.lookOffset != oldDelegate.lookOffset ||
        oldDelegate.eyeTilt != eyeTilt;
  }
}