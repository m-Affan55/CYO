import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class VotingView extends StatefulWidget {
  final String targetName;
  final String title;
  final Function(String) onVote;

  const VotingView({
    super.key,
    required this.targetName,
    required this.title,
    required this.onVote,
  });

  @override
  State<VotingView> createState() => _VotingViewState();
}

class _VotingViewState extends State<VotingView> {
  String? _selectedVote;

  void _handleVote(String vote) {
    if (_selectedVote != null) return; // Prevent changing vote
    setState(() {
      _selectedVote = vote;
    });
    // Add brief delay before sending so user sees selection state
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onVote(vote);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Text(
          'VOTE NOW',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.primaryRed,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Does ${widget.targetName} deserve the title:',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCharcoal,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryRed.withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: 5,
              )
            ],
          ),
          child: Center(
            child: Text(
              '"${widget.title}"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.primaryRed,
                height: 1.2,
              ),
            ),
          ),
        ),
        const Spacer(),
        
        // Timer Bar
        LinearProgressIndicator(
          value: 0.7, // Mock value
          backgroundColor: AppTheme.surfaceCharcoal,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
          minHeight: 4,
        ),
        const SizedBox(height: 32),
        
        // Voting Buttons
        Row(
          children: [
            Expanded(
              child: _VoteButton(
                label: 'Disagree',
                color: AppTheme.primaryRed,
                icon: Icons.close,
                isSelected: _selectedVote == 'disagree',
                isDisabled: _selectedVote != null && _selectedVote != 'disagree',
                onTap: () => _handleVote('disagree'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VoteButton(
                label: 'Neutral',
                color: AppTheme.textMuted,
                icon: Icons.remove,
                isSelected: _selectedVote == 'neutral',
                isDisabled: _selectedVote != null && _selectedVote != 'neutral',
                onTap: () => _handleVote('neutral'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VoteButton(
                label: 'Agree',
                color: AppTheme.successGreen,
                icon: Icons.check,
                isSelected: _selectedVote == 'agree',
                isDisabled: _selectedVote != null && _selectedVote != 'agree',
                onTap: () => _handleVote('agree'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _VoteButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _VoteButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : (isDisabled ? AppTheme.surfaceCharcoal.withOpacity(0.5) : AppTheme.surfaceCharcoal),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : (isDisabled ? Colors.transparent : const Color(0xFF2A2A2A)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20)]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isDisabled ? AppTheme.textMuted.withOpacity(0.5) : color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: isDisabled ? AppTheme.textMuted.withOpacity(0.5) : AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
