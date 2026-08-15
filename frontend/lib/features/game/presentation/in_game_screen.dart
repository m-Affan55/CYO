import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:frontend/core/providers/game_provider.dart';

import 'widgets/title_creation_view.dart';
import 'widgets/title_selection_view.dart';
import 'widgets/voting_view.dart';

// Helper to find a user's name by their ID
String _getPlayerName(List<dynamic> players, String? id) {
  if (id == null) return 'Unknown';
  final p = players.cast<Map<String, dynamic>>().firstWhere(
    (p) => p['id'] == id, 
    orElse: () => {'name': 'Unknown'}
  );
  return p['name'];
}

class InGameScreen extends ConsumerStatefulWidget {
  final bool isSecretMode;

  const InGameScreen({super.key, this.isSecretMode = false});

  @override
  ConsumerState<InGameScreen> createState() => _InGameScreenState();
}

class _InGameScreenState extends ConsumerState<InGameScreen> {
  
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final user = ref.watch(userProvider);
    final engineState = gameState.engineState ?? {};
    final phase = engineState['phase'] ?? 'TITLE_CREATION';
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Prevent accidental back
        title: Text(widget.isSecretMode ? 'SECRET ROUND' : 'GAME ROUND', style: const TextStyle(fontSize: 12, letterSpacing: 2, color: AppTheme.textMuted)),
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
            child: _buildCurrentPhase(phase, engineState, gameState.players, user.id, gameState.typingPlayers),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPhase(String phase, Map<String, dynamic> engineState, List<dynamic> players, String myUserId, List<String> typingPlayers) {
    switch (phase) {
      case 'TITLE_CREATION':
        final titlesMap = engineState['titles'] as Map<String, dynamic>? ?? {};
        final hasSubmitted = titlesMap.containsKey(myUserId);
        
        final typingNames = typingPlayers
            .where((id) => id != myUserId)
            .map((id) => _getPlayerName(players, id))
            .toList();

        return TitleCreationView(
          key: const ValueKey('titleCreation'),
          hasSubmitted: hasSubmitted,
          titlesSubmitted: titlesMap.length,
          totalPlayers: players.length,
          titlesMap: titlesMap,
          players: players,
          typingNames: typingNames,
          onTitleSubmit: (title) {
            final ws = ref.read(webSocketServiceProvider);
            ws.sendAction('SUBMIT_TITLE', {'title': title});
          },
          onTyping: (isTyping) {
            final ws = ref.read(webSocketServiceProvider);
            ws.sendAction('TYPING', {'is_typing': isTyping});
          }
        );
      
      case 'SELECTING_ASSIGNER':
        // For MVP, if there is no assigner picked yet, anyone can click a button to pick an assigner.
        // Usually, the server picks randomly, or host presses. Let's just give everyone a button.
        final assignerId = engineState['assigner_id'];
        
        if (assignerId == null) {
            return Center(
              child: PrimaryButton(
                text: 'Spin Assigner Wheel',
                onPressed: () {
                   // Just pick self for MVP demo, or random
                   final ws = ref.read(webSocketServiceProvider);
                   ws.sendAction('SELECT_ASSIGNER', {'assigner_id': myUserId});
                }
              )
            );
        } else {
            // This is just a transition phase
            final text = widget.isSecretMode
                ? "An assigner was selected!"
                : "Assigner selected: ${_getPlayerName(players, assignerId)}";
            return Center(child: Text(text));
        }

      case 'SELECTING_TARGET':
      case 'TITLE_SELECTION':
        final assignerId = engineState['assigner_id'];
        final amIAssigner = (assignerId == myUserId);
        final assignerName = _getPlayerName(players, assignerId);
        
        if (amIAssigner) {
          // I am picking the target and title
          final titlesMap = engineState['titles'] as Map<String, dynamic>? ?? {};
          final availableTitles = titlesMap.values.cast<String>().toList();
          
          // Target selection mock: Just pick first other player
          final possibleTargets = players.where((p) => p['id'] != myUserId).toList();
          final targetId = possibleTargets.isNotEmpty ? possibleTargets.first['id'] : myUserId;
          final targetName = _getPlayerName(players, targetId);
          
          return TitleSelectionView(
            key: const ValueKey('titleSelection'),
            assignerName: 'You',
            targetName: targetName,
            availableTitles: availableTitles,
            onTitleSelected: (title) {
              final ws = ref.read(webSocketServiceProvider);
              ws.sendAction('ASSIGN_TITLE', {
                  'target_id': targetId,
                  'title': title
              });
            },
          );
        } else {
          final text = widget.isSecretMode
              ? "Someone is picking a target and title..."
              : "$assignerName is picking a target and title...";
          return Center(child: Text(text));
        }

      case 'VOTING':
        final targetId = engineState['target_id'];
        final assignerId = engineState['assigner_id'];
        final title = engineState['selected_title'];
        final targetName = _getPlayerName(players, targetId);
        
        final amITarget = (targetId == myUserId);
        final amIAssigner = (assignerId == myUserId);
        
        if (amITarget || amIAssigner) {
           return Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Text('VOTING IN PROGRESS...', style: Theme.of(context).textTheme.displayMedium),
                 const SizedBox(height: 16),
                 Text('Wait for others to vote if $targetName is "$title".')
               ]
             )
           );
        }
        
        return VotingView(
          key: const ValueKey('voting'),
          targetName: targetName,
          title: title ?? '',
          onVote: (vote) {
            final ws = ref.read(webSocketServiceProvider);
            bool boolVote = vote == 'agree'; // Maps agree to true, otherwise false
            ws.sendAction('VOTE', {'vote': boolVote});
          },
        );

      case 'ROUND_RESULTS':
        return _buildResultsView(engineState, players);
        
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildResultsView(Map<String, dynamic> engineState, List<dynamic> players) {
    // Note: To properly show results we need the latest points, which means we might need a fetch or the server sends it.
    // For MVP, we'll just show a "Round Over" placeholder since points are updated in DB.
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
              'ROUND COMPLETE',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.successGreen, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Points updated in database!",
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 64),
          PrimaryButton(
            text: 'End Game (MVP)',
            onPressed: () {
               context.go('/home');
            },
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCharcoal,
        title: const Text('Leave Game?'),
        content: const Text('Are you sure you want to leave?'),
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
