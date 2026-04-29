import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/onboarding_provider.dart';

class ReviewStep extends StatelessWidget {
  final VoidCallback onComplete;
  final bool isLoading;

  const ReviewStep({
    super.key,
    required this.onComplete,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final draft = Provider.of<OnboardingProvider>(context).draft;
    debugPrint('ReviewStep build - draft: $draft');

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Review Your Information',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please review all the information below before completing your setup.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
          
                    // Tennis Center Information
                    _buildSection(
                      context,
                      title: 'Tennis Center',
                      icon: CupertinoIcons.sportscourt,
                      children: [
                        _buildInfoRow('Name', draft.centerInfo['name']?.toString() ?? 'Not provided'),
                        _buildInfoRow('Description', draft.centerInfo['description']?.toString() ?? 'Not provided'),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Address
                    _buildSection(
                      context,
                      title: 'Address',
                      icon: CupertinoIcons.location,
                      children: [
                        _buildInfoRow('Street', draft.addressInfo['street']?.toString() ?? 'Not provided'),
                        _buildInfoRow('City', draft.addressInfo['city']?.toString() ?? 'Not provided'),
                        _buildInfoRow('State/Province', draft.addressInfo['state']?.toString() ?? 'Not provided'),
                        _buildInfoRow('Postal Code', draft.addressInfo['postalCode']?.toString() ?? 'Not provided'),
                        _buildInfoRow('Country', draft.addressInfo['country']?.toString() ?? 'Not provided'),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Contact Information
                    _buildSection(
                      context,
                      title: 'Contact Information',
                      icon: CupertinoIcons.phone,
                      children: [
                        _buildInfoRow('Phone', draft.contactInfo['phoneNumber']?.toString() ?? 'Not provided'),
                        _buildInfoRow('Email', draft.contactInfo['email']?.toString() ?? 'Not provided'),
                        if (draft.contactInfo['website']?.toString().isNotEmpty ?? false)
                          _buildInfoRow('Website', draft.contactInfo['website']?.toString() ?? ''),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Operating Hours
                    _buildSection(
                      context,
                      title: 'Operating Hours',
                      icon: CupertinoIcons.clock,
                      children: _buildOperatingHours(draft),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Courts
                    _buildSection(
                      context,
                      title: 'Courts',
                      icon: CupertinoIcons.sportscourt,
                      children: _buildCourtsList(draft),
                    ),
                    
                    const SizedBox(height: 32),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : onComplete,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Complete Setup',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    // Ensure all children have unique keys
    final keyedChildren = List<Widget>.generate(
      children.length,
      (index) => children[index].key != null 
          ? children[index] 
          : KeyedSubtree(
              key: ValueKey('section_${title}_$index'),
              child: children[index],
            ),
    );

    return Container(
      key: ValueKey('section_$title'),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            key: ValueKey('${title}_header'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, key: ValueKey('${title}_icon'), color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  key: ValueKey('${title}_title'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Content - Wrapped in SizedBox with fixed height
          SizedBox(
            key: ValueKey('${title}_content'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: keyedChildren,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : 'Not provided',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildOperatingHours(dynamic draft) {
    final List<Widget> result = [];
    try {
      final hours = draft.operatingHours is Map ? Map<String, dynamic>.from(draft.operatingHours) : {};
      debugPrint('Operating hours data: $hours');
      
      final List<String> days = [
        'monday', 'tuesday', 'wednesday', 'thursday', 
        'friday', 'saturday', 'sunday'
      ];
      
      final Map<String, String> dayNames = {
        'monday': 'Monday',
        'tuesday': 'Tuesday',
        'wednesday': 'Wednesday',
        'thursday': 'Thursday',
        'friday': 'Friday',
        'saturday': 'Saturday',
        'sunday': 'Sunday',
      };
      
      for (int i = 0; i < days.length; i++) {
        final day = days[i];
        try {
          final dayHours = hours[day] is Map ? Map<String, dynamic>.from(hours[day]) : <String, dynamic>{};
          debugPrint('$day hours: $dayHours');
          
          final isClosed = dayHours['isClosed'] == true;
          
          String hoursText;
          if (isClosed) {
            hoursText = 'Closed';
          } else {
            final open = dayHours['open']?.toString() ?? '--:--';
            final close = dayHours['close']?.toString() ?? '--:--';
            hoursText = '${_formatTime(open)} - ${_formatTime(close)}';
          }
          
          result.add(
            SizedBox(
              key: ValueKey('hour_${day}_$i'),
              child: _buildInfoRow(
                dayNames[day] ?? day[0].toUpperCase() + day.substring(1),
                hoursText,
              ),
            ),
          );
        } catch (e) {
          debugPrint('Error processing $day: $e');
          result.add(
            SizedBox(
              key: ValueKey('hour_error_$i'),
              child: _buildInfoRow(
                dayNames[day] ?? day[0].toUpperCase() + day.substring(1),
                'Error loading hours',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _buildOperatingHours: $e');
      result.add(
        SizedBox(
          key: const ValueKey('hours_error'),
          child: _buildInfoRow('Error', 'Could not load operating hours'),
        ),
      );
    }
    
    return result;
  }
  
  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    
    try {
      final parts = time.split(':');
      if (parts.length < 2) return time;
      
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:$minute $period';
    } catch (e) {
      debugPrint('Error formatting time "$time": $e');
      return time;
    }
  }
  
  List<Widget> _buildCourtsList(dynamic draft) {
    final List<Widget> result = [];
    try {
      final courts = draft.courts is List ? List<dynamic>.from(draft.courts) : [];
      debugPrint('Courts data: $courts');
      
      if (courts.isEmpty) {
        return [
          const Text('No courts added', style: TextStyle(color: Colors.grey)),
        ];
      }
      
      for (int i = 0; i < courts.length; i++) {
        try {
          final court = courts[i];
          final courtMap = court is Map ? Map<String, dynamic>.from(court) : <String, dynamic>{};
          
          final courtWidget = Padding(
            key: ValueKey('court_${courtMap['id'] ?? i}'),
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courtMap['name']?.toString() ?? 'Unnamed Court',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${courtMap['surface'] ?? 'Unknown'} • ${courtMap['indoor'] == true ? 'Indoor' : 'Outdoor'} • \$${courtMap['pricePerHour'] ?? '0'}/hour',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (courtMap['lighting'] != null && courtMap['lighting'] != 'None')
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.lightbulb,
                        size: 16,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        courtMap['lighting']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
          
          result.add(KeyedSubtree(
            key: ValueKey('court_container_${courtMap['id'] ?? i}'),
            child: courtWidget,
          ));
        } catch (e) {
          debugPrint('Error rendering court at index $i: $e');
          result.add(KeyedSubtree(
            key: ValueKey('court_error_$i'),
            child: ListTile(
              title: const Text('Error loading court'),
              subtitle: Text('Error: ${e.toString()}'),
              leading: const Icon(Icons.error_outline, color: Colors.red),
            ),
          ));
        }
      }
    } catch (e) {
      debugPrint('Error in _buildCourtsList: $e');
      result.add(const KeyedSubtree(
        key: ValueKey('courts_error'),
        child: ListTile(
          title: Text('Error loading courts'),
          leading: Icon(Icons.error_outline, color: Colors.red),
        ),
      ));
    }
    
    return result;
  }
}
