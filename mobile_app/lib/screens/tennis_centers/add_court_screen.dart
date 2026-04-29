import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/court_model.dart';
import '../../services/data_service.dart';
import '../../widgets/squircle_button.dart';
import '../../widgets/squircle_container.dart';
import '../../widgets/squircle_text_field.dart';
import '../../utils/responsive_utils.dart';

class AddCourtScreen extends StatefulWidget {
  final String tennisCenterId;
  final String tennisCenterName;
  
  const AddCourtScreen({
    super.key,
    required this.tennisCenterId,
    required this.tennisCenterName,
  });

  @override
  State<AddCourtScreen> createState() => _AddCourtScreenState();
}

class _AddCourtScreenState extends State<AddCourtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  
  SurfaceType _selectedSurface = SurfaceType.hard;
  bool _isIndoor = false;
  bool _hasLighting = true;
  bool _isLoading = false;
  
  // Court availability
  Map<String, dynamic> _tennisCenterAvailability = {};
  final bool _isUsingCustomAvailability = false;
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
    _loadTennisCenterAvailability();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }
  
  // Load tennis center operating hours
  Future<void> _loadTennisCenterAvailability() async {
    setState(() {
      _isLoadingAvailability = true;
    });
    
    try {
      final dataService = DataService();
      
      // Load tennis center operating hours
      _tennisCenterAvailability = await dataService.getTennisCenterOperatingHours(widget.tennisCenterId);
      
      setState(() {
        _isLoadingAvailability = false;
      });
    } catch (e) {
      debugPrint('Error loading tennis center availability: $e');
      setState(() {
        _isLoadingAvailability = false;
      });
    }
  }
  
  // Add a new court to the tennis center
  Future<void> _addCourt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dataService = DataService();
      
      // Create court data map
      final courtData = {
        'tennisCenter': widget.tennisCenterId,
        'name': _nameController.text.trim(),
        'surface': _selectedSurface.toString().split('.').last,
        'indoor': _isIndoor,
        'hourlyRate': double.parse(_hourlyRateController.text),
        'images': [], // No images initially
        'features': [], // Features are managed at the tennis center level
        'hasLighting': _hasLighting,
      };
      
      // Add availability if using custom availability
      if (_isUsingCustomAvailability) {
        // In this case, we would add custom availability
        // But for now, we'll just inherit from the tennis center
        // by not setting availability at all
      }
      
      // Add court in the backend
      await dataService.addCourt(widget.tennisCenterId, courtData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Court "${_nameController.text}" added successfully')),
        );
        
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add court: $e')),
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
        title: Text('Add Court - ${widget.tennisCenterName}'),
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
                    
                    // Add court button
                    Center(
                      child: SquircleButton(
                        label: 'Add Court',
                        onPressed: _addCourt,
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
              _nameController.text.isEmpty ? 'New Court' : _nameController.text,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        'This court will inherit availability hours from the tennis center.',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const Divider(),
                    
                    // Display availability hours
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        'Tennis Center Operating Hours',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    
                    // Display days of the week
                    ..._buildDaysOfWeekAvailability(),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    
                    // Note about editing availability after creation
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'You can set custom availability hours for this court after creation by editing the court.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
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
    
    return days.map((day) {
      final capitalizedDay = day[0].toUpperCase() + day.substring(1);
      final dayData = _tennisCenterAvailability[day] as Map<String, dynamic>?;
      
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
}
