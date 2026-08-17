import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/game_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:frontend/core/services/api_service.dart';
import 'package:frontend/core/widgets/primary_button.dart';

class GameLobbyScreen extends ConsumerWidget {
  final bool isSecretMode;

  const GameLobbyScreen({super.key, required this.isSecretMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<GameState>(gameStateProvider, (previous, next) {
      // BUG-10: Both host AND non-host navigate only after GAME_STARTED is confirmed by server.
      // Removed the immediate push from the onPressed button.
      if (previous?.status != 'PLAYING' && next.status == 'PLAYING') {
        context.push('/in-game', extra: {'isSecretMode': next.secretMode});
      }
      // BUG-4: Handle game abort
      if (!previous!.isAborted && next.isAborted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Game Aborted'),
            content: Text(next.abortMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(gameStateProvider.notifier).reset();
                  ref.read(webSocketServiceProvider).disconnect();
                  context.go('/home');
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });

    final gameState = ref.watch(gameStateProvider);
    final user = ref.watch(userProvider);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                'Friday Night CYO',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CODE ',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textMuted,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    gameState.roomCode.isEmpty ? '....' : gameState.roomCode,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Waiting Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCharcoal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Waiting for players...', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    Text('${gameState.players.length} / ${gameState.maxPlayers}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Player Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: gameState.players.map((p) {
                    final isHost = p['id'] == gameState.hostId;
                    final isReady = p['is_connected'] == true;
                    final initials = (p['name'] as String).substring(0, 1).toUpperCase();
                    
                    return _PlayerLobbyCard(
                      initials: initials,
                      name: p['name'],
                      isReady: isReady,
                      isHost: isHost,
                      color: AppTheme.primaryRed,
                    );
                  }).toList(),
                ),
              ),
              
              // Buttons
              if (user.id == gameState.hostId)
                Builder(builder: (context) {
                  final bool canStart = gameState.players.length >= 3;
                  return PrimaryButton(
                    text: canStart ? 'Start Game' : 'Need 3 Players',
                    // BUG-10: Only send the WS action. Navigation is handled by ref.listen above.
                    onPressed: canStart ? () {
                      final ws = ref.read(webSocketServiceProvider);
                      ws.sendAction('START_GAME');
                    } : () {},
                    color: canStart ? AppTheme.primaryRed : AppTheme.surfaceCharcoal,
                  );
                })
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text(
                    'Waiting for host to start...',
                    style: TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppTheme.backgroundBlack,
                      builder: (context) => _InviteFriendsSheet(roomCode: gameState.roomCode),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: Color(0xFF2A2A2A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.surfaceCharcoal,
                  ),
                  child: const Text('+ Invite Friends'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerLobbyCard extends StatelessWidget {
  final String initials;
  final String name;
  final bool isReady;
  final bool isHost;
  final Color color;

  const _PlayerLobbyCard({
    required this.initials,
    required this.name,
    required this.isReady,
    this.isHost = false,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHost ? AppTheme.primaryRed.withOpacity(0.5) : color.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (isHost)
                const Positioned(
                  top: -8,
                  right: -4,
                  child: Text('👑', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isReady ? AppTheme.successGreen : AppTheme.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isReady ? 'Ready' : 'Not ready',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isReady ? AppTheme.successGreen : AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}


class _InviteFriendsSheet extends ConsumerStatefulWidget {
  final String roomCode;
  const _InviteFriendsSheet({required this.roomCode});

  @override
  ConsumerState<_InviteFriendsSheet> createState() => _InviteFriendsSheetState();
}

class _InviteFriendsSheetState extends ConsumerState<_InviteFriendsSheet> {
  List<dynamic> _friends = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;
    
    setState(() => _isLoading = true);
    try {
      final token = await ref.read(authServiceProvider).getToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/friends/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() => _friends = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Error fetching friends: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendInvite(String friendId) async {
    try {
      final token = await ref.read(authServiceProvider).getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/invites/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'friend_id': friendId,
          'room_code': widget.roomCode,
        }),
      );
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite sent!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send invite')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    if (!authState.isAuthenticated) {
      return Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Log in to invite friends directly!', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: 'Join my CYO game! Code: ${widget.roomCode}'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite code copied to clipboard!')),
                );
                Navigator.pop(context);
              },
              child: const Text('Copy Invite Code instead'),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(24.0),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Invite Friends', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close, color: AppTheme.textMuted), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_friends.isEmpty)
            const Text('No friends found.', style: TextStyle(color: AppTheme.textMuted))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final friend = _friends[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryRed,
                      child: Text(friend['username'].substring(0, 2).toUpperCase(), style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(friend['username'], style: const TextStyle(color: AppTheme.textPrimary)),
                    trailing: ElevatedButton(
                      onPressed: () => _sendInvite(friend['id']),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
                      child: const Text('Invite'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
