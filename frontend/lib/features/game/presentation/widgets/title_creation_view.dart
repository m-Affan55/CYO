import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class TitleCreationView extends StatefulWidget {
  final bool hasSubmitted;
  final int titlesSubmitted;
  final int totalPlayers;
  final Function(String) onTitleSubmit;

  const TitleCreationView({
    super.key,
    required this.hasSubmitted,
    required this.titlesSubmitted,
    required this.totalPlayers,
    required this.onTitleSubmit,
  });

  @override
  State<TitleCreationView> createState() => _TitleCreationViewState();
}

class _TitleCreationViewState extends State<TitleCreationView> {
  final TextEditingController _controller = TextEditingController();

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
      ],
    );
  }
}
