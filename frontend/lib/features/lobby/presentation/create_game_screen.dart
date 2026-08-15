import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/primary_button.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final TextEditingController _gameNameController = TextEditingController(text: 'Friday Night CYO');
  int _maxPlayers = 6;
  int _selectedRounds = 5;
  int _selectedTimer = 30; // Max 30 seconds
  bool _isSecretMode = false;

  final List<int> _roundOptions = [3, 5, 7, 10];
  final List<int> _timerOptions = [15, 20, 30];

  @override
  void dispose() {
    _gameNameController.dispose();
    super.dispose();
  }

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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Game',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Set up your game and invite friends.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),

              // Game Name
              Text(
                'GAME NAME',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _gameNameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surfaceCharcoal,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryRed),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Max Players Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MAX PLAYERS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_maxPlayers > 3) setState(() => _maxPlayers--);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCharcoal,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2A2A2A)),
                          ),
                          child: const Icon(Icons.remove, size: 20, color: AppTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$_maxPlayers',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.primaryRed,
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          if (_maxPlayers < 12) setState(() => _maxPlayers++);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCharcoal,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2A2A2A)),
                          ),
                          child: const Icon(Icons.add, size: 20, color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Rounds
              Text(
                'ROUNDS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _roundOptions.map((rounds) {
                  final isSelected = _selectedRounds == rounds;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRounds = rounds;
                      });
                    },
                    child: Container(
                      width: 70,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryRed : AppTheme.surfaceCharcoal,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppTheme.primaryRed : const Color(0xFF2A2A2A)),
                      ),
                      child: Center(
                        child: Text(
                          '$rounds',
                          style: TextStyle(
                            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Vote Timer
              Text(
                'VOTE TIMER',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _timerOptions.map((timer) {
                  final isSelected = _selectedTimer == timer;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTimer = timer;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryRed.withOpacity(0.1) : AppTheme.surfaceCharcoal,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppTheme.primaryRed : const Color(0xFF2A2A2A)),
                        ),
                        child: Center(
                          child: Text(
                            '${timer}s',
                            style: TextStyle(
                              color: isSelected ? AppTheme.primaryRed : AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Secret Mode Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCharcoal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isSecretMode ? AppTheme.primaryRed : const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SECRET CALLER MODE',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: _isSecretMode ? AppTheme.primaryRed : AppTheme.textPrimary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hide the identity of the person picking the title. Voting becomes completely unbiased!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isSecretMode,
                      activeColor: AppTheme.primaryRed,
                      onChanged: (val) => setState(() => _isSecretMode = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Action Buttons
              PrimaryButton(
                text: 'Continue – Invite Friends',
                onPressed: () {
                  context.push('/game-lobby', extra: {'isSecretMode': _isSecretMode});
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.push('/game-lobby', extra: {'isSecretMode': _isSecretMode});
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: Color(0xFF2A2A2A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.surfaceCharcoal,
                  ),
                  child: const Text('Skip Invites – Go to Lobby'),
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
