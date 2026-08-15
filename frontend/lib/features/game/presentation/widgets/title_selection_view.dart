import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/primary_button.dart';

class TitleSelectionView extends StatefulWidget {
  final String assignerName;
  final String targetName;
  final List<String> availableTitles;
  final Function(String) onTitleSelected;

  const TitleSelectionView({
    super.key,
    required this.assignerName,
    required this.targetName,
    required this.availableTitles,
    required this.onTitleSelected,
  });

  @override
  State<TitleSelectionView> createState() => _TitleSelectionViewState();
}

class _TitleSelectionViewState extends State<TitleSelectionView> {
  String? _selectedTitle;

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
                'YOUR TURN',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.backgroundBlack),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Call out ${widget.targetName}',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Select the title that best describes them.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 32),
        
        Expanded(
          child: ListView.separated(
            itemCount: widget.availableTitles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final title = widget.availableTitles[index];
              final isSelected = _selectedTitle == title;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTitle = title;
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
                        title,
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
          text: 'Confirm & Reveal',
          onPressed: _selectedTitle != null ? () => widget.onTitleSelected(_selectedTitle!) : () {},
          color: _selectedTitle != null ? AppTheme.primaryRed : AppTheme.surfaceCharcoal,
        ),
      ],
    );
  }
}
