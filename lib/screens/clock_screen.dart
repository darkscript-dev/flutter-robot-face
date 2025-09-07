import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// ADDED: Import the pod face screen to navigate back to it.
import 'pod_face_screen.dart';

class ClockScreen extends StatefulWidget {
  const ClockScreen({Key? key}) : super(key: key);

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- NEW NAVIGATION LOGIC ---
  /// Pushes a new PodFaceScreen and removes all previous screens.
  /// This creates a "forward" slide animation, completing the loop.
  void _navigateToPodFaceAndResetStack(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PodFaceScreen(),
        // This transition makes the PodFaceScreen slide in from the right.
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // Start off-screen to the right
          const end = Offset.zero;       // End on-screen
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
      // This predicate is false for every route, so it removes them all.
          (Route<dynamic> route) => false,
    );
  }

  /// Navigates back to the previous screen (DataOverlayScreen).
  void _navigateBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        // Swipe Left: Go forward to the PodFaceScreen
        if ((details.primaryVelocity ?? 0) < -100) {
          _navigateToPodFaceAndResetStack(context); // Use the new method
        }
        // Swipe Right: Go back to the DataOverlayScreen
        else if ((details.primaryVelocity ?? 0) > 100) {
          _navigateBack(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('HH:mm').format(_now),
                style: const TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                DateFormat('EEEE, MMMM d').format(_now),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}