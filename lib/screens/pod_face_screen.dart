import 'dart:async';
import 'package:flutter/material.dart';
import '../api/pod_api.dart';
import '../models/pod_status.dart';
import '../services/sound_manager.dart';
import '../widgets/animated_pod_face.dart';
import '../widgets/dreaming_particles.dart';
import 'data_overlay_screen.dart';

enum FaceDisplayMode { attract, waking, active }

class PodFaceScreen extends StatefulWidget {
  const PodFaceScreen({Key? key}) : super(key: key);
  @override
  State<PodFaceScreen> createState() => PodFaceScreenState();
}

class PodFaceScreenState extends State<PodFaceScreen> with TickerProviderStateMixin {
  // Mode Management
  FaceDisplayMode _currentMode = FaceDisplayMode.waking;
  Timer? _inactivityTimer;

  // Face State Management
  PodEmotionalState _currentFaceState = PodEmotionalState.sleeping;
  Timer? _statusUpdateTimer;

  PodStatus? _currentStatus;

  bool _isDebugStateForced = false;
  late AnimationController _auraController;

  @override
  void initState() {
    super.initState();
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _startWakeUpSequence();
  }

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    _inactivityTimer?.cancel();
    _auraController.dispose();
    SoundManager().stopDreamingLoop();
    super.dispose();
  }

  Color _getAuraColor(PodEmotionalState state) {
    if (_currentMode != FaceDisplayMode.active) return Colors.transparent;
    switch (state) {
      case PodEmotionalState.happy: return Colors.green.withOpacity(0.5);
      case PodEmotionalState.thirsty:
      case PodEmotionalState.thirstySoil: return Colors.blue.withOpacity(0.4);
      case PodEmotionalState.hot: return Colors.orange.withOpacity(0.4);
      case PodEmotionalState.disconnected: return Colors.grey.withOpacity(0.3);
      default: return Colors.transparent;
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 60), _enterAttractMode);
  }

  void _enterAttractMode() {
    if (_isDebugStateForced) return;
    if (_currentMode == FaceDisplayMode.attract) return;
    print("[Face App] Entering Attract Mode.");
    _statusUpdateTimer?.cancel();
    SoundManager().play(Sound.voiceSleep);
    SoundManager().startDreamingLoop();
    setState(() {
      _currentMode = FaceDisplayMode.attract;
      _currentFaceState = PodEmotionalState.sleeping;
    });
  }

  void _startWakeUpSequence() async {
    if (_currentMode == FaceDisplayMode.active || (_currentMode == FaceDisplayMode.waking && _currentFaceState != PodEmotionalState.sleeping)) {
      _resetInactivityTimer();
      return;
    }

    SoundManager().stopDreamingLoop();
    SoundManager().play(Sound.voiceWakeup);

    print("[Face App] Starting Wake Up Sequence.");
    setState(() => _currentMode = FaceDisplayMode.waking);
    setState(() => _currentFaceState = PodEmotionalState.sleeping);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _currentFaceState = PodEmotionalState.waking);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _currentFaceState = PodEmotionalState.happy);
    print("[Face App] Wake Up Complete. Entering Active Mode.");
    setState(() => _currentMode = FaceDisplayMode.active);
    _startStatusUpdates();
    _resetInactivityTimer();
  }

  Future<void> _startStatusUpdates() async {
    await PodApi().initialize();
    _updateFace();
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 3), (_) => _updateFace());
  }

  Future<void> _updateFace() async {
    if (_isDebugStateForced) return;
    try {
      final status = await PodApi().getStatus();
      final newState = _determineStateFromStatus(status);
      if (mounted) {
        setState(() {
          _currentStatus = status;
          if (newState != _currentFaceState) {
            _currentFaceState = newState;

            switch (newState) {
              case PodEmotionalState.happy:
                SoundManager().play(Sound.voiceGiggle);
                break;
              case PodEmotionalState.thirsty:
                SoundManager().play(Sound.voiceThirsty);
                break;
              case PodEmotionalState.needsNutrients:
                SoundManager().play(Sound.voiceHungry);
                break;
              case PodEmotionalState.hot:
                SoundManager().play(Sound.voiceHot);
                break;
              case PodEmotionalState.thirstySoil:
                SoundManager().play(Sound.voiceRootsDry);
                break;
              case PodEmotionalState.hidingFromLight:
                SoundManager().play(Sound.voiceTooBright);
                break;
              case PodEmotionalState.sunbathing:
                SoundManager().play(Sound.voiceSunshine);
                break;
              case PodEmotionalState.disconnected:
                SoundManager().play(Sound.sfxError);
                break;
              default:
                break;
            }
          }
        });
      }
    } catch (e) {
      _statusUpdateTimer?.cancel();
      if (mounted) {
        SoundManager().play(Sound.sfxError);
        setState(() { _currentFaceState = PodEmotionalState.disconnected; });
      }
    }
  }

  PodEmotionalState _determineStateFromStatus(PodStatus status) {
    if (status.waterLevel == 'LOW') return PodEmotionalState.thirsty;
    if (status.nutrientLevel == 'LOW') return PodEmotionalState.needsNutrients;
    if (status.ledStatus == 'OFF') return PodEmotionalState.sleeping;
    if (status.temperature > 30.0) return PodEmotionalState.hot;
    if (status.moisture > 900) return PodEmotionalState.thirstySoil;
    double avgAngle = (status.coverAngle1 + status.coverAngle2 + status.coverAngle3) / 3.0;
    if (avgAngle < 45) return PodEmotionalState.hidingFromLight;
    if (avgAngle > 75) return PodEmotionalState.sunbathing;
    return PodEmotionalState.happy;
  }

  void _navigateToDataScreen() {
    if (_currentStatus == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return DataOverlayScreen(status: _currentStatus!);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _showDebugMenu() async {
    SoundManager().play(Sound.blip);
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Debug: Force State'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: PodEmotionalState.values.map((state) {
                return ListTile(
                  title: Text(
                    state.toString().split('.').last,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    print("DEBUG: Forcing state to $state");
                    _isDebugStateForced = true;
                    _statusUpdateTimer?.cancel();
                    _inactivityTimer?.cancel();
                    SoundManager().stopDreamingLoop();
                    setState(() {
                      _currentMode = FaceDisplayMode.active;
                      _currentFaceState = state;
                    });
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Resume Live Data'),
              onPressed: () {
                print("DEBUG: Resuming live data feed.");
                _isDebugStateForced = false;
                _startStatusUpdates();
                _resetInactivityTimer();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auraColor = _getAuraColor(_currentFaceState);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          SoundManager().play(Sound.blip);
          if (_currentMode == FaceDisplayMode.attract) {
            _startWakeUpSequence();
          } else if (_currentMode == FaceDisplayMode.active) {
            _resetInactivityTimer();
          }
        },
        onHorizontalDragEnd: (details) {
          if (_currentMode == FaceDisplayMode.active && (details.primaryVelocity ?? 0) < 0) {
            _resetInactivityTimer();
            _navigateToDataScreen();
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_currentMode == FaceDisplayMode.active)
              FadeTransition(
                opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_auraController),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0, top: 0, bottom: 0, width: screenWidth * 0.1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [auraColor, Colors.transparent],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0, top: 0, bottom: 0, width: screenWidth * 0.1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [auraColor, Colors.transparent],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_currentMode == FaceDisplayMode.attract) const DreamingParticles(),

            AnimatedPodFace(state: _currentFaceState),

            // --- REMOVED: The data overlay is no longer part of this screen's stack ---
            /*
            if (_currentMode == FaceDisplayMode.active && _currentStatus != null)
              Positioned(
                left: 20, bottom: 20,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _showOverlay ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: DataOverlay(status: _currentStatus!),
                  ),
                ),
              ),
            */

            Positioned(
              top: 0, left: 0,
              child: GestureDetector(
                onTap: () {
                  SoundManager().play(Sound.blip);
                  _inactivityTimer?.cancel();
                  _statusUpdateTimer?.cancel();
                  Navigator.pushReplacementNamed(context, '/connect');
                },
                child: Container(width: 100, height: 100, color: Colors.transparent),
              ),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: () {
                  SoundManager().play(Sound.blip);
                  _enterAttractMode();
                },
                child: Container(width: 100, height: 100, color: Colors.transparent),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: GestureDetector(
                onLongPress: _showDebugMenu,
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}