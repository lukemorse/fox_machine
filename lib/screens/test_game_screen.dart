import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'dart:developer' as developer;

import '../game/fox_machine_game.dart';

class TestGameScreen extends StatelessWidget {
  final Function() onBackToMenu;

  const TestGameScreen({
    Key? key,
    required this.onBackToMenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    developer.log('Building TestGameScreen');

    // Create a minimal game instance with callback to return to menu
    final game = FoxMachineGame(
      onMainMenuPressed: onBackToMenu,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GameWidget(
          game: game,
          // Use a simple loading screen
          loadingBuilder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
          // Use a simple error screen
          errorBuilder: (context, error) {
            developer.log('Error in GameWidget: $error');
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'An error occurred: $error',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onBackToMenu,
                    child: const Text('Back to Menu'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
