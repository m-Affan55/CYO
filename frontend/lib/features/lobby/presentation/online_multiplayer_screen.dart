import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';

class OnlineMultiplayerScreen extends StatelessWidget {
  const OnlineMultiplayerScreen({super.key});

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
                onTap: () {
                  // context.push('/join-game');
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) => _buildCodeBox()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeBox() {
    return Container(
      width: 40,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.backgroundBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A2A)),
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
