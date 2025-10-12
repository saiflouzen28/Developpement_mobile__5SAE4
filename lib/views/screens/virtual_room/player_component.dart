// lib/views/screens/virtual_room/player_component.dart

import 'package:flame/components.dart';
// 'package:flame/input.dart' is no longer needed here.
import 'package:flutter/material.dart';
// 'virtual_event_game.dart' is no longer needed here as this component is self-contained.

// Represents a single character in the room.
// FIX: The 'with Tappable' mixin is removed as it's deprecated and not needed.
class PlayerComponent extends PositionComponent {
  final String id;
  final bool isCurrentUser;
  final Paint _paint;

  static final Vector2 initialSize = Vector2.all(50.0);
  final double _speed = 200.0; // Speed in pixels per second
  Vector2? _targetPosition; // The destination where the player is moving

  PlayerComponent({
    required this.id,
    this.isCurrentUser = false,
  })  : _paint = Paint()..color = isCurrentUser ? Colors.blue.shade700 : Colors.red.shade700,
        super(size: initialSize, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Add a visual representation (a circle for now)
    add(CircleComponent(radius: size.x / 2, paint: _paint));

    // Add a text label to identify the player
    add(
      TextComponent(
        text: isCurrentUser ? 'You' : 'User-$id',
        anchor: Anchor.bottomCenter,
        position: Vector2(0, -size.y / 2 - 5), // Position text above the circle
        textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    // If a target position is set, move the player towards it.
    if (_targetPosition != null) {
      final difference = _targetPosition! - position;

      // If we are close enough to the target, stop.
      if (difference.length < 2.0) {
        _targetPosition = null;
        return;
      }

      // Move towards the target.
      final direction = difference.normalized();
      position += direction * _speed * dt;
    }
  }

  // This is called by the game to move this player
  void moveTo(Vector2 newPosition) {
    _targetPosition = newPosition;
  }
}
