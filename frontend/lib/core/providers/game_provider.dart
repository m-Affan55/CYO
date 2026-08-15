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
  
  GameState({
    this.roomCode = '',
    this.players = const [],
    this.status = 'WAITING',
  });

  GameState copyWith({String? roomCode, List<dynamic>? players, String? status}) {
    return GameState(
      roomCode: roomCode ?? this.roomCode,
      players: players ?? this.players,
      status: status ?? this.status,
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
    if (eventType == 'GAME_STARTED') {
      state = state.copyWith(status: 'PLAYING');
    }
  }
}

final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier();
});
