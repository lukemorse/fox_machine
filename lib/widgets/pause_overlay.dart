import 'package:flutter/material.dart';
import '../game/fox_machine_game.dart';

/// Displays the pause menu overlay
class PauseOverlay extends StatelessWidget {
  final FoxMachineGame game;

  const PauseOverlay({super.key, required this.game});

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
              'Game Paused',
              style: TextStyle(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
                  onPressed: () {
                    game.resume();
                    game.overlays.remove('pause');
                    game.overlays.add('hud');
                  },
                  child: const Text('Resume'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () {
                    game.reset();
                    game.overlays.remove('pause');
                    game.overlays.add('hud');
                  },
                  child: const Text('Restart'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
