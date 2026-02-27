
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../models/lead_model.dart';
import '../../providers/lead_provider.dart';
import '../../widgets/animations/fade_in_slide.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../utils/error_handler.dart';
import '../../providers/user_management_provider.dart';

class AddEditLeadScreen extends ConsumerStatefulWidget {
  final LeadModel? lead;

  const AddEditLeadScreen({super.key, this.lead});

  @override
  ConsumerState<AddEditLeadScreen> createState() => _AddEditLeadScreenState();
}

class _AddEditLeadScreenState extends ConsumerState<AddEditLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _email;
  late String _phone;
  late String _source;
  final List<String> _sourceOptions = ['website', 'instagram', 'referral', 'cold_call', 'other'];
  late String _assignedTo;
  late double? _estimatedValue;
  late LeadStatus _status;
  String _countryCode = '+1';

  @override
  void initState() {
    super.initState();
    _name = widget.lead?.name ?? '';
    _email = widget.lead?.email ?? '';
    _phone = widget.lead?.phone ?? '';
    _source = widget.lead?.source ?? 'website';
    if (_source.isEmpty || !_sourceOptions.contains(_source)) {
      if (_source.isNotEmpty) {
        _sourceOptions.add(_source); // Add if it is a custom existing one
      } else {
        _source = 'website';
      }
    }
    _assignedTo = widget.lead?.assignedTo ?? '';
    _estimatedValue = widget.lead?.estimatedValue;
    _status = widget.lead?.status ?? LeadStatus.newLead;
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final lead = LeadModel(
        id: widget.lead?.id ?? '',
        name: _name,
        email: _email,
        phone: _phone,
        source: _source,
        status: _status,
        assignedTo: _assignedTo,
        estimatedValue: _estimatedValue,
        createdAt: widget.lead?.createdAt ?? DateTime.now(),
      );

      try {
        if (widget.lead == null) {
          await ref.read(leadsProvider.notifier).addLead(lead);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lead added successfully')),
            );
          }
        } else {
          await ref.read(leadsProvider.notifier).updateLead(lead);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lead updated successfully')),
            );
          }
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${ErrorHandler.formatError(e)}')),
          );
        }
      }
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CountryCodePicker(
                            onChanged: (country) {
                               setState(() {
                                 _countryCode = country.dialCode ?? '+91';
                               });
                            },
                            initialSelection: _phone.startsWith('+') ? _phone.split(' ')[0] : 'IN',
                            favorite: const ['+91', 'US', 'IN', 'GB'],
                            showCountryOnly: false,
                            showOnlyCountryWhenClosed: false,
                            alignLeft: false,
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: _phone,
                              decoration: const InputDecoration(
                                hintText: 'Phone Number',
                                border: InputBorder.none,
                                counterText: "",
                              ),
                              keyboardType: TextInputType.phone,
                              maxLength: 15,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter phone number';
                                if (value.length < 7) return 'Too short';
                                return null;
                              },
                              onSaved: (value) {
                                if (value!.startsWith('+')) {
                                  _phone = value;
                                } else {
                                  _phone = '$_countryCode $value';
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInSlide(
                    delay: 0.3,
                    child: DropdownButtonFormField<String>(
                      value: _source,
                      decoration: const InputDecoration(
                        labelText: 'Lead Source',
                        prefixIcon: Icon(Icons.source_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: _sourceOptions.map((source) {
                        return DropdownMenuItem(
                          value: source,
                          child: Text(source[0].toUpperCase() + source.substring(1).replaceAll('_', ' ')),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _source = value!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInSlide(
                    delay: 0.4,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final usersAsync = ref.watch(userManagementProvider);
                        return usersAsync.when(
                          data: (users) {
                            // Validate if current _assignedTo exists in the users list.
                            final validIds = users.map((u) => u.id).toList();
                            final currentValue = validIds.contains(_assignedTo) ? _assignedTo : '';

                            return DropdownButtonFormField<String>(
                              value: currentValue.isEmpty ? null : currentValue,
                              decoration: const InputDecoration(
                                labelText: 'Assigned To',
                                prefixIcon: Icon(Icons.assignment_ind_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              ),
                              items: [
                                const DropdownMenuItem<String>(value: null, child: Text('Unassigned')),
                                ...users.map((user) => DropdownMenuItem<String>(
                                  value: user.id,
                                  child: Text(user.name),
                                )),
                              ],
                              onChanged: (value) => setState(() => _assignedTo = value ?? ''),
                              onSaved: (value) => _assignedTo = value ?? '',
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, __) => const Text('Failed to load users'),
                        );
                      },
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
                      items: LeadStatus.values
                          .where((s) => s != LeadStatus.converted)
                          .map((status) {
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
      ),
    );
  }
}
