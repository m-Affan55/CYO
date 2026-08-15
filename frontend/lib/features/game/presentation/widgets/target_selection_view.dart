import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/primary_button.dart';

class TargetSelectionView extends StatefulWidget {
  final List<String> availableTargets;
  final Function(String) onTargetSelected;

  const TargetSelectionView({
    super.key,
    required this.availableTargets,
    required this.onTargetSelected,
  });

  @override
  State<TargetSelectionView> createState() => _TargetSelectionViewState();
}

class _TargetSelectionViewState extends State<TargetSelectionView> {
  String? _selectedTarget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'SECRET CALLER',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.backgroundBlack),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Choose your target',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Shh... nobody knows you are picking.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 32),
        
        Expanded(
          child: ListView.separated(
            itemCount: widget.availableTargets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final target = widget.availableTargets[index];
              final isSelected = _selectedTarget == target;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTarget = target;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryRed.withOpacity(0.1) : AppTheme.surfaceCharcoal,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryRed : const Color(0xFF2A2A2A),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        target,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryRed : AppTheme.textPrimary,
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: AppTheme.primaryRed),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 24),
        PrimaryButton(
          text: 'Next',
          onPressed: _selectedTarget != null ? () => widget.onTargetSelected(_selectedTarget!) : () {},
          color: _selectedTarget != null ? AppTheme.primaryRed : AppTheme.surfaceCharcoal,
        ),
      ],
    );
  }
}
