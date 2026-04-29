import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../utils/location_utils.dart';
import '../../../widgets/map_picker.dart';

class AddressStep extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  const AddressStep({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<AddressStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;

  bool _isLoadingLocation = false;
  bool _isResolvingAddress = false;
  bool _hasLocation = false;
  bool _isApplyingResolvedAddress = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();

    final rawInitialData = Map<String, dynamic>.from(widget.initialData);
    final addressData = rawInitialData['address'] is Map
        ? Map<String, dynamic>.from(rawInitialData['address'] as Map)
        : rawInitialData;

    _streetController = TextEditingController(
      text: addressData['street']?.toString() ?? '',
    );
    _cityController = TextEditingController(
      text: addressData['city']?.toString() ?? '',
    );
    _stateController = TextEditingController(
      text: addressData['state']?.toString() ?? '',
    );
    _postalCodeController = TextEditingController(
      text: addressData['zipCode']?.toString() ??
          addressData['postalCode']?.toString() ??
          '',
    );
    _countryController = TextEditingController(
      text: addressData['country']?.toString() ?? '',
    );

    final locationData = rawInitialData['location'];
    if (locationData is Map) {
      _latitude = _readCoordinate(locationData['latitude']);
      _longitude = _readCoordinate(locationData['longitude']);
      _hasLocation = _latitude != null && _longitude != null;
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  double? _readCoordinate(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  LatLng? get _selectedLatLng {
    if (_latitude == null || _longitude == null) {
      return null;
    }
    return LatLng(_latitude!, _longitude!);
  }

  String get _fullAddress {
    return <String>[
      _streetController.text.trim(),
      _cityController.text.trim(),
      _stateController.text.trim(),
      _postalCodeController.text.trim(),
      _countryController.text.trim(),
    ].where((part) => part.isNotEmpty).join(', ');
  }

  bool get _canResolveAddress {
    return _streetController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _stateController.text.trim().isNotEmpty &&
        _countryController.text.trim().isNotEmpty;
  }

  void _handleManualAddressEdit(String _) {
    if (_isApplyingResolvedAddress || !_hasLocation) {
      return;
    }

    setState(() {
      _latitude = null;
      _longitude = null;
      _hasLocation = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await LocationUtils.getCurrentPosition();
      await _applySelectedLocation(
        LatLng(position.latitude, position.longitude),
        syncAddressFields: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not determine your location. Enter the address or pin it on the map.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _locateEnteredAddress() async {
    if (!_canResolveAddress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the address details before locating it.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isResolvingAddress = true);

    try {
      final location = await LocationUtils.getLocationFromAddress(
        address: _fullAddress,
      );
      if (location == null) {
        throw Exception('not_found');
      }

      await _applySelectedLocation(location, syncAddressFields: false);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We could not match that address. Pin the location manually on the map.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResolvingAddress = false);
      }
    }
  }

  Future<void> _pickLocationOnMap() async {
    LatLng? initialPosition = _selectedLatLng;
    if (initialPosition == null && _canResolveAddress) {
      initialPosition = await LocationUtils.getLocationFromAddress(
        address: _fullAddress,
      );
    }

    if (!mounted) {
      return;
    }

    final navigator = Navigator.of(context);
    String? selectedAddress;
    final selectedPosition = await navigator.push<LatLng>(
      MaterialPageRoute(
        builder: (context) => MapPicker(
          title: 'Pin Tennis Center Location',
          initialPosition: initialPosition,
          confirmButtonText: 'Use This Location',
          onLocationSelected: (position, address) {
            selectedAddress = address;
          },
        ),
      ),
    );

    if (selectedPosition == null) {
      return;
    }

    await _applySelectedLocation(
      selectedPosition,
      syncAddressFields: true,
      fallbackAddress: selectedAddress,
    );
  }

  Future<void> _applySelectedLocation(
    LatLng position, {
    required bool syncAddressFields,
    String? fallbackAddress,
  }) async {
    if (syncAddressFields) {
      final placemark = await LocationUtils.getPlacemarkFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (placemark != null) {
        _isApplyingResolvedAddress = true;
        _streetController.text = (placemark.street ?? '').trim().isNotEmpty
            ? placemark.street!.trim()
            : _streetController.text;
        _cityController.text = (placemark.locality ?? '').trim().isNotEmpty
            ? placemark.locality!.trim()
            : _cityController.text;
        _stateController.text =
            (placemark.administrativeArea ?? '').trim().isNotEmpty
                ? placemark.administrativeArea!.trim()
                : _stateController.text;
        _postalCodeController.text =
            (placemark.postalCode ?? '').trim().isNotEmpty
                ? placemark.postalCode!.trim()
                : _postalCodeController.text;
        _countryController.text = (placemark.country ?? '').trim().isNotEmpty
            ? placemark.country!.trim()
            : _countryController.text;
        _isApplyingResolvedAddress = false;
      } else if (fallbackAddress != null && fallbackAddress.trim().isNotEmpty) {
        _isApplyingResolvedAddress = true;
        if (_streetController.text.trim().isEmpty) {
          _streetController.text = fallbackAddress.trim();
        }
        _isApplyingResolvedAddress = false;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _hasLocation = true;
    });
    _updateData();
  }

  void _updateData() {
    final addressData = <String, dynamic>{
      'street': _streetController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'zipCode': _postalCodeController.text.trim(),
      'postalCode': _postalCodeController.text.trim(),
      'country': _countryController.text.trim(),
    };

    widget.onChanged(<String, dynamic>{
      'address': addressData,
      'location': _hasLocation && _latitude != null && _longitude != null
          ? <String, double>{
              'latitude': _latitude!,
              'longitude': _longitude!,
            }
          : null,
    });
  }

  Widget _buildLocationActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    bool isBusy = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationStatusCard() {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      decoration: ShapeDecoration(
        color: theme.cardColor,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.all(
            SmoothRadius(
              cornerRadius: 16,
              cornerSmoothing: 0.6,
            ),
          ),
          side: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _hasLocation
                  ? CupertinoIcons.location_solid
                  : CupertinoIcons.location_slash,
              size: 42,
              color: _hasLocation ? theme.colorScheme.primary : theme.hintColor,
            ),
            const SizedBox(height: 12),
            Text(
              _hasLocation
                  ? 'Verified Center Location'
                  : 'Location Not Verified Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _hasLocation && _latitude != null && _longitude != null
                  ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                  : 'Use current location, locate the address, or pin the center on the map.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (_hasLocation) ...[
              const SizedBox(height: 8),
              Text(
                _fullAddress.isNotEmpty
                    ? _fullAddress
                    : 'Coordinates saved for this center.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      onChanged: _updateData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Location',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.headlineSmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help players find your tennis center with an accurate location and verified address.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            _buildLocationActionButton(
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              icon: CupertinoIcons.location_solid,
              label: _hasLocation
                  ? 'Refresh From My Current Location'
                  : 'Use My Current Location',
              isBusy: _isLoadingLocation,
            ),
            const SizedBox(height: 12),
            _buildLocationActionButton(
              onPressed: _isResolvingAddress ? null : _locateEnteredAddress,
              icon: CupertinoIcons.search,
              label: 'Locate Entered Address',
              isBusy: _isResolvingAddress,
            ),
            const SizedBox(height: 12),
            _buildLocationActionButton(
              onPressed: _pickLocationOnMap,
              icon: CupertinoIcons.map,
              label: _hasLocation ? 'Adjust Pin on Map' : 'Pin Location on Map',
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _streetController,
              decoration: InputDecoration(
                labelText: 'Street Address',
                hintText: 'e.g., 123 Tennis Court',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(CupertinoIcons.location_solid),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              style: const TextStyle(fontSize: 16),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a street address';
                }
                if (value.trim().length < 5) {
                  return 'Please enter a valid address';
                }
                return null;
              },
              onChanged: _handleManualAddressEdit,
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    onChanged: _handleManualAddressEdit,
                    onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _stateController,
                    decoration: InputDecoration(
                      labelText: 'State',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Req';
                      }
                      return null;
                    },
                    onChanged: _handleManualAddressEdit,
                    onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _postalCodeController,
                    decoration: InputDecoration(
                      labelText: 'Postal Code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Req';
                      }
                      return null;
                    },
                    onChanged: _handleManualAddressEdit,
                    onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _countryController,
              decoration: InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(CupertinoIcons.globe),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              style: const TextStyle(fontSize: 16),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a country';
                }
                return null;
              },
              onChanged: _handleManualAddressEdit,
              onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
            const SizedBox(height: 24),
            _buildLocationStatusCard(),
            const SizedBox(height: 8),
            Text(
              'If you edit the address after pinning the center, the saved coordinates are cleared until you locate the address again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
