import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Color activeColor;

  const AnimatedCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor = AppTheme.success,
  });

  @override
  State<AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<AnimatedCheckbox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onChanged != null) {
      widget.onChanged!(!widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.value ? widget.activeColor : Theme.of(context).unselectedWidgetColor,
                width: 2,
              ),
              color: Color.lerp(Colors.transparent, widget.activeColor, _animation.value),
            ),
            child: CustomPaint(
              painter: _CheckmarkPainter(progress: _animation.value),
            ),
          );
        },
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;

  _CheckmarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final start = Offset(size.width * 0.25, size.height * 0.5);
    final mid = Offset(size.width * 0.45, size.height * 0.7);
    final end = Offset(size.width * 0.75, size.height * 0.3);

    path.moveTo(start.dx, start.dy);
    
    // Draw first segment (down)
    if (progress < 0.5) {
      final p1 = progress * 2;
      path.lineTo(
        start.dx + (mid.dx - start.dx) * p1,
        start.dy + (mid.dy - start.dy) * p1,
      );
    } else {
      path.lineTo(mid.dx, mid.dy);
      // Draw second segment (up)
      final p2 = (progress - 0.5) * 2;
      path.lineTo(
        mid.dx + (end.dx - mid.dx) * p2,
        mid.dy + (end.dy - mid.dy) * p2,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
