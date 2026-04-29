import 'package:flutter/material.dart';

class SquircleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final Function()? onTap;
  final bool readOnly;
  final double cornerRadius;
  final double cornerSmoothing;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final bool filled;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final int? maxLines;
  final int? minLines;
  final bool? enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  final BoxBorder? border;
  final TextCapitalization textCapitalization;

  const SquircleTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.onTap,
    this.readOnly = false,
    this.cornerRadius = 16.0,
    this.cornerSmoothing = 0.6,
    this.contentPadding,
    this.fillColor,
    this.filled = true,
    this.style,
    this.hintStyle,
    this.labelStyle,
    this.maxLines = 1,
    this.minLines,
    this.enabled,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.border,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      onTap: onTap,
      readOnly: readOnly,
      style: style,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: filled,
        fillColor: fillColor ?? Theme.of(context).cardColor,
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: hintStyle,
        labelStyle: labelStyle,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(
            Radius.circular(cornerRadius),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: border != null ? (border as Border).top : BorderSide.none,
          borderRadius: BorderRadius.all(
            Radius.circular(cornerRadius),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: border != null ? (border as Border).top : BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(cornerRadius),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(cornerRadius),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2.0,
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(cornerRadius),
          ),
        ),
      ),
    );
  }
}