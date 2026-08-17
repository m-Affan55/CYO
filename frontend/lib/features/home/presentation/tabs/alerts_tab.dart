import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/services/api_service.dart';

class AlertsTab extends ConsumerStatefulWidget {
  const AlertsTab({super.key});

  @override
  ConsumerState<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends ConsumerState<AlertsTab> {
  List<dynamic> _invites = [];
  List<dynamic> _friendRequests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final token = await ref.read(authServiceProvider).getToken();
      final headers = {'Authorization': 'Bearer $token'};
      
      final invitesRes = await http.get(Uri.parse('${ApiService.baseUrl}/invites/'), headers: headers);
      final friendsRes = await http.get(Uri.parse('${ApiService.baseUrl}/friends/requests'), headers: headers);
      
      if (invitesRes.statusCode == 200) {
        _invites = jsonDecode(invitesRes.body);
      }
      if (friendsRes.statusCode == 200) {
        _friendRequests = jsonDecode(friendsRes.body);
      }
      
      setState(() {});
    } catch (e) {
      debugPrint("Error fetching alerts: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _handleFriendRequest(String id, bool accept) async {
    final token = await ref.read(authServiceProvider).getToken();
    final action = accept ? 'accept' : 'reject';
    await http.post(
      Uri.parse('${ApiService.baseUrl}/friends/$action/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _fetchData();
  }
  
  Future<void> _handleGameInvite(dynamic invite) async {
    final token = await ref.read(authServiceProvider).getToken();
    await http.delete(
      Uri.parse('${ApiService.baseUrl}/invites/${invite['id']}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (mounted) {
      final user = ref.read(authProvider).user;
      context.push('/game-lobby', extra: {
        'isSecretMode': false,
        'autoJoinCode': invite['room_code'],
        'autoJoinName': user?['username'] ?? 'Player',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ALERTS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primaryRed, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          else if (_invites.isEmpty && _friendRequests.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('All caught up!', style: Theme.of(context).textTheme.bodyMedium),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  ..._friendRequests.map((req) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Friend Request', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Someone wants to be friends', style: TextStyle(color: AppTheme.textMuted)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _handleFriendRequest(req['id'], true)),
                        IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _handleFriendRequest(req['id'], false)),
                      ],
                    ),
                  )),
                  ..._invites.map((inv) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Game Invite from ${inv['sender']['username']}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                    subtitle: Text('Code: ${inv['room_code']}', style: const TextStyle(color: AppTheme.textMuted)),
                    trailing: ElevatedButton(
                      onPressed: () => _handleGameInvite(inv),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
                      child: const Text('Join', style: TextStyle(color: Colors.white)),
                    ),
                  ))
                ],
              ),
            ),
        ],
      ),
    );
  }
}
