import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:frontend/core/widgets/primary_button.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROFILE',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primaryRed, letterSpacing: 2),
          ),
          const SizedBox(height: 32),
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryRed, width: 2),
              ),
              child: Center(
                child: Text(
                  user != null && user['username'] != null 
                      ? user['username'].substring(0, 2).toUpperCase() 
                      : 'GU', 
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.primaryRed)
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user != null ? user['username'] ?? 'Guest' : 'Guest',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ),
          Center(
            child: Text(
              user != null ? (user['status'] ?? 'No status') : 'Not logged in',
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 48),
          
          ListTile(
            title: const Text('Total Points', style: TextStyle(color: AppTheme.textPrimary)),
            trailing: Text(user != null ? '${user['points']} pts' : '0 pts', style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(color: Color(0xFF2A2A2A)),
          
          const Spacer(),
          PrimaryButton(
            text: 'Log Out',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/');
            },
          ),
        ],
      ),
    );
  }
}
