import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:provider/provider.dart';

import 'package:mobile_app/providers/onboarding_provider.dart';

class CourtsSetupStep extends StatefulWidget {
  final List<dynamic> initialCourts;
  final Function(List<Map<String, dynamic>>) onChanged;

  const CourtsSetupStep({
    super.key,
    required this.initialCourts,
    required this.onChanged,
  });

  @override
  State<CourtsSetupStep> createState() => _CourtsSetupStepState();
}

class _CourtsSetupStepState extends State<CourtsSetupStep> {
  bool _didSeedProvider = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSeedProvider) {
      return;
    }

    final onboarding = context.read<OnboardingProvider>();
    final initialCourtsList = widget.initialCourts
        .whereType<Map<dynamic, dynamic>>()
        .map<Map<String, dynamic>>(
          (court) => Map<String, dynamic>.from(court),
        )
        .toList(growable: false);

    if (initialCourtsList.isNotEmpty) {
      onboarding.initializeCourts(initialCourtsList);
    }

    _didSeedProvider = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncParent(onboarding);
    });
  }

  void _syncParent(OnboardingProvider onboarding) {
    widget.onChanged(
      onboarding.draft.courts
          .map((court) => Map<String, dynamic>.from(court))
          .toList(growable: false),
    );
  }

  void _updateCourt(
    OnboardingProvider onboarding,
    String id,
    Map<String, dynamic> updates,
  ) {
    onboarding.updateCourt(id, updates);
    _syncParent(onboarding);
  }

  void _removeCourt(OnboardingProvider onboarding, String id) {
    onboarding.removeCourt(id);
    _syncParent(onboarding);
  }

  void _addCourt(OnboardingProvider onboarding) {
    onboarding.addCourt();
    _syncParent(onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = Provider.of<OnboardingProvider>(context);
    final courts = onboarding.draft.courts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Set Up Your Courts',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add all the courts in your tennis center. You can add more later in the settings.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courts.length,
            itemBuilder: (context, index) {
              final court = courts[index];
              final courtId = court['id'] ?? 'court_${UniqueKey()}';
              return Card(
                key: ValueKey(courtId),
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(
                        court['name'] ?? 'Court ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      trailing: courts.length > 1
                          ? IconButton(
                              icon: const Icon(
                                CupertinoIcons.trash,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeCourt(
                                onboarding,
                                court['id'] as String,
                              ),
                            )
                          : null,
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDropdownField(
                            label: 'Surface',
                            value: court['surface'] ?? 'Hard',
                            items: [
                              'Hard',
                              'Clay',
                              'Grass',
                              'Carpet',
                              'Artificial Grass',
                            ],
                            onChanged: (value) => _updateCourt(
                              onboarding,
                              court['id'] as String,
                              {'surface': value},
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: 'Lighting',
                            value: court['lighting'] ?? 'None',
                            items: ['None', 'Floodlights', 'Indoor'],
                            onChanged: (value) => _updateCourt(
                              onboarding,
                              court['id'] as String,
                              {'lighting': value},
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPriceField(
                            context: context,
                            initialValue:
                                court['pricePerHour']?.toString() ?? '0.0',
                            onChanged: (value) => _updateCourt(
                              onboarding,
                              court['id'] as String,
                              {
                                'pricePerHour': double.tryParse(value) ?? 0.0,
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Court Name',
                            initialValue: court['name'] ?? 'Court ${index + 1}',
                            onChanged: (value) => _updateCourt(
                              onboarding,
                              court['id'] as String,
                              {'name': value},
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text(
                                'Indoor Court',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: court['indoor'] ?? false,
                                onChanged: (value) => _updateCourt(
                                  onboarding,
                                  court['id'] as String,
                                  {'indoor': value},
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _addCourt(onboarding),
            child: const Text('Add Court'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required Function(String) onChanged,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: ShapeDecoration(
            color: Colors.grey[100],
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 8,
                cornerSmoothing: 0.6,
              ),
            ),
          ),
          child: TextFormField(
            initialValue: initialValue,
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: InputBorder.none,
              isDense: true,
            ),
            keyboardType: keyboardType,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField({
    required BuildContext context,
    required String initialValue,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price per Hour',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: ShapeDecoration(
            color: Colors.grey[100],
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 8,
                cornerSmoothing: 0.6,
              ),
            ),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12.0, right: 4.0),
                child: Text(
                  '\$',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: TextFormField(
                  initialValue: initialValue,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.only(right: 12, top: 12, bottom: 12),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: onChanged,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: Text(
                  '/hour',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          key: ValueKey('${label}_dropdown'),
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          items: items.map<DropdownMenuItem<T>>((T item) {
            return DropdownMenuItem<T>(
              key: ValueKey('${label}_${item.toString()}'),
              value: item,
              child: Text(
                item.toString(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
