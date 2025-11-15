import 'dart:math';
import 'package:flutter/material.dart';

/// A container that displays an animated glowing border, inspired by CSS glow effects.
///
/// This widget uses a CustomPainter with a rotating SweepGradient to create two
/// "comets" of light that flow in a single direction on opposite sides of the border.
class GlowingContainer extends StatefulWidget {
  final Widget? child;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final BorderRadiusGeometry borderRadius;
  final Color glowColor;
  /// The thickness of the border where the glow is visible.
  final double borderWidth;
  /// The thickness of the glowing bars themselves.
  final double glowBarWidth;
  final Duration animationDuration;
  final bool enableAnimation;

  const GlowingContainer({
    super.key,
    this.child,
    this.width = 190,
    this.height = 254,
    this.padding = const EdgeInsets.all(8),
    this.backgroundColor = const Color(0xFF151515),
    this.borderRadius = const BorderRadius.all(Radius.circular(5)),
    this.glowColor = const Color(0xFFFF9966),
    this.borderWidth = 2.0,
    this.glowBarWidth = 6.0,
    this.animationDuration = const Duration(milliseconds: 5000),
    this.enableAnimation = true,
  });

  @override
  State<GlowingContainer> createState() => _GlowingContainerState();
}

class _GlowingContainerState extends State<GlowingContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    if (widget.enableAnimation) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(GlowingContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationDuration != widget.animationDuration) {
      _controller.duration = widget.animationDuration;
      if (widget.enableAnimation) {
        _controller.repeat();
      }
    }
    if (oldWidget.enableAnimation != widget.enableAnimation) {
      if (widget.enableAnimation) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedBorderRadius = widget.borderRadius.resolve(Directionality.of(context));

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        // The outer clip needs a slightly larger radius to contain the glow effect
        borderRadius: resolvedBorderRadius.add(BorderRadius.all(Radius.circular(widget.borderWidth))),
        child: Stack(
          children: [
            // Glow border painter
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _GlowingRectPainter(
                      progress: _controller.value,
                      glowColor: widget.glowColor,
                      glowWidth: widget.glowBarWidth,
                      borderRadius: resolvedBorderRadius,
                    ),
                  );
                },
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(widget.borderWidth),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: widget.borderRadius,
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
  final BorderRadius borderRadius;

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
          // This configuration creates two opposite bars of light
          Colors.transparent,
          glowColor,
          glowColor,
          Colors.transparent, // Gap between bars
          Colors.transparent,
          glowColor,
          glowColor,
          Colors.transparent,
        ],
        stops: const [
          0.0,    // Start of gap
          0.05,   // Start of first bar
          0.15,   // End of first bar (10% of the circumference)
          0.5,    // End of first gap (at the halfway point)
          0.5,    // Start of second gap
          0.55,   // Start of second bar
          0.65,   // End of second bar (10% of the circumference)
          1.0,    // End of second gap
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Deflate the rect to account for the stroke width, so the glow is on the edge
    final rrect = borderRadius.toRRect(rect).deflate(glowWidth / 2);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowingRectPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
