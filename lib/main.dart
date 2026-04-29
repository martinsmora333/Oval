import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:mobile_app/config/maps_config.dart';
import 'utils/responsive_utils.dart';
import 'services/supabase_service.dart';

import 'screens/auth/auth_wrapper.dart';
import 'screens/bookings/booking_details_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/tennis_center_onboarding_screen.dart';
import 'screens/tennis_centers/tennis_center_details_screen.dart';
import 'screens/tennis_centers/add_court_screen.dart';
import 'screens/tennis_centers/edit_court_screen.dart';
import 'screens/tennis_centers/tennis_center_manager_main_screen.dart';
import 'screens/tennis_centers/tennis_centers_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/tennis_centers_provider.dart';
import 'providers/invitation_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/onboarding_provider.dart';

void main() async {
  // Set up global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    // Log the error to a remote server if needed
    // Example: logErrorToServer(details);
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize Google Maps
  await MapsConfig.initialize();

  // Configure Google Maps platform-specific settings
  if (defaultTargetPlatform == TargetPlatform.android) {
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => TennisCentersProvider()),
        ChangeNotifierProvider(create: (_) => InvitationProvider()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: const OvalApp(),
    ),
  );
}

class OvalApp extends StatelessWidget {
  const OvalApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lock orientation to portrait mode for better UX
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      title: 'Oval',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A5D1A),
          primary: const Color(0xFF1A5D1A),
          secondary: const Color(0xFFD6ED17),
        ),
        // Base text theme with font family
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontFamily: 'TexGyreAdventor', fontWeight: FontWeight.w700),
          displayMedium: TextStyle(
              fontFamily: 'TexGyreAdventor', fontWeight: FontWeight.w700),
          displaySmall: TextStyle(
              fontFamily: 'TexGyreAdventor', fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(
              fontFamily: 'TexGyreAdventor', fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontFamily: 'TexGyreAdventor'),
          headlineSmall: TextStyle(fontFamily: 'TexGyreAdventor'),
          titleLarge: TextStyle(
              fontFamily: 'TexGyreAdventor', fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontFamily: 'TexGyreAdventor'),
          titleSmall: TextStyle(
              fontFamily: 'TexGyreAdventor', fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(fontFamily: 'TexGyreAdventor'),
          bodyMedium: TextStyle(fontFamily: 'TexGyreAdventor'),
          bodySmall: TextStyle(fontFamily: 'TexGyreAdventor'),
          labelLarge: TextStyle(
              fontFamily: 'TexGyreAdventor', fontWeight: FontWeight.w700),
          labelMedium: TextStyle(fontFamily: 'TexGyreAdventor'),
          labelSmall: TextStyle(fontFamily: 'TexGyreAdventor'),
        ),
        // Basic theme settings - responsive ones will be applied in the builder
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // Apply responsive theme at the app level
      builder: (BuildContext context, Widget? child) {
        // Initialize responsive utils
        ResponsiveUtils.init(context);

        // Apply text scaling
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.8,
          maxScaleFactor: 1.2,
          child: Builder(
            builder: (context) {
              ErrorWidget.builder = (FlutterErrorDetails details) {
                // Customize the error widget
                return const Center(
                  child: Text(
                    'Something went wrong! Please try again later.',
                    style: TextStyle(color: Colors.red, fontSize: 18),
                  ),
                );
              };
              return child!;
            },
          ),
        );
      },
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/tennis_centers': (context) => const TennisCentersScreen(),
        '/tennis-center-dashboard': (context) =>
            const TennisCenterManagerMainScreen(),
        '/tennis-center-onboarding': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return TennisCenterOnboardingScreen(
              userId: args['userId'] as String,
              tempTennisCenterId: args['tempTennisCenterId'] as String,
            );
          }

          final userModel = context.read<AuthProvider>().userModel;
          final userId = userModel?.id ?? '';
          return TennisCenterOnboardingScreen(
            userId: userId,
            tempTennisCenterId: 'temp_$userId',
          );
        },
        '/booking_details': (context) => BookingDetailsScreen(
              bookingId: ModalRoute.of(context)!.settings.arguments as String,
            ),
        '/tennis_center_details': (context) => TennisCenterDetailsScreen(
              tennisCenterId: (ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>)['tennisCenterId'] as String,
            ),
        '/add_court': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return AddCourtScreen(
            tennisCenterId: args['tennisCenterId'] as String,
            tennisCenterName: args['tennisCenterName'] as String,
          );
        },
        '/edit_court': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return EditCourtScreen(
            tennisCenterId: args['tennisCenterId'] as String,
            tennisCenterName: args['tennisCenterName'] as String,
            courtData: args['courtData'] as Map<String, dynamic>,
          );
        },
      },
    );
  }
}

// Example logging function
void logErrorToServer(FlutterErrorDetails details) {
  // Send error details to your logging server
  debugPrint('Error logged to server: ${details.exceptionAsString()}');
}
