import 'dart:math';
import 'package:flutter/material.dart';

enum ShadowAlignment {
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}

class GlowingContainer extends StatefulWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final BorderRadiusGeometry borderRadius;
  final Color glowColor;
  final Color? secondaryGlowColor;
  final bool showGlow;
  final bool showShadow;
  final List<BoxShadow>? customBoxShadow;
  
  // Enhanced shadow properties
  final Color shadowColor;
  final Color? secondaryShadowColor;
  final double shadowBlurRadius;
  final double shadowSpreadRadius;
  final ShadowAlignment shadowAlignment;
  final double shadowOffsetDistance;
  
  // Animation properties
  final Duration animationDuration;
  final bool enableAnimation;
  final double glowWidth;
  final double glowIntensity;
  
  // Border properties
  final double borderWidth;
  final List<Color>? gradientColors;
  final List<double>? gradientStops;

  const GlowingContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(8),
    this.backgroundColor = const Color(0xFF151515),
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.glowColor = const Color(0xFFFF9966),
    this.secondaryGlowColor,
    this.showGlow = true,
    this.showShadow = true,
    this.customBoxShadow,
    this.shadowColor = const Color(0xFFFF9966),
    this.secondaryShadowColor,
    this.shadowBlurRadius = 12.0,
    this.shadowSpreadRadius = 0.0,
    this.shadowAlignment = ShadowAlignment.center,
    this.shadowOffsetDistance = 4.0,
    this.animationDuration = const Duration(seconds: 3),
    this.enableAnimation = true,
    this.glowWidth = 2.0,
    this.glowIntensity = 0.8,
    this.borderWidth = 2.0,
    this.gradientColors,
    this.gradientStops,
  }) : assert(glowIntensity >= 0.0 && glowIntensity <= 2.0, 'glowIntensity must be between 0.0 and 2.0'),
       assert(borderWidth >= 0.0, 'borderWidth must be non-negative'),
       assert(glowWidth >= 0.0, 'glowWidth must be non-negative'),
       assert(shadowBlurRadius >= 0.0, 'shadowBlurRadius must be non-negative'),
       assert(shadowSpreadRadius >= 0.0, 'shadowSpreadRadius must be non-negative'),
       assert(shadowOffsetDistance >= 0.0, 'shadowOffsetDistance must be non-negative');

  @override
  State<GlowingContainer> createState() => _GlowingContainerState();
}

class _GlowingContainerState extends State<GlowingContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    if (widget.enableAnimation) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(GlowingContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle animation duration changes
    if (oldWidget.animationDuration != widget.animationDuration) {
      _controller.duration = widget.animationDuration;
    }
    
    // Handle animation state changes
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

  Offset _getShadowOffset() {
    const sqrt2 = 1.4142135623730951; // More precise sqrt(2)
    
    switch (widget.shadowAlignment) {
      case ShadowAlignment.top:
        return Offset(0, -widget.shadowOffsetDistance);
      case ShadowAlignment.bottom:
        return Offset(0, widget.shadowOffsetDistance);
      case ShadowAlignment.left:
        return Offset(-widget.shadowOffsetDistance, 0);
      case ShadowAlignment.right:
        return Offset(widget.shadowOffsetDistance, 0);
      case ShadowAlignment.topLeft:
        return Offset(
          -widget.shadowOffsetDistance / sqrt2, 
          -widget.shadowOffsetDistance / sqrt2
        );
      case ShadowAlignment.topRight:
        return Offset(
          widget.shadowOffsetDistance / sqrt2, 
          -widget.shadowOffsetDistance / sqrt2
        );
      case ShadowAlignment.bottomLeft:
        return Offset(
          -widget.shadowOffsetDistance / sqrt2, 
          widget.shadowOffsetDistance / sqrt2
        );
      case ShadowAlignment.bottomRight:
        return Offset(
          widget.shadowOffsetDistance / sqrt2, 
          widget.shadowOffsetDistance / sqrt2
        );
      case ShadowAlignment.center:
        return const Offset(0, 0);
    }
  }

  List<BoxShadow> _buildBoxShadows() {
    if (widget.customBoxShadow != null) {
      return widget.customBoxShadow!;
    }

    if (!widget.showShadow) {
      return [];
    }

    final List<BoxShadow> shadows = [];
    final shadowOffset = _getShadowOffset();
    
    // Primary shadow
    shadows.add(BoxShadow(
      color: widget.shadowColor.withAlpha((255 * 0.4).round()),
      blurRadius: widget.shadowBlurRadius,
      spreadRadius: widget.shadowSpreadRadius,
      offset: shadowOffset,
    ));
    
    // Secondary shadow if provided
    if (widget.secondaryShadowColor != null) {
      shadows.add(BoxShadow(
        color: widget.secondaryShadowColor!.withAlpha((255 * 0.2).round()),
        blurRadius: widget.shadowBlurRadius * 1.5,
        spreadRadius: widget.shadowSpreadRadius + 2,
        offset: shadowOffset * 1.2,
      ));
    }
    
    // Glow shadow effect
    if (widget.showGlow) {
      shadows.add(BoxShadow(
        color: widget.glowColor.withAlpha((255 * widget.glowIntensity * 0.3).round()),
        blurRadius: widget.shadowBlurRadius * 2,
        spreadRadius: widget.shadowSpreadRadius + 4,
        offset: Offset.zero,
      ));
    }
    
    return shadows;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius,
            boxShadow: _buildBoxShadows(),
          ),
          child: Stack(
            children: [
              // Animated glowing border
              if (widget.showGlow && widget.enableAnimation)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GlowBorderPainter(
                      progress: _rotationAnimation.value,
                      borderRadius: widget.borderRadius,
                      glowColor: widget.glowColor,
                      secondaryGlowColor: widget.secondaryGlowColor,
                      borderWidth: widget.borderWidth,
                      glowWidth: widget.glowWidth,
                      glowIntensity: widget.glowIntensity,
                      gradientColors: widget.gradientColors,
                      gradientStops: widget.gradientStops,
                    ),
                  ),
                ),
              
              // Static glow border (when animation is disabled)
              if (widget.showGlow && !widget.enableAnimation)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: widget.borderRadius,
                      border: Border.all(
                        color: widget.glowColor.withAlpha(
                          (255 * widget.glowIntensity).round().clamp(0, 255)
                        ),
                        width: widget.borderWidth,
                      ),
                    ),
                  ),
                ),
              
              // Content container
              Container(
                padding: widget.padding,
                child: widget.child,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowBorderPainter extends CustomPainter {
  final double progress;
  final BorderRadiusGeometry borderRadius;
  final Color glowColor;
  final Color? secondaryGlowColor;
  final double borderWidth;
  final double glowWidth;
  final double glowIntensity;
  final List<Color>? gradientColors;
  final List<double>? gradientStops;

  const _GlowBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.glowColor,
    this.secondaryGlowColor,
    required this.borderWidth,
    required this.glowWidth,
    required this.glowIntensity,
    this.gradientColors,
    this.gradientStops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Create the rotating gradient with proper opacity handling
    final List<Color> colors = gradientColors ?? _createDefaultColors();
    final List<double> stops = gradientStops ?? _createDefaultStops();
    
    // Validate stops array
    if (stops.length != colors.length) {
      debugPrint('Warning: gradientStops length does not match gradientColors length');
      return;
    }
    
    // Create multiple paint layers for better glow effect
    final paints = _createPaintLayers(rect, colors, stops);
    
    // Get the resolved border radius
    final resolvedBorderRadius = borderRadius.resolve(TextDirection.ltr);
    
    // Draw each paint layer
    for (final paint in paints) {
      _drawBorderLayer(canvas, rect, paint, resolvedBorderRadius);
    }
  }

  List<Color> _createDefaultColors() {
    return [
      Colors.transparent,
      glowColor.withAlpha((255 * glowIntensity * 0.3).round()),
      glowColor.withAlpha((255 * glowIntensity).round()),
      (secondaryGlowColor ?? glowColor).withAlpha(
        (255 * glowIntensity * 0.8).round()
      ),
      glowColor.withAlpha((255 * glowIntensity).round()),
      glowColor.withAlpha((255 * glowIntensity * 0.3).round()),
      Colors.transparent,
    ];
  }

  List<double> _createDefaultStops() {
    return const [0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0];
  }

  List<Paint> _createPaintLayers(Rect rect, List<Color> colors, List<double> stops) {
    final paints = <Paint>[];
    
    // Outer glow
    paints.add(Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: progress,
        endAngle: progress + (2 * pi),
        colors: colors.map((c) => 
          c.withAlpha((c.alpha * 0.3).round().clamp(0, 255))
        ).toList(),
        stops: stops,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + glowWidth * 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    
    // Main glow
    paints.add(Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: progress,
        endAngle: progress + (2 * pi),
        colors: colors,
        stops: stops,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + glowWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1));
    
    // Core border
    paints.add(Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: progress,
        endAngle: progress + (2 * pi),
        colors: colors.map((c) => 
          c.withAlpha((c.alpha * 1.2).round().clamp(0, 255))
        ).toList(),
        stops: stops,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth);

    return paints;
  }

  void _drawBorderLayer(Canvas canvas, Rect rect, Paint paint, BorderRadius resolvedBorderRadius) {
    final strokeWidth = paint.strokeWidth;
    final adjustedRect = rect.deflate(strokeWidth / 2);
    
    if (adjustedRect.width <= 0 || adjustedRect.height <= 0) return;
    
    if (resolvedBorderRadius == BorderRadius.zero) {
      canvas.drawRect(adjustedRect, paint);
    } else {
      final rrect = RRect.fromRectAndCorners(
        adjustedRect,
        topLeft: resolvedBorderRadius.topLeft,
        topRight: resolvedBorderRadius.topRight,
        bottomLeft: resolvedBorderRadius.bottomLeft,
        bottomRight: resolvedBorderRadius.bottomRight,
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.secondaryGlowColor != secondaryGlowColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.glowWidth != glowWidth ||
        oldDelegate.glowIntensity != glowIntensity ||
        !_listEquals(oldDelegate.gradientColors, gradientColors) ||
        !_listEquals(oldDelegate.gradientStops, gradientStops);
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/* 
// Example usage in your app:
GlowingContainer(
  width: 200,
  height: 150,
  glowColor: Colors.blue,
  shadowAlignment: ShadowAlignment.bottom,
  shadowOffsetDistance: 8,
  child: YourWidget(),
)
*/