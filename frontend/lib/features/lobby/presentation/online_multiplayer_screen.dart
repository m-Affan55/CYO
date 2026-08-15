import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/game_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';

class OnlineMultiplayerScreen extends ConsumerStatefulWidget {
  const OnlineMultiplayerScreen({super.key});

  @override
  ConsumerState<OnlineMultiplayerScreen> createState() => _OnlineMultiplayerScreenState();
}

class _OnlineMultiplayerScreenState extends ConsumerState<OnlineMultiplayerScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(text: 'Player');
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ONLINE MULTIPLAYER',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 2,
                  color: AppTheme.primaryRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How do you want to play?',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 48),
              
              _ActionCard(
                title: 'Create Game',
                description: 'Start a new private game and invite your friends with a code.',
                icon: Icons.add,
                isPrimary: true,
                onTap: () {
                  context.push('/create-game');
                },
              ),
              const SizedBox(height: 16),
              _ActionCard(
                title: 'Join Game',
                description: 'Enter an invite code to jump into an existing game with friends.',
                icon: Icons.login,
                isPrimary: false,
                onTap: () async {
                  if (_isLoading) return;
                  if (_codeController.text.length != 4) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code must be 4 letters')));
                    return;
                  }
                  
                  setState(() => _isLoading = true);
                  try {
                    final api = ref.read(apiServiceProvider);
                    final response = await api.joinRoom(
                      _codeController.text, 
                      _nameController.text, 
                      '#00C4B4' // Default color
                    );
                    
                    ref.read(userProvider.notifier).state = UserState(
                      id: response['id'],
                      name: response['name'],
                      color: response['color'],
                      roomId: response['room_id'],
                    );
                    
                    // Note: Ideally we'd fetch the room data to set in GameState.
                    // For MVP, we'll just set the roomCode.
                    ref.read(gameStateProvider.notifier).setRoomData({'id': response['room_id']});
                    
                    final ws = ref.read(webSocketServiceProvider);
                    ws.onMessageReceived = (event) {
                      ref.read(gameStateProvider.notifier).handleWebSocketEvent(event);
                    };
                    ws.connect(response['room_id'], response['id']);
                    
                    if (!context.mounted) return;
                    context.push('/game-lobby', extra: {'isSecretMode': false});
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Your Name',
                          filled: true,
                          fillColor: AppTheme.backgroundBlack,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _codeController,
                        maxLength: 4,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: '4-Letter Code',
                          filled: true,
                          fillColor: AppTheme.backgroundBlack,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;
  final Widget? child;

  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    this.isPrimary = false,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCharcoal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? AppTheme.primaryRed.withOpacity(0.5) : const Color(0xFF2A2A2A),
            width: 1,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.primaryRed.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary ? AppTheme.primaryRed : AppTheme.backgroundBlack,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}
