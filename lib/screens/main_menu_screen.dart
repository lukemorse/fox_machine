import 'package:flutter/material.dart';
import 'dart:math' as math;

// MainMenuScreen as a Flutter widget
class MainMenuScreen extends StatefulWidget {
  // Callback to navigate to the game
  final VoidCallback onPlayPressed;

  const MainMenuScreen({super.key, required this.onPlayPressed});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Create animation for title pulsing effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E), // Deep blue
              Color(0xFF000000), // Black
            ],
          ),
        ),
        child: Stack(
          children: [
            // Pattern background
            Positioned.fill(
              child: CustomPaint(
                painter: StarPattern(),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated title with quirky font
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      );
                    },
                    child: Transform.rotate(
                      angle: -0.05,
                      child: const Text(
                        'FOX MACHINE',
                        style: TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 90,
                          letterSpacing: 2.0,
                          color: Colors.yellowAccent,
                          shadows: [
                            Shadow(
                              color: Colors.orangeAccent,
                              blurRadius: 15,
                              offset: Offset(5, 5),
                            ),
                            Shadow(
                              color: Colors.redAccent,
                              blurRadius: 10,
                              offset: Offset(-3, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),

                  // Play button with hover effect
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.onPlayPressed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              offset: Offset(5, 5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Text(
                          'START GAME',
                          style: TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 24,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Instructions with comic font
                  Transform.rotate(
                    angle: 0.03,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'PART FOX, PART MACHINE',
                        style: TextStyle(
                          fontFamily: 'ComicNeue',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for star pattern background
class StarPattern extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final math.Random random =
        math.Random(42); // Fixed seed for consistent pattern
    final Paint paint = Paint()
      ..color = Colors.white.withAlpha(77)
      ..style = PaintingStyle.fill;

    // Draw stars
    for (int i = 0; i < 100; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double radius = random.nextDouble() * 2 + 1;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
