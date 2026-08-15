import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class TitleCreationView extends StatefulWidget {
  final bool hasSubmitted;
  final int titlesSubmitted;
  final int totalPlayers;
  final Map<String, dynamic> titlesMap;
  final List<dynamic> players;
  final List<String> typingNames;
  final Function(String) onTitleSubmit;
  final Function(bool) onTyping;

  const TitleCreationView({
    super.key,
    required this.hasSubmitted,
    required this.titlesSubmitted,
    required this.totalPlayers,
    required this.titlesMap,
    required this.players,
    required this.typingNames,
    required this.onTitleSubmit,
    required this.onTyping,
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
    if (_controller.text.trim().isNotEmpty && !widget.hasSubmitted) {
      widget.onTitleSubmit(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Add a title to the pool.',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Everyone needs to submit one title to start.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 32),
        
        if (!widget.hasSubmitted) ...[
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
        ] else ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.surfaceCharcoal, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text("Title submitted! Waiting for others...")),
          ),
        ],
        
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
        
        // Progress
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pool Progress', style: Theme.of(context).textTheme.labelLarge),
            Text('${widget.titlesSubmitted} / ${widget.totalPlayers}', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primaryRed)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: widget.totalPlayers == 0 ? 0 : widget.titlesSubmitted / widget.totalPlayers,
          backgroundColor: AppTheme.surfaceCharcoal,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 32),
        
        // List of added titles
        Expanded(
          child: ListView.separated(
            itemCount: widget.titlesMap.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final authorId = widget.titlesMap.keys.elementAt(index);
              final title = widget.titlesMap.values.elementAt(index);
              
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
                child: Text('"$title" (by $authorName)', style: Theme.of(context).textTheme.bodyLarge),
              );
            },
          ),
        ),
      ],
    );
  }
}
