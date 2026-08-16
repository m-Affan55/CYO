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
            child: _buildCurrentPhase(phase, engineState, gameState.players, user.id, gameState.typingPlayers, gameState.hostId),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPhase(String phase, Map<String, dynamic> engineState, List<dynamic> players, String myUserId, List<String> typingPlayers, String hostId) {
    switch (phase) {
      case 'TITLE_CREATION':
        final titles = engineState['titles'] as List<dynamic>? ?? [];
        
        final typingNames = typingPlayers
            .where((id) => id != myUserId)
            .map((id) => _getPlayerName(players, id))
            .toList();

        return TitleCreationView(
          key: const ValueKey('titleCreation'),
          totalPlayers: players.length,
          titles: titles,
          players: players,
          typingNames: typingNames,
          myUserId: myUserId,
          isHost: myUserId == hostId,
          onTitleSubmit: (title) {
            final ws = ref.read(webSocketServiceProvider);
            ws.sendAction('SUBMIT_TITLE', {'title': title});
          },
          onTyping: (isTyping) {
            final ws = ref.read(webSocketServiceProvider);
            ws.sendAction('TYPING', {'is_typing': isTyping});
          },
          onStartGame: () {
            final ws = ref.read(webSocketServiceProvider);
            ws.sendAction('START_ROUND');
          }
        );
      
      case 'SELECTING_ASSIGNER':
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryRed),
              const SizedBox(height: 32),
              Text('Selecting Assigner...', style: Theme.of(context).textTheme.displayMedium),
            ],
          ),
        );

      case 'SELECTING_TARGET':
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryRed),
              const SizedBox(height: 32),
              Text('Selecting Target...', style: Theme.of(context).textTheme.displayMedium),
            ],
          ),
        );

      case 'TITLE_SELECTION':
        final assignerId = engineState['assigner_id'];
        final targetId = engineState['target_id'];
        final amIAssigner = (assignerId == myUserId);
        final assignerName = _getPlayerName(players, assignerId);
        final targetName = _getPlayerName(players, targetId);
        
        if (amIAssigner) {
          final titles = engineState['titles'] as List<dynamic>? ?? [];
          final usedTitles = List<String>.from(engineState['used_titles'] ?? []);
          final availableTitles = titles
              .map((t) => t['text'] as String)
              .where((text) => !usedTitles.contains(text))
              .toList();
          
          return TitleSelectionView(
            key: const ValueKey('titleSelection'),
            assignerName: 'You',
            targetName: targetName,
            availableTitles: availableTitles,
            onTitleSelected: (title) {
              final ws = ref.read(webSocketServiceProvider);
              ws.sendAction('ASSIGN_TITLE', {
                  'title': title
              });
            },
          );
        } else {
          final text = widget.isSecretMode
              ? "Someone is picking a title for $targetName..."
              : "$assignerName is picking a title for $targetName...";
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
      case 'GAME_OVER':
        return _buildResultsView(phase, engineState, players);
        
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildResultsView(String phase, Map<String, dynamic> engineState, List<dynamic> players) {
    // Sort players by score
    final sortedPlayers = List<dynamic>.from(players);
    sortedPlayers.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    
    return Center(
      key: ValueKey(phase),
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
              phase == 'GAME_OVER' ? 'GAME OVER' : 'ROUND COMPLETE',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.successGreen, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 32),
          Text('Leaderboard', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: sortedPlayers.length,
              itemBuilder: (context, index) {
                final p = sortedPlayers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryRed.withOpacity(0.2),
                    child: Text('${index + 1}', style: const TextStyle(color: AppTheme.primaryRed)),
                  ),
                  title: Text(p['name']),
                  trailing: Text('${p['score'] ?? 0} pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                );
              },
            ),
          ),
          if (phase == 'GAME_OVER')
            PrimaryButton(
              text: 'Return to Lobby',
              onPressed: () {
                 context.go('/home');
              },
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Next round starting soon...', style: TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
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
