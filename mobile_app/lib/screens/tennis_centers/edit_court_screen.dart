import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/court_model.dart';
import '../../services/data_service.dart';
import '../../widgets/squircle_button.dart';
import '../../widgets/squircle_container.dart';
import '../../widgets/squircle_text_field.dart';
import '../../utils/responsive_utils.dart';

class EditCourtScreen extends StatefulWidget {
  final String tennisCenterId;
  final String tennisCenterName;
  final Map<String, dynamic> courtData;
  
  const EditCourtScreen({
    super.key,
    required this.tennisCenterId,
    required this.tennisCenterName,
    required this.courtData,
  });

  @override
  State<EditCourtScreen> createState() => _EditCourtScreenState();
}

class _EditCourtScreenState extends State<EditCourtScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _hourlyRateController;
  
  late SurfaceType _selectedSurface;
  late bool _isIndoor;
  late bool _hasLighting;
  bool _isLoading = false;
  
  // Court availability
  Map<String, dynamic> _courtAvailability = {};
  Map<String, dynamic> _tennisCenterAvailability = {};
  bool _isUsingCustomAvailability = false;
  bool _isLoadingAvailability = true;
  
  // Court surface colors for preview
  final Map<SurfaceType, Color> _surfaceColors = {
    SurfaceType.clay: Colors.orange[300]!,
    SurfaceType.hard: Colors.blue[300]!,
    SurfaceType.grass: Colors.green[400]!,
    SurfaceType.carpet: Colors.purple[200]!,
  };
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.courtData['name'] ?? '');
    _hourlyRateController = TextEditingController(
      text: (widget.courtData['hourlyRate'] ?? 0.0).toString()
    );
    
    // Initialize surface type
    final surfaceStr = widget.courtData['surface'] ?? 'hard';
    _selectedSurface = _getSurfaceTypeFromString(surfaceStr);
    
    // Initialize other properties
    _isIndoor = widget.courtData['indoor'] ?? false;
    _hasLighting = widget.courtData['hasLighting'] ?? true;
    
    // Load availability slots
    _loadAvailabilitySlots();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }
  
  // Helper method to convert string to SurfaceType
  SurfaceType _getSurfaceTypeFromString(String surface) {
    switch (surface.toLowerCase()) {
      case 'clay':
        return SurfaceType.clay;
      case 'hard':
        return SurfaceType.hard;
      case 'grass':
        return SurfaceType.grass;
      case 'carpet':
        return SurfaceType.carpet;
      default:
        return SurfaceType.hard;
    }
  }
  
  // Load availability for this court
  Future<void> _loadAvailabilitySlots() async {
    setState(() {
      _isLoadingAvailability = true;
    });
    
    try {
      final dataService = DataService();
      
      // Load tennis center operating hours
      _tennisCenterAvailability = await dataService.getTennisCenterOperatingHours(widget.tennisCenterId);
      
      // Load court-specific availability if it exists
      final courtAvailability = await dataService.getCourtOperatingHours(widget.tennisCenterId, widget.courtData['id']);
      
      // Check if court has custom availability or is using tennis center availability
      final hasCustomAvailability = widget.courtData.containsKey('availability') && widget.courtData['availability'] != null;
      
      setState(() {
        _courtAvailability = courtAvailability;
        _isUsingCustomAvailability = hasCustomAvailability;
        _isLoadingAvailability = false;
      });
    } catch (e) {
      debugPrint('Error loading availability: $e');
      setState(() {
        _isLoadingAvailability = false;
      });
    }
  }
  
  // Update court in the backend
  Future<void> _updateCourt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataService = DataService();
      
      // Create updated court data
      final updatedCourtData = {
        'name': _nameController.text.trim(),
        'surface': _selectedSurface.toString().split('.').last,
        'indoor': _isIndoor,
        'hourlyRate': double.parse(_hourlyRateController.text),
        'hasLighting': _hasLighting,
      };
      
      // Update the court basic info
      await dataService.updateCourt(
        widget.tennisCenterId, 
        widget.courtData['id'], 
        updatedCourtData
      );
      
      // Handle court availability separately
      if (_isUsingCustomAvailability) {
        // Update with custom availability
        await dataService.updateCourtAvailability(
          widget.tennisCenterId,
          widget.courtData['id'],
          _courtAvailability
        );
      } else if (widget.courtData.containsKey('availability') && widget.courtData['availability'] != null) {
        // Remove custom availability to inherit from tennis center
        await dataService.updateCourtAvailability(
          widget.tennisCenterId,
          widget.courtData['id'],
          null
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Court "${_nameController.text}" updated successfully')),
        );
        
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update court: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Initialize responsive utils for this screen
    ResponsiveUtils.init(context);
    
    // Calculate responsive sizes
    final double verticalSpacing = ResponsiveUtils.blockSizeVertical * 2;
    final double horizontalSpacing = ResponsiveUtils.blockSizeHorizontal * 3;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Court - ${widget.tennisCenterName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(horizontalSpacing),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Court preview
                    _buildCourtPreview(horizontalSpacing),
                    SizedBox(height: verticalSpacing),
                    
                    // Court name
                    SquircleTextField(
                      controller: _nameController,
                      labelText: 'Court Name',
                      hintText: 'e.g. Court 1, Center Court',
                      prefixIcon: const Icon(CupertinoIcons.sportscourt),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a court name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: verticalSpacing),
                    
                    // Court surface selection
                    _buildSurfaceSelection(verticalSpacing, horizontalSpacing),
                    SizedBox(height: verticalSpacing),
                    
                    // Indoor/Outdoor toggle
                    _buildIndoorOutdoorToggle(horizontalSpacing),
                    SizedBox(height: verticalSpacing),
                    
                    // Lighting toggle
                    _buildLightingToggle(horizontalSpacing),
                    SizedBox(height: verticalSpacing),
                    
                    // Hourly rate
                    SquircleTextField(
                      controller: _hourlyRateController,
                      labelText: 'Hourly Rate (\$)',
                      hintText: 'e.g. 25.00',
                      prefixIcon: const Icon(CupertinoIcons.money_dollar),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an hourly rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: verticalSpacing),
                    
                    // Court availability section
                    _buildAvailabilitySection(verticalSpacing, horizontalSpacing),
                    SizedBox(height: verticalSpacing * 2),
                    
                    // Update court button
                    Center(
                      child: SquircleButton(
                        label: 'Update Court',
                        onPressed: _updateCourt,
                        width: double.infinity,
                      ),
                    ),
                    SizedBox(height: verticalSpacing),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildCourtPreview(double horizontalSpacing) {
    return SquircleContainer(
      height: 180,
      color: _surfaceColors[_selectedSurface]!,
      cornerRadius: 16,
      cornerSmoothing: 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.sportscourt,
              size: 60,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              _nameController.text.isEmpty ? 'Court' : _nameController.text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_selectedSurface.toString().split('.').last.toUpperCase()} - ${_isIndoor ? 'Indoor' : 'Outdoor'}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSurfaceSelection(double verticalSpacing, double horizontalSpacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Court Surface',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildSurfaceOption(SurfaceType.clay, 'Clay', Colors.orange[300]!),
            SizedBox(width: horizontalSpacing),
            _buildSurfaceOption(SurfaceType.hard, 'Hard', Colors.blue[300]!),
            SizedBox(width: horizontalSpacing),
            _buildSurfaceOption(SurfaceType.grass, 'Grass', Colors.green[400]!),
            SizedBox(width: horizontalSpacing),
            _buildSurfaceOption(SurfaceType.carpet, 'Carpet', Colors.purple[200]!),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSurfaceOption(SurfaceType surface, String label, Color color) {
    final isSelected = _selectedSurface == surface;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSurface = surface;
          });
        },
        child: SquircleContainer(
          height: 80,
          color: color,
          cornerRadius: 12,
          cornerSmoothing: 0.6,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected)
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildIndoorOutdoorToggle(double horizontalSpacing) {
    return SquircleContainer(
      padding: EdgeInsets.all(horizontalSpacing),
      color: Colors.white,
      cornerRadius: 12,
      cornerSmoothing: 0.6,
      child: Row(
        children: [
          Icon(
            _isIndoor ? CupertinoIcons.house_fill : CupertinoIcons.sun_max_fill,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Court Environment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  _isIndoor ? 'Indoor Court' : 'Outdoor Court',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _isIndoor,
            activeTrackColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              setState(() {
                _isIndoor = value;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildLightingToggle(double horizontalSpacing) {
    return SquircleContainer(
      padding: EdgeInsets.all(horizontalSpacing),
      color: Colors.white,
      cornerRadius: 12,
      cornerSmoothing: 0.6,
      child: Row(
        children: [
          Icon(
            _hasLighting ? CupertinoIcons.lightbulb_fill : CupertinoIcons.lightbulb_slash,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Court Lighting',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  _hasLighting ? 'Court has lighting' : 'No lighting available',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _hasLighting,
            activeTrackColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              setState(() {
                _hasLighting = value;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAvailabilitySection(double verticalSpacing, double horizontalSpacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Court Availability',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        SquircleContainer(
          padding: EdgeInsets.all(horizontalSpacing),
          color: Colors.white,
          cornerRadius: 12,
          cornerSmoothing: 0.6,
          child: _isLoadingAvailability
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Column(
                  children: [
                    // Toggle between tennis center and custom availability
                    SwitchListTile(
                      title: Text(
                        'Use Custom Availability',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      subtitle: Text(
                        _isUsingCustomAvailability
                            ? 'Court has custom availability hours'
                            : 'Using tennis center availability hours',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      value: _isUsingCustomAvailability,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (value) {
                        setState(() {
                          _isUsingCustomAvailability = value;
                          
                          // If switching to custom availability, copy tennis center hours
                          if (value && _courtAvailability.isEmpty) {
                            _courtAvailability = Map<String, dynamic>.from(_tennisCenterAvailability);
                          }
                        });
                      },
                    ),
                    const Divider(),
                    
                    // Display availability hours
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Operating Hours',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    
                    // Display days of the week
                    ..._buildDaysOfWeekAvailability(),
                    
                    // Edit button for custom availability
                    if (_isUsingCustomAvailability)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(CupertinoIcons.pencil),
                          label: const Text('Edit Hours'),
                          onPressed: () {
                            _showEditAvailabilityDialog();
                          },
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
  
  // Build list of days with their operating hours
  List<Widget> _buildDaysOfWeekAvailability() {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final displayData = _isUsingCustomAvailability ? _courtAvailability : _tennisCenterAvailability;
    
    return days.map((day) {
      final capitalizedDay = day[0].toUpperCase() + day.substring(1);
      final dayData = displayData[day] as Map<String, dynamic>?;
      
      String hoursText = 'Closed';
      if (dayData != null) {
        final isClosed = dayData['isClosed'] ?? false;
        if (!isClosed) {
          final open = dayData['open'] ?? '09:00';
          final close = dayData['close'] ?? '21:00';
          hoursText = '$open - $close';
        }
      }
      
      return ListTile(
        dense: true,
        title: Text(capitalizedDay),
        trailing: Text(
          hoursText,
          style: TextStyle(
            color: hoursText == 'Closed' ? Colors.red : Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }).toList();
  }
  
  // Show dialog to edit availability hours
  void _showEditAvailabilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Availability'),
        content: const Text('Detailed availability editing will be implemented in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
