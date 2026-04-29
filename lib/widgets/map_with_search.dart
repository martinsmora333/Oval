import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:figma_squircle/figma_squircle.dart';

import '../widgets/squircle_container.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';

import '../config/maps_config.dart';
import '../utils/map_utils.dart';
import '../utils/permission_utils.dart';

/// A widget that displays a map with a search bar.
class MapWithSearch extends StatefulWidget {
  /// The initial position of the map.
  final LatLng? initialPosition;

  /// The initial zoom level of the map.
  final double initialZoom;

  /// The minimum zoom level of the map.
  final double minZoom;

  /// The maximum zoom level of the map.
  final double maxZoom;

  /// The padding around the map in pixels.
  final double padding;

  /// The color of the search bar.
  final Color searchBarColor;

  /// The hint text for the search bar.
  final String searchHint;

  /// Callback when a location is selected.
  final Function(LatLng)? onLocationSelected;

  /// Callback when the map is created.
  final Function(GoogleMapController)? onMapCreated;

  /// The markers to display on the map.
  final Set<Marker> markers;

  /// Whether to show the current location button.
  final bool showMyLocationButton;

  /// Whether to show the search bar.
  final bool showSearchBar;

  /// Whether to show the map type selector.
  final bool showMapTypeSelector;

  /// The initial map type.
  final MapType initialMapType;

  /// The color of the current location button.
  final Color locationButtonColor;

  /// The color of the map type selector button.
  final Color mapTypeButtonColor;

  /// The color of the search bar text.
  final Color searchTextColor;

  /// The color of the search bar hint text.
  final Color searchHintColor;

  /// The color of the search bar icon.
  final Color searchIconColor;

  /// Creates a [MapWithSearch] widget.
  const MapWithSearch({
    super.key,
    this.initialPosition,
    this.initialZoom = 15.0,
    this.minZoom = 3.0,
    this.maxZoom = 19.0,
    this.padding = 16.0,
    this.searchBarColor = Colors.white,
    this.searchHint = 'Search for a location',
    this.onLocationSelected,
    this.onMapCreated,
    this.markers = const {},
    this.showMyLocationButton = true,
    this.showSearchBar = true,
    this.showMapTypeSelector = true,
    this.initialMapType = MapType.normal,
    this.locationButtonColor = Colors.blue,
    this.mapTypeButtonColor = Colors.blue,
    this.searchTextColor = Colors.black87,
    this.searchHintColor = Colors.black54,
    this.searchIconColor = Colors.blue,
  });

  @override
  State<MapWithSearch> createState() => _MapWithSearchState();
}

class _MapWithSearchState extends State<MapWithSearch> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentPosition;
  MapType _currentMapType = MapType.normal;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentMapType = widget.initialMapType;
    _initializeLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      if (widget.initialPosition != null) {
        setState(() {
          _currentPosition = widget.initialPosition;
          _isLoading = false;
        });
        return;
      }

      final hasPermission = await PermissionUtils.requestLocationPermission();
      if (!hasPermission) {
        setState(() => _isLoading = false);
        return;
      }

      final position = await MapUtils.getCurrentLocation();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller.complete(controller);
    widget.onMapCreated?.call(controller);
  }

  Future<void> _onMapTap(LatLng position) async {
    widget.onLocationSelected?.call(position);
  }

  Future<void> _onSearchButtonPressed() async {
    // Show the place picker
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlacePicker(
          apiKey: MapsConfig.googleMapsApiKey,
          initialPosition: _currentPosition ?? const LatLng(0, 0),
          useCurrentLocation: true,
          selectInitialPosition: true,
          usePlaceDetailSearch: true,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _currentPosition = LatLng(
          result.geometry!.location.lat,
          result.geometry!.location.lng,
        );
      });

      // Move camera to the selected location
      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          _currentPosition!,
          widget.initialZoom,
        ),
      );

      widget.onLocationSelected?.call(_currentPosition!);
    }
  }

  Future<void> _onMyLocationButtonPressed() async {
    final hasPermission = await PermissionUtils.requestLocationPermission();
    if (!hasPermission) return;

    try {
      final position = await MapUtils.getCurrentLocation();
      if (!mounted) return;
      setState(() => _currentPosition = position);

      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(position, widget.initialZoom),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get current location'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition ?? const LatLng(0, 0),
                  zoom: widget.initialZoom,
                ),
                onMapCreated: _onMapCreated,
                onTap: _onMapTap,
                markers: widget.markers,
                mapType: _currentMapType,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: true,
                minMaxZoomPreference: MinMaxZoomPreference(
                  widget.minZoom,
                  widget.maxZoom,
                ),
                onCameraMove: (position) {
                  // Update current position when the camera moves
                  setState(() {
                    _currentPosition = position.target;
                  });
                },
              ),

        // Search Bar
        if (widget.showSearchBar)
          Positioned(
            top: widget.padding,
            left: widget.padding,
            right: widget.padding,
            child: _buildSearchBar(),
          ),

        // Current Location Button
        if (widget.showMyLocationButton)
          Positioned(
            bottom: widget.padding + (widget.showMapTypeSelector ? 60 : 0),
            right: widget.padding,
            child: _buildFloatingActionButton(
              icon: CupertinoIcons.location,
              onPressed: _onMyLocationButtonPressed,
              backgroundColor: widget.locationButtonColor,
            ),
          ),

        // Map Type Selector
        if (widget.showMapTypeSelector)
          Positioned(
            bottom: widget.padding,
            right: widget.padding,
            child: _buildFloatingActionButton(
              icon: _currentMapType == MapType.normal
                  ? CupertinoIcons.map_fill
                  : CupertinoIcons.map,
              onPressed: _onMapTypeButtonPressed,
              backgroundColor: widget.mapTypeButtonColor,
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SquircleContainer(
      elevation: 4.0,
      cornerRadius: 20.0,
      cornerSmoothing: 0.6,
      color: widget.searchBarColor,
      child: InkWell(
        onTap: _onSearchButtonPressed,
        borderRadius: SmoothBorderRadius(
          cornerRadius: 20.0,
          cornerSmoothing: 0.6,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.search,
                color: widget.searchIconColor,
              ),
              const SizedBox(width: 12.0),
              Text(
                widget.searchHint,
                style: TextStyle(
                  color: widget.searchHintColor,
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return SquircleContainer(
      elevation: 2.0,
      cornerRadius: 24.0,
      cornerSmoothing: 0.6,
      color: backgroundColor,
      child: InkWell(
        onTap: onPressed,
        borderRadius: SmoothBorderRadius(
          cornerRadius: 24.0,
          cornerSmoothing: 0.6,
        ),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: Colors.white, size: 20.0),
        ),
      ),
    );
  }
}
