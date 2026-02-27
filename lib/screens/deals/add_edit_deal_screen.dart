
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/deal_model.dart';
import '../../providers/deal_provider.dart';
import '../../providers/contact_provider.dart';
import '../../providers/user_management_provider.dart';
import '../../widgets/animations/fade_in_slide.dart';

class AddEditDealScreen extends ConsumerStatefulWidget {
  final DealModel? deal;

  const AddEditDealScreen({super.key, this.deal});

  @override
  ConsumerState<AddEditDealScreen> createState() => _AddEditDealScreenState();
}

class _AddEditDealScreenState extends ConsumerState<AddEditDealScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  String? _contactId;
  String _contactName = '';
  String _companyName = '';
  late double _value;
  late DealStage _stage;
  late String _assignedTo;
  late DateTime _expectedCloseDate;
  late String _notes;

  @override
  void initState() {
    super.initState();
    _title = widget.deal?.title ?? '';
    _contactId = widget.deal?.contactId;
    _contactName = widget.deal?.contactName ?? '';
    _companyName = widget.deal?.companyName ?? '';
    _value = widget.deal?.value ?? 0.0;
    _stage = widget.deal?.stage ?? DealStage.qualification;
    _assignedTo = widget.deal?.assignedTo ?? '';
    _expectedCloseDate = widget.deal?.expectedCloseDate ?? DateTime.now();
    _notes = widget.deal?.notes ?? '';
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final deal = DealModel(
        id: widget.deal?.id ?? '',
        title: _title,
        contactId: _contactId ?? '',
        contactName: _contactName,
        companyName: _companyName,
        value: _value,
        stage: _stage,
        assignedTo: _assignedTo,
        expectedCloseDate: _expectedCloseDate,
        notes: _notes,
        createdAt: widget.deal?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.deal == null) {
        ref.read(dealsProvider.notifier).addDeal(deal);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deal added successfully')),
        );
      } else {
        ref.read(dealsProvider.notifier).updateDeal(deal);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deal updated successfully')),
        );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deal == null ? 'Add Deal' : 'Edit Deal'),
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
                    initialValue: _title,
                    decoration: const InputDecoration(
                      labelText: 'Deal Name',
                      prefixIcon: Icon(Icons.work_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a deal name' : null,
                    onSaved: (value) => _title = value!,
                  ),
                ),
                const SizedBox(height: 16),
                FadeInSlide(
                  delay: 0.1,
                  child: contactsAsync.when(
                    data: (contacts) => DropdownButtonFormField<String>(
                      value: _contactId,
                      decoration: const InputDecoration(
                        labelText: 'Contact',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: contacts.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.name} (${c.company})', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (value) {
                         final selectedContact = contacts.firstWhere((c) => c.id == value);
                         setState(() {
                           _contactId = value;
                           _contactName = selectedContact.name;
                           _companyName = selectedContact.company;
                         });
                      },
                      validator: (value) => value == null ? 'Please select a contact' : null,
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error loading contacts'),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInSlide(
                  delay: 0.2,
                  child: TextFormField(
                    key: ValueKey(_companyName), // Force rebuild to show update
                    initialValue: _companyName,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Company',
                      prefixIcon: const Icon(Icons.business),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInSlide(
                  delay: 0.3,
                  child: TextFormField(
                    initialValue: _value.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Value (INR)',
                      prefixIcon: Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter value' : null,
                    onSaved: (value) =>
                        _value = double.tryParse(value ?? '0') ?? 0.0,
                    keyboardType: TextInputType.number,
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
                          final validIds = users.map((u) => u.id).toList();
                          final currentValue = validIds.contains(_assignedTo) ? _assignedTo : '';
                          return DropdownButtonFormField<String>(
                            value: currentValue.isEmpty ? null : currentValue,
                            decoration: const InputDecoration(
                              labelText: 'Assigned To',
                              prefixIcon: Icon(Icons.person_pin_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Unassigned')),
                              ...users.map((user) => DropdownMenuItem(
                                value: user.id,
                                child: Text(user.name),
                              )),
                            ],
                            onChanged: (value) => setState(() => _assignedTo = value ?? ''),
                            onSaved: (value) => _assignedTo = value ?? '',
                            validator: (value) => value == null || value.isEmpty ? 'Please assign a user' : null,
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Text('Failed to load users'),
                      );
                    },
                   ),
                ),
                 const SizedBox(height: 16),
                 FadeInSlide(
                   delay: 0.5,
                   child: Card(
                     elevation: 0,
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(12),
                       side: BorderSide(color: Theme.of(context).dividerColor),
                     ),
                     child: ListTile(
                      title: Text('Close Date: ${_expectedCloseDate.toIso8601String().split('T')[0]}'),
                      leading: const Icon(Icons.event),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _expectedCloseDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != _expectedCloseDate) {
                          setState(() {
                            _expectedCloseDate = picked;
                          });
                        }
                      },
                    ),
                   ),
                 ),
                const SizedBox(height: 16),
                FadeInSlide(
                  delay: 0.6,
                  child: DropdownButtonFormField<DealStage>(
                    value: _stage,
                    decoration: const InputDecoration(
                      labelText: 'Stage',
                      prefixIcon: Icon(Icons.stairs_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                       contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: DealStage.values.map((stage) {
                      return DropdownMenuItem(
                        value: stage,
                        child: Text(stage.label),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _stage = value!),
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
                    maxLines: 3,
                    onSaved: (value) => _notes = value ?? '',
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
                      widget.deal == null ? 'Create Deal' : 'Update Deal',
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
