import 'package:flutter/material.dart';

/// A utility class for responsive UI design
class ResponsiveUtils {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  
  static late double _safeAreaHorizontal;
  static late double _safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  
  static late double pixelRatio;
  
  // Device type constants
  static bool isPhone = false;
  static bool isTablet = false;
  static bool isDesktop = false;
  
  /// Initialize responsive utils with BuildContext
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
    
    _safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - _safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - _safeAreaVertical) / 100;
    
    pixelRatio = _mediaQueryData.devicePixelRatio;
    
    // Determine device type
    final shortestSide = _mediaQueryData.size.shortestSide;
    isPhone = shortestSide < 600;
    isTablet = shortestSide >= 600 && shortestSide < 900;
    isDesktop = shortestSide >= 900;
  }
  
  /// Convert fontSize to a responsive size based on the screen width
  static double responsiveFontSize(double fontSize) {
    // Adjust the divisor to control how much the font scales with screen size
    double scaleFactor = screenWidth / 375; // 375 is baseline width (iPhone X)
    
    // Limit the scaling to avoid too large or too small text
    scaleFactor = scaleFactor.clamp(0.8, 1.2);
    
    return fontSize * scaleFactor;
  }
  
  /// Calculate responsive padding based on screen size
  static EdgeInsets responsivePadding({
    double horizontal = 24.0,
    double vertical = 24.0,
  }) {
    double h = horizontal * (screenWidth / 375).clamp(0.8, 1.2);
    double v = vertical * (screenHeight / 812).clamp(0.8, 1.2);
    
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }
  
  /// Calculate responsive width as a percentage of screen width
  static double responsiveWidth(double percentage) {
    return screenWidth * percentage / 100;
  }
  
  /// Calculate responsive height as a percentage of screen height
  static double responsiveHeight(double percentage) {
    return screenHeight * percentage / 100;
  }
  
  /// Get responsive button height based on device type
  static double get buttonHeight {
    if (isPhone) return 50;
    if (isTablet) return 56;
    return 60; // Desktop
  }
  
  /// Get responsive icon size based on device type
  static double get iconSize {
    if (isPhone) return 24;
    if (isTablet) return 28;
    return 32; // Desktop
  }
}
