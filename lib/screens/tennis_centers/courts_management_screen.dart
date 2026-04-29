import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/tennis_centers_provider.dart';
import '../../services/data_service.dart';
import '../../widgets/squircle_container.dart';
import '../../widgets/squircle_button.dart';
import '../../utils/responsive_utils.dart';
import 'add_court_screen.dart';
import 'edit_court_screen.dart';

class CourtsManagementScreen extends StatefulWidget {
  final String tennisCenterId;
  
  const CourtsManagementScreen({
    super.key,
    required this.tennisCenterId,
  });

  @override
  State<CourtsManagementScreen> createState() => _CourtsManagementScreenState();
}

class _CourtsManagementScreenState extends State<CourtsManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _courts = [];
  String _tennisCenterName = 'Tennis Center';
  
  // Surface type colors for display
  final Map<String, Color> _surfaceColors = {
    'clay': Colors.orange[300]!,
    'hard': Colors.blue[300]!,
    'grass': Colors.green[400]!,
    'carpet': Colors.purple[200]!,
  };
  
  @override
  void initState() {
    super.initState();
    _loadCourts();
  }
  
  Future<void> _loadCourts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final tennisCentersProvider = Provider.of<TennisCentersProvider>(context, listen: false);
      final courts = await tennisCentersProvider.getCourtsForTennisCenter(widget.tennisCenterId);
      
      // Get tennis center name
      final dataService = DataService();
      final tennisCenterData = await dataService.getTennisCenterById(widget.tennisCenterId);
      _tennisCenterName = tennisCenterData?['name'] ?? 'Tennis Center';
      
      setState(() {
        _courts = courts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading courts: $e');
      setState(() {
        _isLoading = false;
      });
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
        title: const Text('Courts Management'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCourts,
              child: _courts.isEmpty
                  ? _buildEmptyState(verticalSpacing)
                  : _buildCourtsList(verticalSpacing, horizontalSpacing),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCourtScreen(
                tennisCenterId: widget.tennisCenterId,
                tennisCenterName: _tennisCenterName,
              ),
            ),
          );
          
          // Refresh courts list if a court was added
          if (result == true) {
            _loadCourts();
          }
        },
        child: const Icon(CupertinoIcons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  
  Widget _buildEmptyState(double verticalSpacing) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.sportscourt,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Courts Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any courts for this tennis center yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          SquircleButton(
            label: 'Add Court',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCourtScreen(
                    tennisCenterId: widget.tennisCenterId,
                    tennisCenterName: _tennisCenterName,
                  ),
                ),
              );
              
              // Refresh courts list if a court was added
              if (result == true) {
                _loadCourts();
              }
            },
            width: 200,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCourtsList(double verticalSpacing, double horizontalSpacing) {
    return ListView.builder(
      padding: EdgeInsets.all(horizontalSpacing),
      itemCount: _courts.length,
      itemBuilder: (context, index) {
        final court = _courts[index];
        return SquircleContainer(
          margin: EdgeInsets.only(bottom: verticalSpacing),
          padding: EdgeInsets.all(horizontalSpacing),
          color: Colors.white,
          cornerRadius: 16,
          cornerSmoothing: 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      court['name'] ?? 'Court',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.pencil),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditCourtScreen(
                            tennisCenterId: widget.tennisCenterId,
                            tennisCenterName: _tennisCenterName,
                            courtData: court,
                          ),
                        ),
                      );
                      
                      // Refresh courts list if a court was updated
                      if (result == true) {
                        _loadCourts();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Court surface
              Row(
                children: [
                  Icon(CupertinoIcons.sportscourt, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSurfaceColor(court['surface']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Surface: ${_capitalizeFirstLetter(court['surface'] ?? 'hard')}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      court['indoor'] == true ? 'Indoor' : 'Outdoor',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Court features
              Row(
                children: [
                  Icon(CupertinoIcons.star, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Features: ${_getFeaturesList(court['features'])}',
                      style: TextStyle(color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Court price
              Row(
                children: [
                  Icon(CupertinoIcons.money_dollar_circle, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Price: \$${(court['hourlyRate'] ?? 0.0).toStringAsFixed(2)}/hour',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(CupertinoIcons.clock, size: 16),
                    label: const Text('Availability'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Court Availability feature coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Helper method to get surface color
  Color _getSurfaceColor(String? surface) {
    if (surface == null) return _surfaceColors['hard']!;
    return _surfaceColors[surface.toLowerCase()] ?? _surfaceColors['hard']!;
  }
  
  // Helper method to capitalize first letter
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  // Helper method to format features list
  String _getFeaturesList(dynamic features) {
    if (features == null) return 'None';
    if (features is List && features.isEmpty) return 'None';
    if (features is List) {
      return features.join(', ');
    }
    return 'None';
  }
}
