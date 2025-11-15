import 'dart:math';
import 'package:flutter/material.dart';

class RectGlowBorder extends StatefulWidget {
  final Widget child;
  final double width, height;
  final Color glowColor;
  final double glowBarWidth; // thickness of moving glow
  final double borderWidth;  // spacing from edge
  final Duration duration;

  const RectGlowBorder({
    super.key,
    required this.child,
    this.width = 190,
    this.height = 254,
    this.glowColor = const Color(0xFFFF9966),
    this.glowBarWidth = 6,
    this.borderWidth = 2,
    this.duration = const Duration(seconds: 5),
  });

  @override
  State<RectGlowBorder> createState() => _RectGlowBorderState();
}

class _RectGlowBorderState extends State<RectGlowBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //final size = Size(widget.width, widget.height);
    final radius = Radius.circular(5);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5 + widget.borderWidth),
        child: Stack(
          children: [
            // Glow border
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _GlowingRectPainter(
                      progress: _controller.value,
                      glowColor: widget.glowColor,
                      glowWidth: widget.glowBarWidth,
                      borderRadius: radius,
                    ),
                  );
                },
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(widget.borderWidth),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.7),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    )
                  ],
                ),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowingRectPainter extends CustomPainter {
  final double progress;
  final Color glowColor;
  final double glowWidth;
  final Radius borderRadius;

  _GlowingRectPainter({
    required this.progress,
    required this.glowColor,
    required this.glowWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final Paint paint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * pi,
        transform: GradientRotation(progress * 2 * pi),
        colors: [
          Colors.transparent,
          glowColor,
          glowColor,
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.8, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final rrect = RRect.fromRectAndRadius(
      rect.deflate(glowWidth / 2),
      borderRadius,
    );

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowingRectPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
