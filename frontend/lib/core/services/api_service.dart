import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://127.0.0.1:8000/api';
  }

  Future<Map<String, dynamic>> createRoom(String hostName, String hostColor, int maxPlayers, int rounds, int timer, bool secretMode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rooms/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'host_name': hostName,
        'host_color': hostColor,
        'max_players': maxPlayers,
        'rounds': rounds,
        'timer': timer,
        'secret_mode': secretMode,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create room: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> joinRoom(String roomCode, String playerName, String playerColor) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rooms/$roomCode/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': playerName,
        'color': playerColor,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to join room: ${response.body}');
    }
  }
}
