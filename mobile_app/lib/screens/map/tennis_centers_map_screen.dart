import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:provider/provider.dart';

import '../../widgets/squircle_container.dart';
import '../../config/app_config.dart';
import '../../utils/map_utils.dart';
import '../../utils/map_style_utils.dart';
import '../../utils/map_cluster_manager.dart';
import '../../utils/map_marker_utils.dart';
import '../../utils/permission_utils.dart';
import '../../models/tennis_center.dart';
import '../../providers/tennis_centers_provider.dart';

/// A screen that displays tennis centers on a map.
class TennisCentersMapScreen extends StatefulWidget {
  /// The initial position of the map.
  final LatLng? initialPosition;

  /// The title of the screen.
  final String? title;

  /// Whether to show the back button.
  final bool showBackButton;

  /// Callback when a tennis center is selected.
  final Function(TennisCenter)? onTennisCenterSelected;

  /// Creates a [TennisCentersMapScreen] widget.
  const TennisCentersMapScreen({
    super.key,
    this.initialPosition,
    this.title = 'Tennis Centers',
    this.showBackButton = true,
    this.onTennisCenterSelected,
  });

  @override
  State<TennisCentersMapScreen> createState() =>
      _TennisCentersMapScreenState();
}

class _TennisCentersMapScreenState extends State<TennisCentersMapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  late OvalMapClusterManager _clusterManager;
  
  LatLng? _currentPosition;
  bool _isLoading = true;
  bool _isMapMoving = false;
  MapType _currentMapType = MapType.normal;
  
  List<TennisCenter> _tennisCenters = [];
  TennisCenter? _selectedTennisCenter;
  
  // Default camera position (San Francisco)
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _clusterManager = OvalMapClusterManager(
      clusterColor: const Color(0xFF1A5D1A),
      clusterTextColor: Colors.white,
      onItemTap: _onMarkerTapped,
    );
    _currentPosition = widget.initialPosition;
    _initializeLocation();
  }

  @override
  void dispose() {
    _clusterManager.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      if (widget.initialPosition != null) {
        setState(() {
          _currentPosition = widget.initialPosition;
        });
      } else {
        final hasPermission = await PermissionUtils.requestLocationPermission();
        if (hasPermission) {
          final position = await MapUtils.getCurrentLocation();
          setState(() {
            _currentPosition = position;
          });
        }
      }
      
      // Load tennis centers
      await _loadTennisCenters();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get current location'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadTennisCenters() async {
    try {
      final provider = Provider.of<TennisCentersProvider>(context, listen: false);
      _tennisCenters = await provider.getTennisCentersForMap();
      
      // Create custom marker for tennis centers
      final customMarker = await MapMarkerUtils.createTennisCourtMarker(
        color: const Color(0xFF1A5D1A),
        size: 80.0,
      );
      
      // Add tennis centers to cluster manager
      final items = _tennisCenters.map((center) {
        return MapClusterItem(
          id: center.id,
          position: LatLng(center.latitude, center.longitude),
          title: center.name,
          snippet: '${center.address}, ${center.city}',
          icon: customMarker,
          data: {'tennisCenter': center},
        );
      }).toList();
      
      _clusterManager.clearItems();
      _clusterManager.addItems(items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading tennis centers'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);
    _clusterManager.initialize(controller);

    // Move camera to initial position if provided
    if (_currentPosition != null) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 12.0,
          ),
        ),
      );
    }
  }

  void _onCameraMove(CameraPosition position) {
    _clusterManager.onCameraMove(position);
    if (!_isMapMoving) {
      setState(() => _isMapMoving = true);
    }
  }

  void _onCameraIdle() {
    _clusterManager.onCameraIdle();
    if (_isMapMoving) {
      setState(() => _isMapMoving = false);
    }
  }

  Future<void> _onMyLocationButtonPressed() async {
    final hasPermission = await PermissionUtils.requestLocationPermission();
    if (!hasPermission) return;

    try {
      final position = await MapUtils.getCurrentLocation();
      setState(() => _currentPosition = position);
      
      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(position, 12.0),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get current location'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  void _onMarkerTapped(MapClusterItem item) {
    final tennisCenter = item.data?['tennisCenter'] as TennisCenter?;
    if (tennisCenter != null) {
      setState(() {
        _selectedTennisCenter = tennisCenter;
      });
    }
  }

  void _onTennisCenterSelected(TennisCenter tennisCenter) {
    widget.onTennisCenterSelected?.call(tennisCenter);
    if (Navigator.canPop(context) && widget.onTennisCenterSelected != null) {
      Navigator.of(context).pop(tennisCenter);
      return;
    }

    Navigator.of(context).pushNamed(
      '/tennis_center_details',
      arguments: {'tennisCenterId': tennisCenter.id},
    );
  }

  Widget _buildMapsUnavailableState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.map,
              size: 56,
              color: Color(0xFF1A5D1A),
            ),
            const SizedBox(height: 16),
            const Text(
              'Map view is unavailable in this build.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Google Maps is not configured, so map rendering is disabled. You can still browse centres from the list view.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/tennis_centers');
              },
              child: const Text('Browse Centres'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Tennis Centers'),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(CupertinoIcons.back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: !AppConfig.hasGoogleMapsConfig
          ? _buildMapsUnavailableState(context)
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
              children: [
                // Map
                GoogleMap(
                  initialCameraPosition: _currentPosition != null
                      ? CameraPosition(
                          target: _currentPosition!,
                          zoom: 12.0,
                        )
                      : _kInitialPosition,
                  onMapCreated: _onMapCreated,
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: true,
                  mapToolbarEnabled: false,
                  mapType: _currentMapType,
                  style: MapStyleUtils.tennisCourtStyleForBrightness(
                    Theme.of(context).brightness,
                  ),
                  markers: _clusterManager.markers,
                ),

                // Search Bar
                Positioned(
                  top: 16.0,
                  left: 16.0,
                  right: 16.0,
                  child: SquircleContainer(
                    elevation: 4.0,
                    cornerRadius: 20.0,
                    cornerSmoothing: 0.6,
                    color: Colors.white,
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/tennis_centers');
                      },
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 20.0,
                        cornerSmoothing: 0.6,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.search,
                              color: Color(0xFF1A5D1A),
                            ),
                            const SizedBox(width: 12.0),
                            Text(
                              'Search for tennis centers',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Floating Action Buttons
                Positioned(
                  bottom: 76.0,
                  right: 16.0,
                  child: SquircleContainer(
                    elevation: 2.0,
                    cornerRadius: 24.0,
                    cornerSmoothing: 0.6,
                    color: Colors.white,
                    child: InkWell(
                      onTap: _onMyLocationButtonPressed,
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 24.0,
                        cornerSmoothing: 0.6,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          CupertinoIcons.location,
                          color: const Color(0xFF1A5D1A),
                          size: 20.0,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16.0,
                  right: 16.0,
                  child: SquircleContainer(
                    elevation: 2.0,
                    cornerRadius: 24.0,
                    cornerSmoothing: 0.6,
                    color: Colors.white,
                    child: InkWell(
                      onTap: _onMapTypeButtonPressed,
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 24.0,
                        cornerSmoothing: 0.6,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          _currentMapType == MapType.normal
                              ? CupertinoIcons.map_fill
                              : CupertinoIcons.map,
                          color: const Color(0xFF1A5D1A),
                          size: 20.0,
                        ),
                      ),
                    ),
                  ),
                ),

                // Tennis Center Details
                if (_selectedTennisCenter != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SquircleContainer(
                      elevation: 8.0,
                      cornerRadius: 24.0,
                      cornerSmoothing: 0.6,
                      color: Colors.white,
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedTennisCenter!.name,
                                        style: const TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        '${_selectedTennisCenter!.address}, ${_selectedTennisCenter!.city}',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(CupertinoIcons.xmark_circle),
                                  onPressed: () {
                                    setState(() {
                                      _selectedTennisCenter = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16.0),
                            Row(
                              children: [
                                Expanded(
                                  child: SquircleContainer(
                                    cornerRadius: 16.0,
                                    cornerSmoothing: 0.6,
                                    color: const Color(0xFF1A5D1A),
                                    child: InkWell(
                                      onTap: () => _onTennisCenterSelected(_selectedTennisCenter!),
                                      borderRadius: SmoothBorderRadius(
                                        cornerRadius: 16.0,
                                        cornerSmoothing: 0.6,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'View Details',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: SquircleContainer(
                                    cornerRadius: 16.0,
                                    cornerSmoothing: 0.6,
                                    color: const Color(0xFF1A5D1A),
                                    child: InkWell(
                                      onTap: () =>
                                          _onTennisCenterSelected(
                                        _selectedTennisCenter!,
                                      ),
                                      borderRadius: SmoothBorderRadius(
                                        cornerRadius: 16.0,
                                        cornerSmoothing: 0.6,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'Book Court',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
