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
  final Set<int> _visitedTabs = <int>{0};
  
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
  
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    switch (_selectedIndex) {
      case 1:
        return AppBar(title: const Text('Courts Management'));
      case 2:
        return AppBar(title: const Text('Bookings'));
      case 0:
      default:
        return AppBar(
          title: const Text('Tennis Centers'),
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.square_arrow_right),
              onPressed: () => authProvider.signOut(),
            ),
          ],
        );
    }
  }

  List<Widget> _buildTabs(String selectedTennisCenterId) {
    return [
      _visitedTabs.contains(0)
          ? TennisCenterManagerDashboard(
              key: const PageStorageKey('dashboard'),
              showScaffold: false,
              onTennisCenterSelected: (tennisCenterId) {
                setState(() {
                  _selectedTennisCenterId = tennisCenterId;
                });
              },
            )
          : const SizedBox.shrink(),
      _visitedTabs.contains(1)
          ? CourtsManagementScreen(
              key: const PageStorageKey('courts'),
              showScaffold: false,
              tennisCenterId: selectedTennisCenterId,
            )
          : const SizedBox.shrink(),
      _visitedTabs.contains(2)
          ? BookingsManagementScreen(
              key: const PageStorageKey('bookings'),
              showScaffold: false,
              tennisCenterId: selectedTennisCenterId,
            )
          : const SizedBox.shrink(),
    ];
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
    
    final selectedTennisCenterId =
        managedTennisCenters.contains(_selectedTennisCenterId)
            ? _selectedTennisCenterId!
            : managedTennisCenters.first;
    _selectedTennisCenterId = selectedTennisCenterId;

    return IndexedStack(
      index: _selectedIndex,
      children: _buildTabs(selectedTennisCenterId),
    );
  }
  
  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
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
}
