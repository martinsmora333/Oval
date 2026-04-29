import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    hide Cluster, ClusterManager;
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart'
    as cm;

/// A class that represents a clusterable item on the map.
class MapClusterItem with cm.ClusterItem {
  /// The unique ID of the item.
  final String id;

  /// The position of the item on the map.
  final LatLng position;

  /// The title of the item.
  final String? title;

  /// The snippet of the item.
  final String? snippet;

  /// The icon of the item.
  final BitmapDescriptor? icon;

  /// Additional data associated with the item.
  final Map<String, dynamic>? data;

  /// Creates a [MapClusterItem].
  MapClusterItem({
    required this.id,
    required this.position,
    this.title,
    this.snippet,
    this.icon,
    this.data,
  });

  @override
  LatLng get location => position;
}

/// A utility class for managing map clusters.
class OvalMapClusterManager {
  /// The cluster manager instance.
  late final cm.ClusterManager<MapClusterItem> _manager;

  /// The Google Maps controller.
  GoogleMapController? _mapController;

  /// The markers on the map.
  final Set<Marker> _markers = {};

  /// The items to be clustered.
  final List<MapClusterItem> _items = [];

  /// The color of the clusters.
  final Color clusterColor;

  /// The text color of the clusters.
  final Color clusterTextColor;

  /// The minimum zoom level for clustering.
  final int minClusterZoom;

  /// The maximum zoom level for clustering.
  final int maxClusterZoom;

  /// The size of the clusters.
  final int clusterSize;

  /// The anchor point of the clusters.
  final Offset clusterAnchor;

  /// The anchor point of the markers.
  final Offset markerAnchor;

  /// Callback for taps on individual items.
  final void Function(MapClusterItem item)? onItemTap;

  /// Creates an [OvalMapClusterManager].
  OvalMapClusterManager({
    this.clusterColor = Colors.blue,
    this.clusterTextColor = Colors.white,
    this.minClusterZoom = 0,
    this.maxClusterZoom = 19,
    this.clusterSize = 80,
    this.clusterAnchor = const Offset(0.5, 0.5),
    this.markerAnchor = const Offset(0.5, 0.5),
    this.onItemTap,
  }) {
    _manager = cm.ClusterManager<MapClusterItem>(
      _items,
      _updateMarkers,
      markerBuilder: (cluster) =>
          _markerBuilder(cluster),
      levels: [1, 4.25, 6.75, 8.25, 11.5, 14.5, 16.0, 16.5, 20.0],
      extraPercent: 0.2,
      stopClusteringZoom: maxClusterZoom.toDouble(),
    );
  }

  /// Initializes the cluster manager with a Google Maps controller.
  void initialize(GoogleMapController controller) {
    _mapController = controller;
    _manager.setMapId(controller.mapId);
  }

  /// Updates the markers on the map.
  Future<void> _updateMarkers(Set<Marker> markers) async {
    _markers.clear();
    _markers.addAll(markers);
    if (_mapController != null) {
      _manager.updateMap();
    }
  }

  /// Builds a marker for a cluster item.
  Future<Marker> _markerBuilder(cm.Cluster<MapClusterItem> cluster) async {
    final isCluster = cluster.isMultiple;

    return Marker(
      markerId: MarkerId(cluster.getId()),
      position: cluster.location,
      icon: await _getMarkerIcon(cluster),
      infoWindow: isCluster
          ? InfoWindow(title: 'Cluster of ${cluster.count} items')
          : InfoWindow(
              title: cluster.items.first.title,
              snippet: cluster.items.first.snippet,
            ),
      anchor: isCluster ? clusterAnchor : markerAnchor,
      onTap: isCluster ? null : () => onItemTap?.call(cluster.items.first),
    );
  }

  /// Gets the marker icon for a cluster.
  Future<BitmapDescriptor> _getMarkerIcon(
      cm.Cluster<MapClusterItem> cluster) async {
    if (cluster.isMultiple) {
      return await _getClusterIcon(cluster);
    } else {
      return cluster.items.first.icon ?? BitmapDescriptor.defaultMarker;
    }
  }

  /// Gets the icon for a cluster of items.
  Future<BitmapDescriptor> _getClusterIcon(
      cm.Cluster<MapClusterItem> cluster) async {
    final size = clusterSize;
    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = clusterColor;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Draw the circle
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2.5,
      paint,
    );

    // Draw the border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2.5,
      borderPaint,
    );

    // Draw the text
    textPainter.text = TextSpan(
      text: cluster.count.toString(),
      style: TextStyle(
        fontSize: size / 3,
        fontWeight: FontWeight.bold,
        color: clusterTextColor,
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size / 2 - textPainter.width / 2,
        size / 2 - textPainter.height / 2,
      ),
    );

    // Convert to image
    final image = await pictureRecorder.endRecording().toImage(size, size);
    final data = await image.toByteData(format: ImageByteFormat.png);

    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  /// Adds a list of items to the cluster manager.
  void addItems(List<MapClusterItem> items) {
    _items.addAll(items);
    _manager.setItems(_items);
  }

  /// Adds a single item to the cluster manager.
  void addItem(MapClusterItem item) {
    _items.add(item);
    _manager.setItems(_items);
  }

  /// Removes a list of items from the cluster manager.
  void removeItems(List<MapClusterItem> items) {
    for (final item in items) {
      _items.removeWhere((i) => i.id == item.id);
    }
    _manager.setItems(_items);
  }

  /// Removes a single item from the cluster manager.
  void removeItem(MapClusterItem item) {
    _items.removeWhere((i) => i.id == item.id);
    _manager.setItems(_items);
  }

  /// Clears all items from the cluster manager.
  void clearItems() {
    _items.clear();
    _manager.setItems(_items);
  }

  /// Updates the map when the camera moves.
  void onCameraMove(CameraPosition position) {
    _manager.onCameraMove(position);
  }

  /// Updates the map when the camera is idle.
  void onCameraIdle() {
    _manager.updateMap();
  }

  /// Gets the current markers on the map.
  Set<Marker> get markers => _markers;

  /// Gets the current items in the cluster manager.
  List<MapClusterItem> get items => _items;

  /// Disposes the cluster manager.
  void dispose() {
    _markers.clear();
    _items.clear();
    _mapController = null;
  }
}
