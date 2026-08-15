import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo / Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCharcoal,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryRed.withOpacity(0.5), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryRed.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.gps_fixed, // Placeholder for the target/reveal icon
                      color: AppTheme.primaryRed,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // App Title
              Center(
                child: Text(
                  'REVEAL',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'PARTY GAME',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 4,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // Tagline
              Center(
                child: Text(
                  'Play.\nChallenge.\nReveal.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 40,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Description
              Text(
                'A social party game built for groups of friends. Hidden roles, surprise reveals, and competitive voting.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Buttons
              ElevatedButton(
                onPressed: () {
                  context.push('/how-it-works');
                },
                child: const Text('Get Started'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navigate to Login
                },
                child: Text(
                  'Already have an account? Log In',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
