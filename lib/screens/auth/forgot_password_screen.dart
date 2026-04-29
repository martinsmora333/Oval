import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/squircle_button.dart';
import '../../widgets/squircle_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.resetPassword(_emailController.text.trim());

        if (mounted) {
          setState(() {
            _isLoading = false;
            _emailSent = success;
          });

          if (!success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authProvider.error ?? 'Failed to send reset email')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Reset Password',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _emailSent
                      ? 'Password reset email sent! Check your inbox.'
                      : 'Enter your email and we\'ll send you instructions to reset your password',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                if (!_emailSent) ...[
                  // Reset password form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email field
                        SquircleTextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          labelText: 'Email',
                          prefixIcon: const Icon(CupertinoIcons.mail),
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
                        
                        const SizedBox(height: 24),
                        
                        // Reset button
                        SquircleButton(
                          label: _isLoading ? 'Sending...' : 'Send Reset Link',
                          onPressed: _isLoading ? () {} : () async {
                            await _resetPassword();
                          },
                          width: double.infinity,
                          height: 50,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Success message and back to login button
                  Icon(
                    CupertinoIcons.checkmark_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  SquircleButton(
                    label: 'Back to Login',
                    onPressed: () => Navigator.pop(context),
                    width: double.infinity,
                    height: 50,
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Back to login link
                if (!_emailSent)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Remember your password?',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
