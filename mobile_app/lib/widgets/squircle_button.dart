import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';

class SquircleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final TextStyle? labelStyle;

  const SquircleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 200,
    this.height = 50,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Theme.of(context).primaryColor,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: height / 2,
              cornerSmoothing: 0.8,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: (labelStyle ?? const TextStyle()).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
