import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum TimerPhase { focus, shortBreak, longBreak }

class CircularTimer extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final String timeFormatted;
  final TimerPhase phase;
  final double size;

  const CircularTimer({
    super.key,
    required this.progress,
    required this.timeFormatted,
    required this.phase,
    this.size = 280.0,
  });

  @override
  State<CircularTimer> createState() => _CircularTimerState();
}

class _CircularTimerState extends State<CircularTimer> with SingleTickerProviderStateMixin {
  late AnimationController _startupController;
  late Animation<double> _startupAnimation;
  String _lastMinute = '';

  @override
  void initState() {
    super.initState();
    _lastMinute = widget.timeFormatted.split(':')[0];
    
    _startupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _startupAnimation = CurvedAnimation(parent: _startupController, curve: Curves.easeOutCubic);
    _startupController.forward();
  }

  @override
  void didUpdateWidget(CircularTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentMinute = widget.timeFormatted.split(':')[0];
    if (currentMinute != _lastMinute) {
      _lastMinute = currentMinute;
      // Fade animation is handled implicitly by AnimatedSwitcher in build
    }
    
    if (oldWidget.phase != widget.phase) {
       _startupController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _startupController.dispose();
    super.dispose();
  }

  Color get _phaseColor {
    switch (widget.phase) {
      case TimerPhase.focus:
        return AppTheme.primaryColor;
      case TimerPhase.shortBreak:
        return AppTheme.success;
      case TimerPhase.longBreak:
        return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? AppTheme.surfaceDark : AppTheme.surface2Light;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _startupAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _TimerPainter(
              progress: widget.progress * _startupAnimation.value,
              color: _phaseColor,
              trackColor: trackColor,
              strokeWidth: 10.0,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  widget.timeFormatted,
                  key: ValueKey<String>(widget.timeFormatted.split(':')[0]), // Animate only when minute changes
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 56,
                        color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _TimerPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Draw progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, // Start at top
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.trackColor != trackColor;
  }
}
