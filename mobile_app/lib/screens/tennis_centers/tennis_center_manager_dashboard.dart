import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tennis_centers_provider.dart';
import '../../widgets/squircle_button.dart';
import '../../widgets/squircle_container.dart';
import '../../utils/responsive_utils.dart';

class TennisCenterManagerDashboard extends StatefulWidget {
  final Function(String)? onTennisCenterSelected;
  
  const TennisCenterManagerDashboard({
    super.key,
    this.onTennisCenterSelected,
  });

  @override
  State<TennisCenterManagerDashboard> createState() => _TennisCenterManagerDashboardState();
}

class _TennisCenterManagerDashboardState extends State<TennisCenterManagerDashboard> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _managedCenters = [];
  
  @override
  void initState() {
    super.initState();
    _loadManagedCenters();
  }

  Future<void> _loadManagedCenters() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final tennisCentersProvider = Provider.of<TennisCentersProvider>(context, listen: false);
      
      if (authProvider.userModel?.managedTennisCenters != null) {
        final centers = await tennisCentersProvider.getTennisCentersByIds(
          authProvider.userModel!.managedTennisCenters!
        );
        
        setState(() {
          _managedCenters = centers;
          _isLoading = false;
        });
      } else {
        setState(() {
          _managedCenters = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading managed centers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userModel = authProvider.userModel;
    
    // Initialize responsive utils for this screen
    ResponsiveUtils.init(context);
    
    // Calculate responsive sizes
    final double verticalSpacing = ResponsiveUtils.blockSizeVertical * 2;
    final double horizontalSpacing = ResponsiveUtils.blockSizeHorizontal * 3;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tennis Centers'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_right),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadManagedCenters,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(horizontalSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    Text(
                      'Welcome, ${userModel?.displayName ?? 'Manager'}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: verticalSpacing * 0.5),
                    
                    Text(
                      'Manage your tennis centers and court bookings',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    SizedBox(height: verticalSpacing),
                    
                    // Tennis centers list
                    _managedCenters.isEmpty
                        ? _buildEmptyState(verticalSpacing)
                        : _buildTennisCentersList(verticalSpacing, horizontalSpacing),
                  ],
                ),
              ),
            ),
      // Floating action button removed as per user request
    );
  }
  
  Widget _buildEmptyState(double verticalSpacing) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: verticalSpacing * 3),
          Icon(
            CupertinoIcons.building_2_fill,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: verticalSpacing),
          Text(
            'No Tennis Centers Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: verticalSpacing * 0.5),
          Text(
            'You don\'t have any tennis centers to manage yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: verticalSpacing),
          SquircleButton(
            label: 'Add Tennis Center',
            onPressed: () {
              // TODO: Navigate to add tennis center screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Tennis Center feature coming soon')),
              );
            },
            width: 200,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTennisCentersList(double verticalSpacing, double horizontalSpacing) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _managedCenters.length,
      itemBuilder: (context, index) {
        final center = _managedCenters[index];
        return SquircleContainer(
          margin: EdgeInsets.only(bottom: verticalSpacing),
          padding: EdgeInsets.all(horizontalSpacing),
          color: Colors.white,
          cornerRadius: 16,
          cornerSmoothing: 0.6,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/tennis_center_details',
                arguments: {
                  'tennisCenterId': center['id'],
                },
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(horizontalSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          center['name'] ?? 'Tennis Center',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: verticalSpacing * 0.5),
                  Row(
                    children: [
                      Icon(CupertinoIcons.location_solid, color: Colors.grey[600], size: 16),
                      SizedBox(width: horizontalSpacing * 0.5),
                      Expanded(
                        child: Text(
                          center['address'] is Map
                              ? '${(center['address'] as Map)['street']}, ${(center['address'] as Map)['city']}, ${(center['address'] as Map)['state']}'
                              : 'No address provided',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: verticalSpacing * 0.5),
                  Row(
                    children: [
                      Icon(CupertinoIcons.sportscourt, color: Colors.grey[600], size: 16),
                      SizedBox(width: horizontalSpacing * 0.5),
                      Text(
                        '${center['courtsCount'] ?? 0} Courts',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  SizedBox(height: verticalSpacing * 0.5),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
