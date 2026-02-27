
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/animations/fade_in_slide.dart';
import '../../utils/error_handler.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = StorageService();
  
  late String _name;
  late String _email;
  String? _avatarUrl;
  File? _imageFile;
  bool _isLoading = false;
  
  String? _password;
  String? _confirmPassword;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _name = user?.name ?? '';
    _email = user?.email ?? '';
    _avatarUrl = user?.avatarUrl;
  }

  Future<void> _pickImage() async {
    final file = await _storageService.pickImage();
    if (file != null) {
      setState(() => _imageFile = file);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      
      try {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser == null) return;

        String? newAvatarUrl = _avatarUrl;
        
        // Upload image if selected
        if (_imageFile != null) {
          final path = 'users/${currentUser.id}'; // Overwrite existing
          newAvatarUrl = await _storageService.uploadAvatar(_imageFile!, path);
        } else if (_avatarUrl == null) {
          // If avatarUrl is null (deleted), we want to update the profile to remove it
          newAvatarUrl = '';
        }

        // Update profile
        final updatedUser = currentUser.copyWith(
          name: _name,
          avatarUrl: newAvatarUrl,
        );

        await ref.read(currentUserProvider.notifier).updateProfile(updatedUser);

        // Update password if provided
        if (_password != null && _password!.isNotEmpty) {
           await ref.read(currentUserProvider.notifier).updatePassword(_password!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error: ${ErrorHandler.formatError(e)}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                FadeInSlide(
                  child: Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).primaryColor,
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                      ? NetworkImage(_avatarUrl!) as ImageProvider
                                      : null,
                              child: (_imageFile == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                                  ? Text(
                                      _name.isNotEmpty
                                          ? _name.substring(0, 1).toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                         if (_imageFile != null || (_avatarUrl != null && _avatarUrl!.isNotEmpty))
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _imageFile = null;
                                  _avatarUrl = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                FadeInSlide(
                  delay: 0.1,
                  child: TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter your name' : null,
                    onSaved: (value) => _name = value!,
                  ),
                ),
                const SizedBox(height: 20),
                
                FadeInSlide(
                  delay: 0.2,
                  child: TextFormField(
                    initialValue: _email,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Change Password',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                FadeInSlide(
                  delay: 0.3,
                  child: TextFormField(
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      helperText: 'Leave empty to keep current password',
                    ),
                    validator: (value) {
                       if (value != null && value.isNotEmpty && value.length < 6) {
                         return 'Password must be at least 6 characters';
                       }
                       return null;
                    },
                    onChanged: (value) => _password = value,
                    onSaved: (value) => _password = value,
                  ),
                ),
                const SizedBox(height: 16),

                FadeInSlide(
                  delay: 0.4,
                  child: TextFormField(
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: (value) {
                       if (_password != null && _password!.isNotEmpty) {
                         if (value == null || value.isEmpty) {
                           return 'Please confirm password';
                         }
                         if (value != _password) {
                           return 'Passwords do not match';
                         }
                       }
                       return null;
                    },
                    onSaved: (value) => _confirmPassword = value,
                  ),
                ),

                const SizedBox(height: 40),
                
                FadeInSlide(
                  delay: 0.5,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20, 
                            width: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2)
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}
