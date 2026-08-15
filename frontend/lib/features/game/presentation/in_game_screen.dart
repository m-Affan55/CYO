import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/primary_button.dart';

import 'widgets/title_creation_view.dart';
import 'widgets/roulette_selection_view.dart';
import 'widgets/title_selection_view.dart';
import 'widgets/voting_view.dart';

enum GamePhase {
  titleCreation,
  selectingAssigner,
  selectingTarget,
  titleSelection,
  reveal,
  voting,
  roundResults,
}

class InGameScreen extends StatefulWidget {
  const InGameScreen({super.key});

  @override
  State<InGameScreen> createState() => _InGameScreenState();
}

class _InGameScreenState extends State<InGameScreen> {
  GamePhase _currentPhase = GamePhase.titleCreation;
  
  // Mock State
  final List<String> _mockPlayers = ['You', 'Sarah', 'Mike', 'Jess', 'Alex', 'Chris'];
  String _assigner = '';
  String _target = '';
  String _selectedTitle = '';

  void _advancePhase(GamePhase nextPhase) {
    setState(() {
      _currentPhase = nextPhase;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Prevent accidental back
        title: const Text('ROUND 1 / 5', style: TextStyle(fontSize: 12, letterSpacing: 2, color: AppTheme.textMuted)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showExitDialog(context),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildCurrentPhase(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPhase() {
    switch (_currentPhase) {
      case GamePhase.titleCreation:
        return TitleCreationView(
          key: const ValueKey('titleCreation'),
          onReady: () => _advancePhase(GamePhase.selectingAssigner),
        );
      
      case GamePhase.selectingAssigner:
        return RouletteSelectionView(
          key: const ValueKey('selectingAssigner'),
          prompt: 'SELECTING ASSIGNER...',
          players: _mockPlayers,
          finalSelection: 'You', // Force "You" for demo purposes
          onComplete: () {
            _assigner = 'You';
            _advancePhase(GamePhase.selectingTarget);
          },
        );

      case GamePhase.selectingTarget:
        return RouletteSelectionView(
          key: const ValueKey('selectingTarget'),
          prompt: 'SELECTING TARGET...',
          players: _mockPlayers.where((p) => p != 'You').toList(),
          finalSelection: 'Mike', // Force "Mike" for demo purposes
          onComplete: () {
            _target = 'Mike';
            _advancePhase(GamePhase.titleSelection);
          },
        );

      case GamePhase.titleSelection:
        return TitleSelectionView(
          key: const ValueKey('titleSelection'),
          assignerName: _assigner,
          targetName: _target,
          availableTitles: const ['Code Wizard', 'Always Late', 'Design Guru', 'Main Character', 'The Ghost'],
          onTitleSelected: (title) {
            _selectedTitle = title;
            _advancePhase(GamePhase.reveal);
          },
        );

      case GamePhase.reveal:
        return _buildRevealView();

      case GamePhase.voting:
        return VotingView(
          key: const ValueKey('voting'),
          targetName: _target,
          title: _selectedTitle,
          onVote: (vote) {
            // In a real app, send to backend. Here we just advance to results.
            _advancePhase(GamePhase.roundResults);
          },
        );

      case GamePhase.roundResults:
        return _buildResultsView();
    }
  }

  Widget _buildRevealView() {
    return Center(
      key: const ValueKey('reveal'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$_assigner called out',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          Text(
            _target,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppTheme.primaryRed),
          ),
          const SizedBox(height: 16),
          Text(
            'as',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMuted, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          Text(
            '"$_selectedTitle"',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 64),
          PrimaryButton(
            text: 'Vote Now',
            onPressed: () => _advancePhase(GamePhase.voting),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return Center(
      key: const ValueKey('results'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'MAJORITY AGREE',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.successGreen, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _target,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          Text(
            'is now the',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
          ),
          Text(
            '"$_selectedTitle"',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.primaryRed),
          ),
          const SizedBox(height: 48),
          
          // Mock Score Changes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScoreChange(_target, '+100 pts', AppTheme.successGreen),
              const SizedBox(width: 32),
              _buildScoreChange(_assigner, '+50 pts', AppTheme.textPrimary),
            ],
          ),
          
          const SizedBox(height: 64),
          PrimaryButton(
            text: 'Next Round',
            onPressed: () {
              // Loop back to assigner selection for demo
              _advancePhase(GamePhase.selectingAssigner);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScoreChange(String name, String points, Color color) {
    return Column(
      children: [
        Text(name, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(points, style: Theme.of(context).textTheme.displayMedium?.copyWith(color: color, fontSize: 24)),
      ],
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCharcoal,
        title: const Text('Leave Game?'),
        content: const Text('Are you sure you want to leave? You will forfeit the match.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: const Text('Leave', style: TextStyle(color: AppTheme.primaryRed)),
          ),
        ],
      ),
    );
  }
}
