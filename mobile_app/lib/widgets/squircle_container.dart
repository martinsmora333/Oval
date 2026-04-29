import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';

class SquircleContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double cornerRadius;
  final double cornerSmoothing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final AlignmentGeometry? alignment;
  final double? elevation;

  const SquircleContainer({
    super.key,
    required this.child,
    this.color,
    this.cornerRadius = 16.0,
    this.cornerSmoothing = 0.6,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.border,
    this.boxShadow,
    this.alignment,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      alignment: alignment,
      decoration: ShapeDecoration(
        color: color,
        shadows: elevation != null ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: elevation! * 3,
            offset: Offset(0, elevation! * 0.5),
          ),
        ] : boxShadow,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: cornerRadius,
            cornerSmoothing: cornerSmoothing,
          ),
          side: border != null ? BorderSide(
            color: (border as Border).top.color,
            width: (border as Border).top.width,
            style: (border as Border).top.style,
          ) : BorderSide.none,
        ),
      ),
      child: child,
    );
  }
}