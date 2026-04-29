import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../home/home_screen.dart';
import '../tennis_centers/tennis_center_manager_main_screen.dart';
import '../onboarding/tennis_center_onboarding_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Show loading indicator while checking authentication state
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Navigate based on authentication state
    if (authProvider.isAuthenticated) {
      final userModel = authProvider.userModel;
      
      // Check if user needs to complete onboarding
      if (userModel != null && !userModel.onboardingCompleted) {
        // Redirect to appropriate onboarding based on user type
        if (userModel.userType == UserType.courtManager) {
          // For court managers, redirect to tennis center onboarding
          return TennisCenterOnboardingScreen(
            userId: userModel.id,
            tempTennisCenterId: 'temp_${userModel.id}',
          );
        }
        // TODO: Add player onboarding screen when available
        // For now, redirect players to home screen
        return const HomeScreen();
      }
      
      // User has completed onboarding, show appropriate screen based on user type
      if (userModel?.userType == UserType.courtManager) {
        return const TennisCenterManagerMainScreen();
      } else {
        // Default to player home screen
        return const HomeScreen();
      }
    } else {
      return const LoginScreen();
    }
  }
}
