import 'package:flutter/material.dart';

/// Displays the game over screen when the player dies
class GameOverOverlay extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Game Over',
              style: TextStyle(
                fontSize: 30,
                color: Colors.red,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Score: $score',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () => onRestartPressed(),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () => onMainMenuPressed(),
                  child: const Text(
                    'Main Menu',
                    style: TextStyle(
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
