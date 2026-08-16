import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/primary_button.dart';

class TitleCreationView extends StatefulWidget {
  final int totalPlayers;
  final List<dynamic> titles;
  final List<dynamic> players;
  final List<String> typingNames;
  final String myUserId;
  final bool isHost;
  final Function(String) onTitleSubmit;
  final Function(bool) onTyping;
  final VoidCallback onStartGame;

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
  });

  @override
  State<TitleCreationView> createState() => _TitleCreationViewState();
}

class _TitleCreationViewState extends State<TitleCreationView> {
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;
  
  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }
  
  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
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
    final canStart = uniqueSubmitters.length >= widget.totalPlayers && widget.totalPlayers >= 3;
    final myTitlesCount = widget.titles.where((t) => t['author_id'] == widget.myUserId).length;

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
            )
          ],
        ),
        
        if (widget.typingNames.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(
                width: 12,
                height: 12,
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
        
        // List of added titles
        Expanded(
          child: ListView.separated(
            itemCount: widget.titles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final titleObj = widget.titles[index];
              final authorId = titleObj['author_id'];
              final titleText = titleObj['text'];
              
              String authorName = 'Unknown';
              final authorData = widget.players.cast<Map<String, dynamic>>().firstWhere(
                (p) => p['id'] == authorId, 
                orElse: () => {'name': 'Unknown'}
              );
              authorName = authorData['name'];
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCharcoal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Text('"$titleText" (by $authorName)', style: Theme.of(context).textTheme.bodyLarge),
              );
            },
          ),
        ),
        
        if (widget.isHost) ...[
          const SizedBox(height: 16),
          PrimaryButton(
            text: canStart ? 'Start Game' : 'Waiting for everyone to submit...',
            onPressed: canStart ? widget.onStartGame : () {},
            color: canStart ? AppTheme.primaryRed : AppTheme.surfaceCharcoal,
          ),
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
