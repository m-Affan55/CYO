import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class GameModeCard extends StatelessWidget {
  final String title;
  final String description;
  final String badgeText;
  final bool isPrimary;
  final VoidCallback onTap;

  const GameModeCard({
    super.key,
    required this.title,
    required this.description,
    required this.badgeText,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
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
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundBlack,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isPrimary ? AppTheme.primaryRed : AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
                if (isPrimary) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.successGreen,
                      shape: BoxShape.circle,
                    ),
                  )
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 20,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isPrimary ? AppTheme.primaryRed : AppTheme.backgroundBlack,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: isPrimary ? AppTheme.textPrimary : AppTheme.textSecondary,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
