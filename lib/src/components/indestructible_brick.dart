import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'brick.dart';
import 'ball.dart';

class IndestructibleBrick extends Brick {
  IndestructibleBrick({
    required Vector2 position,
  }) : super(position: position, color: Colors.black);

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    // Indestructible bricks do not get removed on collision
    if (other is Ball) {
      // Log collision with indestructible brick
      log('Hit indestructible brick', name: 'Brick');
    }
  }
} 