import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/providers/booking_provider.dart';
import 'package:mobile_app/providers/invitation_provider.dart';
import 'package:mobile_app/screens/tennis_centers/tennis_centers_screen.dart';
import 'package:mobile_app/screens/profile/profile_screen.dart';
import 'package:mobile_app/screens/invitations/invitations_screen.dart';
import 'package:mobile_app/screens/calendar/calendar_screen.dart';
import 'package:mobile_app/screens/map/tennis_centers_map_screen.dart';
import 'package:mobile_app/widgets/squircle_button.dart';
import 'package:mobile_app/widgets/squircle_container.dart';
import 'package:figma_squircle/figma_squircle.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Load user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        // Load bookings
        final bookingProvider =
            Provider.of<BookingProvider>(context, listen: false);
        bookingProvider.loadUserBookings(authProvider.user!.uid);

        // Load invitations
        final invitationProvider =
            Provider.of<InvitationProvider>(context, listen: false);
        invitationProvider.loadReceivedInvitations(authProvider.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SquircleContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.grey[50],
        cornerRadius: 12,
        cornerSmoothing: 0.6,
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: const Color(0xFF1A5D1A),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final invitationProvider = Provider.of<InvitationProvider>(context);

    // Count pending invitations
    final pendingInvitations =
        invitationProvider.getPendingReceivedInvitations().length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0
          ? AppBar(
              title: Text(
                'Oval',
                style: const TextStyle(
                  fontFamily: 'TexGyreAdventor',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xFF1A5D1A),
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.bell),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InvitationsScreen(),
                          ),
                        );
                      },
                    ),
                    if (pendingInvitations > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: SquircleContainer(
                          padding: const EdgeInsets.all(2),
                          color: Colors.red,
                          cornerRadius: 10,
                          cornerSmoothing: 0.6,
                          width: 16,
                          height: 16,
                          child: Text(
                            '$pendingInvitations',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: CircleAvatar(
                    radius: 15,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user?.displayName != null && user!.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          // Home tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchSection(),
                const SizedBox(height: 24),
                _buildUpcomingMatches(),
                const SizedBox(height: 24),
                _buildRecentCourts(),
              ],
            ),
          ),

          // Calendar tab (includes bookings)
          const CalendarScreen(),

          // Invites tab
          const InvitationsScreen(),

          // Profile tab
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house_fill), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.calendar), label: 'Calendar'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(CupertinoIcons.person_2_square_stack),
                if (pendingInvitations > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        pendingInvitations > 9
                            ? '9+'
                            : pendingInvitations.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Invites',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 16,
            cornerSmoothing: 0.6,
          ),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Find a Court',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A5D1A),
                      ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const TennisCentersMapScreen(),
                      ),
                    );
                  },
                  child: SquircleContainer(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: const Color(0xFF1A5D1A).withValues(alpha: 0.1),
                    cornerRadius: 16,
                    cornerSmoothing: 0.6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.map,
                          size: 14,
                          color: Color(0xFF1A5D1A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View Map',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF1A5D1A),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const TennisCentersMapScreen(),
                ),
              );
            },
            child: Hero(
              tag: 'search_bar',
              child: Material(
                color: Colors.transparent,
                child: SquircleContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.grey[100],
                  cornerRadius: 16,
                  cornerSmoothing: 0.6,
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.search,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Search for tennis courts...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickAction(
                  icon: CupertinoIcons.location_fill,
                  label: 'Nearby',
                  onTap: () {
                    // TODO: Implement nearby courts
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickAction(
                  icon: CupertinoIcons.clock_fill,
                  label: 'Available Now',
                  onTap: () {
                    // TODO: Implement available now
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickAction(
                  icon: CupertinoIcons.star_fill,
                  label: 'Top Rated',
                  onTap: () {
                    // TODO: Implement top rated
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickAction(
                  icon: CupertinoIcons.map_fill,
                  label: 'Map View',
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const TennisCentersMapScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by location',
              prefixIcon: const Icon(CupertinoIcons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SquircleButton(
                  label: 'Find Courts',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TennisCentersScreen(),
                      ),
                    );
                  },
                  width: double.infinity,
                  height: 50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingMatches() {
    return Consumer<BookingProvider>(
      builder: (context, provider, child) {
        final upcomingBookings = provider.getUpcomingBookings();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Matches',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    _onItemTapped(
                        1); // Navigate to Calendar tab which now includes bookings
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (upcomingBookings.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No upcoming matches',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      SquircleButton(
                        label: 'Book a Court',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TennisCentersScreen(),
                            ),
                          );
                        },
                        width: double.infinity,
                        height: 50,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: upcomingBookings.take(2).map((booking) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMatchCard(
                      date: booking.date,
                      time: '${booking.startTime} - ${booking.endTime}',
                      location: booking.tennisCenterName ?? 'Tennis Center',
                      court: booking.courtName ?? 'Court',
                      opponent: booking.inviteeName ?? 'Open Match',
                      bookingId: booking.id,
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMatchCard({
    required String date,
    required String time,
    required String location,
    required String court,
    required String opponent,
    String? bookingId,
  }) {
    return SquircleContainer(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      cornerRadius: 12,
      cornerSmoothing: 0.6,
      boxShadow: [
        BoxShadow(
          color: const Color.fromRGBO(158, 158, 158, 0.1),
          spreadRadius: 1,
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SquircleContainer(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: Color.fromRGBO(
                    Theme.of(context).colorScheme.secondary.r.toInt(),
                    Theme.of(context).colorScheme.secondary.g.toInt(),
                    Theme.of(context).colorScheme.secondary.b.toInt(),
                    0.2),
                cornerRadius: 8,
                cornerSmoothing: 0.6,
                child: Text(
                  date,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(CupertinoIcons.location, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$location - $court',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  opponent[0],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opponent,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Intermediate',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCourts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popular Tennis Centers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TennisCentersScreen(),
                  ),
                );
              },
              child: Text(
                'View All',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCourtCard(
                name: 'Central Tennis Club',
                address: '123 Main St, New York',
                rating: 4.5,
                imageUrl: null,
              ),
              const SizedBox(width: 12),
              _buildCourtCard(
                name: 'Riverside Tennis Center',
                address: '456 Park Ave, New York',
                rating: 4.2,
                imageUrl: null,
              ),
              const SizedBox(width: 12),
              _buildCourtCard(
                name: 'Downtown Tennis Club',
                address: '789 Broadway, New York',
                rating: 4.8,
                imageUrl: null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourtCard({
    required String name,
    required String address,
    required double rating,
    String? imageUrl,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TennisCentersScreen(),
          ),
        );
      },
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(158, 158, 158, 0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.sports_tennis,
                            size: 50,
                            color: Colors.white,
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.sports_tennis,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.location,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.star_fill,
                          size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SquircleButton(
                          label: 'Book',
                          onPressed: () {},
                          width: double.infinity,
                          height: 50,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
