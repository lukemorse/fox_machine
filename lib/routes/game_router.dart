import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'dart:developer' as developer;

import '../screens/main_menu_screen.dart';
import '../game/fox_machine_game.dart';
import '../constants/game_constants.dart';

// A simpler navigation manager using Flutter's navigation
class GameNavigator extends StatefulWidget {
  const GameNavigator({Key? key}) : super(key: key);

  @override
  State<GameNavigator> createState() => _GameNavigatorState();
}

class _GameNavigatorState extends State<GameNavigator> {
  // Track if we're showing the game or menu
  bool _showingGame = false;

  // Game instance
  late FoxMachineGame _game;

  @override
  void initState() {
    super.initState();

    // Log for debugging
    developer.log('Initializing GameNavigator');

    // Create the game
    _game = FoxMachineGame(
      onMainMenuPressed: _goToMainMenu,
    );
  }

  void _goToGame() {
    developer.log('Going to game');

    // Reset the game if needed
    try {
      // Reset the game's state which should trigger a full reinitialize
      _game.reset();

      // Explicitly request camera positioning fix
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          _game.fixCameraPosition();
          developer.log('Applied camera position fix');
        } catch (e) {
          developer.log('Error fixing camera position: $e');
        }
      });

      developer.log('Game reset complete');
    } catch (e) {
      developer.log('Error resetting game: $e');
    }

    setState(() {
      _showingGame = true;
    });
  }

  void _goToMainMenu() {
    developer.log('Going to main menu');
    setState(() {
      _showingGame = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Building GameNavigator, showing game: $_showingGame');

    if (_showingGame) {
      // Create GameWidget with proper overlay setup and debugging information
      return Stack(
        children: [
          GameWidget<FoxMachineGame>(
            game: _game,
            overlayBuilderMap: _game.overlayBuilders,
            initialActiveOverlays: const ['hud'],
            // Add loading and error builders for debugging
            loadingBuilder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorBuilder: (context, error) {
              developer.log('Error in GameWidget: $error');
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Game Error: $error',
                      style: const TextStyle(color: Colors.white),
                    ),
                    ElevatedButton(
                      onPressed: _goToMainMenu,
                      child: const Text('Back to Menu'),
                    ),
                  ],
                ),
              );
            },
          ),
          // Debug overlay in top-left corner when debug mode is enabled
          if (GameConstants.debug)
            Positioned(
              top: 40,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black.withOpacity(0.5),
                child: const Text(
                  'DEBUG MODE',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      return MainMenuScreen(onPlayPressed: _goToGame);
    }
  }
}
