import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../screens/main_menu_screen.dart';
import '../game/fox_machine_game.dart';

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

    // Create the game
    _game = FoxMachineGame(
      onMainMenuPressed: _goToMainMenu,
    );
  }

  void _goToGame() {
    setState(() {
      // Don't call reset here - the game will reset itself properly in onLoad
      // This prevents the double initialization problem
      _showingGame = true;
    });
  }

  void _goToMainMenu() {
    setState(() {
      _showingGame = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showingGame) {
      // Create GameWidget with proper overlay setup
      return GameWidget<FoxMachineGame>(
        game: _game,
        overlayBuilderMap: _game.overlayBuilders,
        initialActiveOverlays: const ['hud'],
      );
    } else {
      return MainMenuScreen(onPlayPressed: _goToGame);
    }
  }
}
