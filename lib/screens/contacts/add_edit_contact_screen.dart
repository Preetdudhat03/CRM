
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/contact_model.dart';
import '../../providers/contact_provider.dart';
import '../../widgets/animations/fade_in_slide.dart';

class AddEditContactScreen extends ConsumerStatefulWidget {
  final ContactModel? contact;

  const AddEditContactScreen({super.key, this.contact});

  @override
  ConsumerState<AddEditContactScreen> createState() => _AddEditContactScreenState();
}

class _AddEditContactScreenState extends ConsumerState<AddEditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _email;
  late String _phone;
  late String _company;
  late String _position;
  late String _address;
  late String _notes;
  late ContactStatus _status;

  @override
  void initState() {
    super.initState();
    _name = widget.contact?.name ?? '';
    _email = widget.contact?.email ?? '';
    _phone = widget.contact?.phone ?? '';
    _company = widget.contact?.company ?? '';
    _position = widget.contact?.position ?? '';
    _address = widget.contact?.address ?? '';
    _notes = widget.contact?.notes ?? '';
    _status = widget.contact?.status ?? ContactStatus.lead;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final contact = ContactModel(
        id: widget.contact?.id ?? '', // Service handles ID for new
        name: _name,
        email: _email,
        phone: _phone,
        company: _company,
        position: _position,
        address: _address,
        notes: _notes,
        status: _status,
        createdAt: widget.contact?.createdAt ?? DateTime.now(),
        lastContacted: widget.contact?.lastContacted ?? DateTime.now(),
        avatarUrl: widget.contact?.avatarUrl,
        isFavorite: widget.contact?.isFavorite ?? false,
      );

      if (widget.contact == null) {
        ref.read(contactsProvider.notifier).addContact(contact);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact added successfully')),
        );
      } else {
        ref.read(contactsProvider.notifier).updateContact(contact);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact updated successfully')),
        );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submit,
          ),
        ],
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
                  child: TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(
                      labelText: 'Contact Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a name' : null,
                    onSaved: (value) => _name = value!,
                  ),
                ),
                const SizedBox(height: 16),
                FadeInSlide(
                  delay: 0.1,
                  child: TextFormField(
                    initialValue: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter an email' : null,
                    onSaved: (value) => _email = value!,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 16),
                FadeInSlide(
                  delay: 0.2,
                  child: TextFormField(
                    initialValue: _phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                         return 'Please enter a phone number';
                      }
                      // Basic regex for phone validation (allows +, space, -, and digits, min 10 chars)
                      final phoneRegex = RegExp(r'^[+]?[0-9\s-]{10,}$');
                      if (!phoneRegex.hasMatch(value)) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                    onSaved: (value) => _phone = value!,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(height: 16),
                 FadeInSlide(
                   delay: 0.3,
                   child: TextFormField(
                    initialValue: _company,
                    decoration: const InputDecoration(
                      labelText: 'Company',
                      prefixIcon: Icon(Icons.business_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    onSaved: (value) => _company = value!,
                  ),
                 ),
                const SizedBox(height: 16),
                 FadeInSlide(
                   delay: 0.4,
                   child: TextFormField(
                    initialValue: _position,
                    decoration: const InputDecoration(
                      labelText: 'Position',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    onSaved: (value) => _position = value!,
                  ),
                 ),
                const SizedBox(height: 16),
                 FadeInSlide(
                   delay: 0.5,
                   child: TextFormField(
                    initialValue: _address,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    onSaved: (value) => _address = value!,
                    maxLines: 2,
                  ),
                 ),
                const SizedBox(height: 16),
                 FadeInSlide(
                   delay: 0.6,
                   child: DropdownButtonFormField<ContactStatus>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.flag_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: ContactStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _status = value!),
                  ),
                 ),
                const SizedBox(height: 16),
                 FadeInSlide(
                   delay: 0.7,
                   child: TextFormField(
                    initialValue: _notes,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    onSaved: (value) => _notes = value!,
                    maxLines: 3,
                  ),
                 ),
                 const SizedBox(height: 32),
                 FadeInSlide(
                   delay: 0.8,
                   child: ElevatedButton(
                     onPressed: _submit,
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                     child: Text(
                       widget.contact == null ? 'Create Contact' : 'Update Contact',
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
