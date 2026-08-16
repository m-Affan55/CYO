import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/primary_button.dart';

class TitleCreationView extends StatefulWidget {
  final int totalPlayers;        // All players (including disconnected)
  final List<dynamic> titles;
  final List<dynamic> players;   // Full player list with is_connected flags
  final List<String> typingNames;
  final String myUserId;
  final bool isHost;
  final Function(String) onTitleSubmit;
  final Function(bool) onTyping;
  final VoidCallback onStartGame;
  final VoidCallback onForceStart; // BUG-16: Force start callback

  const TitleCreationView({
    super.key,
    required this.totalPlayers,
    required this.titles,
    required this.players,
    required this.typingNames,
    required this.myUserId,
    required this.isHost,
    required this.onTitleSubmit,
    required this.onTyping,
    required this.onStartGame,
    required this.onForceStart,
  });

  @override
  State<TitleCreationView> createState() => _TitleCreationViewState();
}

class _TitleCreationViewState extends State<TitleCreationView> {
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;

  // BUG-16: Track time since screen was shown for the Force Start escape hatch
  Timer? _forceStartTimer;
  bool _forceStartAvailable = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);

    // BUG-16: After 90 seconds, reveal the Force Start option for the host
    if (widget.isHost) {
      _forceStartTimer = Timer(const Duration(seconds: 90), () {
        if (mounted) {
          setState(() => _forceStartAvailable = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _forceStartTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _isTyping) {
      _isTyping = hasText;
      widget.onTyping(_isTyping);
    }
  }

  void _submit() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onTitleSubmit(_controller.text.trim());
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uniqueSubmitters = widget.titles.map((t) => t['author_id'] as String).toSet();

    // BUG-14: canStart counts only CONNECTED players, not disconnected ones
    final connectedCount = widget.players
        .where((p) => p['is_connected'] == true)
        .length;
    final canStart = uniqueSubmitters.length >= connectedCount && connectedCount >= 3;

    final myTitlesCount = widget.titles.where((t) => t['author_id'] == widget.myUserId).length;

    // BUG-16: Force start is available if 90s elapsed AND at least majority submitted
    final majority = (connectedCount ~/ 2) + 1;
    final canForceStart = _forceStartAvailable &&
        widget.isHost &&
        uniqueSubmitters.length >= majority &&
        !canStart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CREATE TITLES',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.primaryRed,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add titles to the pool.',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Everyone must submit at least 1 title.\nYou have submitted $myTitlesCount title(s).',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 32),

        // Input row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'E.g., "Always Late"',
                  filled: true,
                  fillColor: AppTheme.surfaceCharcoal,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryRed)),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _submit,
              child: Container(
                height: 56, width: 56,
                decoration: BoxDecoration(color: AppTheme.primaryRed, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.send, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),

        // Typing indicator
        if (widget.typingNames.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textMuted),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.typingNames.join(', ')} is typing a title...',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 32),

        // Title pool list
        Expanded(
          child: ListView.separated(
            itemCount: widget.titles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final titleObj  = widget.titles[index];
              final authorId  = titleObj['author_id'];
              final titleText = titleObj['text'];

              final authorData = widget.players.cast<Map<String, dynamic>>().firstWhere(
                (p) => p['id'] == authorId,
                orElse: () => {'name': 'Unknown'},
              );

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCharcoal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Text('"$titleText" (by ${authorData['name']})', style: Theme.of(context).textTheme.bodyLarge),
              );
            },
          ),
        ),

        // ── Host controls ──
        if (widget.isHost) ...[
          const SizedBox(height: 16),
          PrimaryButton(
            text: canStart ? 'Start Game' : 'Waiting for everyone to submit... (${ uniqueSubmitters.length}/$connectedCount)',
            onPressed: canStart ? widget.onStartGame : () {},
            color: canStart ? AppTheme.primaryRed : AppTheme.surfaceCharcoal,
          ),

          // BUG-16: Force Start escape hatch (appears after 90s if majority submitted)
          if (canForceStart) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: widget.onForceStart,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryRed,
                side: const BorderSide(color: AppTheme.primaryRed),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.skip_next, size: 18),
                  const SizedBox(width: 8),
                  Text('Force Start (${uniqueSubmitters.length}/$connectedCount submitted)', 
                       style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Players who haven\'t submitted will be skipped as assigner.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.textMuted, fontSize: 11,
              ),
            ),
          ],

          // Timer hint for force start
          if (widget.isHost && !canStart && !_forceStartAvailable) ...[
            const SizedBox(height: 8),
            Text(
              'Force Start will be available after 90 seconds if someone is AFK.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.textMuted, fontSize: 11,
              ),
            ),
          ],
        ] else ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Text(
              canStart ? 'Waiting for host to start...' : 'Waiting for everyone to submit...',
              style: const TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ],
    );
  }
}
