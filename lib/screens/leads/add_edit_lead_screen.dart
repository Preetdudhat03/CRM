
import 'package:flutter/material.dart';
import '../../models/lead_model.dart';

class AddEditLeadScreen extends StatefulWidget {
  final LeadModel? lead;

  const AddEditLeadScreen({super.key, this.lead});

  @override
  State<AddEditLeadScreen> createState() => _AddEditLeadScreenState();
}

class _AddEditLeadScreenState extends State<AddEditLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _email;
  late String _phone;
  late String _source;
  late String _assignedTo;
  late double? _estimatedValue;
  late LeadStatus _status;

  @override
  void initState() {
    super.initState();
    _name = widget.lead?.name ?? '';
    _email = widget.lead?.email ?? '';
    _phone = widget.lead?.phone ?? '';
    _source = widget.lead?.source ?? '';
    _assignedTo = widget.lead?.assignedTo ?? '';
    _estimatedValue = widget.lead?.estimatedValue;
    _status = widget.lead?.status ?? LeadStatus.newLead;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Logic to save or update lead
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lead == null ? 'Add Lead' : 'Edit Lead'),
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
                TextFormField(
                  initialValue: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter an email' : null,
                  onSaved: (value) => _email = value!,
                  keyboardType: TextInputType.emailAddress,
                ),
                TextFormField(
                  initialValue: _phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  onSaved: (value) => _phone = value!,
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  initialValue: _source,
                  decoration: const InputDecoration(labelText: 'Source'),
                  onSaved: (value) => _source = value!,
                ),
                 TextFormField(
                  initialValue: _assignedTo,
                  decoration: const InputDecoration(labelText: 'Assigned To'),
                  onSaved: (value) => _assignedTo = value!,
                ),
                 TextFormField(
                  initialValue: _estimatedValue?.toString(),
                  decoration: const InputDecoration(labelText: 'Estimated Value'),
                  onSaved: (value) => _estimatedValue = double.tryParse(value ?? ''),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<LeadStatus>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: LeadStatus.values.map((status) {
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
