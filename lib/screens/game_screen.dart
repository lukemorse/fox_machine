import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/fox_machine_game.dart';
import '../models/game_state.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late FoxMachineGame _game;

  @override
  void initState() {
    super.initState();
    _game = FoxMachineGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'menu': (context, game) =>
              _buildMenuOverlay(context, game as FoxMachineGame),
          'hud': (context, game) =>
              _buildHudOverlay(context, game as FoxMachineGame),
          'pause': (context, game) =>
              _buildPauseOverlay(context, game as FoxMachineGame),
          'gameOver': (context, game) =>
              _buildGameOverOverlay(context, game as FoxMachineGame),
        },
        initialActiveOverlays: const ['menu'],
      ),
    );
  }

  Widget _buildMenuOverlay(BuildContext context, FoxMachineGame game) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Fox Machine',
            style: TextStyle(
              fontSize: 50,
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            ),
            onPressed: () {
              game.gameState = GameState.playing;
              game.overlays.remove('menu');
              game.overlays.add('hud');
            },
            child: const Text(
              'Play',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudOverlay(BuildContext context, FoxMachineGame game) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<double>(
                stream: Stream.periodic(
                    const Duration(milliseconds: 100), (_) => game.score),
                builder: (context, snapshot) {
                  return Text(
                    'Score: ${(snapshot.data ?? 0).toInt()}',
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
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.pause, color: Colors.white, size: 30),
                onPressed: () {
                  game.pause();
                  game.overlays.remove('hud');
                  game.overlays.add('pause');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPauseOverlay(BuildContext context, FoxMachineGame game) {
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
                    game.gameState = GameState.menu;
                    game.overlays.remove('pause');
                    game.overlays.add('menu');
                  },
                  child: const Text('Quit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context, FoxMachineGame game) {
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
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Score: ${game.score.toInt()}',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
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
                    game.reset();
                    game.overlays.remove('gameOver');
                    game.overlays.add('hud');
                  },
                  child: const Text('Play Again'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    game.reset();
                    game.gameState = GameState.menu;
                    game.overlays.remove('gameOver');
                    game.overlays.add('menu');
                  },
                  child: const Text('Main Menu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
