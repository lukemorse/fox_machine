import 'package:flutter/material.dart';
import '../game/fox_machine_game.dart';

/// Displays the heads-up display during gameplay
class HUDOverlay extends StatelessWidget {
  final FoxMachineGame game;

  const HUDOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score display
          Text(
            'Score: ${game.score.toInt()}',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 2.0,
                  color: Colors.black,
                  offset: Offset(1.0, 1.0),
                ),
              ],
              decoration: TextDecoration.none,
            ),
          ),

          // Pause button
          IconButton(
            icon: const Icon(
              Icons.pause,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              // This will trigger the pause overlay through the game's pause method
              game.pause();
            },
          ),
        ],
      ),
    );
  }
}
