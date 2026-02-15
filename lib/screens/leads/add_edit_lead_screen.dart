
import 'package:flutter/material.dart';
import '../../models/lead_model.dart';
import '../../widgets/animations/fade_in_slide.dart';

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeInSlide(
                  delay: 0,
                  child: TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(
                      labelText: 'Lead Name',
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
                    onSaved: (value) => _phone = value!,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(height: 16),
                FadeInSlide(
                  delay: 0.3,
                  child: TextFormField(
                    initialValue: _source,
                    decoration: const InputDecoration(
                      labelText: 'Lead Source',
                      prefixIcon: Icon(Icons.source_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    onSaved: (value) => _source = value!,
                  ),
                ),
                const SizedBox(height: 16),
                FadeInSlide(
                  delay: 0.4,
                  child: TextFormField(
                    initialValue: _assignedTo,
                    decoration: const InputDecoration(
                      labelText: 'Assigned To',
                      prefixIcon: Icon(Icons.assignment_ind_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    onSaved: (value) => _assignedTo = value!,
                  ),
                ),
                const SizedBox(height: 16),
                FadeInSlide(
                  delay: 0.5,
                  child: TextFormField(
                    initialValue: _estimatedValue?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Estimated Value',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    onSaved: (value) => _estimatedValue = double.tryParse(value ?? ''),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 16),
                FadeInSlide(
                  delay: 0.6,
                  child: DropdownButtonFormField<LeadStatus>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.flag_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: LeadStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _status = value!),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInSlide(
                  delay: 0.7,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      widget.lead == null ? 'Create Lead' : 'Update Lead',
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
