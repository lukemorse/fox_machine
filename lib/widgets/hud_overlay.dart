import 'package:flutter/material.dart';
import '../game/fox_machine_game.dart';
import '../constants/game_constants.dart';

/// Displays the heads-up display during gameplay
class HUDOverlay extends StatelessWidget {
  final FoxMachineGame game;

  const HUDOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Top row with score and pause button
          Row(
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

              // Right side with energy meter and pause button
              Row(
                children: [
                  // Energy meter - smaller and closer to pause button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Energy percentage
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt,
                            color: Colors.yellow,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${(game.energy / GameConstants.maxEnergy * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Even smaller energy bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                          width: 80, // Smaller width
                          height: 6, // Smaller height
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: game.energy / GameConstants.maxEnergy,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getEnergyColor(game.energy /
                                            GameConstants.maxEnergy)
                                        .withOpacity(0.7),
                                    _getEnergyColor(
                                        game.energy / GameConstants.maxEnergy),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      width: 8), // Small space between energy and pause button

                  // Pause button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(), // Remove default padding/constraints
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
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to get color based on energy level
  Color _getEnergyColor(double percentage) {
    if (percentage > 0.7) {
      return Colors.green;
    } else if (percentage > 0.4) {
      return Colors.orange;
    } else if (percentage > 0.2) {
      return Colors.orangeAccent;
    } else {
      return Colors.red;
    }
  }
}
