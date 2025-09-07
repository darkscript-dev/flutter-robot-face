import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


// Represents a single "firefly" particle
class Particle {
  Offset position;
  Offset velocity;
  double radius;
  double initialOpacity;

  Particle(this.position, this.velocity, this.radius, this.initialOpacity);
}

class DreamingParticles extends StatefulWidget {
  const DreamingParticles({Key? key}) : super(key: key);

  @override
  State<DreamingParticles> createState() => _DreamingParticlesState();
}

class _DreamingParticlesState extends State<DreamingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];
  final random = Random();
  final int numParticles = 30;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // A long duration for a slow animation
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeParticles();
  }

  void _initializeParticles() {
    // Only create particles if the list is empty
    if (particles.isNotEmpty) return;

    final size = MediaQuery.of(context).size;
    for (int i = 0; i < numParticles; i++) {
      particles.add(
          Particle(
            Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
            Offset(
              (random.nextDouble() - 0.5) * 20, // Slow random velocity x
              (random.nextDouble() - 0.5) * 20, // Slow random velocity y
            ),
            random.nextDouble() * 2.5 + 1.0, // Radius between 1.0 and 3.5
            random.nextDouble() * 0.5 + 0.1, // Opacity between 0.1 and 0.6
          )
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(particles, random, _controller.value),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Random random;
  final double animationValue; // Used to update positions

  _ParticlePainter(this.particles, this.random, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.cyan.withOpacity(0.8);

    // Update and draw each particle
    for (var p in particles) {
      // Update position based on velocity
      p.position += p.velocity * (1 / 60); // Assuming 60fps update interval

      // Boundary checks to wrap particles around the screen
      if (p.position.dx < 0) p.position = Offset(size.width, p.position.dy);
      if (p.position.dx > size.width) p.position = Offset(0, p.position.dy);
      if (p.position.dy < 0) p.position = Offset(p.position.dx, size.height);
      if (p.position.dy > size.height) p.position = Offset(p.position.dx, 0);

      paint.color = Colors.cyan.withOpacity(p.initialOpacity * (0.5 + (sin(animationValue * 2 * pi) + 1) / 4));
      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}