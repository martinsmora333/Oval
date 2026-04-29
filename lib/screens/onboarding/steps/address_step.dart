import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:figma_squircle/figma_squircle.dart';

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
  
  // Location state
  bool _isLoadingLocation = false;
  bool _hasLocation = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    
    // Initialize address data from initialData
    final addressData = widget.initialData['address'] ?? {};
    
    _streetController = TextEditingController(
      text: addressData['street'] ?? '',
    );
    _cityController = TextEditingController(
      text: addressData['city'] ?? '',
    );
    _stateController = TextEditingController(
      text: addressData['state'] ?? '',
    );
    _postalCodeController = TextEditingController(
      text: addressData['zipCode'] ?? '',
    );
    _countryController = TextEditingController(
      text: addressData['country'] ?? '',
    );
    
    // Initialize coordinates if available
    if (widget.initialData['location'] != null) {
      _latitude = widget.initialData['location']['latitude'];
      _longitude = widget.initialData['location']['longitude'];
      _hasLocation = true;
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      // TODO: Implement actual location service
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate getting current location
      setState(() {
        _latitude = 37.7749; // Example: San Francisco
        _longitude = -122.4194;
        _hasLocation = true;
      });
      
      // Update form fields with example data
      if (_cityController.text.isEmpty) _cityController.text = 'San Francisco';
      if (_stateController.text.isEmpty) _stateController.text = 'CA';
      if (_countryController.text.isEmpty) _countryController.text = 'United States';
      if (_postalCodeController.text.isEmpty) _postalCodeController.text = '94107';
      
      _updateData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not determine your location. Please enter manually.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _updateData() {
    if (_formKey.currentState?.validate() ?? false) {
      final addressData = {
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zipCode': _postalCodeController.text.trim(),
        'country': _countryController.text.trim(),
      };
      
      // Only include coordinates if we have them
      if (_latitude != null && _longitude != null) {
        widget.onChanged({
          'address': addressData,
          'location': {
            'latitude': _latitude,
            'longitude': _longitude,
          },
        });
      } else {
        widget.onChanged({'address': addressData});
      }
    }
  }

  Widget _buildLocationButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
        icon: _isLoadingLocation
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(CupertinoIcons.location_solid, size: 18),
        label: Text(_hasLocation ? 'Update My Location' : 'Use My Current Location'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 200,
      decoration: ShapeDecoration(
        color: Theme.of(context).cardColor,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.all(SmoothRadius(
            cornerRadius: 16,
            cornerSmoothing: 0.6,
          )),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.map,
            size: 48,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 12),
          Text(
            'Location Preview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _hasLocation 
                ? '${_cityController.text}, ${_stateController.text}'
                : 'Location will appear here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
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
              'Help players find your tennis center with an accurate location.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            
            // Location Button
            _buildLocationButton(),
            const SizedBox(height: 24),
            
            // Address Form
            TextFormField(
              controller: _streetController,
              decoration: InputDecoration(
                labelText: 'Street Address',
                hintText: 'e.g., 123 Tennis Court',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(CupertinoIcons.location_solid),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            
            // City, State, ZIP Row
            Row(
              children: [
                // City
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    style: const TextStyle(fontSize: 16),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  ),
                ),
                const SizedBox(width: 12),
                // State
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _stateController,
                    decoration: InputDecoration(
                      labelText: 'State',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                    style: const TextStyle(fontSize: 16),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Req';
                      }
                      return null;
                    },
                    onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  ),
                ),
                const SizedBox(width: 12),
                // ZIP/Postal
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _postalCodeController,
                    decoration: InputDecoration(
                      labelText: 'ZIP',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                    style: const TextStyle(fontSize: 16),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Req';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Country
            TextFormField(
              controller: _countryController,
              decoration: InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(CupertinoIcons.globe),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              style: const TextStyle(fontSize: 16),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a country';
                }
                return null;
              },
              onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
            
            const SizedBox(height: 24),
            
            // Map Preview
            _buildMapPlaceholder(),
            
            const SizedBox(height: 8),
            Text(
              'Verify the location is correct. Players will use this to find your tennis center.',
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
