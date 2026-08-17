import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/services/api_service.dart';
import 'package:frontend/core/services/websocket_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());
final webSocketServiceProvider = Provider((ref) => WebSocketService());

// ─── UserState ────────────────────────────────────────────────────────────────

class UserState {
  final String id;
  final String name;
  final String color;
  final String roomId;

  const UserState({
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

final userProvider = StateProvider<UserState>((ref) => const UserState());

// ─── GameState ────────────────────────────────────────────────────────────────

class GameState {
  final String roomCode;
  final String hostId;
  final List<dynamic> players;
  final String status;
  final Map<String, dynamic>? engineState;
  final List<String> typingPlayers;

  // BUG-12: secret_mode from server
  final bool secretMode;

  // BUG-13: actual max players from room settings
  final int maxPlayers;

  // BUG-4: game aborted flag + message
  final bool isAborted;
  final String abortMessage;
  
  final int requiredTitles;
  final List<dynamic> turnHistory;

  const GameState({
    this.roomCode = '',
    this.hostId = '',
    this.players = const [],
    this.status = 'WAITING',
    this.engineState,
    this.typingPlayers = const [],
    this.secretMode = false,
    this.maxPlayers = 12,
    this.isAborted = false,
    this.abortMessage = '',
    this.requiredTitles = 1,
    this.turnHistory = const [],
  });

  GameState copyWith({
    String? roomCode,
    String? hostId,
    List<dynamic>? players,
    String? status,
    Map<String, dynamic>? engineState,
    List<String>? typingPlayers,
    bool? secretMode,
    int? maxPlayers,
    bool? isAborted,
    String? abortMessage,
    int? requiredTitles,
    List<dynamic>? turnHistory,
  }) {
    return GameState(
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      players: players ?? this.players,
      status: status ?? this.status,
      engineState: engineState ?? this.engineState,
      typingPlayers: typingPlayers ?? this.typingPlayers,
      secretMode: secretMode ?? this.secretMode,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      isAborted: isAborted ?? this.isAborted,
      abortMessage: abortMessage ?? this.abortMessage,
      requiredTitles: requiredTitles ?? this.requiredTitles,
      turnHistory: turnHistory ?? this.turnHistory,
    );
  }

  // Cleared abort flag (returns same state but with abort cleared)
  GameState clearAbort() => copyWith(isAborted: false, abortMessage: '');
}

// ─── GameStateNotifier ────────────────────────────────────────────────────────

class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(const GameState());

  /// BUG-7: Reset all state when starting a new session
  void reset() {
    state = const GameState();
  }

  void setRoomData(Map<String, dynamic> data) {
    state = state.copyWith(
      roomCode: data['id'] ?? data['room_id'] ?? state.roomCode,
      hostId: data['host_id'] ?? state.hostId,
      players: data['users'] ?? state.players,
      status: data['status'] ?? state.status,
      maxPlayers: data['max_players'] ?? state.maxPlayers,
    );
  }

  void handleWebSocketEvent(Map<String, dynamic> event) {
    print('WS Event: $event');
    final eventType = event['event'];

    switch (eventType) {
      case 'STATE_UPDATE':
        final engineState = event['state'] as Map<String, dynamic>?;
        var newTyping = state.typingPlayers;
        if (engineState != null) {
          // Remove "typing" indicator for anyone who already submitted
          final titles = engineState['titles'] as List<dynamic>? ?? [];
          final submittedIds = titles.map((t) => t['author_id'] as String).toSet();
          newTyping = state.typingPlayers.where((id) => !submittedIds.contains(id)).toList();
        }
        state = state.copyWith(
          engineState: engineState, 
          typingPlayers: newTyping,
          turnHistory: engineState?['turn_history'] as List<dynamic>? ?? state.turnHistory,
        );
        break;

      case 'PLAYERS_UPDATED':
        state = state.copyWith(players: event['players'] ?? state.players);
        break;

      case 'GAME_STARTED':
        // BUG-12: Capture secret_mode from server for all clients
        final secretMode = event['secret_mode'] as bool? ?? false;
        final requiredTitles = event['rounds'] as int? ?? 1;
        state = state.copyWith(status: 'PLAYING', secretMode: secretMode, requiredTitles: requiredTitles);
        break;

      case 'TITLE_ADDED':
        final userId = event['user_id'] as String?;
        if (userId != null) {
          final newTyping = List<String>.from(state.typingPlayers)..remove(userId);
          state = state.copyWith(typingPlayers: newTyping);
        }
        break;

      case 'PLAYER_TYPING':
        final userId   = event['user_id'] as String?;
        final isTyping = event['is_typing'] == true;
        if (userId != null) {
          final newTyping = List<String>.from(state.typingPlayers);
          if (isTyping && !newTyping.contains(userId)) {
            newTyping.add(userId);
          } else if (!isTyping) {
            newTyping.remove(userId);
          }
          state = state.copyWith(typingPlayers: newTyping);
        }
        break;

      case 'GAME_ABORTED':
        // BUG-4: Signal the UI to show an abort dialog and navigate home
        final message = event['message'] as String? ?? 'The game was aborted.';
        state = state.copyWith(isAborted: true, abortMessage: message, status: 'ABORTED');
        break;

      case 'GAME_RESET':
        // MISSING-1: Host triggered Play Again — clear engine state so UI returns to TITLE_CREATION
        state = state.copyWith(
          engineState: {},
          status: 'PLAYING',
          isAborted: false,
          abortMessage: '',
        );
        break;

      case 'PLAYER_SKIPPED':
        // BUG-15: AFK assigner — no state change needed, STATE_UPDATE follows immediately
        break;

      case 'ROUND_RESULTS_COMPLETED':
        // MISSING-3: Results are already embedded in engine state via last_results
        // STATE_UPDATE with last_results will arrive separately — nothing to do here
        break;

      default:
        break;
    }
  }
}

final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier();
});
