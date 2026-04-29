import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/responsive_theme.dart';
import '../../widgets/squircle_container.dart';
import '../../widgets/squircle_text_field.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  UserType _selectedUserType = UserType.player; // Default to Player login

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
        userType: _selectedUserType,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error ?? 'Login failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Initialize responsive utils for this screen
    ResponsiveUtils.init(context);
    
    // Calculate responsive sizes
    final double logoSize = ResponsiveUtils.responsiveWidth(ResponsiveUtils.isPhone ? 15 : 12);
    final double ballSize = logoSize / 2;
    final double headingFontSize = ResponsiveUtils.responsiveFontSize(ResponsiveUtils.isPhone ? 24 : 28);
    final double bodyFontSize = ResponsiveUtils.responsiveFontSize(ResponsiveUtils.isPhone ? 14 : 16);
    final double buttonHeight = ResponsiveUtils.buttonHeight;
    final double verticalSpacing = ResponsiveUtils.blockSizeVertical * 2.5;
    final double horizontalSpacing = ResponsiveUtils.blockSizeHorizontal * 3;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: context.responsivePadding(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and app name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tennis ball logo
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFF274E13), // Dark green
                        shape: BoxShape.rectangle,
                      ),
                      child: Center(
                        child: Container(
                          width: ballSize,
                          height: ballSize,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB4D335), // Light green/yellow for tennis ball
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: horizontalSpacing),
                    Text(
                      'Oval',
                      style: TextStyle(
                        fontFamily: 'TexGyreAdventor',
                        fontSize: headingFontSize * 1.5, // Make the logo text a bit larger
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: const Color(0xFF274E13), // Dark green
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: verticalSpacing * 2),
                
                // User type toggle
                SquircleContainer(
                  margin: EdgeInsets.symmetric(vertical: verticalSpacing),
                  color: Colors.grey[100],
                  cornerRadius: 12,
                  cornerSmoothing: 0.6,
                  child: Row(
                    children: [
                      // Player tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedUserType = UserType.player;
                            });
                          },
                          child: SquircleContainer(
                            padding: EdgeInsets.symmetric(vertical: verticalSpacing * 0.8),
                            color: _selectedUserType == UserType.player
                                ? Colors.white
                                : Colors.grey[100],
                            cornerRadius: 12,
                            cornerSmoothing: 0.6,
                            border: _selectedUserType == UserType.player
                                ? Border.all(color: Colors.grey[300]!)
                                : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: _selectedUserType == UserType.player
                                      ? Colors.black
                                      : Colors.grey[600],
                                  size: ResponsiveUtils.iconSize,
                                ),
                                SizedBox(width: horizontalSpacing * 0.5),
                                Flexible(
                                  child: Text(
                                    'Player',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: bodyFontSize,
                                      color: _selectedUserType == UserType.player
                                          ? Colors.black
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Court Manager tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedUserType = UserType.courtManager;
                            });
                          },
                          child: SquircleContainer(
                            padding: EdgeInsets.symmetric(vertical: verticalSpacing * 0.8),
                            color: _selectedUserType == UserType.courtManager
                                ? Colors.white
                                : Colors.grey[100],
                            cornerRadius: 12,
                            cornerSmoothing: 0.6,
                            border: _selectedUserType == UserType.courtManager
                                ? Border.all(color: Colors.grey[300]!)
                                : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.business_outlined,
                                  color: _selectedUserType == UserType.courtManager
                                      ? Colors.black
                                      : Colors.grey[600],
                                  size: ResponsiveUtils.iconSize,
                                ),
                                SizedBox(width: horizontalSpacing * 0.5),
                                Flexible(
                                  child: Text(
                                    'Court Manager',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: bodyFontSize,
                                      color: _selectedUserType == UserType.courtManager
                                          ? Colors.black
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Login header
                Text(
                  'Sign in as ${_selectedUserType == UserType.player ? 'Player' : 'Court Manager'}',
                  style: TextStyle(
                    fontFamily: 'TexGyreAdventor',
                    fontSize: headingFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: verticalSpacing * 0.6),
                
                // Description text
                Text(
                  _selectedUserType == UserType.player
                      ? 'Access your player account and manage your bookings'
                      : 'Access your venue dashboard and manage your courts',
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: verticalSpacing * 1.6),
                
                // Login form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email field
                      SquircleTextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(fontSize: bodyFontSize),
                        labelText: 'Email',
                        labelStyle: TextStyle(fontSize: bodyFontSize),
                        prefixIcon: Icon(
                          CupertinoIcons.mail,
                          size: ResponsiveUtils.iconSize,
                        ),
                        cornerRadius: 12,
                        cornerSmoothing: 0.6,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: verticalSpacing * 0.8),
                      
                      // Password field
                      SquircleTextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: TextStyle(fontSize: bodyFontSize),
                        labelText: 'Password',
                        labelStyle: TextStyle(fontSize: bodyFontSize),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          size: ResponsiveUtils.iconSize,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: ResponsiveUtils.iconSize,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                        cornerRadius: 12,
                        cornerSmoothing: 0.6,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: verticalSpacing * 0.4),
                      
                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: const Color(0xFF1A5D1A),
                              fontSize: bodyFontSize * 0.9,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: verticalSpacing),
                      
                      // Login button
                      SizedBox(
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A5D1A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: verticalSpacing * 0.5),
                          ),
                          child: authProvider.isLoading
                              ? SizedBox(
                                  height: ResponsiveUtils.blockSizeVertical * 2.5,
                                  width: ResponsiveUtils.blockSizeVertical * 2.5,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: bodyFontSize * 1.1,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: horizontalSpacing * 0.5),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: ResponsiveUtils.iconSize,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      
                      SizedBox(height: verticalSpacing),
                      
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[400])),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalSpacing),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: bodyFontSize * 0.9,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[400])),
                        ],
                      ),
                      
                      SizedBox(height: verticalSpacing),
                      
                      // Sign up button
                      SizedBox(
                        height: buttonHeight,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF1A5D1A),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Don't have an account? Create one",
                            style: TextStyle(
                              fontSize: bodyFontSize,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A5D1A),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
