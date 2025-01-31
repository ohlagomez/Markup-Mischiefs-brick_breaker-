import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import '../brick_breaker.dart';
import 'bat.dart';
import 'ball.dart';

enum PowerUpType {
  multiBall,     // Spawns additional balls
  fireBall,      // Ball that can break multiple bricks
  enlargePaddle, // Increases paddle size
  shrinkPaddle,  // Decreases paddle size
  speedUp,       // Increases ball speed
  slowDown,      // Decreases ball speed
}

class PowerUp extends RectangleComponent 
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  final PowerUpType type;
  final double fallSpeed;

  PowerUp({
    required this.type,
    required super.position,
    this.fallSpeed = 200,
  }) : super(
          size: Vector2(50, 20),
          paint: _getPaintForType(type),
          children: [RectangleHitbox()],
        );

  static Paint _getPaintForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.multiBall:
        // Bright green for multi-ball (represents multiplication/growth)
        return Paint()..color = Colors.lightGreenAccent;
      
      case PowerUpType.fireBall:
        // Intense red for fire ball (represents destruction/power)
        return Paint()..color = Colors.deepOrange;
      
      case PowerUpType.enlargePaddle:
        // Blue for paddle enlargement (represents expansion)
        return Paint()..color = Colors.blueAccent;
      
      case PowerUpType.shrinkPaddle:
        // Purple for paddle shrinkage (represents reduction)
        return Paint()..color = Colors.purpleAccent;
      
      case PowerUpType.speedUp:
        // Bright orange for speed up (represents acceleration)
        return Paint()..color = Colors.orangeAccent;
      
      case PowerUpType.slowDown:
        // Teal for slow down (represents deceleration)
        return Paint()..color = Colors.tealAccent;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += fallSpeed * dt;

    // Remove power-up if it goes off screen
    if (position.y > game.height) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Bat) {
      _applyPowerUp(other);
      removeFromParent();
    }
  }

  void _applyPowerUp(Bat bat) {
    switch (type) {
      case PowerUpType.multiBall:
        // Creates two additional balls with slightly different trajectories
        _createMultiBall();
        break;
      case PowerUpType.fireBall:
        // TODO: Implement fire ball logic to break multiple bricks
        _createFireBall();
        break;
      case PowerUpType.enlargePaddle:
        // Increases paddle width by 50%
        _enlargePaddle(bat);
        break;
      case PowerUpType.shrinkPaddle:
        // Decreases paddle width by 50%
        _shrinkPaddle(bat);
        break;
      case PowerUpType.speedUp:
        // Increases ball speed by 50%
        _speedUpBall();
        break;
      case PowerUpType.slowDown:
        // Decreases ball speed by 50%
        _slowDownBall();
        break;
    }
  }

  void _createMultiBall() {
    final existingBalls = game.world.children.query<Ball>();
    
    if (existingBalls.isNotEmpty) {
      final originalBall = existingBalls.first;
      
      // Create two additional balls with slightly different angles
      for (int i = 0; i < 2; i++) {
        final newBall = Ball(
          velocity: Vector2(
            originalBall.velocity.x * (i == 0 ? 1.2 : -1.2), 
            originalBall.velocity.y
          ),
          position: originalBall.position.clone(),
          radius: originalBall.width / 2,
          difficultyModifier: originalBall.difficultyModifier,
        );
        
        // Ensure the new balls are added to the game world
        game.world.add(newBall);
      }
    }
  }

  void _createFireBall() {
    final existingBalls = game.world.children.query<Ball>();
    
    if (existingBalls.isNotEmpty) {
      final originalBall = existingBalls.first;
      
      final fireBall = Ball(
        velocity: originalBall.velocity.clone(),
        position: originalBall.position.clone(),
        radius: originalBall.width / 2,
        difficultyModifier: originalBall.difficultyModifier,
        isFireBall: true,  // Set as fire ball
      );
      
      // Explicitly set fire ball color
      fireBall.paint.color = Colors.deepOrange;
      
      game.world.add(fireBall);
    }
  }

  void _enlargePaddle(Bat bat) {
    bat.size.x *= 1.5;
  }

  void _shrinkPaddle(Bat bat) {
    bat.size.x *= 0.5;
  }

  void _speedUpBall() {
    final balls = game.world.children.query<Ball>();
    for (var ball in balls) {
      ball.velocity.scale(1.5);
    }
    
    // Set a timer to revert speed after 10 seconds
    Future.delayed(Duration(seconds: 10), () {
      for (var ball in balls) {
        ball.velocity.scale(1 / 1.5);
      }
    });
  }

  void _slowDownBall() {
    final balls = game.world.children.query<Ball>();
    for (var ball in balls) {
      ball.velocity.scale(0.5);
    }
    
    // Set a timer to revert speed after 10 seconds
    Future.delayed(Duration(seconds: 10), () {
      for (var ball in balls) {
        ball.velocity.scale(2.0); // Revert to original speed
      }
    });
  }
}