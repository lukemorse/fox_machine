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

          // Robot mode indicator
          game.isRobotForm
              ? const Text(
                  'ROBOT MODE',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                    decoration: TextDecoration.none,
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
