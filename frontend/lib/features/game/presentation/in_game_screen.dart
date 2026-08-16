import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/primary_button.dart';
import 'package:frontend/core/providers/game_provider.dart';

import 'widgets/title_creation_view.dart';
import 'widgets/title_selection_view.dart';
import 'widgets/voting_view.dart';

// ─── Helper ───────────────────────────────────────────────────────────────────

String _getPlayerName(List<dynamic> players, String? id) {
  if (id == null) return 'Unknown';
  final p = players.cast<Map<String, dynamic>>().firstWhere(
    (p) => p['id'] == id,
    orElse: () => {'name': 'Unknown'},
  );
  return p['name'];
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class InGameScreen extends ConsumerStatefulWidget {
  final bool isSecretMode;
  const InGameScreen({super.key, this.isSecretMode = false});

  @override
  ConsumerState<InGameScreen> createState() => _InGameScreenState();
}

class _InGameScreenState extends ConsumerState<InGameScreen> {
  // BUG-15: Show AFK skip toast
  String? _skippedMessage;

  @override
  void initState() {
    super.initState();
    // Listen for raw websocket events that need imperative UI responses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupEventListeners();
    });
  }

  void _setupEventListeners() {
    final ws = ref.read(webSocketServiceProvider);
    final existingCallback = ws.onMessageReceived;
    ws.onMessageReceived = (event) {
      existingCallback?.call(event);
      if (!mounted) return;
      final eventType = event['event'];
      if (eventType == 'PLAYER_SKIPPED') {
        final msg = event['message'] as String? ?? 'A player was skipped.';
        setState(() => _skippedMessage = msg);
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _skippedMessage = null);
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final gameState  = ref.watch(gameStateProvider);
    final user       = ref.watch(userProvider);
    final engineState = gameState.engineState ?? {};
    final phase      = engineState['phase'] as String? ?? 'TITLE_CREATION';

    // BUG-12: Use secretMode from server state, fall back to widget param
    final secretMode = gameState.secretMode || widget.isSecretMode;

    // BUG-4: Handle game abort
    ref.listen<GameState>(gameStateProvider, (previous, next) {
      if (!previous!.isAborted && next.isAborted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.surfaceCharcoal,
            title: const Text('Game Aborted'),
            content: Text(next.abortMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(gameStateProvider.notifier).reset();
                  ref.read(webSocketServiceProvider).disconnect();
                  context.go('/home');
                },
                child: const Text('OK', style: TextStyle(color: AppTheme.primaryRed)),
              ),
            ],
          ),
        );
      }
      // MISSING-1: Handle Play Again — navigate back if server resets to TITLE_CREATION
      final prevPhase = previous.engineState?['phase'];
      final nextPhase = next.engineState?['phase'];
      if (prevPhase != 'TITLE_CREATION' && nextPhase == 'TITLE_CREATION' &&
          previous.status == 'PLAYING' && next.status == 'PLAYING') {
        // Game was reset — rebuild will handle showing TITLE_CREATION view
      }
    });

    // MISSING-2: Round indicator
    final round    = engineState['round']      as int? ?? 1;
    final maxRound = engineState['max_rounds'] as int? ?? 1;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: phase != 'TITLE_CREATION'
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryRed.withOpacity(0.4)),
                ),
                child: Text(
                  'ROUND $round / $maxRound',
                  style: const TextStyle(fontSize: 12, letterSpacing: 2, color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
                ),
              )
            : Text(
                secretMode ? 'SECRET ROUND' : 'GAME ROUND',
                style: const TextStyle(fontSize: 12, letterSpacing: 2, color: AppTheme.textMuted),
              ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showExitDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: _buildCurrentPhase(phase, engineState, gameState.players, user.id,
                    gameState.typingPlayers, gameState.hostId, secretMode),
              ),
            ),
            // BUG-15: AFK skip toast
            if (_skippedMessage != null)
              Positioned(
                top: 16, left: 24, right: 24,
                child: AnimatedOpacity(
                  opacity: _skippedMessage != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCharcoal,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryRed.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.skip_next, color: AppTheme.primaryRed, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_skippedMessage!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPhase(
    String phase,
    Map<String, dynamic> engineState,
    List<dynamic> players,
    String myUserId,
    List<String> typingPlayers,
    String hostId,
    bool secretMode,
  ) {
    switch (phase) {
      case 'TITLE_CREATION':
        final titles = engineState['titles'] as List<dynamic>? ?? [];
        final typingNames = typingPlayers
            .where((id) => id != myUserId)
            .map((id) => _getPlayerName(players, id))
            .toList();

        return TitleCreationView(
          key: const ValueKey('TITLE_CREATION'),
          totalPlayers: players.length,
          titles: titles,
          players: players,
          typingNames: typingNames,
          myUserId: myUserId,
          isHost: myUserId == hostId,
          onTitleSubmit: (title) => ref.read(webSocketServiceProvider).sendAction('SUBMIT_TITLE', {'title': title}),
          onTyping: (isTyping) => ref.read(webSocketServiceProvider).sendAction('TYPING', {'is_typing': isTyping}),
          onStartGame: () => ref.read(webSocketServiceProvider).sendAction('START_ROUND'),
          // BUG-16: Force start
          onForceStart: () => ref.read(webSocketServiceProvider).sendAction('FORCE_START'),
        );

      case 'SELECTING_ASSIGNER':
        return Center(
          key: const ValueKey('SELECTING_ASSIGNER'),
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
          key: const ValueKey('SELECTING_TARGET'),
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
        final assignerId = engineState['assigner_id'] as String?;
        final targetId   = engineState['target_id']   as String?;
        final amIAssigner = assignerId == myUserId;
        final assignerName = _getPlayerName(players, assignerId);
        final targetName   = _getPlayerName(players, targetId);

        if (amIAssigner) {
          final titles = engineState['titles'] as List<dynamic>? ?? [];
          final usedTitles = List<String>.from(engineState['used_titles'] ?? []);
          final availableTitles = titles
              .map((t) => t['text'] as String)
              .where((text) => !usedTitles.contains(text))
              .toList();

          return TitleSelectionView(
            key: const ValueKey('TITLE_SELECTION_ASSIGNER'),
            assignerName: 'You',
            targetName: targetName,
            availableTitles: availableTitles,
            onTitleSelected: (title) =>
                ref.read(webSocketServiceProvider).sendAction('ASSIGN_TITLE', {'title': title}),
          );
        } else {
          // BUG-12: In secret mode, hide the assigner's name
          final displayName = secretMode ? 'Someone' : assignerName;
          return Center(
            key: const ValueKey('TITLE_SELECTION_WAITING'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppTheme.primaryRed),
                const SizedBox(height: 32),
                Text(
                  '$displayName is picking a title for $targetName...',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ],
            ),
          );
        }

      case 'VOTING':
        final targetId   = engineState['target_id']    as String?;
        final assignerId = engineState['assigner_id']  as String?;
        final title      = engineState['selected_title'] as String? ?? '';
        final targetName = _getPlayerName(players, targetId);
        final votingEndsAt = (engineState['voting_ends_at'] as num?)?.toDouble();

        final amITarget   = targetId   == myUserId;
        final amIAssigner = assignerId == myUserId;

        if (amITarget || amIAssigner) {
          return Center(
            key: const ValueKey('VOTING_WAITING'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('VOTING IN PROGRESS...', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 16),
                Text('Wait for others to vote on "$title" for $targetName.'),
              ],
            ),
          );
        }

        return VotingView(
          key: const ValueKey('VOTING'),
          targetName: targetName,
          title: title,
          votingEndsAt: votingEndsAt,
          onVote: (vote) => ref.read(webSocketServiceProvider).sendAction('VOTE', {'vote': vote}),
        );

      case 'ROUND_RESULTS':
      case 'GAME_OVER':
        return _buildResultsView(phase, engineState, players, myUserId == hostId);

      default:
        return Center(key: const ValueKey('DEFAULT'), child: const CircularProgressIndicator());
    }
  }

  // ─── MISSING-3: Turn summary + leaderboard ────────────────────────────────

  Widget _buildResultsView(String phase, Map<String, dynamic> engineState, List<dynamic> players, bool isHost) {
    final sortedPlayers = List<dynamic>.from(players)
      ..sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    // MISSING-3: last_results from server
    final lastResults = engineState['last_results'] as Map<String, dynamic>?;
    final selectedTitle  = lastResults?['selected_title']  as String?;
    final targetId       = lastResults?['target_id']       as String?;
    final majorityAgrees = lastResults?['majority_agrees'] as bool?;
    final agreeCount     = lastResults?['agree_count']     as int? ?? 0;
    final disagreeCount  = lastResults?['disagree_count']  as int? ?? 0;
    final targetPoints   = lastResults?['target_points']   as int? ?? 0;
    final assignerPoints = lastResults?['assigner_points'] as int? ?? 0;
    final targetName     = _getPlayerName(players, targetId);

    return Center(
      key: ValueKey(phase),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Phase badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              phase == 'GAME_OVER' ? 'GAME OVER' : 'ROUND COMPLETE',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.successGreen, letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // MISSING-3: Turn summary card
          if (lastResults != null && selectedTitle != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCharcoal,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '"$selectedTitle"',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.primaryRed, fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Was given to $targetName',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _VoteCountBadge(label: 'Agree', count: agreeCount, color: AppTheme.successGreen),
                      _VoteCountBadge(label: 'Disagree', count: disagreeCount, color: AppTheme.primaryRed),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (majorityAgrees ?? false) ? AppTheme.successGreen.withOpacity(0.15) : AppTheme.primaryRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (majorityAgrees ?? false)
                          ? '✓ Majority Agrees! +$targetPoints pts for target, +$assignerPoints pts for assigner'
                          : '✗ Majority Disagrees. $assignerPoints pts for assigner',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: (majorityAgrees ?? false) ? AppTheme.successGreen : AppTheme.primaryRed,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Leaderboard
          Text('Leaderboard', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 16),
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
                  trailing: Text(
                    '${p['score'] ?? 0} pts',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                  ),
                );
              },
            ),
          ),

          // Actions
          if (phase == 'GAME_OVER') ...[
            if (isHost)
              PrimaryButton(
                text: 'Play Again',
                onPressed: () => ref.read(webSocketServiceProvider).sendAction('RESET_GAME'),
              )
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Waiting for host to start again...', style: TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(webSocketServiceProvider).disconnect();
                  ref.read(gameStateProvider.notifier).reset();
                  context.go('/home');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textMuted,
                  side: const BorderSide(color: Color(0xFF2A2A2A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Return to Home'),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Next round starting soon...', style: TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
            ),
          const SizedBox(height: 16),
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
              ref.read(webSocketServiceProvider).disconnect();
              ref.read(gameStateProvider.notifier).reset();
              context.go('/home');
            },
            child: const Text('Leave', style: TextStyle(color: AppTheme.primaryRed)),
          ),
        ],
      ),
    );
  }
}

// ─── Small helper widget ──────────────────────────────────────────────────────

class _VoteCountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _VoteCountBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
