import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import '../brick_breaker.dart';
import '../config.dart';
import 'ball.dart';
import 'multi_hit_brick.dart';

class Brick extends RectangleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  Brick({required super.position, required Color color})
      : super(
          size: Vector2(brickWidth, brickHeight),
          anchor: Anchor.center,
          paint: Paint()
            ..color = color
            ..style = PaintingStyle.fill,
          children: [RectangleHitbox()],
        );

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is Ball) {
      // 30% chance to spawn a power-up when a brick is hit
      if (game.rand.nextDouble() < 0.3) {
        game.spawnPowerUp(position);
      }

      // Check if the current brick is a MultiHitBrick
      if (this is MultiHitBrick) {
        developer.log('Collided with MultiHitBrick', name: 'Ball');
        // No need to call a separate hit method; logic is handled in MultiHitBrick
      } else {
        removeFromParent(); // Remove the brick if it's not a MultiHitBrick
      }
      
      // Increment score when a brick is destroyed
      game.score.value++;
      
      // Check if all breakable bricks are destroyed
      game.checkWinCondition();
    }
  }
}