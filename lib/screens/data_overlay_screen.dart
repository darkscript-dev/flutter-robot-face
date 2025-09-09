import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/pod_status.dart';
import 'clock_screen.dart';

class DataOverlayScreen extends StatelessWidget {
  final PodStatus status;

  const DataOverlayScreen({
    Key? key,
    required this.status,
  }) : super(key: key);

  void _navigateToClockScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const ClockScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  // --- Helper functions to normalize data for progress bars ---

  // Normalizes moisture (e.g., 300 is wet, 1000 is dry)
  double _getMoistureProgress() {
    // Invert the value so that higher moisture means a fuller bar.
    // Clamping ensures the value stays between 0.0 and 1.0.
    return (1.0 - ((status.moisture - 300) / (1000 - 300))).clamp(0.0, 1.0);
  }

  // Normalizes temperature (e.g., 15-35°C is the "normal" range)
  double _getTemperatureProgress() {
    return ((status.temperature - 15) / (35 - 15)).clamp(0.0, 1.0);
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 100) Navigator.of(context).pop();
        if ((details.primaryVelocity ?? 0) < -100) _navigateToClockScreen(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(44.10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                const Text(
                  'System Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Real-time sensor data from the pod',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),

                // --- DATA ROWS ---
                Row(
                  children: [
                    Expanded(
                      child: _StatusCard(
                        icon: CupertinoIcons.thermometer,
                        title: 'Temperature',
                        value: status.temperature.toStringAsFixed(1),
                        unit: '°C',
                        progress: _getTemperatureProgress(),
                        progressColor: Colors.deepOrangeAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatusCard(
                        icon: CupertinoIcons.drop,
                        title: 'Soil Moisture',
                        value: status.moisture.toInt().toString(),
                        unit: '',
                        progress: _getMoistureProgress(),
                        progressColor: Colors.lightBlueAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatusCard(
                        icon: CupertinoIcons.chart_pie,
                        title: 'Water Tank',
                        value: status.waterLevel,
                        unit: '',
                        progress: status.waterLevel == 'OK' ? 1.0 : 0.1,
                        progressColor: status.waterLevel == 'OK'
                            ? Colors.greenAccent
                            : Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatusCard(
                        icon: CupertinoIcons.leaf_arrow_circlepath,
                        title: 'Nutrients',
                        value: status.nutrientLevel,
                        unit: '',
                        progress: status.nutrientLevel == 'OK' ? 1.0 : 0.1,
                        progressColor: status.nutrientLevel == 'OK'
                            ? Colors.greenAccent
                            : Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Row(
                //   children: [
                //     Expanded(
                //       child: _StatusCard(
                //         icon: status.ledStatus == 'ON'
                //             ? CupertinoIcons.sun_max_fill
                //             : CupertinoIcons.moon_stars_fill,
                //         title: 'Grow Light',
                //         value: status.ledStatus,
                //         unit: '',
                //         progress: status.ledStatus == 'ON' ? 1.0 : 0.0,
                //         progressColor: Colors.yellow,
                //       ),
                //     ),
                //     const SizedBox(width: 16),
                //     // This empty container ensures the 'Grow Light' card
                //     // maintains the same width as the cards above it.
                //     Expanded(child: Container()),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A reusable UI component for displaying a single piece of status data.
class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final double progress;
  final Color progressColor;

  const _StatusCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.progress,
    required this.progressColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Title
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Value and Unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}