import 'package:flutter/material.dart';
import '../game/fox_machine_game.dart';
import 'dart:math' as math;

/// Displays the pause menu overlay
class PauseOverlay extends StatefulWidget {
  final FoxMachineGame game;

  const PauseOverlay({super.key, required this.game});

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: -0.03,
      end: 0.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: const Color(0xFF2A4494).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.4),
                spreadRadius: 5,
                blurRadius: 15,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: Colors.lightBlueAccent,
              width: 3,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAUSED',
                style: TextStyle(
                  fontSize: 38,
                  fontFamily: 'Bangers', // Quirky font
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      blurRadius: 8.0,
                      color: Colors.cyan,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Take a breather!',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'ComicNeue', // Quirky font
                  color: Colors.yellow,
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PauseButton(
                    text: 'Resume',
                    icon: Icons.play_arrow,
                    color: Colors.green,
                    onPressed: () {
                      widget.game.resume();
                    },
                  ),
                  const SizedBox(width: 20),
                  _PauseButton(
                    text: 'Restart',
                    icon: Icons.refresh,
                    color: Colors.redAccent,
                    onPressed: () {
                      widget.game.reset();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _PauseButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_PauseButton> createState() => _PauseButtonState();
}

class _PauseButtonState extends State<_PauseButton> {
  bool _isHovering = false;

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
                fontFamily: 'ComicNeue', // Quirky font
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
