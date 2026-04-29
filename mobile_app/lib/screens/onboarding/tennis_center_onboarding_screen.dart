import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/cupertino.dart';

import '../../models/geo_point.dart';
import '../../models/tennis_center_model.dart';
import '../../models/court_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tennis_centers_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../utils/location_utils.dart';
import 'steps/center_info_step.dart';
import 'steps/address_step.dart';
import 'steps/contact_info_step.dart';
import 'steps/operating_hours_step.dart';
import 'steps/courts_setup_step.dart';
import 'steps/review_step.dart';
import 'onboarding_complete_screen.dart';

class TennisCenterOnboardingScreen extends StatefulWidget {
  final String userId;
  final String tempTennisCenterId;

  const TennisCenterOnboardingScreen({
    super.key,
    required this.userId,
    required this.tempTennisCenterId,
  });

  @override
  State<TennisCenterOnboardingScreen> createState() =>
      _TennisCenterOnboardingScreenState();
}

class _TennisCenterOnboardingScreenState
    extends State<TennisCenterOnboardingScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Form data
  final Map<String, dynamic> _formData = {
    'name': '',
    'description': '',
    'phoneNumber': '',
    'email': '',
    'website': '',
    'address': {
      'street': '',
      'city': '',
      'state': '',
      'zipCode': '',
      'postalCode': '',
      'country': '',
    },
    'location': null,
    'operatingHours': {},
    'amenities': [],
    'courts': [],
  };

  // List of steps
  late final List<Widget> _steps;

  @override
  void initState() {
    super.initState();

    // Initialize steps only once in initState
    _steps = [
      _createCenterInfoStep(),
      _createAddressStep(),
      _createContactInfoStep(),
      _createOperatingHoursStep(),
      _createCourtsSetupStep(),
      _createReviewStep(),
    ];
  }

  Widget _createCenterInfoStep() {
    return CenterInfoStep(
      key: const ValueKey('center_info_step'),
      initialData: Map<String, dynamic>.from(_formData),
      onChanged: (data) => _updateFormData(Map<String, dynamic>.from(data)),
    );
  }

  Widget _createAddressStep() {
    return AddressStep(
      key: const ValueKey('address_step'),
      initialData: <String, dynamic>{
        'address': Map<String, dynamic>.from(
            _formData['address'] as Map? ?? const <String, dynamic>{}),
        'location': _formData['location'],
      },
      onChanged: (address) =>
          _updateFormData(Map<String, dynamic>.from(address as Map)),
    );
  }

  Widget _createContactInfoStep() {
    return ContactInfoStep(
      key: const ValueKey('contact_info_step'),
      initialData: Map<String, dynamic>.from(_formData),
      onChanged: (data) => _updateFormData(Map<String, dynamic>.from(data)),
    );
  }

  Widget _createOperatingHoursStep() {
    return OperatingHoursStep(
      key: const ValueKey('operating_hours_step'),
      initialData:
          Map<String, dynamic>.from(_formData['operatingHours'] as Map? ?? {}),
      onChanged: (hours) => _updateFormData(
          {'operatingHours': Map<String, dynamic>.from(hours as Map)}),
    );
  }

  Widget _createCourtsSetupStep() {
    return CourtsSetupStep(
      key: const ValueKey('courts_setup_step'),
      initialCourts:
          List<Map<String, dynamic>>.from(_formData['courts'] as List? ?? []),
      onChanged: (courts) =>
          _updateFormData({'courts': List<Map<String, dynamic>>.from(courts)}),
    );
  }

  Widget _createReviewStep() {
    return ReviewStep(
      key: const ValueKey('review_step'),
      onComplete: _completeOnboarding,
      isLoading: _isSubmitting,
    );
  }

  void _updateFormData(Map<String, dynamic> data) {
    setState(() {
      _formData.addAll(Map<String, dynamic>.from(data));
    });

    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);

    if (data.containsKey('name') ||
        data.containsKey('description') ||
        data.containsKey('logoUrl')) {
      onboardingProvider.updateCenterInfo(<String, dynamic>{
        'name': _formData['name'] ?? '',
        'description': _formData['description'] ?? '',
        'logoUrl': _formData['logoUrl'],
      });
    }

    if (data.containsKey('address') || data.containsKey('location')) {
      final address = _normalizedAddressData();
      final location = _formData['location'];
      onboardingProvider.updateAddress(<String, dynamic>{
        ...address,
        if (location != null) 'location': location,
      });
    }

    if (data.containsKey('phoneNumber') ||
        data.containsKey('email') ||
        data.containsKey('website')) {
      onboardingProvider.updateContact(<String, dynamic>{
        'phoneNumber': _formData['phoneNumber'] ?? '',
        'email': _formData['email'] ?? '',
        'website': _formData['website'] ?? '',
      });
    }

    if (data.containsKey('operatingHours')) {
      onboardingProvider.updateOperatingHours(
        Map<String, dynamic>.from(
          _formData['operatingHours'] as Map? ?? const <String, dynamic>{},
        ),
      );
    }

    if (data.containsKey('courts')) {
      onboardingProvider.initializeCourts(
        List<Map<String, dynamic>>.from(
          _formData['courts'] as List? ?? const <Map<String, dynamic>>[],
        ),
      );
    }
  }

  Map<String, dynamic> _normalizedAddressData() {
    final rawAddress = Map<String, dynamic>.from(
        _formData['address'] as Map? ?? const <String, dynamic>{});
    final postalCode = rawAddress['zipCode']?.toString() ??
        rawAddress['postalCode']?.toString() ??
        '';

    return <String, dynamic>{
      'street': rawAddress['street']?.toString() ?? '',
      'city': rawAddress['city']?.toString() ?? '',
      'state': rawAddress['state']?.toString() ?? '',
      'zipCode': postalCode,
      'postalCode': postalCode,
      'country': rawAddress['country']?.toString() ?? '',
    };
  }

  Map<String, OperatingHours> _normalizedOperatingHours() {
    final rawHours = Map<String, dynamic>.from(
      _formData['operatingHours'] as Map? ?? const <String, dynamic>{},
    );
    final normalized = <String, OperatingHours>{};

    rawHours.forEach((day, hours) {
      if (hours is Map) {
        normalized[day] = OperatingHours.fromMap(
          Map<String, dynamic>.from(hours),
        );
      }
    });

    return normalized;
  }

  Future<GeoPoint> _resolveCenterLocation() async {
    final locationData = _formData['location'];
    if (locationData is Map) {
      final latitude = _readCoordinate(locationData['latitude']);
      final longitude = _readCoordinate(locationData['longitude']);
      if (latitude != null && longitude != null) {
        return GeoPoint(latitude, longitude);
      }
    }

    final address = _normalizedAddressData();
    final formattedAddress = <String>[
      address['street']?.toString() ?? '',
      address['city']?.toString() ?? '',
      address['state']?.toString() ?? '',
      address['zipCode']?.toString() ?? '',
      address['country']?.toString() ?? '',
    ].where((part) => part.isNotEmpty).join(', ');

    final resolvedLocation = await LocationUtils.getLocationFromAddress(
      address: formattedAddress,
    );
    if (resolvedLocation == null) {
      throw Exception(
        'We could not determine the tennis center location from the entered address. Use current location or pin the center on the map before completing setup.',
      );
    }

    return GeoPoint(
      resolvedLocation.latitude,
      resolvedLocation.longitude,
    );
  }

  double? _readCoordinate(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  bool _isSubmitting = false;

  Future<void> _completeOnboarding() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final provider =
          Provider.of<TennisCentersProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final resolvedLocation = await _resolveCenterLocation();

      // Create tennis center with all collected data
      final tennisCenter = TennisCenterModel(
        id: widget.tempTennisCenterId,
        name: _formData['name'] ?? 'New Tennis Center',
        description: _formData['description'] ?? '',
        phoneNumber: _formData['phoneNumber'] ?? '',
        email: _formData['email'] ?? '',
        website: _formData['website'],
        address: Address.fromMap(_normalizedAddressData()),
        location: resolvedLocation,
        operatingHours: _normalizedOperatingHours(),
        amenities: List<String>.from(_formData['amenities'] ?? []),
        images: [], // Default empty images list
        createdAt: DateTime.now(),
        managerIds: [widget.userId],
        // Optional parameters with defaults
        stripeAccountId: null,
        rating: null,
      );

      // Save tennis center
      final savedCenterId =
          await provider.createOrUpdateTennisCenter(tennisCenter);
      if (savedCenterId == null) {
        throw Exception('Failed to save tennis center');
      }

      // Save courts
      if (_formData['courts'] != null) {
        for (var courtData in _formData['courts']) {
          try {
            await provider.addCourtToTennisCenter(
              savedCenterId,
              CourtModel.fromMap(Map<String, dynamic>.from(courtData)),
            );
          } catch (e) {
            debugPrint('Error saving court: $e');
            // Continue with other courts even if one fails
          }
        }
      }

      // Update user's onboarding status
      try {
        await authProvider.updateUserOnboardingStatus(completed: true);
        await authProvider.refreshUserData();
      } catch (e) {
        debugPrint('Error updating user onboarding status: $e');
        // Continue even if updating onboarding status fails
      }

      // Show completion screen
      if (mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OnboardingCompleteScreen(
              onContinue: () {
                Navigator.of(context)
                    .pushReplacementNamed('/tennis-center-dashboard');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing setup: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  bool get _isLastStep => _currentStep == _steps.length - 1;
  bool get _isFirstStep => _currentStep == 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope<void>(
      canPop: _isFirstStep,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _previousStep();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Setup Your Tennis Center',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          leading: _isFirstStep
              ? IconButton(
                  icon: const Icon(CupertinoIcons.xmark),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : IconButton(
                  icon: const Icon(CupertinoIcons.chevron_left),
                  onPressed: _previousStep,
                ),
        ),
        body: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / _steps.length,
              backgroundColor: theme.dividerColor,
              minHeight: 2,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),

            // Step indicator
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_steps.length, (index) {
                  final isActive = index == _currentStep;
                  final isCompleted = index < _currentStep;

                  return GestureDetector(
                    onTap: () {
                      if (index < _currentStep) {
                        _pageController.jumpToPage(index);
                        setState(() => _currentStep = index);
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: ShapeDecoration(
                        color: isActive
                            ? theme.primaryColor
                            : isCompleted
                                ? theme.primaryColor.withValues(alpha: 0.1)
                                : theme.dividerColor.withValues(alpha: 0.3),
                        shape: const SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius.all(
                            SmoothRadius(
                              cornerRadius: 16,
                              cornerSmoothing: 0.6,
                            ),
                          ),
                        ),
                      ),
                      child: isCompleted
                          ? Icon(
                              CupertinoIcons.checkmark_alt,
                              size: 18,
                              color: theme.primaryColor,
                            )
                          : Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : theme.textTheme.bodyLarge?.color
                                          ?.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  );
                }),
              ),
            ),

            // Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                itemCount: _steps.length,
                itemBuilder: (context, index) => _steps[index],
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!_isFirstStep) ...[
                      TextButton(
                        onPressed: _previousStep,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                        child: const Text('Back'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton(
                      onPressed: _isLastStep ? _completeOnboarding : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isLastStep ? 'Complete Setup' : 'Continue',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
