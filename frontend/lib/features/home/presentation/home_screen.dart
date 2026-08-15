import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/game_mode_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.backgroundBlack,
        selectedItemColor: AppTheme.primaryRed,
        unselectedItemColor: AppTheme.textMuted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryRed, width: 1.5),
                        ),
                        child: const Center(
                          child: Text('YO', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Good evening,', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                          Text('NightOwl99', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.darkRed.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '1,580 pts',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primaryRed),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCharcoal,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: const Icon(Icons.notifications_none, size: 20, color: AppTheme.textPrimary),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),
              
              // Hero Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.surfaceCharcoal,
                      AppTheme.darkRed.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'READY?',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primaryRed, letterSpacing: 2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to Play?',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your crew is waiting. Pick a mode and jump in.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'GAME MODE',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              
              GameModeCard(
                title: 'Play Online',
                description: 'Play with friends anywhere.',
                badgeText: 'Online',
                isPrimary: true,
                onTap: () {
                  context.push('/online-multiplayer');
                },
              ),
              const SizedBox(height: 16),
              GameModeCard(
                title: 'Play Offline',
                description: 'Play together on one device.',
                badgeText: 'Offline',
                onTap: () {
                  // Not implemented yet
                },
              ),
              
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ACTIVE GAMES',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted, letterSpacing: 2),
                  ),
                  Text(
                    '2 games',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Active Game Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCharcoal,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Friday Night CYO',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Your turn',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '6 Players · Round 3/5',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Fake avatars
                        Row(
                          children: [
                            _buildMiniAvatar('YO', AppTheme.primaryRed),
                            Transform.translate(offset: const Offset(-8, 0), child: _buildMiniAvatar('SK', const Color(0xFF6B4EFF))),
                            Transform.translate(offset: const Offset(-16, 0), child: _buildMiniAvatar('MT', const Color(0xFF00C4B4))),
                            Transform.translate(offset: const Offset(-24, 0), child: _buildMiniAvatar('+2', AppTheme.textMuted)),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Continue',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primaryRed),
                            ),
                            const Icon(Icons.arrow_forward, color: AppTheme.primaryRed, size: 16),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniAvatar(String initials, Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppTheme.backgroundBlack,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
