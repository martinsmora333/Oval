import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'responsive_utils.dart';

/// A class for creating responsive text themes and styles
class ResponsiveTheme {
  /// Creates a responsive text theme based on the device size
  static TextTheme getResponsiveTextTheme(BuildContext context) {
    // Ensure responsive utils are initialized
    ResponsiveUtils.init(context);
    
    // Base theme to adapt
    final baseTheme = Theme.of(context).textTheme;
    
    // Return a responsive text theme
    return TextTheme(
      displayLarge: _getResponsiveStyle(baseTheme.displayLarge, 32),
      displayMedium: _getResponsiveStyle(baseTheme.displayMedium, 28),
      displaySmall: _getResponsiveStyle(baseTheme.displaySmall, 24),
      
      headlineLarge: _getResponsiveStyle(baseTheme.headlineLarge, 22),
      headlineMedium: _getResponsiveStyle(baseTheme.headlineMedium, 20),
      headlineSmall: _getResponsiveStyle(baseTheme.headlineSmall, 18),
      
      titleLarge: _getResponsiveStyle(baseTheme.titleLarge, 18),
      titleMedium: _getResponsiveStyle(baseTheme.titleMedium, 16),
      titleSmall: _getResponsiveStyle(baseTheme.titleSmall, 14),
      
      bodyLarge: _getResponsiveStyle(baseTheme.bodyLarge, 16),
      bodyMedium: _getResponsiveStyle(baseTheme.bodyMedium, 14),
      bodySmall: _getResponsiveStyle(baseTheme.bodySmall, 12),
      
      labelLarge: _getResponsiveStyle(baseTheme.labelLarge, 16),
      labelMedium: _getResponsiveStyle(baseTheme.labelMedium, 14),
      labelSmall: _getResponsiveStyle(baseTheme.labelSmall, 12),
    );
  }
  
  /// Create responsive buttons
  static ElevatedButtonThemeData elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(Size(88, ResponsiveUtils.buttonHeight)),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.blockSizeHorizontal * 4,
          ),
        ),
        shape: WidgetStateProperty.all(
          SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 20,
              cornerSmoothing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
  
  /// Create responsive outlined buttons
  static OutlinedButtonThemeData outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(Size(88, ResponsiveUtils.buttonHeight)),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.blockSizeHorizontal * 4,
          ),
        ),
        shape: WidgetStateProperty.all(
          SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 20,
              cornerSmoothing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
  
  /// Create responsive text buttons
  static TextButtonThemeData textButtonTheme() {
    return TextButtonThemeData(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.blockSizeHorizontal * 2,
            vertical: ResponsiveUtils.blockSizeVertical * 1,
          ),
        ),
        shape: WidgetStateProperty.all(
          SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 20,
              cornerSmoothing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
  
  /// Create responsive input decoration theme
  static InputDecorationTheme inputDecorationTheme() {
    return InputDecorationTheme(
      contentPadding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.blockSizeHorizontal * 4,
        vertical: ResponsiveUtils.blockSizeVertical * 2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.shade700, width: 2),
      ),
    );
  }
  
  /// Helper to create responsive text style
  static TextStyle _getResponsiveStyle(TextStyle? baseStyle, double fontSize) {
    if (baseStyle == null) {
      return TextStyle(
        fontSize: ResponsiveUtils.responsiveFontSize(fontSize),
      );
    }
    
    return baseStyle.copyWith(
      fontSize: ResponsiveUtils.responsiveFontSize(fontSize),
    );
  }
}

/// Extension methods for BuildContext to easily access responsive utils
extension ResponsiveExtension on BuildContext {
  /// Initialize responsive utils for this context
  void initResponsive() {
    ResponsiveUtils.init(this);
  }
  
  /// Get responsive text theme for this context
  TextTheme get responsiveTextTheme => ResponsiveTheme.getResponsiveTextTheme(this);
  
  /// Get screen width
  double get screenWidth => ResponsiveUtils.screenWidth;
  
  /// Get screen height
  double get screenHeight => ResponsiveUtils.screenHeight;
  
  /// Check if device is a phone
  bool get isPhone => ResponsiveUtils.isPhone;
  
  /// Check if device is a tablet
  bool get isTablet => ResponsiveUtils.isTablet;
  
  /// Check if device is a desktop
  bool get isDesktop => ResponsiveUtils.isDesktop;
  
  /// Get responsive padding
  EdgeInsets responsivePadding({double horizontal = 24.0, double vertical = 24.0}) {
    ResponsiveUtils.init(this);
    return ResponsiveUtils.responsivePadding(horizontal: horizontal, vertical: vertical);
  }
}
