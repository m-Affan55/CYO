import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/game_mode_card.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:frontend/features/home/presentation/tabs/friends_tab.dart';
import 'package:frontend/features/home/presentation/tabs/alerts_tab.dart';
import 'package:frontend/features/home/presentation/tabs/profile_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  Widget _buildHomeTab(Map<String, dynamic>? user) {
    return SingleChildScrollView(
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
                      // If we parsed color properly, we could use it here.
                    ),
                    child: Center(
                      child: Text(
                        user != null && user['username'] != null 
                            ? user['username'].substring(0, 2).toUpperCase() 
                            : 'GU', 
                        style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good evening,', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                      Text(user != null ? user['username'] ?? 'Guest' : 'Guest', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                      '${user != null ? user['points'] ?? 0 : 0} pts',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primaryRed),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = 2; // Go to alerts
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCharcoal,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: const Icon(Icons.notifications_none, size: 20, color: AppTheme.textPrimary),
                    ),
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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
          // ACTIVE GAMES is mocked for now
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE GAMES',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted, letterSpacing: 2),
              ),
              Text(
                '1 game',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
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
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final List<Widget> _tabs = [
      _buildHomeTab(user),
      const FriendsTab(),
      const AlertsTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.backgroundBlack,
        selectedItemColor: AppTheme.primaryRed,
        unselectedItemColor: AppTheme.textMuted,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          if (!authState.isAuthenticated && index != 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please log in to use this feature')),
            );
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: SafeArea(
        child: _tabs[_currentIndex],
      ),
    );
  }
}
