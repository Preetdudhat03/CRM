
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/role_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/user_management_provider.dart';
import '../../../widgets/animations/fade_in_slide.dart';

class AddEditUserScreen extends ConsumerStatefulWidget {
  final UserModel? user;

  const AddEditUserScreen({super.key, this.user});

  @override
  ConsumerState<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends ConsumerState<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _email;
  late Role _role;

  @override
  void initState() {
    super.initState();
    _name = widget.user?.name ?? '';
    _email = widget.user?.email ?? '';
    _role = widget.user?.role ?? Role.employee;
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final userManagementNotifier = ref.read(userManagementProvider.notifier);

      try {
        if (widget.user == null) {
          await userManagementNotifier.addUser(_name, _email, _role);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User added successfully')),
            );
          }
        } else {
          final updatedUser = widget.user!.copyWith(name: _name, email: _email, role: _role);
          await userManagementNotifier.updateUser(updatedUser);
          
          // Check if we updated ourselves and refresh current user provider
          final currentUser = ref.read(currentUserProvider);
          if (currentUser?.id == widget.user!.id) {
            await ref.read(currentUserProvider.notifier).refreshUser();
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User updated successfully')),
            );
          }
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceAll("Exception:", "")}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? 'Add User' : 'Edit User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeInSlide(
                  delay: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.user == null ? Icons.person_add_outlined : Icons.edit_outlined,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
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
                    validator: (value) => value!.isEmpty ? 'Please enter name' : null,
                    onSaved: (value) => _name = value!,
                  ),
                ),
                const SizedBox(height: 16),
                
                FadeInSlide(
                  delay: 0.2,
                  child: TextFormField(
                    initialValue: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                         borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? 'Please enter email' : null,
                    onSaved: (value) => _email = value!,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 16),
                
                FadeInSlide(
                  delay: 0.3,
                  child: DropdownButtonFormField<Role>(
                    value: _role,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      border: OutlineInputBorder(
                         borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    items: Role.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.displayName),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _role = value!),
                  ),
                ),
                const SizedBox(height: 32),
                
                FadeInSlide(
                  delay: 0.4,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.user == null ? 'Create User' : 'Update User',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
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
