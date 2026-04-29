import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/squircle_button.dart';
import '../../widgets/squircle_container.dart';
import '../../widgets/squircle_text_field.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  PlayerLevel _selectedLevel = PlayerLevel.intermediate;
  UserType _selectedUserType = UserType.player; // Default to Player account

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _selectedLevel,
        _selectedUserType,
      );

      if (success && mounted) {
        // Automatically sign in the user after successful registration
        try {
          final signedIn = await authProvider.signIn(
            _emailController.text.trim(),
            _passwordController.text,
            userType: _selectedUserType,
          );

          if (signedIn && mounted) {
            // Navigate based on user type
            if (_selectedUserType == UserType.courtManager) {
              // For court managers, go to the onboarding screen
              Navigator.pushReplacementNamed(context, '/tennis-center-onboarding');
            } else {
              // For players, go to the home screen
              Navigator.pushReplacementNamed(context, '/home');
            }
          }
        } catch (e) {
          // If auto-login fails, just show the error and stay on the register screen
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Registration successful but login failed: ${e.toString()}'),
                backgroundColor: Colors.red[700],
              ),
            );
          }
        }
      } else if (!success && mounted) {
        // Show a detailed error message
        final errorMessage = authProvider.error ?? 'Registration failed';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 10), // Extended duration to read error
            backgroundColor: Colors.red[700],
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
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
    final double headingFontSize = ResponsiveUtils.responsiveFontSize(ResponsiveUtils.isPhone ? 24 : 28);
    final double bodyFontSize = ResponsiveUtils.responsiveFontSize(ResponsiveUtils.isPhone ? 14 : 16);
    final double buttonHeight = ResponsiveUtils.buttonHeight;
    final double verticalSpacing = ResponsiveUtils.blockSizeVertical * 2;
    final double horizontalSpacing = ResponsiveUtils.blockSizeHorizontal * 2.5;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          iconSize: ResponsiveUtils.iconSize,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.blockSizeHorizontal * 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Create ${_selectedUserType == UserType.player ? "Player" : "Court Manager"} Account',
                  style: TextStyle(
                    fontFamily: 'TexGyreAdventor',
                    fontSize: headingFontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A5D1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: verticalSpacing * 0.5),
                
                // Description text
                Text(
                  _selectedUserType == UserType.player
                      ? 'Join our community and start playing!'
                      : 'Manage your tennis center and court bookings',
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: verticalSpacing),
                
                // User type toggle
                SquircleContainer(
                  margin: EdgeInsets.symmetric(vertical: verticalSpacing * 0.75, horizontal: 2.0),
                  padding: EdgeInsets.all(4.0),
                  color: Colors.grey[200],
                  cornerRadius: 16,
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
                                : Colors.transparent,
                            cornerRadius: 12,
                            cornerSmoothing: 0.6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.person_fill,
                                  color: _selectedUserType == UserType.player
                                      ? Colors.black
                                      : Colors.grey[600],
                                  size: ResponsiveUtils.iconSize,
                                ),
                                SizedBox(width: horizontalSpacing * 0.8),
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
                                : Colors.transparent,
                            cornerRadius: 12,
                            cornerSmoothing: 0.6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.building_2_fill,
                                  color: _selectedUserType == UserType.courtManager
                                      ? Colors.black
                                      : Colors.grey[600],
                                  size: ResponsiveUtils.iconSize,
                                ),
                                SizedBox(width: horizontalSpacing * 0.8),
                                Flexible(
                                  child: Text(
                                    'Sports Centre',
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
                
                SizedBox(height: verticalSpacing),
                
                // Registration form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name field
                      SquircleTextField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(fontSize: bodyFontSize),
                        labelText: _selectedUserType == UserType.player ? 'Full Name' : 'Tennis Center Name',
                        labelStyle: TextStyle(fontSize: bodyFontSize),
                        prefixIcon: Icon(
                          CupertinoIcons.person_fill,
                          size: ResponsiveUtils.iconSize,
                        ),
                        cornerRadius: 12,
                        cornerSmoothing: 0.6,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          if (value.length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: verticalSpacing),
                      
                      // Email field
                      SquircleTextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(fontSize: bodyFontSize),
                        labelText: 'Email',
                        labelStyle: TextStyle(fontSize: bodyFontSize),
                        prefixIcon: Icon(
                          Icons.email_outlined,
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
                      
                      SizedBox(height: verticalSpacing),
                      
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
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: verticalSpacing),
                      
                      // Confirm password field
                      SquircleTextField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        style: TextStyle(fontSize: bodyFontSize),
                        labelText: 'Confirm Password',
                        labelStyle: TextStyle(fontSize: bodyFontSize),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          size: ResponsiveUtils.iconSize,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: ResponsiveUtils.iconSize,
                          ),
                          onPressed: _toggleConfirmPasswordVisibility,
                        ),
                        cornerRadius: 12,
                        cornerSmoothing: 0.6,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      
                      // Player level selector (only show for player accounts)
                      if (_selectedUserType == UserType.player) ...[
                        SizedBox(height: verticalSpacing),
                        
                        Text(
                          'Select your skill level:',
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            color: Colors.grey[700],
                          ),
                        ),
                        
                        SizedBox(height: verticalSpacing * 0.5),
                        
                        Container(
                          padding: EdgeInsets.symmetric(vertical: verticalSpacing * 0.5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildLevelRadioTile(PlayerLevel.beginner, bodyFontSize),
                              Divider(height: 1, color: Colors.grey[200]),
                              _buildLevelRadioTile(PlayerLevel.intermediate, bodyFontSize),
                              Divider(height: 1, color: Colors.grey[200]),
                              _buildLevelRadioTile(PlayerLevel.advanced, bodyFontSize),
                              Divider(height: 1, color: Colors.grey[200]),
                              _buildLevelRadioTile(PlayerLevel.pro, bodyFontSize),
                            ],
                          ),
                        ),
                      ],
                      
                      SizedBox(height: verticalSpacing * 1.5),
                      
                      // Register button
                      SquircleButton(
                        label: 'Create Account',
                        onPressed: authProvider.isLoading ? () {} : () async {
                          await _register();
                        },
                        width: double.infinity,
                        height: buttonHeight,
                      ),
                      
                      SizedBox(height: verticalSpacing),
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
  
  Widget _buildLevelRadioTile(PlayerLevel level, double fontSize) {
    String levelName;
    String description;
    
    switch (level) {
      case PlayerLevel.beginner:
        levelName = 'Beginner';
        description = 'New to tennis or still learning basics';
        break;
      case PlayerLevel.intermediate:
        levelName = 'Intermediate';
        description = 'Consistent player with developed strokes';
        break;
      case PlayerLevel.advanced:
        levelName = 'Advanced';
        description = 'Experienced player with strong technique';
        break;
      case PlayerLevel.pro:
        levelName = 'Professional';
        description = 'Competitive tournament player';
        break;
    }
    
    return RadioListTile<PlayerLevel>(
      title: Text(
        levelName,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          fontSize: fontSize * 0.85,
          color: Colors.grey[600],
        ),
      ),
      value: level,
      groupValue: _selectedLevel,
      activeColor: const Color(0xFF1A5D1A),
      onChanged: (PlayerLevel? value) {
        if (value != null) {
          setState(() {
            _selectedLevel = value;
          });
        }
      },
    );
  }
}
