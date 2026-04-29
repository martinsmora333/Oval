import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../widgets/map_with_search.dart';
import '../../utils/map_utils.dart';
import '../../utils/permission_utils.dart';

/// A screen that displays a map with search functionality.
class MapScreen extends StatefulWidget {
  /// The initial position of the map.
  final LatLng? initialPosition;

  /// The title of the screen.
  final String? title;

  /// Whether to show the back button.
  final bool showBackButton;

  /// Callback when a location is selected.
  final Function(LatLng)? onLocationSelected;

  /// Creates a [MapScreen] widget.
  const MapScreen({
    super.key,
    this.initialPosition,
    this.title = 'Map',
    this.showBackButton = true,
    this.onLocationSelected,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();

  /// Shows the map screen as a dialog.
  static Future<LatLng?> showAsDialog(
    BuildContext context, {
    LatLng? initialPosition,
    String? title,
  }) async {
    return await showDialog<LatLng>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600.0,
              maxHeight: 600.0,
            ),
            child: MapScreen(
              initialPosition: initialPosition,
              title: title ?? 'Select Location',
              showBackButton: false,
              onLocationSelected: (position) {
                Navigator.of(context).pop(position);
              },
            ),
          ),
        );
      },
    );
  }
}

class _MapScreenState extends State<MapScreen> {
  final Set<Marker> _markers = {};
  LatLng? _selectedPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      if (widget.initialPosition != null) {
        _addMarker(widget.initialPosition!);
        setState(() => _isLoading = false);
        return;
      }

      final hasPermission = await PermissionUtils.requestLocationPermission();
      if (!hasPermission) {
        setState(() => _isLoading = false);
        return;
      }

      final position = await MapUtils.getCurrentLocation();
      setState(() {
        _selectedPosition = position;
        _addMarker(position);
        _isLoading = false;
      });
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

  void _addMarker(LatLng position) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('selected_location'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Selected Location'),
      ),
    );
  }

  void _onLocationSelected(LatLng position) {
    setState(() {
      _selectedPosition = position;
      _addMarker(position);
    });
    
    widget.onLocationSelected?.call(position);
  }

  Future<void> _onDonePressed() async {
    if (_selectedPosition != null) {
      Navigator.of(context).pop(_selectedPosition);
    } else {
      final hasPermission = await PermissionUtils.requestLocationPermission();
      if (!hasPermission) return;

      try {
        final position = await MapUtils.getCurrentLocation();
        if (mounted) {
          Navigator.of(context).pop(position);
        }
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Map'),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(CupertinoIcons.back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          if (widget.onLocationSelected != null)
            TextButton(
              onPressed: _onDonePressed,
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : MapWithSearch(
              initialPosition: _selectedPosition,
              onLocationSelected: _onLocationSelected,
              markers: _markers,
            ),
    );
  }
}
