import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Displays the game over screen when the player dies
class GameOverOverlay extends StatefulWidget {
  final Function onMainMenuPressed;
  final Function onRestartPressed;
  final int score;

  const GameOverOverlay({
    super.key,
    required this.onMainMenuPressed,
    required this.onRestartPressed,
    required this.score,
  });

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF421C52).withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.orangeAccent,
            width: 4,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME OVER!',
              style: TextStyle(
                fontSize: 42,
                fontFamily: 'Bangers', // Quirky font
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.yellow,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Transform.rotate(
              angle: -0.05, // Slight tilt
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 5,
                      offset: Offset(3, 3),
                    ),
                  ],
                ),
                child: Text(
                  'Score: ${widget.score}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontFamily: 'PressStart2P', // Pixel font
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QuirkyButton(
                  text: 'Play Again!',
                  icon: Icons.replay,
                  color: Colors.greenAccent,
                  onPressed: () => widget.onRestartPressed(),
                ),
                const SizedBox(width: 20),
                _QuirkyButton(
                  text: 'Main Menu',
                  icon: Icons.home,
                  color: Colors.lightBlueAccent,
                  onPressed: () => widget.onMainMenuPressed(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuirkyButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _QuirkyButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_QuirkyButton> createState() => _QuirkyButtonState();
}

class _QuirkyButtonState extends State<_QuirkyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => _isHovering = true),
      onTapUp: (_) => setState(() => _isHovering = false),
      onTapCancel: () => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform:
            _isHovering ? (Matrix4.identity()..scale(1.1)) : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: _isHovering ? 2 : 0,
              blurRadius: _isHovering ? 8 : 3,
              offset: _isHovering ? const Offset(0, 2) : const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.8),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              widget.text,
              style: const TextStyle(
                fontSize: 18,
                fontFamily:
                    'ComicNeue', // Quirky font (needs to be added to pubspec)
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
