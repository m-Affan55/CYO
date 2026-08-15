import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/primary_button.dart';

class TitleCreationView extends StatefulWidget {
  final VoidCallback onReady;

  const TitleCreationView({super.key, required this.onReady});

  @override
  State<TitleCreationView> createState() => _TitleCreationViewState();
}

class _TitleCreationViewState extends State<TitleCreationView> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _titles = [];
  final int _minTitles = 6;

  void _addTitle() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() {
        _titles.add(_controller.text.trim());
        _controller.clear();
      });
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
          'Add titles to the pool.',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Everyone is adding titles right now. You need at least $_minTitles total to start.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 32),
        
        // Input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'E.g., "Always Late", "Code Wizard"',
                  filled: true,
                  fillColor: AppTheme.surfaceCharcoal,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryRed),
                  ),
                ),
                onSubmitted: (_) => _addTitle(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _addTitle,
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: AppTheme.textPrimary),
              ),
            )
          ],
        ),
        const SizedBox(height: 32),
        
        // Progress
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pool Progress', style: Theme.of(context).textTheme.labelLarge),
            Text('${_titles.length} / $_minTitles', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primaryRed)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_titles.length / _minTitles).clamp(0.0, 1.0),
          backgroundColor: AppTheme.surfaceCharcoal,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 32),
        
        // List of added titles
        Expanded(
          child: ListView.separated(
            itemCount: _titles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCharcoal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Text(_titles[index]),
              );
            },
          ),
        ),
        
        // Button
        PrimaryButton(
          text: _titles.length >= _minTitles ? 'Ready to Start' : 'Waiting for more titles...',
          onPressed: _titles.length >= _minTitles ? widget.onReady : () {},
          color: _titles.length >= _minTitles ? AppTheme.primaryRed : AppTheme.surfaceCharcoal,
        ),
      ],
    );
  }
}
