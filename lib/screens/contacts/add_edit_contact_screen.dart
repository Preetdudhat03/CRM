
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/contact_model.dart';
import '../../providers/contact_provider.dart';

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
              children: [
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a name' : null,
                  onSaved: (value) => _name = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter an email' : null,
                  onSaved: (value) => _email = value!,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  onSaved: (value) => _phone = value!,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _company,
                  decoration: const InputDecoration(labelText: 'Company'),
                  onSaved: (value) => _company = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _position,
                  decoration: const InputDecoration(labelText: 'Position'),
                  onSaved: (value) => _position = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _address,
                  decoration: const InputDecoration(labelText: 'Address'),
                  onSaved: (value) => _address = value!,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  onSaved: (value) => _notes = value!,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ContactStatus>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ContactStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _status = value!),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
