import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A utility class for creating custom markers for Google Maps.
class MapMarkerUtils {
  /// Creates a custom marker from an asset image.
  ///
  /// [assetPath] is the path to the asset image.
  /// [width] is the width of the marker in pixels.
  /// [height] is the height of the marker in pixels.
  static Future<BitmapDescriptor> createCustomMarkerFromAsset(
    String assetPath, {
    int width = 80,
    int height = 80,
  }) async {
    final ByteData byteData = await rootBundle.load(assetPath);
    final Uint8List byteList = byteData.buffer.asUint8List();
    
    final ui.Codec codec = await ui.instantiateImageCodec(
      byteList,
      targetWidth: width,
      targetHeight: height,
    );
    
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteData2 = await frameInfo.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    
    final Uint8List uint8List = byteData2!.buffer.asUint8List();
    return BitmapDescriptor.bytes(uint8List);
  }

  /// Creates a custom marker with text.
  ///
  /// [text] is the text to display on the marker.
  /// [backgroundColor] is the background color of the marker.
  /// [textColor] is the color of the text.
  /// [size] is the size of the marker in pixels.
  static Future<BitmapDescriptor> createCustomMarkerWithText(
    String text, {
    Color backgroundColor = Colors.blue,
    Color textColor = Colors.white,
    double size = 80.0,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = backgroundColor;
    final double radius = size / 2;

    // Draw the circle
    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      paint,
    );

    // Draw the border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      borderPaint,
    );

    // Draw the text
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: size / 3,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );

    // Convert to image
    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    return BitmapDescriptor.bytes(uint8List);
  }

  /// Creates a tennis court marker.
  ///
  /// [color] is the color of the marker.
  /// [size] is the size of the marker in pixels.
  static Future<BitmapDescriptor> createTennisCourtMarker({
    Color color = const Color(0xFF1A5D1A),
    double size = 80.0,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double radius = size / 2;
    
    // Draw the circle background
    final Paint backgroundPaint = Paint()..color = color;
    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      backgroundPaint,
    );
    
    // Draw the white border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(
      Offset(radius, radius),
      radius - 1,
      borderPaint,
    );
    
    // Draw the tennis court
    final Paint courtPaint = Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Court outline
    final double courtWidth = size * 0.6;
    final double courtHeight = courtWidth * 0.5;
    final double courtLeft = radius - courtWidth / 2;
    final double courtTop = radius - courtHeight / 2;
    
    final Rect courtRect = Rect.fromLTWH(
      courtLeft,
      courtTop,
      courtWidth,
      courtHeight,
    );
    
    canvas.drawRect(courtRect, courtPaint);
    
    // Net
    canvas.drawLine(
      Offset(radius, courtTop),
      Offset(radius, courtTop + courtHeight),
      courtPaint,
    );
    
    // Convert to image
    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    return BitmapDescriptor.bytes(uint8List);
  }

  /// Creates a cluster marker.
  ///
  /// [count] is the number of items in the cluster.
  /// [color] is the color of the marker.
  /// [textColor] is the color of the text.
  /// [size] is the size of the marker in pixels.
  static Future<BitmapDescriptor> createClusterMarker(
    int count, {
    Color color = const Color(0xFF1A5D1A),
    Color textColor = Colors.white,
    double size = 80.0,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final double radius = size / 2;

    // Draw the circle
    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      paint,
    );

    // Draw the border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      borderPaint,
    );

    // Draw the text
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: TextStyle(
          color: textColor,
          fontSize: size / 3,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );

    // Convert to image
    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    return BitmapDescriptor.bytes(uint8List);
  }
}
