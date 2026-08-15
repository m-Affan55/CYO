import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/services/api_service.dart';
import 'package:frontend/core/services/websocket_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());
final webSocketServiceProvider = Provider((ref) => WebSocketService());

class UserState {
  final String id;
  final String name;
  final String color;
  final String roomId;

  UserState({
    this.id = '',
    this.name = '',
    this.color = '',
    this.roomId = '',
  });

  UserState copyWith({String? id, String? name, String? color, String? roomId}) {
    return UserState(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      roomId: roomId ?? this.roomId,
    );
  }
}

final userProvider = StateProvider<UserState>((ref) => UserState());

class GameState {
  final String roomCode;
  final List<dynamic> players;
  final String status;
  final Map<String, dynamic>? engineState;
  final List<String> typingPlayers;
  
  GameState({
    this.roomCode = '',
    this.players = const [],
    this.status = 'WAITING',
    this.engineState,
    this.typingPlayers = const [],
  });

  GameState copyWith({String? roomCode, List<dynamic>? players, String? status, Map<String, dynamic>? engineState, List<String>? typingPlayers}) {
    return GameState(
      roomCode: roomCode ?? this.roomCode,
      players: players ?? this.players,
      status: status ?? this.status,
      engineState: engineState ?? this.engineState,
      typingPlayers: typingPlayers ?? this.typingPlayers,
    );
  }
}

class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(GameState());

  void setRoomData(Map<String, dynamic> data) {
    state = state.copyWith(
      roomCode: data['id'] ?? data['room_id'] ?? state.roomCode,
      players: data['users'] ?? state.players,
      status: data['status'] ?? state.status,
    );
  }

  void handleWebSocketEvent(Map<String, dynamic> event) {
    print('WS Event: $event');
    final eventType = event['event'];
    
    // As a simple approach for MVP, if we get an event that someone joined,
    // we would ideally re-fetch the room or append them.
    // For now we just print it.
    if (eventType == 'STATE_UPDATE') {
      final engineState = event['state'] as Map<String, dynamic>?;
      var newTyping = state.typingPlayers;
      if (engineState != null) {
        final titles = engineState['titles'] as Map<String, dynamic>? ?? {};
        newTyping = state.typingPlayers.where((id) => !titles.containsKey(id)).toList();
      }
      state = state.copyWith(engineState: engineState, typingPlayers: newTyping);
    } else if (eventType == 'PLAYERS_UPDATED') {
      state = state.copyWith(players: event['players'] ?? state.players);
    } else if (eventType == 'GAME_STARTED') {
      state = state.copyWith(status: 'PLAYING');
    } else if (eventType == 'TITLE_ADDED') {
      final userId = event['user_id'];
      if (userId != null) {
        final newTyping = List<String>.from(state.typingPlayers);
        newTyping.remove(userId);
        state = state.copyWith(typingPlayers: newTyping);
      }
    } else if (eventType == 'PLAYER_TYPING') {
      final userId = event['user_id'];
      final isTyping = event['is_typing'] == true;
      final newTyping = List<String>.from(state.typingPlayers);
      if (isTyping && !newTyping.contains(userId)) {
        newTyping.add(userId);
      } else if (!isTyping) {
        newTyping.remove(userId);
      }
      state = state.copyWith(typingPlayers: newTyping);
    }
  }
}

final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier();
});
