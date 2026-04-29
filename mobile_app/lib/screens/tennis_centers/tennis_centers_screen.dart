import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../models/tennis_center_model.dart';
import '../../providers/tennis_centers_provider.dart';
import '../../widgets/squircle_text_field.dart';
import 'package:figma_squircle/figma_squircle.dart';

class TennisCentersScreen extends StatefulWidget {
  const TennisCentersScreen({super.key});

  @override
  State<TennisCentersScreen> createState() => _TennisCentersScreenState();
}

class _TennisCentersScreenState extends State<TennisCentersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Try to load tennis centers when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TennisCentersProvider>(context, listen: false);
      provider.loadTennisCenters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tennis Centers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: () {
              debugPrint('Manual refresh of tennis centers triggered');
              final provider = Provider.of<TennisCentersProvider>(context, listen: false);
              provider.loadTennisCenters();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SquircleTextField(
              controller: _searchController,
              hintText: 'Search tennis centers...',
              prefixIcon: const Icon(CupertinoIcons.search),
              cornerRadius: 12,
              cornerSmoothing: 0.6,
              fillColor: Colors.grey[100],
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          // Tennis centers list
          Expanded(
            child: Consumer<TennisCentersProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (provider.tennisCenters.isEmpty) {
                  return const Center(
                    child: Text('No tennis centers found'),
                  );
                }
                
                final filteredCenters = provider.tennisCenters
                    .where((center) => center.name.toLowerCase().contains(_searchQuery))
                    .toList();
                
                if (filteredCenters.isEmpty) {
                  return Center(
                    child: Text('No results for "$_searchQuery"'),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredCenters.length,
                  itemBuilder: (context, index) {
                    final center = filteredCenters[index];
                    return _buildTennisCenterCard(context, center);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTennisCenterCard(BuildContext context, TennisCenterModel center) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: SmoothRectangleBorder(
        borderRadius: SmoothBorderRadius(cornerRadius: 12, cornerSmoothing: 0.6),
      ),
      child: InkWell(
        onTap: () {
          debugPrint('Tapped on center with ID: ${center.id}');
          Navigator.pushNamed(
            context,
            '/tennis_center_details',
            arguments: {
              'tennisCenterId': center.id,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tennis center image
              if (center.imageUrl != null) ...[  
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    center.imageUrl!,
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
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Tennis center name and rating
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      center.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        center.rating != null
                            ? center.rating!.toStringAsFixed(1)
                            : '0.0',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Address
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      center.address.toString(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Hours
              Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Open ${center.openingHours}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Court count
              Row(
                children: [
                  Icon(
                    Icons.sports_tennis_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${center.courtCount} Courts',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'From \$${center.pricePerHour.toStringAsFixed(0)}/hour',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
