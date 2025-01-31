import 'dart:async';
import 'dart:math' as math;
import 'dart:developer' as developer;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/components.dart';
import 'config.dart';
import 'components/power_up.dart';
import 'components/multi_hit_brick.dart';
import 'components/indestructible_brick.dart';


enum PlayState { welcome, playing, gameOver, won }

class BrickBreaker extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapDetector {
  BrickBreaker()
      : super(
          camera: CameraComponent.withFixedResolution(
            width: gameWidth,
            height: gameHeight,
          ),
        );

  final ValueNotifier<int> score = ValueNotifier(0);
  final rand = math.Random();
  double get width => size.x;
  double get height => size.y;

  late PlayState _playState;
  PlayState get playState => _playState;
  set playState(PlayState playState) {
    _playState = playState;
    
    // Add logging for play state changes
    developer.log('Play state changed', 
      name: 'BrickBreaker', 
      error: 'New state: ${playState.name}'
    );

    switch (playState) {
      case PlayState.welcome:
      case PlayState.gameOver:
      case PlayState.won:
        overlays.add(playState.name);
        break;
      case PlayState.playing:
        overlays.remove(PlayState.welcome.name);
        overlays.remove(PlayState.gameOver.name);
        overlays.remove(PlayState.won.name);
        break;
    }
  }

  // Add a configuration for power-up spawn rates
  final PowerUpSpawnConfig powerUpSpawnConfig = PowerUpSpawnConfig(
    overallSpawnChance: 0.7,  // 10% chance of spawning a power-up when a brick is destroyed
    specificPowerUpChances: {
      PowerUpType.multiBall: 0.20,      // 20% chance for multi-ball
      PowerUpType.fireBall: 0.15,       // 15% chance for fire ball
      PowerUpType.enlargePaddle: 0.15,  // 15% chance for enlarge paddle
      PowerUpType.shrinkPaddle: 0.15,   // 15% chance for shrink paddle
      PowerUpType.speedUp: 0.20,        // 20% chance for speed up
      PowerUpType.slowDown: 0.15,       // 15% chance for slow down
    }
  );

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();

    camera.viewfinder.anchor = Anchor.topLeft;

    world.add(PlayArea());

    playState = PlayState.welcome;
  }

  void startGame() {
    if (playState == PlayState.playing) return;

    developer.log('Starting game', name: 'BrickBreaker');

    world.removeAll(world.children.query<Ball>());
    world.removeAll(world.children.query<Bat>());
    world.removeAll(world.children.query<Brick>());

    playState = PlayState.playing;
    score.value = 0;

    world.add(Ball(
        difficultyModifier: difficultyModifier,
        radius: ballRadius,
        position: size / 2,
        velocity: Vector2((rand.nextDouble() - 0.5) * width, height * 0.2)
            .normalized()
          ..scale(height / 4)));

    world.add(Bat(
        size: Vector2(batWidth, batHeight),
        cornerRadius: const Radius.circular(ballRadius / 2),
        position: Vector2(width / 2, height * 0.95)));

    world.addAll([
      for (var i = 0; i < brickColors.length; i++)
        for (var j = 1; j <= 5; j++)
          // Randomly choose brick type
          (rand.nextDouble() < 0.1) // 10% chance for indestructible brick
              ? IndestructibleBrick(
                  position: Vector2(
                    (i + 0.5) * brickWidth + (i + 1) * brickGutter,
                    (j + 2.0) * brickHeight + j * brickGutter,
                  ),
                )
              : (rand.nextDouble() < 0.2) // 20% chance for multi-hit brick
                  ? MultiHitBrick(
                      position: Vector2(
                        (i + 0.5) * brickWidth + (i + 1) * brickGutter,
                        (j + 2.0) * brickHeight + j * brickGutter,
                      ),
                      hitsRemaining: 3, // Ensure this is set to 3
                    )
                  : Brick(
                      position: Vector2(
                        (i + 0.5) * brickWidth + (i + 1) * brickGutter,
                        (j + 2.0) * brickHeight + j * brickGutter,
                      ),
                      color: brickColors[i],
                    ),
    ]);
  }

  @override
  void onTap() {
    super.onTap();
    
    // Log tap event
    developer.log('Game tapped', name: 'BrickBreaker');
    
    startGame();
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    super.onKeyEvent(event, keysPressed);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        world.children.query<Bat>().first.moveBy(-batStep);
        break;
      case LogicalKeyboardKey.arrowRight:
        world.children.query<Bat>().first.moveBy(batStep);
        break;
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.enter:
        startGame();
        break;
    }
    return KeyEventResult.handled;
  }

  @override
  Color backgroundColor() => const Color(0xfff2e8cf);

 void spawnPowerUp(Vector2 position) {
  if (rand.nextDouble() < powerUpSpawnConfig.overallSpawnChance) {
    double randomValue = rand.nextDouble();
    double cumulativeProbability = 0.0;

    for (var powerUpType in PowerUpType.values) {
      cumulativeProbability += powerUpSpawnConfig.specificPowerUpChances[powerUpType]!;

      if (randomValue <= cumulativeProbability) {
        final powerUp = PowerUp(
          type: powerUpType,
          position: position,
        );

        world.add(powerUp);
        break;
      }
    }
  }
}


  void checkWinCondition() {
    final remainingBreakableBricks = world.children.query<Brick>().where((brick) => brick is! IndestructibleBrick).toList();
    
    developer.log('Remaining breakable bricks: ${remainingBreakableBricks.length}', name: 'BrickBreaker');
    
    if (remainingBreakableBricks.isEmpty) {
        playState = PlayState.won;
        developer.log('All breakable bricks destroyed. You win!', name: 'BrickBreaker');
    }
  }
}

// Add this class to control power-up spawn rates
class PowerUpSpawnConfig {
  final double overallSpawnChance;
  final Map<PowerUpType, double> specificPowerUpChances;

  const PowerUpSpawnConfig({
    required this.overallSpawnChance,
    required this.specificPowerUpChances,
  });
}