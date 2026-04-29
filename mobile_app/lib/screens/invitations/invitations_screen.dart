import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/invitation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/invitation_provider.dart';
import '../../providers/booking_provider.dart';
import '../bookings/booking_details_screen.dart';
import '../../widgets/squircle_container.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load invitations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final invitationProvider =
            Provider.of<InvitationProvider>(context, listen: false);
        invitationProvider.loadReceivedInvitations(authProvider.user!.uid);
        invitationProvider.loadSentInvitations(authProvider.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildTabBar(BuildContext context) {
    return TabBar(
      controller: _tabController,
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Theme.of(context).colorScheme.primary,
      tabs: const [
        Tab(text: 'Received'),
        Tab(text: 'Sent'),
      ],
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildReceivedInvitationsTab(),
        _buildSentInvitationsTab(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showScaffold) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: kToolbarHeight * 0.7,
          titleSpacing: 0,
          bottom: _buildTabBar(context),
        ),
        body: _buildTabView(),
      );
    }

    return Column(
      children: [
        Material(color: Colors.white, child: _buildTabBar(context)),
        Expanded(child: _buildTabView()),
      ],
    );
  }

  Widget _buildReceivedInvitationsTab() {
    return Consumer<InvitationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final receivedInvitations = provider.receivedInvitations;

        if (receivedInvitations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.mail,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No invitations received',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: receivedInvitations.length,
          itemBuilder: (context, index) {
            final invitation = receivedInvitations[index];
            return _buildReceivedInvitationCard(invitation);
          },
        );
      },
    );
  }

  Widget _buildSentInvitationsTab() {
    return Consumer<InvitationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final sentInvitations = provider.sentInvitations;

        if (sentInvitations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.paperplane,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No invitations sent',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sentInvitations.length,
          itemBuilder: (context, index) {
            final invitation = sentInvitations[index];
            return _buildSentInvitationCard(invitation);
          },
        );
      },
    );
  }

  Widget _buildReceivedInvitationCard(InvitationModel invitation) {
    final now = DateTime.now();
    final isExpired = invitation.isExpired(now);
    final isPending =
        invitation.status == InvitationStatus.pending && !isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(invitation.status, isExpired),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isExpired && invitation.status == InvitationStatus.pending
                        ? 'Expired'
                        : invitation.statusString,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  isPending
                      ? invitation.formattedTimeRemaining(now)
                      : _formatDateTime(invitation.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Invitation details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 20,
                  child: Text(
                    invitation.creatorName != null &&
                            invitation.creatorName!.isNotEmpty
                        ? invitation.creatorName![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.creatorName ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'invited you to play tennis',
                        style: TextStyle(
                          color: Colors.grey[800],
                        ),
                      ),
                      if (invitation.message != null &&
                          invitation.message!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '"${invitation.message!}"',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Booking details
            FutureBuilder(
              future: Provider.of<BookingProvider>(context, listen: false)
                  .getBookingById(invitation.bookingId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final booking = snapshot.data;

                if (booking == null) {
                  return const Text('Booking details not available');
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingDetailsScreen(
                          bookingId: booking.id,
                        ),
                      ),
                    );
                  },
                  child: SquircleContainer(
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey[100],
                    cornerRadius: 8,
                    cornerSmoothing: 0.6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.courtName ?? 'Court',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.tennisCenterName ?? 'Tennis Center',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.calendar,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              booking.date,
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              CupertinoIcons.time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.startTime} - ${booking.endTime}',
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Action buttons for pending invitations
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineInvitation(invitation.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptInvitation(invitation.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSentInvitationCard(InvitationModel invitation) {
    final now = DateTime.now();
    final isExpired = invitation.isExpired(now);
    final isAwaitingResponse =
        invitation.status == InvitationStatus.pending && !isExpired;
    final canCancel =
        invitation.status == InvitationStatus.queued || isAwaitingResponse;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(invitation.status, isExpired),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isExpired && invitation.status == InvitationStatus.pending
                        ? 'Expired'
                        : invitation.statusString,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  isAwaitingResponse
                      ? invitation.formattedTimeRemaining(now)
                      : _formatDateTime(invitation.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Invitation details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange,
                  radius: 20,
                  child: Text(
                    invitation.inviteeName != null &&
                            invitation.inviteeName!.isNotEmpty
                        ? invitation.inviteeName![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.inviteeName ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAwaitingResponse
                            ? 'waiting for response'
                            : invitation.status == InvitationStatus.queued
                                ? 'queued for invitation'
                                : invitation.status == InvitationStatus.accepted
                                    ? 'accepted your invitation'
                                    : 'declined your invitation',
                        style: TextStyle(
                          color: Colors.grey[800],
                        ),
                      ),
                      if (invitation.message != null &&
                          invitation.message!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '"${invitation.message!}"',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Booking details
            FutureBuilder(
              future: Provider.of<BookingProvider>(context, listen: false)
                  .getBookingById(invitation.bookingId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final booking = snapshot.data;

                if (booking == null) {
                  return const Text('Booking details not available');
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingDetailsScreen(
                          bookingId: booking.id,
                        ),
                      ),
                    );
                  },
                  child: SquircleContainer(
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey[100],
                    cornerRadius: 8,
                    cornerSmoothing: 0.6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.courtName ?? 'Court',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.tennisCenterName ?? 'Tennis Center',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.calendar,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              booking.date,
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              CupertinoIcons.time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.startTime} - ${booking.endTime}',
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Cancel button for queued or active invitations
            if (canCancel) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancelInvitation(invitation.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel Invitation'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _acceptInvitation(String invitationId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final invitationProvider =
        Provider.of<InvitationProvider>(context, listen: false);

    if (authProvider.user != null) {
      try {
        final success = await invitationProvider.acceptInvitation(
            invitationId, authProvider.user!.uid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Invitation accepted'
                  : 'Failed to accept invitation'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _declineInvitation(String invitationId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final invitationProvider =
        Provider.of<InvitationProvider>(context, listen: false);

    if (authProvider.user != null) {
      try {
        final success = await invitationProvider.declineInvitation(
            invitationId, authProvider.user!.uid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Invitation declined'
                  : 'Failed to decline invitation'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _cancelInvitation(String invitationId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final invitationProvider =
        Provider.of<InvitationProvider>(context, listen: false);

    if (authProvider.user != null) {
      try {
        final success = await invitationProvider.cancelInvitation(
            invitationId, authProvider.user!.uid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Invitation cancelled'
                  : 'Failed to cancel invitation'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Color _getStatusColor(InvitationStatus status, bool isExpired) {
    if (isExpired && status == InvitationStatus.pending) {
      return Colors.grey;
    }

    switch (status) {
      case InvitationStatus.queued:
        return Colors.blueGrey;
      case InvitationStatus.pending:
        return Colors.orange;
      case InvitationStatus.accepted:
        return Colors.green;
      case InvitationStatus.declined:
        return Colors.red;
      case InvitationStatus.expired:
      case InvitationStatus.cancelled:
      case InvitationStatus.skipped:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
