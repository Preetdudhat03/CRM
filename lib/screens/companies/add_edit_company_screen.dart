import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../models/company_model.dart';
import '../../providers/company_provider.dart';
import '../../widgets/animations/fade_in_slide.dart';
import '../../utils/error_handler.dart';
import '../../providers/user_management_provider.dart';
import '../../models/user_model.dart';

class AddEditCompanyScreen extends ConsumerStatefulWidget {
  final CompanyModel? company;

  const AddEditCompanyScreen({super.key, this.company});

  @override
  ConsumerState<AddEditCompanyScreen> createState() =>
      _AddEditCompanyScreenState();
}

class _AddEditCompanyScreenState extends ConsumerState<AddEditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _industry;
  late String _website;
  late String _phone;
  late String _address;
  late String _notes;
  late double _revenue;
  late int? _employeeCount;
  String? _assignedTo;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = widget.company?.name ?? '';
    _industry = widget.company?.industry ?? '';
    _website = widget.company?.website ?? '';
    _phone = widget.company?.phone ?? '';
    _address = widget.company?.address ?? '';
    _notes = widget.company?.notes ?? '';
    _revenue = widget.company?.revenue ?? 0.0;
    _employeeCount = widget.company?.employeeCount;
    _assignedTo = widget.company?.assignedTo;
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = ref.read(currentUserProvider);
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final company = CompanyModel(
          id: widget.company?.id ?? '',
          name: _name,
          industry: _industry.isNotEmpty ? _industry : null,
          website: _website.isNotEmpty ? _website : null,
          phone: _phone.isNotEmpty ? _phone : null,
          address: _address.isNotEmpty ? _address : null,
          notes: _notes.isNotEmpty ? _notes : null,
          revenue: _revenue,
          employeeCount: _employeeCount,
          assignedTo: _assignedTo,
          organizationId: widget.company?.organizationId ?? currentUser?.organizationId,
          createdAt: widget.company?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.company == null) {
          await ref.read(companiesProvider.notifier).addCompany(company);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Company added successfully')),
            );
          }
        } else {
          await ref.read(companiesProvider.notifier).updateCompany(company);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Company updated successfully')),
            );
          }
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${ErrorHandler.formatError(e)}'),
              backgroundColor: Colors.red,
            ),
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
      appBar: AppBar(
        title: Text(widget.company == null ? 'Add Company' : 'Edit Company'),
        actions: [
          if (!_isLoading)
            IconButton(icon: const Icon(Icons.check), onPressed: _submit),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FadeInSlide(
                            delay: 0,
                            child: TextFormField(
                              initialValue: _name,
                              decoration: const InputDecoration(
                                labelText: 'Company Name',
                                prefixIcon: Icon(Icons.business_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                              validator: (value) => value!.isEmpty
                                  ? 'Please enter a company name'
                                  : null,
                              onSaved: (value) => _name = value!,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInSlide(
                            delay: 0.1,
                            child: TextFormField(
                              initialValue: _industry,
                              decoration: const InputDecoration(
                                labelText: 'Industry',
                                hintText: 'e.g. Technology, Healthcare',
                                prefixIcon: Icon(Icons.category_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                              onSaved: (value) => _industry = value!,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInSlide(
                            delay: 0.2,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _revenue == 0.0
                                        ? ''
                                        : _revenue.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Annual Revenue (\$)',
                                      prefixIcon: Icon(
                                        Icons.monetization_on_outlined,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                    ],
                                    onSaved: (value) => _revenue =
                                        double.tryParse(value ?? '0') ?? 0.0,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    initialValue:
                                        _employeeCount?.toString() ?? '',
                                    decoration: const InputDecoration(
                                      labelText: 'Employees',
                                      prefixIcon: Icon(Icons.people_outline),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onSaved: (value) => _employeeCount =
                                        int.tryParse(value ?? ''),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInSlide(
                            delay: 0.3,
                            child: TextFormField(
                              initialValue: _website,
                              decoration: const InputDecoration(
                                labelText: 'Website',
                                hintText: 'https://example.com',
                                prefixIcon: Icon(Icons.language_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.url,
                              onSaved: (value) => _website = value!,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInSlide(
                            delay: 0.4,
                            child: TextFormField(
                              initialValue: _phone,
                              decoration: const InputDecoration(
                                labelText: 'Company Phone',
                                prefixIcon: Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              onSaved: (value) => _phone = value!,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInSlide(
                            delay: 0.5,
                            child: TextFormField(
                              initialValue: _address,
                              decoration: const InputDecoration(
                                labelText: 'Headquarters Address',
                                prefixIcon: Icon(Icons.location_on_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                              maxLines: 2,
                              onSaved: (value) => _address = value!,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInSlide(
                            delay: 0.6,
                            child: TextFormField(
                              initialValue: _notes,
                              decoration: const InputDecoration(
                                labelText: 'Notes',
                                prefixIcon: Icon(Icons.note_alt_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                              maxLines: 4,
                              onSaved: (value) => _notes = value!,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInSlide(
                            delay: 0.65,
                            child: _buildAssigneeDropdown(),
                          ),
                          const SizedBox(height: 32),
                          FadeInSlide(
                            delay: 0.7,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                widget.company == null
                                    ? 'Create Company'
                                    : 'Update Company',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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

  Widget _buildAssigneeDropdown() {
    final usersAsync = ref.watch(userManagementProvider);

    return usersAsync.when(
      data: (users) {
        return DropdownButtonFormField<String>(
          value: _assignedTo,
          decoration: const InputDecoration(
            labelText: 'Assigned Manager',
            prefixIcon: Icon(Icons.person_pin_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('No Manager'),
            ),
            ...users.map(
              (user) =>
                  DropdownMenuItem(value: user.id, child: Text(user.name)),
            ),
          ],
          onChanged: (val) => setState(() => _assignedTo = val),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Error loading managers'),
    );
  }
}
