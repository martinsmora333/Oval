import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ContactInfoStep extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  const ContactInfoStep({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<ContactInfoStep> createState() => _ContactInfoStepState();
}

class _ContactInfoStepState extends State<ContactInfoStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;

  // Form state
  bool _isWebsiteValid = true;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: widget.initialData['phoneNumber'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.initialData['email'] ?? '',
    );
    _websiteController = TextEditingController(
      text: widget.initialData['website'] ?? '',
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  bool _validateUrl(String url, {bool required = false}) {
    if (url.isEmpty) return !required;
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  void _updateData() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    
    // Validate URL
    _isWebsiteValid = _validateUrl(_websiteController.text);
    
    if (isFormValid && _isWebsiteValid) {
      widget.onChanged({
        'phoneNumber': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
      });
    }
  }

  Widget _buildContactField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          prefixIcon: Icon(icon, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          errorMaxLines: 2,
        ),
        style: const TextStyle(fontSize: 16),
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        onChanged: (_) => _updateData(),
        validator: isRequired ? validator : null,
        onEditingComplete: () => FocusScope.of(context).nextFocus(),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Contact Information',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.headlineSmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How can players get in touch with your tennis center?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            
            // Phone Number
            _buildContactField(
              label: 'Phone Number',
              controller: _phoneController,
              hintText: 'e.g., +1 (555) 123-4567',
              icon: CupertinoIcons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a phone number';
                }
                // Basic phone number validation (at least 8 digits)
                final digits = value.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 8) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            
            // Email
            _buildContactField(
              label: 'Contact Email',
              controller: _emailController,
              hintText: 'contact@example.com',
              icon: CupertinoIcons.mail,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an email address';
                }
                // Basic email validation
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            
            // Website
            _buildContactField(
              label: 'Website',
              controller: _websiteController,
              hintText: 'https://www.example.com',
              icon: CupertinoIcons.globe,
              keyboardType: TextInputType.url,
              isRequired: false,
            ),
            
            const SizedBox(height: 8),
            if (!_isWebsiteValid)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
                child: Text(
                  'Please enter a valid URL (e.g., https://example.com)',
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                ),
              ),
            
            const Divider(height: 32),
            

            
            // Help Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This information will be visible to players who want to contact your tennis center.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
