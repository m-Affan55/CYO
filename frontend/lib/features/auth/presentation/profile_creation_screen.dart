import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/primary_button.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  
  final List<Color> _avatarColors = [
    AppTheme.primaryRed,
    const Color(0xFF6B4EFF),
    const Color(0xFF00C4B4),
    const Color(0xFFFF9500),
    const Color(0xFF34C759),
    const Color(0xFFAF52DE),
  ];
  
  int _selectedColorIndex = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _statusController.dispose();
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
                'STEP 3 OF 3',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 2,
                  color: AppTheme.primaryRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your profile',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'How you appear to other players',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              
              // Avatar Preview
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _avatarColors[_selectedColorIndex],
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _avatarColors[_selectedColorIndex].withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'ME',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: _avatarColors[_selectedColorIndex],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Color Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_avatarColors.length, (index) {
                  final isSelected = _selectedColorIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColorIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _avatarColors[index],
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 48),
              
              // Form Fields
              Text(
                'USERNAME',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: 'e.g. NightOwl99',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.surfaceCharcoal,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Text(
                    'STATUS ',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Optional',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _statusController,
                decoration: InputDecoration(
                  hintText: 'e.g. Always watching 👀',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.surfaceCharcoal,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              PrimaryButton(
                text: 'Continue',
                onPressed: () {
                  context.go('/home');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
