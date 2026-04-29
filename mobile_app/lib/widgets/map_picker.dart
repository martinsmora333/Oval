import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:figma_squircle/figma_squircle.dart';

import '../widgets/squircle_container.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../utils/location_utils.dart';
import '../utils/permission_utils.dart';
import 'location_search_bar.dart';

/// A widget that allows picking a location on a map.
class MapPicker extends StatefulWidget {
  /// The initial position of the map.
  final LatLng? initialPosition;

  /// The title of the screen.
  final String? title;

  /// The hint text for the search bar.
  final String searchHint;

  /// The text for the confirm button.
  final String confirmButtonText;

  /// The text for the current location button.
  final String currentLocationButtonText;

  /// Whether to show the current location button.
  final bool showCurrentLocationButton;

  /// Whether to show the search bar.
  final bool showSearchBar;

  /// The color of the confirm button.
  final Color confirmButtonColor;

  /// The color of the text on the confirm button.
  final Color confirmButtonTextColor;

  /// The color of the current location button.
  final Color currentLocationButtonColor;

  /// The color of the text on the current location button.
  final Color currentLocationButtonTextColor;

  /// The color of the pin on the map.
  final Color pinColor;

  /// The size of the pin on the map.
  final double pinSize;

  /// The padding around the map.
  final EdgeInsetsGeometry padding;

  /// The margin around the map.
  final EdgeInsetsGeometry margin;

  /// The height of the map.
  final double? height;

  /// The width of the map.
  final double? width;


  /// Callback when a location is selected.
  final Function(LatLng position, String? address)? onLocationSelected;

  /// Creates a [MapPicker] widget.
  const MapPicker({
    super.key,
    this.initialPosition,
    this.title,
    this.searchHint = 'Search for a location',
    this.confirmButtonText = 'Confirm Location',
    this.currentLocationButtonText = 'Use Current Location',
    this.showCurrentLocationButton = true,
    this.showSearchBar = true,
    this.confirmButtonColor = Colors.blue,
    this.confirmButtonTextColor = Colors.white,
    this.currentLocationButtonColor = Colors.white,
    this.currentLocationButtonTextColor = Colors.blue,
    this.pinColor = Colors.red,
    this.pinSize = 40.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.height,
    this.width,
    this.onLocationSelected,
  });

  /// Shows the map picker as a dialog.
  static Future<LatLng?> showAsDialog(
    BuildContext context, {
    LatLng? initialPosition,
    String? title,
    String? confirmButtonText,
    bool showCurrentLocationButton = true,
    bool showSearchBar = true,
  }) async {
    return await showDialog<LatLng>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600.0,
              maxHeight: 700.0,
            ),
            child: MapPicker(
              initialPosition: initialPosition,
              title: title ?? 'Select Location',
              confirmButtonText: confirmButtonText ?? 'Select',
              showCurrentLocationButton: showCurrentLocationButton,
              showSearchBar: showSearchBar,
            ),
          ),
        );
      },
    );
  }

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  LatLng? _selectedPosition;
  String? _selectedAddress;
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isMapMoving = false;
  
  // Default camera position (San Francisco)
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _initializeLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      if (widget.initialPosition != null) {
        await _updatePosition(widget.initialPosition!);
        setState(() => _isLoading = false);
        return;
      }

      final hasPermission = await PermissionUtils.requestLocationPermission();
      if (!hasPermission) {
        setState(() => _isLoading = false);
        return;
      }

      final position = await LocationUtils.getCurrentPosition();
      await _updatePosition(LatLng(position.latitude, position.longitude));
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

  Future<void> _updatePosition(LatLng position) async {
    setState(() {
      _selectedPosition = position;
      _isSearching = true;
    });

    try {
      // Get address from coordinates
      final address = await LocationUtils.getFormattedAddress(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      if (mounted) {
        setState(() {
          _selectedAddress = address;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);
    
    // Move camera to initial position if provided
    if (_selectedPosition != null) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _selectedPosition!,
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  Future<void> _onCameraMove(CameraPosition position) async {
    if (!_isMapMoving) {
      setState(() => _isMapMoving = true);
    }
  }

  Future<void> _onCameraIdle() async {
    if (_isMapMoving) {
      final screenSize = MediaQuery.sizeOf(context);
      final controller = await _mapController.future;
      if (!mounted) return;
      final position = await controller.getLatLng(ScreenCoordinate(
        x: screenSize.width ~/ 2,
        y: screenSize.height ~/ 2,
      ));
      
      await _updatePosition(position);
      setState(() => _isMapMoving = false);
    }
  }

  Future<void> _onCurrentLocationPressed() async {
    final hasPermission = await PermissionUtils.requestLocationPermission();
    if (!hasPermission) return;

    try {
      final position = await LocationUtils.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);
      
      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15.0),
      );
      
      await _updatePosition(location);
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

  void _onConfirmPressed() {
    if (_selectedPosition != null) {
      widget.onLocationSelected?.call(_selectedPosition!, _selectedAddress);
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(_selectedPosition);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.title != null
          ? AppBar(
              title: Text(widget.title!),
              leading: IconButton(
                icon: const Icon(CupertinoIcons.back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (widget.showSearchBar) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LocationSearchBar(
                      hintText: widget.searchHint,
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onLocationSelected: (position, address) {
                        _searchController.text = address;
                        _searchFocusNode.unfocus();
                        _mapController.future.then((controller) {
                          controller.animateCamera(
                            CameraUpdate.newLatLngZoom(position, 15.0),
                          );
                        });
                        _updatePosition(position);
                      },
                    ),
                  ),
                  const Divider(height: 1.0),
                ],
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: _selectedPosition != null
                            ? CameraPosition(
                                target: _selectedPosition!,
                                zoom: 15.0,
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
                        onTap: (position) {
                          _updatePosition(position);
                        },
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.location_solid,
                              size: widget.pinSize,
                              color: widget.pinColor,
                            ),
                            if (_isSearching || _isMapMoving)
                              const CircularProgressIndicator(),
                          ],
                        ),
                      ),
                      if (widget.showCurrentLocationButton)
                        Positioned(
                          bottom: 16.0,
                          right: 16.0,
                          child: SquircleContainer(
                            elevation: 2.0,
                            cornerRadius: 24.0,
                            cornerSmoothing: 0.6,
                            color: widget.currentLocationButtonColor,
                            child: InkWell(
                              onTap: _onCurrentLocationPressed,
                              borderRadius: SmoothBorderRadius(
                                cornerRadius: 24.0,
                                cornerSmoothing: 0.6,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  CupertinoIcons.location,
                                  color: widget.currentLocationButtonTextColor,
                                  size: 20.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8.0,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Location',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        _selectedAddress ?? 'No location selected',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16.0),
                      SizedBox(
                        width: double.infinity,
                        child: SquircleContainer(
                          color: _selectedPosition != null
                              ? widget.confirmButtonColor
                              : widget.confirmButtonColor.withValues(alpha: 0.5),
                          cornerRadius: 16.0,
                          cornerSmoothing: 0.6,
                          child: InkWell(
                            onTap: _selectedPosition != null
                                ? _onConfirmPressed
                                : null,
                            borderRadius: SmoothBorderRadius(
                              cornerRadius: 16.0,
                              cornerSmoothing: 0.6,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              alignment: Alignment.center,
                              child: Text(
                                widget.confirmButtonText,
                                style: TextStyle(
                                  color: widget.confirmButtonTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
