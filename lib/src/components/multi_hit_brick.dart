// lib/src/components/multi_hit_brick.dart
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

import '../brick_breaker.dart';
import 'brick.dart';
import 'ball.dart';

class MultiHitBrick extends Brick {
  int hitsRemaining;

  MultiHitBrick({
    required Vector2 position,
    this.hitsRemaining = 3,
  }) : super(position: position, color: Colors.grey) {
    log('MultiHitBrick initialized with hitsRemaining: $hitsRemaining', name: 'Brick');
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Add a hitbox to the brick
    add(RectangleHitbox()..size = size); // Set the hitbox size to match the brick size
  }

  void _playBreakingEffect() {
    // Example: Change color briefly
    log('Breaking effect played for MultiHitBrick', name: 'Brick');
    paint.color = Colors.red;
    Future.delayed(Duration(milliseconds: 100), () {
      paint.color = Colors.grey.withOpacity(hitsRemaining / 3);
    });
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Ball) {
      log('Collision detected with MultiHitBrick', name: 'Brick');

      hitsRemaining--;
      log('Multi-hit brick hit, remaining hits: $hitsRemaining', name: 'Brick');

      Vector2 ballVelocity = other.velocity.clone(); // Clone velocity before modifying

      if (intersectionPoints.isNotEmpty) {
        Vector2 collisionPoint = intersectionPoints.first;

        double ballCenterX = other.position.x + (other.width / 2);
        double ballCenterY = other.position.y + (other.height / 2);

        double brickLeft = position.x;
        double brickRight = position.x + width;
        double brickTop = position.y;
        double brickBottom = position.y + height;

        bool hitFromTop = ballCenterY < brickTop && ballVelocity.y > 0;
        bool hitFromBottom = ballCenterY > brickBottom && ballVelocity.y < 0;
        bool hitFromLeft = ballCenterX < brickLeft && ballVelocity.x > 0;
        bool hitFromRight = ballCenterX > brickRight && ballVelocity.x < 0;

        if (hitFromTop) {
          ballVelocity.y = -ballVelocity.y; // Reverse vertical velocity
          other.position.y = brickTop - other.height - 1; // Prevent sticking
        } else if (hitFromBottom) {
          ballVelocity.y = -ballVelocity.y;
          other.position.y = brickBottom + 1;
        } else if (hitFromLeft) {
          ballVelocity.x = -ballVelocity.x; // Reverse horizontal velocity
          other.position.x = brickLeft - other.width - 1;
        } else if (hitFromRight) {
          ballVelocity.x = -ballVelocity.x;
          other.position.x = brickRight + 1;
        }
      }

      other.updateVelocity(ballVelocity); // Apply the corrected velocity

      _playBreakingEffect(); // Trigger effect

      if (hitsRemaining <= 0) {
        log('Multi-hit brick removed', name: 'Brick');
        removeFromParent(); // Destroy brick when hits run out
        game.score.value++;
        game.checkWinCondition();
      } else {
        // Change color based on remaining hits
        double opacity = hitsRemaining / 3;
        paint.color = Colors.grey.withOpacity(opacity);
        log('Multi-hit brick color changed to opacity: $opacity', name: 'Brick');
      }
    }
  }
}
