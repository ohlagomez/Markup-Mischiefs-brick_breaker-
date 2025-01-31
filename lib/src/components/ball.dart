import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import '../brick_breaker.dart';
import 'bat.dart';
import 'brick.dart';
import 'play_area.dart';
import 'multi_hit_brick.dart';
import 'indestructible_brick.dart';


class Ball extends CircleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  Ball({
    required this.velocity,
    required super.position,
    required double radius,
    required this.difficultyModifier,
    this.isFireBall = false,
  }) : _originalColor = const Color(0xff1e6091),
       super(
            radius: radius,
            anchor: Anchor.center,
            paint: Paint()
              ..color = isFireBall 
                  ? Colors.deepOrange 
                  : const Color(0xff1e6091),
            children: [CircleHitbox()]);

  final Vector2 velocity;
  final double difficultyModifier;
  bool isFireBall;
  final Color _originalColor;

  void resetToOriginalColor() {
    paint.color = _originalColor;
    isFireBall = false;
  }

  void updateVelocity(Vector2 newVelocity) {
    velocity.setFrom(newVelocity);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    // Check for boundary collisions
    if (position.x < 0) {
        position.x = 0; // Adjust position to stay within bounds
        velocity.x = -velocity.x; // Reverse direction on x-axis
    } else if (position.x + width > game.width) {
        position.x = game.width - width; // Adjust position to stay within bounds
        velocity.x = -velocity.x; // Reverse direction on x-axis
    }

    if (position.y < 0) {
        position.y = 0; // Adjust position to stay within bounds
        velocity.y = -velocity.y; // Reverse direction on y-axis
    } else if (position.y + height > game.height) {
        developer.log('Ball out of bounds', 
            name: 'Ball',
            error: 'Checking game over state'
        );
        _checkGameOver();
    }
  }

  void _checkGameOver() {
    removeFromParent();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        final remainingBalls = game.world.children.query<Ball>();
        
        developer.log('Game Over Check', 
          name: 'Ball',
          error: 'Remaining balls: ${remainingBalls.length}'
        );
        
        if (remainingBalls.isEmpty) {
          developer.log('Triggering Game Over', 
            name: 'Ball', 
            error: 'No balls remaining'
          );
          game.playState = PlayState.gameOver;
        }
      } catch (e) {
        developer.log('Error checking game over', 
          name: 'Ball', 
          error: e.toString()
        );
      }
    });
  }

 @override
void onCollisionStart(
    Set<Vector2> intersectionPoints, PositionComponent other) {
  super.onCollisionStart(intersectionPoints, other);
  
  if (other is PlayArea) {
    if (intersectionPoints.first.y <= 0) {
      velocity.y = -velocity.y;
    } else if (intersectionPoints.first.x <= 0) {
      velocity.x = -velocity.x;
    } else if (intersectionPoints.first.x >= game.width) {
      velocity.x = -velocity.x;
    } else if (intersectionPoints.first.y >= game.height) {
      developer.log('Ball out of bounds', 
        name: 'Ball',
        error: 'Checking game over state'
      );
      _checkGameOver();
    }
  } else if (other is Bat) {
    if (intersectionPoints.isNotEmpty) {
      position.y = other.position.y - other.size.y / 2 - height / 2;
    }
    
    if (isFireBall) {
      resetToOriginalColor();
    }
    
    velocity.y = -velocity.y;
    velocity.x = velocity.x +
        (position.x - other.position.x) / other.size.x * game.width * 0.3;
  } else if (other is Brick) {
    if (isFireBall) {
      _breakMultipleBricks(other);
    } else {
      if (position.y < other.position.y - other.size.y / 2) {
        velocity.y = -velocity.y;
      } else if (position.y > other.position.y + other.size.y / 2) {
        velocity.y = -velocity.y;
      } else if (position.x < other.position.x) {
        velocity.x = -velocity.x;
      } else if (position.x > other.position.x) {
        velocity.x = -velocity.x;
      }
      velocity.setFrom(velocity * difficultyModifier);
    }
  }
}

  void _breakMultipleBricks(Brick initialBrick) {
    // Remove the initial brick if it's not indestructible
    if (initialBrick is! IndestructibleBrick) {
        initialBrick.removeFromParent();
        game.score.value++;
        _createBreakEffect(initialBrick.position); // Create effect for the initial brick
    }

    // Find nearby bricks to remove
    final nearbyBricks = game.world.children.query<Brick>();
    final bricksToRemove = nearbyBricks.where((brick) {
        final distance = (brick.position - position).length;
        // Only consider bricks that are not indestructible
        return distance < 100 && brick is! IndestructibleBrick;
    }).toList();

    for (var brick in bricksToRemove) {
        brick.removeFromParent();
        game.score.value++;
        _createBreakEffect(brick.position); // Create effect for each broken brick
    }

    velocity.y = -velocity.y; // Reverse the ball's direction after breaking bricks
  }

  void _createBreakEffect(Vector2 position) {
    // Create a visual effect for breaking bricks
    final breakEffect = CircleComponent(
        radius: 30, // Adjust size as needed
        position: position,
        paint: Paint()..color = Colors.red.withOpacity(0.5), // Semi-transparent red for break effect
    );

    game.world.add(breakEffect);

    // Optionally, remove the effect after a short duration
    Future.delayed(Duration(seconds: 1), () {
        breakEffect.removeFromParent();
    });
  }
}