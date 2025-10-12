// lib/views/screens/virtual_room/virtual_event_game.dart

import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart'; // Correct import for event handlers
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'player_component.dart';

// This is the core of the Flame game. It manages the game world.
class VirtualEventGame extends FlameGame with TapCallbacks {
  final int roomId;
  late final PlayerComponent myPlayer;
  final Map<String, PlayerComponent> otherPlayers = {};

  VirtualEventGame({required this.roomId});

  @override
  Color backgroundColor() => const Color(0xFF2E7D32); // A nice green for the floor

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Get the user ID from your AuthProvider. For now, it's hardcoded.
    final myUserId = 'user-achraf';
    myPlayer = PlayerComponent(
      id: myUserId,
      isCurrentUser: true, // This player is controllable by the user
    );

    // Place the player in the center of the initial screen
    myPlayer.position = size / 2;
    add(myPlayer);

    // Set the camera to follow our player after they have been added
    camera.follow(myPlayer);

    // --- DUMMY PLAYER SIMULATION ---
    _addOtherPlayer('user-guest1', Vector2(100, 200));
    _addOtherPlayer('user-guest2', Vector2(500, 300));
  }

  // This method is now part of the TapCallbacks mixin
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    // When the screen is tapped, move the current user's player to that location.
    myPlayer.moveTo(event.localPosition);
  }

  // Simulates another player joining the room
  void _addOtherPlayer(String id, Vector2 position) {
    final otherPlayer = PlayerComponent(id: id);
    otherPlayer.position = position;
    otherPlayers[id] = otherPlayer;
    add(otherPlayer);
  }

  // In a real app, you would call this when you receive a position update from your backend
  void updatePlayerPosition(String id, Vector2 newPosition) {
    if (otherPlayers.containsKey(id)) {
      otherPlayers[id]?.moveTo(newPosition);
    }
  }
}
