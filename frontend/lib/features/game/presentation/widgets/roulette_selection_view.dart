import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/primary_button.dart';

class RouletteSelectionView extends StatefulWidget {
  final String prompt;
  final List<String> players;
  final String finalSelection;
  final VoidCallback onComplete;

  const RouletteSelectionView({
    super.key,
    required this.prompt,
    required this.players,
    required this.finalSelection,
    required this.onComplete,
  });

  @override
  State<RouletteSelectionView> createState() => _RouletteSelectionViewState();
}

class _RouletteSelectionViewState extends State<RouletteSelectionView> {
  int _currentIndex = 0;
  Timer? _timer;
  bool _isFinished = false;
  double _speed = 50.0;

  @override
  void initState() {
    super.initState();
    _startRoulette();
  }

  void _startRoulette() {
    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    _timer = Timer(Duration(milliseconds: _speed.toInt()), () {
      if (!mounted) return;

      setState(() {
        // Cycle through random players
        _currentIndex = Random().nextInt(widget.players.length);
      });

      // Slow down over time
      _speed *= 1.1;

      if (_speed > 400) {
        // Stop on the final selection
        setState(() {
          _currentIndex = widget.players.indexOf(widget.finalSelection);
          _isFinished = true;
        });
        
        // Wait a beat, then complete
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) widget.onComplete();
        });
      } else {
        _scheduleNextTick();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayerName = widget.players.isNotEmpty ? widget.players[_currentIndex] : '';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.prompt,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(_isFinished ? 32 : 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isFinished ? AppTheme.primaryRed.withOpacity(0.2) : AppTheme.surfaceCharcoal,
              border: Border.all(
                color: _isFinished ? AppTheme.primaryRed : const Color(0xFF2A2A2A),
                width: _isFinished ? 4 : 1,
              ),
              boxShadow: _isFinished
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryRed.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      )
                    ]
                  : [],
            ),
            child: CircleAvatar(
              radius: _isFinished ? 80 : 60,
              backgroundColor: AppTheme.backgroundBlack,
              child: Text(
                currentPlayerName.isNotEmpty ? currentPlayerName.substring(0, 2).toUpperCase() : '?',
                style: TextStyle(
                  fontSize: _isFinished ? 48 : 32,
                  fontWeight: FontWeight.w900,
                  color: _isFinished ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
              color: _isFinished ? AppTheme.primaryRed : AppTheme.textPrimary,
              fontSize: _isFinished ? 40 : 28,
            ),
            child: Text(currentPlayerName),
          ),
          
          if (_isFinished) ...[
            const SizedBox(height: 48),
            PrimaryButton(text: 'Continue', onPressed: widget.onComplete),
          ]
        ],
      ),
    );
  }
}
