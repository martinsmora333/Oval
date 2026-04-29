import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import 'edit_profile_screen.dart';
import '../auth/login_screen.dart';
import '../../widgets/squircle_button.dart';
import '../../widgets/squircle_container.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  void _loadUserData() {
    // Use a future delayed to avoid build-time setState issues
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final userModel = authProvider.userModel;
      
      // Force refresh user data if needed
      if (user != null && userModel == null) {
        authProvider.refreshUserData();
      }
      
      if (user != null) {
        // Load bookings
        final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
        if (bookingProvider.userBookings.isEmpty) {
          bookingProvider.loadUserBookings(user.uid);
        }
      }
    });
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      await authProvider.refreshUserData();
      
      if (authProvider.user != null) {
        await bookingProvider.refreshBookings(authProvider.user!.uid);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userModel = authProvider.userModel;
    
    // Login screen if not authenticated
    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'TexGyreAdventor'),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.person_circle_fill, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Please sign in to view your profile',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'TexGyreAdventor',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              SquircleButton(
                label: 'Sign In',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                width: double.infinity,
                height: 50,
              ),
            ],
          ),
        ),
      );
    }

    // Loading screen while fetching user data
    if (userModel == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'TexGyreAdventor'),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(fontFamily: 'TexGyreAdventor'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Main profile screen with user data
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'TexGyreAdventor'),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.pencil),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((_) {
                // Refresh the profile when returning from edit screen
                _refreshData();
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile header with background
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Stack(
                  children: [
                    // Tennis ball pattern for background
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: Image.network(
                          'https://img.freepik.com/free-vector/tennis-ball-pattern-background_1412-34.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                      child: Column(
                        children: [
                          // Profile picture
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromRGBO(0, 0, 0, 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                child: userModel.profileImageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(60),
                                        child: Image.network(
                                          userModel.profileImageUrl!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Text(
                                              userModel.displayName[0].toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 40,
                                                color: Colors.white,
                                                fontFamily: 'TexGyreAdventor',
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Text(
                                        userModel.displayName[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 40,
                                          color: Colors.white,
                                          fontFamily: 'TexGyreAdventor',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // User name
                          Text(
                            userModel.displayName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'TexGyreAdventor',
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Player level
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 255, 255, 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatPlayerLevel(userModel.playerLevel),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'TexGyreAdventor',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // User stats
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Consumer<BookingProvider>(
                  builder: (context, bookingProvider, _) {
                    final upcomingCount = bookingProvider.getUpcomingBookings().length;
                    final pastCount = bookingProvider.getPastBookings().length;
                    final confirmedCount = bookingProvider.userBookings
                        .where((b) => b.status == BookingStatus.confirmed)
                        .length;
                    
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(context, upcomingCount.toString(), 'Upcoming'),
                        _buildStatItem(context, pastCount.toString(), 'Past'),
                        _buildStatItem(context, confirmedCount.toString(), 'Confirmed'),
                      ],
                    );
                  },
                ),
              ),
              
              // Account and preferences sections
              SquircleContainer(
                margin: const EdgeInsets.all(16),
                color: Colors.white,
                cornerRadius: 16,
                cornerSmoothing: 0.6,
                elevation: 2,
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                child: Column(
                  children: [
                    // Account Information
                    _buildProfileSectionCard(
                      context,
                      'Account Information',
                      Icons.person_outline,
                      [
                        _buildProfileItem(context, 'Email', userModel.email),
                        if (userModel.phoneNumber != null && userModel.phoneNumber!.isNotEmpty)
                          _buildProfileItem(context, 'Phone', userModel.phoneNumber!),
                        _buildProfileItem(
                          context, 
                          'Member Since', 
                          DateFormat('MMMM d, yyyy').format(userModel.createdAt)
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Playing preferences
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _buildProfileSectionCard(
                  context,
                  'Playing Preferences',
                  Icons.sports_tennis,
                  [
                    _buildProfileItem(
                      context, 
                      'Player Level', 
                      _formatPlayerLevel(userModel.playerLevel),
                    ),
                    if (userModel.preferredPlayTimes != null && userModel.preferredPlayTimes!.isNotEmpty)
                      _buildProfileItem(
                        context, 
                        'Preferred Times', 
                        userModel.preferredPlayTimes!.join(', ')
                      ),
                    if (userModel.preferredLocations != null && userModel.preferredLocations!.isNotEmpty)
                      _buildProfileItem(
                        context, 
                        'Preferred Locations', 
                        userModel.preferredLocations!.join(', ')
                      ),
                  ],
                ),
              ),
              
              // Payment information
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _buildProfileSectionCard(
                  context,
                  'Payment Information',
                  Icons.payment,
                  [
                    userModel.stripeCustomerId != null
                        ? _buildProfileItem(
                            context, 
                            'Payment Methods', 
                            userModel.paymentMethods != null && userModel.paymentMethods!.isNotEmpty
                                ? '${userModel.paymentMethods!.length} saved'
                                : 'No payment methods'
                          )
                        : _buildProfileItem(
                            context, 
                            'Payment Methods', 
                            'Not set up'
                          ),
                    _buildActionItem(
                      context, 
                      'Manage Payment Methods', 
                      () {
                        // TODO: Navigate to payment methods screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon'))
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Sign out button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SquircleButton(
                  label: 'Sign Out',
                  onPressed: () => _showSignOutDialog(context),
                  width: double.infinity,
                  height: 50,
                ),
              ),
              
              // Version information
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'Oval Tennis v1.0.0',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontFamily: 'TexGyreAdventor',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontFamily: 'TexGyreAdventor',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSectionCard(BuildContext context, String title, IconData icon, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'TexGyreAdventor',
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...items,
        ],
      ),
    );
  }
  
  Widget _buildProfileItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: 'TexGyreAdventor',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'TexGyreAdventor',
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionItem(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'TexGyreAdventor',
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatPlayerLevel(PlayerLevel level) {
    switch (level) {
      case PlayerLevel.beginner:
        return 'Beginner';  
      case PlayerLevel.intermediate:
        return 'Intermediate';
      case PlayerLevel.advanced:
        return 'Advanced';
      case PlayerLevel.pro:
        return 'Professional';
    }
  }
  
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
