import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/court_model.dart';
import '../../models/tennis_center_model.dart';
import '../../providers/tennis_centers_provider.dart';
import 'court_booking_screen.dart';

class TennisCenterDetailsScreen extends StatefulWidget {
  final String tennisCenterId;

  const TennisCenterDetailsScreen({
    super.key,
    required this.tennisCenterId,
  });

  @override
  State<TennisCenterDetailsScreen> createState() =>
      _TennisCenterDetailsScreenState();
}

class _TennisCenterDetailsScreenState extends State<TennisCenterDetailsScreen> {
  Future<void> _launchUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWebsite(String website) async {
    final normalized = website.startsWith('http://') ||
            website.startsWith('https://')
        ? website
        : 'https://$website';
    await _launchUri(Uri.parse(normalized));
  }

  // Build address section
  Widget _buildAddressSection(TennisCenterModel center) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          center.address.formattedAddress,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  // Build contact information section
  Widget _buildContactInfo(TennisCenterModel center) {
    final rows = <Widget>[];

    if (center.phoneNumber.trim().isNotEmpty) {
      rows.add(
        GestureDetector(
          onTap: () => _launchUri(
            Uri(
              scheme: 'tel',
              path: center.phoneNumber,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone, size: 20, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  center.phoneNumber,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (center.email.trim().isNotEmpty) {
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: 8));
      }
      rows.add(
        GestureDetector(
          onTap: () => _launchUri(
            Uri(
              scheme: 'mailto',
              path: center.email,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.email, size: 20, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  center.email,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (center.website != null && center.website!.trim().isNotEmpty) {
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: 8));
      }
      rows.add(
        GestureDetector(
          onTap: () {
            _launchWebsite(center.website!);
          },
          child: Row(
            children: [
              const Icon(Icons.language, size: 20, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  center.website!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...rows,
      ],
    );
  }

  // Build amenities section
  Widget _buildAmenities(TennisCenterModel center) {
    if (center.amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: center.amenities
              .map((amenity) => Chip(
                    label: Text(amenity),
                    backgroundColor: Colors.grey[200],
                  ))
              .toList(),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // Load tennis center details and courts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<TennisCentersProvider>(context, listen: false);
      provider.loadTennisCenterDetails(widget.tennisCenterId);
      provider.loadCourts(widget.tennisCenterId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<TennisCentersProvider>(
        builder: (context, provider, _) {
          final center = provider.selectedTennisCenter;
          final courts = provider.courts;

          if (center == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              // App bar with center image
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: center.imageUrl != null
                      ? Image.network(
                          center.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
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
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.sports_tennis,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              // Tennis center details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Center name
                      Text(
                        center.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const SizedBox(height: 16),

                      // Description
                      if (center.description.isNotEmpty) ...[
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          center.description,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Address
                      _buildAddressSection(center),

                      const SizedBox(height: 24),

                      // Contact Information
                      _buildContactInfo(center),

                      const SizedBox(height: 24),

                      // Amenities
                      _buildAmenities(center),

                      const SizedBox(height: 24),

                      // Courts section header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Courts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Courts list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: provider.isLoadingCourts
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      )
                    : courts.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text('No courts available'),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final court = courts[index];
                                return buildCourtCard(
                                    context, court, widget.tennisCenterId);
                              },
                              childCount: courts.length,
                            ),
                          ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          );
        },
      ),
    );
  }

  // Build court card widget
  Widget buildCourtCard(
      BuildContext context, CourtModel court, String tennisCenterId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.sports_tennis, color: Colors.green),
        title: Text(
          court.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle:
            Text('${court.surfaceTypeString} • ${court.environmentString}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to court booking screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourtBookingScreen(
                court: court,
                tennisCenterId: tennisCenterId,
              ),
            ),
          );
        },
      ),
    );
  }
}
