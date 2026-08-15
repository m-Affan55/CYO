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
  final TextEditingController _gameNameController = TextEditingController(text: 'Friday Chaos');
  double _maxPlayers = 6;
  int _selectedRounds = 5;
  bool _voteTimerEnabled = true;

  final List<int> _roundOptions = [3, 5, 7, 10];

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

              // Max Players Slider
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
                  Text(
                    '${_maxPlayers.toInt()}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.primaryRed,
                  inactiveTrackColor: AppTheme.textPrimary,
                  thumbColor: AppTheme.textPrimary,
                  overlayColor: AppTheme.primaryRed.withOpacity(0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _maxPlayers,
                  min: 3,
                  max: 12,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() {
                      _maxPlayers = value;
                    });
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('3', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted)),
                  Text('12', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted)),
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

              // Vote Timer Toggle
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCharcoal,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vote Timer', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('60 seconds per round', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted)),
                      ],
                    ),
                    Switch(
                      value: _voteTimerEnabled,
                      activeColor: AppTheme.textPrimary,
                      activeTrackColor: AppTheme.primaryRed,
                      inactiveThumbColor: AppTheme.textMuted,
                      inactiveTrackColor: AppTheme.backgroundBlack,
                      onChanged: (value) {
                        setState(() {
                          _voteTimerEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Action Buttons
              PrimaryButton(
                text: 'Continue – Invite Friends',
                onPressed: () {
                  // TODO: Implement actual game creation logic on backend
                  context.push('/game-lobby');
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.push('/game-lobby');
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
