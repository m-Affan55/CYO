import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/auth_provider.dart';

class HowItWorksScreen extends StatelessWidget {
  final bool isGuest;
  const HowItWorksScreen({super.key, this.isGuest = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HOW IT WORKS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 2,
                  color: AppTheme.primaryRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ready in 4 steps',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 48),
              
              // Steps List
              Expanded(
                child: ListView(
                  children: const [
                    _StepCard(
                      number: '01',
                      title: 'Create or Join',
                      description: 'Start a private game and invite your crew, or jump into one with a code.',
                      icon: Icons.gamepad,
                      isActive: true,
                    ),
                    SizedBox(height: 16),
                    _StepCard(
                      number: '02',
                      title: 'Get Your Role',
                      description: 'Find out if you are assigning the title or voting.',
                      icon: Icons.masks,
                    ),
                    SizedBox(height: 16),
                    _StepCard(
                      number: '03',
                      title: 'Play the Round',
                      description: 'Submit titles and watch the target get revealed.',
                      icon: Icons.track_changes,
                    ),
                    SizedBox(height: 16),
                    _StepCard(
                      number: '04',
                      title: 'Vote & Score',
                      description: 'Agree or disagree to win points. Don\'t miss the vote!',
                      icon: Icons.how_to_vote,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              // Bottom Nav
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Progress Dots
                  Row(
                    children: [
                      Container(width: 24, height: 4, decoration: BoxDecoration(color: AppTheme.primaryRed, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 4),
                      Container(width: 8, height: 4, decoration: BoxDecoration(color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 4),
                      Container(width: 8, height: 4, decoration: BoxDecoration(color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2))),
                    ],
                  ),
                  SizedBox(
                    width: 120,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final authState = ref.watch(authProvider);
                        
                        return PrimaryButton(
                          text: authState.isLoading && isGuest ? 'Joining...' : 'Next',
                          onPressed: authState.isLoading ? () {} : () async {
                            if (isGuest) {
                              try {
                                await ref.read(authProvider.notifier).registerGuest();
                                if (context.mounted) context.go('/home');
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              }
                            } else {
                              context.push('/profile-creation');
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final bool isActive;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppTheme.primaryRed.withOpacity(0.5) : const Color(0xFF2A2A2A),
          width: 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.primaryRed.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundBlack,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? AppTheme.primaryRed : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      number,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isActive ? AppTheme.primaryRed : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
