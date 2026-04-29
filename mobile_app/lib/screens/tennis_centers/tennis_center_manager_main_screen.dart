import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'tennis_center_manager_dashboard.dart';
import 'bookings_management_screen.dart';
import 'courts_management_screen.dart'; // We'll create this next

class TennisCenterManagerMainScreen extends StatefulWidget {
  const TennisCenterManagerMainScreen({super.key});

  @override
  State<TennisCenterManagerMainScreen> createState() => _TennisCenterManagerMainScreenState();
}

class _TennisCenterManagerMainScreenState extends State<TennisCenterManagerMainScreen> {
  int _selectedIndex = 0;
  String? _selectedTennisCenterId;
  
  @override
  void initState() {
    super.initState();
    // Initialize the selected tennis center ID
    _initSelectedTennisCenter();
  }
  
  Future<void> _initSelectedTennisCenter() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final managedTennisCenters = authProvider.userModel?.managedTennisCenters ?? [];
    
    if (managedTennisCenters.isNotEmpty && _selectedTennisCenterId == null) {
      setState(() {
        _selectedTennisCenterId = managedTennisCenters.first;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.building_2_fill),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.sportscourt),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar),
            label: '',
          ),
        ],
      ),
    );
  }
  
  Widget _buildBody() {
    // Get the list of managed tennis centers
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final managedTennisCenters = authProvider.userModel?.managedTennisCenters ?? [];
    
    // Show a placeholder if no tennis centers are available
    if (managedTennisCenters.isEmpty) {
      return const Center(
        child: Text('No tennis centers to manage'),
      );
    }
    
    // Make sure we have a selected tennis center ID
    _selectedTennisCenterId ??= managedTennisCenters.first;
    
    // Return the appropriate screen based on the selected index
    switch (_selectedIndex) {
      case 0:
        return TennisCenterManagerDashboard(
          key: const PageStorageKey('dashboard'),
          onTennisCenterSelected: (tennisCenterId) {
            setState(() {
              _selectedTennisCenterId = tennisCenterId;
            });
          },
        );
      case 1:
        return CourtsManagementScreen(
          key: const PageStorageKey('courts'),
          tennisCenterId: _selectedTennisCenterId!,
        );
      case 2:
        return BookingsManagementScreen(
          key: const PageStorageKey('bookings'),
          tennisCenterId: _selectedTennisCenterId!,
        );
      default:
        return TennisCenterManagerDashboard(
          key: const PageStorageKey('dashboard'),
          onTennisCenterSelected: (tennisCenterId) {
            setState(() {
              _selectedTennisCenterId = tennisCenterId;
            });
          },
        );
    }
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
