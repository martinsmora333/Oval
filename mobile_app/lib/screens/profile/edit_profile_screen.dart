import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/squircle_button.dart';
import '../../widgets/squircle_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late PlayerLevel _selectedLevel;
  bool _isLoading = false;
  File? _profileImage;
  final _picker = ImagePicker();
  final _storageService = StorageService();
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  void _loadUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user != null) {
      _nameController.text = user.displayName;
      if (user.phoneNumber != null) {
        _phoneController.text = user.phoneNumber!;
      }
      _selectedLevel = user.playerLevel;
    } else {
      _selectedLevel = PlayerLevel.intermediate;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.user;
        
        if (user == null) {
          throw Exception('User not authenticated');
        }
        
        String? photoURL;
        
        // Upload profile image if selected
        if (_profileImage != null) {
          photoURL = await _storageService.uploadProfilePicture(_profileImage!, user.uid);
        }
        
        // Update user profile
        final success = await authProvider.updateProfile(
          displayName: _nameController.text.trim(),
          photoURL: photoURL,
          playerLevel: _selectedLevel,
        );
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(authProvider.error ?? 'Failed to update profile')),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile picture
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!) as ImageProvider
                              : null),
                      child: (_profileImage == null && user.profileImageUrl == null)
                          ? Text(
                              user.displayName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.camera,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Name field
              SquircleTextField(
                controller: _nameController,
                labelText: 'Full Name',
                prefixIcon: const Icon(CupertinoIcons.person),
                cornerRadius: 12,
                cornerSmoothing: 0.6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Phone field
              SquircleTextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                labelText: 'Phone Number (optional)',
                prefixIcon: const Icon(CupertinoIcons.phone),
                cornerRadius: 12,
                cornerSmoothing: 0.6,
              ),
              
              const SizedBox(height: 16),
              
              // Player level dropdown
              DropdownButtonFormField<PlayerLevel>(
                value: _selectedLevel,
                decoration: InputDecoration(
                  labelText: 'Playing Level',
                  prefixIcon: const Icon(CupertinoIcons.sportscourt),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: PlayerLevel.values.map((level) {
                  return DropdownMenuItem<PlayerLevel>(
                    value: level,
                    child: Text(level.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLevel = value;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 32),
              
              // Save button
              SquircleButton(
                label: 'Save Changes',
                onPressed: _isLoading ? () {} : () async {
                  await _saveProfile();
                },
                width: 200,
                height: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
