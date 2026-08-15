import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/primary_button.dart';

class GameLobbyScreen extends StatelessWidget {
  const GameLobbyScreen({super.key});

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
                    'X7K92P',
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
                    Text('6 / 8', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                  children: [
                    _PlayerLobbyCard(initials: 'YO', name: 'You', isReady: true, isHost: true, color: AppTheme.primaryRed),
                    _PlayerLobbyCard(initials: 'SK', name: 'Sarah K', isReady: true, color: const Color(0xFF6B4EFF)),
                    _PlayerLobbyCard(initials: 'MT', name: 'Mike T', isReady: false, color: const Color(0xFF00C4B4)),
                    _PlayerLobbyCard(initials: 'JR', name: 'Jess R', isReady: true, color: const Color(0xFFFF9500)),
                    _PlayerLobbyCard(initials: 'AM', name: 'Alex M', isReady: false, color: const Color(0xFF34C759)),
                    _PlayerLobbyCard(initials: 'CB', name: 'Chris B', isReady: true, color: const Color(0xFFAF52DE)),
                    const _EmptyLobbySlot(),
                    const _EmptyLobbySlot(),
                  ],
                ),
              ),
              
              // Buttons
              PrimaryButton(
                text: 'Start Game',
                onPressed: () {
                  context.push('/in-game');
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: Color(0xFF2A2A2A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.surfaceCharcoal,
                  ),
                  child: const Text('+ Invite More Friends'),
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

class _EmptyLobbySlot extends StatelessWidget {
  const _EmptyLobbySlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A), style: BorderStyle.solid),
      ),
      child: Center(
        child: Text(
          'Empty',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
        ),
      ),
    );
  }
}
