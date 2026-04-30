import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:mobile_app/config/app_config.dart';
import 'package:provider/provider.dart';
import 'package:figma_squircle/figma_squircle.dart';

import 'package:mobile_app/models/booking_model.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/providers/booking_provider.dart';
import 'package:mobile_app/providers/invitation_provider.dart';
import 'package:mobile_app/screens/calendar/calendar_screen.dart';
import 'package:mobile_app/screens/invitations/invitations_screen.dart';
import 'package:mobile_app/screens/map/tennis_centers_map_screen.dart';
import 'package:mobile_app/screens/profile/profile_screen.dart';
import 'package:mobile_app/screens/tennis_centers/tennis_centers_screen.dart';
import 'package:mobile_app/widgets/squircle_button.dart';
import 'package:mobile_app/widgets/squircle_container.dart';

void _openMapOrFallback(BuildContext context) {
  if (AppConfig.hasGoogleMapsConfig) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const TennisCentersMapScreen(),
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Map view is unavailable in this build. Showing centre list instead.',
      ),
    ),
  );
  Navigator.push(
    context,
    CupertinoPageRoute(
      builder: (context) => const TennisCentersScreen(),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final Set<int> _visitedTabs = <int>{0};

  static const int _homeTabIndex = 0;
  static const int _invitesTabIndex = 2;
  static const int _profileTabIndex = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      if (user == null) {
        return;
      }

      context.read<BookingProvider>().loadUserBookings(user.uid);
      context.read<InvitationProvider>().loadReceivedInvitations(user.uid);
    });
  }

  void _setTab(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index);
    });
  }

  PreferredSizeWidget? _buildAppBar(
    BuildContext context,
    int pendingInvitations,
    AuthProvider authProvider,
  ) {
    if (_selectedIndex != _homeTabIndex) {
      return null;
    }

    final user = authProvider.userModel;

    return AppBar(
      title: const Text(
        'Oval',
        style: TextStyle(
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
              onPressed: () => _setTab(_invitesTabIndex),
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
          onPressed: () => _setTab(_profileTabIndex),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  List<Widget> _buildTabs() {
    return [
      const _HomeTabContent(),
      _visitedTabs.contains(1)
          ? const CalendarScreen(showScaffold: false)
          : const SizedBox.shrink(),
      _visitedTabs.contains(2)
          ? const InvitationsScreen(showScaffold: false)
          : const SizedBox.shrink(),
      _visitedTabs.contains(3)
          ? const ProfileScreen(showScaffold: false)
          : const SizedBox.shrink(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final invitationProvider = context.watch<InvitationProvider>();
    final pendingInvitations =
        invitationProvider.getPendingReceivedInvitations().length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, pendingInvitations, authProvider),
      body: IndexedStack(
        index: _selectedIndex,
        children: _buildTabs(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _setTab,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house_fill),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar),
            label: 'Calendar',
          ),
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
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_crop_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTabContent extends StatelessWidget {
  const _HomeTabContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SearchSection(),
          SizedBox(height: 24),
          _UpcomingMatchesSection(),
          SizedBox(height: 24),
          _RecentCourtsSection(),
        ],
      ),
    );
  }
}

class _SearchSection extends StatelessWidget {
  const _SearchSection();

  @override
  Widget build(BuildContext context) {
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
                    _openMapOrFallback(context);
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
          const SizedBox(height: 8),
          Text(
            'Discover nearby tennis centres and book your next match.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SquircleButton(
                  label: 'Browse Centres',
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const TennisCentersScreen(),
                      ),
                    );
                  },
                  height: 46,
                ),
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: CupertinoIcons.map_pin_ellipse,
                label: 'Map',
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
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
}

class _UpcomingMatchesSection extends StatelessWidget {
  const _UpcomingMatchesSection();

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final now = DateTime.now();
    final upcomingBookings = bookingProvider.userBookings
        .where((booking) {
          if (booking.status == BookingStatus.cancelled ||
              booking.status == BookingStatus.completed ||
              booking.status == BookingStatus.noShow) {
            return false;
          }

          return booking.isUpcoming(now) || booking.isInProgress(now);
        })
        .take(3)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Matches',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (bookingProvider.isLoading && upcomingBookings.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (upcomingBookings.isEmpty)
          _EmptyCard(
            icon: CupertinoIcons.calendar_badge_plus,
            title: 'No upcoming matches',
            message: 'Book a court to see your next session here.',
          )
        else
          Column(
            children: upcomingBookings
                .map(
                  (booking) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(booking.tennisCenterName ?? 'Tennis Court'),
                      subtitle: Text(booking.formattedDateTime),
                      trailing: Text(
                        booking.statusString,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _RecentCourtsSection extends StatelessWidget {
  const _RecentCourtsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Explore Centres',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const TennisCentersScreen(),
                  ),
                );
              },
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _EmptyCard(
          icon: CupertinoIcons.search,
          title: 'Search by location or map',
          message: 'Use the map and centre browser to find courts near you.',
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SquircleContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.grey[50],
      cornerRadius: 16,
      cornerSmoothing: 0.6,
      border: Border.all(color: Colors.grey[200]!),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey[500]),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}
