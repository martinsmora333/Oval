import 'dart:io';

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/services/storage_service.dart';

class CenterInfoStep extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  const CenterInfoStep({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<CenterInfoStep> createState() => _CenterInfoStepState();
}

class _CenterInfoStepState extends State<CenterInfoStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isUploading = false;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialData['name'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialData['description'] ?? '',
    );
    _logoUrl = widget.initialData['logoUrl'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateData() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onChanged({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        if (_logoUrl != null) 'logoUrl': _logoUrl,
      });
    }
  }

  Future<void> _uploadLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);
      
      // Get the file
      final File imageFile = File(image.path);
      
      // Upload the file to Supabase Storage
      final storage = StorageService();
      final newLogoUrl = await storage.uploadTennisCenterImage(
        imageFile, 
        'logo_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (mounted) {
        setState(() {
          _logoUrl = newLogoUrl;
          _isUploading = false;
        });
        
        _updateData();
      }
    } catch (e) {
      debugPrint('Error uploading logo: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to upload logo. Please try again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Form(
      key: _formKey,
      onChanged: _updateData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Tennis Center Information',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.headlineSmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us about your tennis center. You can update this information later in settings.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            
            // Logo Upload
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _uploadLogo,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: ShapeDecoration(
                        color: theme.cardColor,
                        shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius.all(
                            SmoothRadius(
                              cornerRadius: 24,
                              cornerSmoothing: 0.6,
                            ),
                          ),
                          side: BorderSide(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: _isUploading
                          ? const Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _logoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    _logoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        CupertinoIcons.photo,
                                        size: 40,
                                        color: Colors.grey,
                                      );
                                    },
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.camera,
                                      size: 32,
                                      color: theme.primaryColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add Logo',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  if (_logoUrl != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _uploadLogo,
                      child: const Text('Change Logo'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tennis Center Name',
                hintText: 'e.g., Central Tennis Club',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(CupertinoIcons.sportscourt),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              style: const TextStyle(fontSize: 16),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name for your tennis center';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                if (value.trim().length > 100) {
                  return 'Name is too long';
                }
                return null;
              },
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 20),
            
            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Tell players about your tennis center, facilities, and what makes it special...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              style: const TextStyle(fontSize: 16),
              maxLines: 5,
              maxLength: 500,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _updateData(),
            ),
            const SizedBox(height: 8),
            Text(
              '${_descriptionController.text.length}/500',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _descriptionController.text.length > 500
                    ? theme.colorScheme.error
                    : theme.hintColor,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
