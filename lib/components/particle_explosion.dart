import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../game/fox_machine_game.dart';

/// A component that creates explosion particle effects
class ParticleExplosion extends Component
    with HasGameReference<FoxMachineGame> {
  final Vector2 position;
  final Color color;
  final double size;
  final int particleCount;
  final double duration;

  ParticleExplosion({
    required this.position,
    this.color = Colors.orange,
    this.size = 20.0,
    this.particleCount = 20,
    this.duration = 1.0,
  });

  // Factory method to create a more dramatic explosion with multiple bursts
  static void createBigExplosion({
    required Vector2 position,
    required Component world,
    Color baseColor = Colors.orange,
    double size = 25.0,
    bool isGameOver =
        false, // Flag to indicate if this is a game over explosion
  }) {
    final random = Random();

    // For game over, enhance the explosions
    if (isGameOver) {
      // Bigger, more orange explosion for game over
      baseColor = Color.lerp(baseColor, Colors.orange, 0.7)!;
      size *= 1.5; // Bigger explosion
    }

    // Create initial burst
    final mainExplosion = ParticleExplosion(
      position: position,
      color: baseColor,
      size: size,
      particleCount: isGameOver ? 80 : 50, // More particles for game over
      duration: isGameOver ? 2.0 : 1.5, // Longer duration for game over
    );
    world.add(mainExplosion);

    // Create delayed secondary bursts around the main position
    final burstCount =
        isGameOver ? 5 : 3; // More secondary bursts for game over
    for (int i = 0; i < burstCount; i++) {
      Future.delayed(Duration(milliseconds: 100 + i * 80), () {
        // Create offset for secondary bursts
        final offset = Vector2(
          (random.nextDouble() * 2 - 1) * size * (isGameOver ? 1.3 : 1.0),
          (random.nextDouble() * 2 - 1) * size * (isGameOver ? 1.3 : 1.0),
        );

        // Create secondary explosion at offset position
        final secondaryColor = HSLColor.fromColor(baseColor)
            .withLightness(
                (HSLColor.fromColor(baseColor).lightness + 0.2).clamp(0.0, 1.0))
            .withSaturation(isGameOver
                ? 1.0
                : (HSLColor.fromColor(baseColor).saturation + 0.1)
                    .clamp(0.0, 1.0))
            .toColor();

        final secondaryExplosion = ParticleExplosion(
          position: position.clone() + offset,
          color: secondaryColor,
          size: size * (isGameOver ? 0.8 : 0.7),
          particleCount: isGameOver ? 40 : 30,
          duration: isGameOver ? 1.5 : 1.0,
        );

        if (world is World) {
          world.add(secondaryExplosion);
        }
      });
    }

    // Create a spreading smoke/dust effect
    final dustCount = isGameOver ? 25 : 15;
    final dustParticles = ParticleSystemComponent(
      particle: Particle.generate(
        count: dustCount,
        lifespan: isGameOver ? 3.0 : 2.0, // Longer smoke trail for game over
        generator: (i) {
          final angle = random.nextDouble() * 2 * pi;
          final speed = random.nextDouble() * 50 + (isGameOver ? 40 : 20);
          final offset = Vector2(cos(angle), sin(angle)) * speed;

          return AcceleratedParticle(
            acceleration: Vector2(
                0, isGameOver ? -40 : -20), // More upward drift for game over
            speed: offset,
            position: Vector2.zero(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = 0.7 - (particle.progress * 0.6); // Fade out

                // For game over, add more orange tint to smoke
                final smokeColor = isGameOver
                    ? Color.lerp(
                        Colors.grey.withAlpha((opacity * 255).toInt()),
                        Colors.orange.withAlpha((opacity * 0.6 * 255).toInt()),
                        0.5,
                      )!
                    : Color.lerp(
                        Colors.grey.withAlpha((opacity * 255).toInt()),
                        baseColor.withAlpha((opacity * 0.3 * 255).toInt()),
                        0.3,
                      )!;

                final sizeFactor = particle.progress < 0.3
                    ? particle.progress / 0.3 // Grow for first 30%
                    : 1.0; // Then maintain size

                final currentSize =
                    size * (isGameOver ? 1.2 : 0.8) * sizeFactor;

                final paint = Paint()
                  ..color = smokeColor
                  ..style = PaintingStyle.fill;

                canvas.drawCircle(
                  Offset.zero,
                  currentSize,
                  paint,
                );
              },
            ),
          );
        },
      ),
    );

    dustParticles.position = position.clone();
    world.add(dustParticles);

    // For game over explosions, add additional fiery particles
    if (isGameOver) {
      final fireParticles = ParticleSystemComponent(
        particle: Particle.generate(
          count: 35,
          lifespan: 1.2,
          generator: (i) {
            final angle = random.nextDouble() * 2 * pi;
            final speed = random.nextDouble() * 200 + 100;
            final offset = Vector2(cos(angle), sin(angle)) * speed;

            // Create fiery colors - from yellow to orange to red
            final colorIndex = random.nextDouble();
            final fireColor = colorIndex < 0.3
                ? Colors.yellow
                : (colorIndex < 0.7 ? Colors.orange : Colors.red);

            return AcceleratedParticle(
              acceleration: Vector2(0, 300),
              speed: offset,
              position: Vector2.zero(),
              child: ComputedParticle(
                renderer: (canvas, particle) {
                  final opacity = (1 - particle.progress) * 0.9;
                  final fireSize = size * 0.6 * (1 - particle.progress * 0.7);

                  final paint = Paint()
                    ..color = fireColor.withAlpha((opacity * 255).toInt())
                    ..style = PaintingStyle.fill;

                  // Draw flame-like shape
                  canvas.drawCircle(
                    Offset.zero,
                    fireSize,
                    paint,
                  );

                  // Add glow
                  final glowPaint = Paint()
                    ..color =
                        Colors.white.withAlpha((opacity * 0.4 * 255).toInt())
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 2.0;

                  canvas.drawCircle(
                    Offset.zero,
                    fireSize * 1.3,
                    glowPaint,
                  );
                },
              ),
            );
          },
        ),
      );

      fireParticles.position = position.clone();
      world.add(fireParticles);
    }
  }

  @override
  Future<void> onLoad() async {
    final random = Random();

    // Create direct particle system component (like in collectible)
    final particleSystem = ParticleSystemComponent(
      particle: Particle.generate(
        count: particleCount,
        lifespan: duration,
        generator: (i) {
          // Create random angle and speed for each particle
          final speed = random.nextDouble() * 300 + 100;
          final angle = random.nextDouble() * 2 * pi;
          final offset = Vector2(cos(angle), sin(angle)) * speed;

          // Random size for variety
          final particleSize = size * (0.3 + random.nextDouble() * 0.7);

          // Color variation - add some randomness
          final particleColor = HSLColor.fromColor(color)
              .withLightness((HSLColor.fromColor(color).lightness +
                      random.nextDouble() * 0.3)
                  .clamp(0.0, 1.0))
              .withSaturation((HSLColor.fromColor(color).saturation +
                      random.nextDouble() * 0.2)
                  .clamp(0.0, 1.0))
              .toColor();

          return AcceleratedParticle(
            acceleration: Vector2(0, 400), // Add gravity
            speed: offset,
            position: Vector2.zero(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                // Fade out based on progress
                final opacity = (1 - particle.progress) * 0.9;

                // Size decreases as particle ages
                final currentSize =
                    particleSize * (1 - particle.progress * 0.5);

                // Main particle (filled circle)
                final paint = Paint()
                  ..color = particleColor.withAlpha((opacity * 255).toInt())
                  ..style = PaintingStyle.fill;

                canvas.drawCircle(
                  Offset.zero,
                  currentSize,
                  paint,
                );

                // Glow effect (outer stroke)
                final glowPaint = Paint()
                  ..color =
                      particleColor.withAlpha((opacity * 0.5 * 255).toInt())
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2.0;

                canvas.drawCircle(
                  Offset.zero,
                  currentSize * 1.3,
                  glowPaint,
                );
              },
            ),
          );
        },
      ),
    );

    // Add the flash effect separately
    final flashSystem = ParticleSystemComponent(
      particle: Particle.generate(
        count: 1,
        lifespan: 0.2,
        generator: (i) => ComputedParticle(
          renderer: (canvas, particle) {
            final opacity = (1 - particle.progress) * 0.8;
            final flashPaint = Paint()
              ..color = Colors.white.withAlpha((opacity * 255).toInt())
              ..style = PaintingStyle.fill;

            canvas.drawCircle(
              Offset.zero,
              size * 4 * (1 - particle.progress * 0.5),
              flashPaint,
            );
          },
        ),
      ),
    );

    // Position both components at explosion position
    particleSystem.position = position.clone();
    flashSystem.position = position.clone();

    // Add directly to game world (like in collectible)
    game.gameWorld.add(particleSystem);
    game.gameWorld.add(flashSystem);

    // Remove this component since we don't need it anymore
    // (particles are now directly in the game world)
    removeFromParent();
  }
}
