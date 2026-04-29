import 'dart:async';
import 'dart:math' show min, max, pi, sin, cos, sqrt, atan2;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

/// A utility class for handling Google Maps related operations.
class MapUtils {
  /// The default zoom level for the map.
  static const double defaultZoom = 15.0;

  /// The minimum zoom level for the map.
  static const double minZoom = 3.0;

  /// The maximum zoom level for the map.
  static const double maxZoom = 19.0;

  /// The default padding around the map in pixels.
  static const double defaultPadding = 50.0;

  /// The default animation duration in milliseconds.
  static const int defaultAnimationDuration = 500;

  /// The default camera position (San Francisco).
  static const CameraPosition defaultCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: defaultZoom,
  );

  /// Animates the camera to a specific position.
  ///
  /// [controller] is the Google Maps controller.
  /// [target] is the target location to animate to.
  /// [zoom] is the zoom level (optional).
  /// [bearing] is the bearing in degrees (optional).
  /// [tilt] is the tilt in degrees (optional).
  /// [duration] is the duration of the animation in milliseconds (optional).
  static Future<void> animateCameraToPosition(
    GoogleMapController controller,
    LatLng target, {
    double? zoom,
    double? bearing,
    double? tilt,
    int? duration,
  }) async {
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom ?? defaultZoom,
          bearing: bearing ?? 0,
          tilt: tilt ?? 0,
        ),
      ),
    );
  }

  /// Fits the camera to show a list of markers with padding.
  ///
  /// [controller] is the Google Maps controller.
  /// [positions] is the list of positions to include in the view.
  /// [padding] is the padding around the markers in pixels.
  /// [maxZoom] is the maximum zoom level to allow.
  /// [duration] is the duration of the animation in milliseconds.
  static Future<void> fitToMarkers(
    GoogleMapController controller,
    List<LatLng> positions, {
    double padding = defaultPadding,
    double? maxZoom,
    int? duration,
  }) async {
    if (positions.isEmpty) return;

    final LatLngBounds bounds = _calculateBounds(positions);
    final CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(
      bounds,
      padding.roundToDouble(),
    );

    if (duration != null && duration > 0) {
      await controller.animateCamera(cameraUpdate);
    } else {
      await controller.moveCamera(cameraUpdate);
    }

    // Apply max zoom hint if specified.
    if (maxZoom != null) {
      final LatLng center = calculateCenter(positions);
      await controller
          .animateCamera(CameraUpdate.newLatLngZoom(center, maxZoom));
    }
  }

  /// Calculates the bounds that include all the given positions.
  static LatLngBounds _calculateBounds(List<LatLng> positions) {
    assert(positions.isNotEmpty);

    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (final position in positions) {
      minLat = min(minLat, position.latitude);
      maxLat = max(maxLat, position.latitude);
      minLng = min(minLng, position.longitude);
      maxLng = max(maxLng, position.longitude);
    }

    return LatLngBounds(
      northeast: LatLng(maxLat, maxLng),
      southwest: LatLng(minLat, minLng),
    );
  }

  /// Creates a marker with the given properties.
  ///
  /// [markerId] is the unique identifier for the marker.
  /// [position] is the position of the marker.
  /// [icon] is the custom icon for the marker (optional).
  /// [infoWindow] is the info window for the marker (optional).
  /// [onTap] is the callback when the marker is tapped (optional).
  /// [draggable] specifies if the marker is draggable (defaults to false).
  /// [anchor] is the anchor point for the marker icon (defaults to center).
  /// [zIndex] is the z-index of the marker (optional).
  /// [visible] specifies if the marker is visible (defaults to true).
  static Marker createMarker({
    required String markerId,
    required LatLng position,
    BitmapDescriptor? icon,
    InfoWindow? infoWindow,
    VoidCallback? onTap,
    bool draggable = false,
    Offset anchor = const Offset(0.5, 0.5),
    double? zIndex,
    bool visible = true,
  }) {
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      icon: icon ?? BitmapDescriptor.defaultMarker,
      infoWindow: infoWindow ?? InfoWindow.noText,
      onTap: onTap,
      draggable: draggable,
      anchor: anchor,
      zIndex: zIndex ?? 0,
      visible: visible,
    );
  }

  /// Creates a cluster of markers.
  ///
  /// [clusterId] is the unique identifier for the cluster.
  /// [position] is the position of the cluster.
  /// [points] is the list of points in the cluster.
  /// [builder] is a function that builds the cluster icon based on the cluster size.
  static Marker createClusterMarker({
    required String clusterId,
    required LatLng position,
    required int pointCount,
    required BitmapDescriptor Function(int) builder,
    VoidCallback? onTap,
  }) {
    return Marker(
      markerId: MarkerId(clusterId),
      position: position,
      icon: builder(pointCount),
      onTap: onTap,
    );
  }

  /// Calculates the center point of multiple positions.
  static LatLng calculateCenter(List<LatLng> positions) {
    if (positions.isEmpty) {
      return const LatLng(0, 0);
    }

    if (positions.length == 1) {
      return positions.first;
    }

    double x = 0;
    double y = 0;
    double z = 0;

    for (final position in positions) {
      final double lat = position.latitude * pi / 180;
      final double lng = position.longitude * pi / 180;

      x += cos(lat) * cos(lng);
      y += cos(lat) * sin(lng);
      z += sin(lat);
    }

    final int total = positions.length;
    x = x / total;
    y = y / total;
    z = z / total;

    final double centerLng = atan2(y, x);
    final double centerLat = atan2(z, sqrt(x * x + y * y));

    return LatLng(
      centerLat * 180 / pi,
      centerLng * 180 / pi,
    );
  }

  /// Gets the current location of the device.
  ///
  /// Returns a [LatLng] with the current position.
  /// Throws a [Exception] if the location could not be determined.
  static Future<LatLng> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      // Fallback to last known position
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        return LatLng(lastPosition.latitude, lastPosition.longitude);
      }
      rethrow;
    }
  }

  /// Calculates the distance between two points in meters.
  ///
  /// [start] is the starting point.
  /// [end] is the ending point.
  ///
  /// Returns the distance in meters.
  static double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Formats a duration in seconds to a human-readable string.
  ///
  /// Example: 3665 seconds -> "1h 1m 5s"
  static String formatDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;

    final List<String> parts = [];
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0 || hours > 0) parts.add('${minutes}m');
    parts.add('${remainingSeconds}s');

    return parts.join(' ');
  }

  /// Creates a custom marker icon with the given color and optional text.
  ///
  /// [context] is the build context.
  /// [color] is the color of the marker.
  /// [text] is the text to display on the marker (optional).
  /// [size] is the size of the marker (defaults to 48.0).
  static Future<BitmapDescriptor> createCustomMarkerIcon({
    required BuildContext context,
    required Color color,
    String? text,
    double size = 48.0,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final double radius = size / 2;

    // Draw the circle
    canvas.drawCircle(
      Offset(radius, radius),
      radius * 0.9,
      paint,
    );

    // Draw the border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      Offset(radius, radius),
      radius * 0.9,
      borderPaint,
    );

    // Add text if provided
    if (text != null && text.isNotEmpty) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          radius - textPainter.width / 2,
          radius - textPainter.height / 2,
        ),
      );
    }

    // Convert canvas to image
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(
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
