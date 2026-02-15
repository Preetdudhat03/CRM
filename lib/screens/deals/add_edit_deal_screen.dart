
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/deal_model.dart';
import '../../providers/deal_provider.dart';
import '../../providers/contact_provider.dart';

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
              children: [
                TextFormField(
                  initialValue: _title,
                  decoration: const InputDecoration(labelText: 'Deal Name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a deal name' : null,
                  onSaved: (value) => _title = value!,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: contactsAsync.when(
                    data: (contacts) => DropdownButtonFormField<String>(
                      value: _contactId,
                      decoration: const InputDecoration(labelText: 'Contact'),
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
                TextFormField(
                  key: ValueKey(_companyName), // Force rebuild to show update
                  initialValue: _companyName,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Company',
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                TextFormField(
                  initialValue: _value.toString(),
                  decoration: const InputDecoration(labelText: 'Value (INR)'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter value' : null,
                  onSaved: (value) =>
                      _value = double.tryParse(value ?? '0') ?? 0.0,
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  initialValue: _assignedTo,
                  decoration: const InputDecoration(labelText: 'Assigned To'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please assign a user' : null,
                  onSaved: (value) => _assignedTo = value!,
                ),
                 ListTile(
                  title: Text('Close Date: ${_expectedCloseDate.toIso8601String().split('T')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  contentPadding: EdgeInsets.zero,
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
                DropdownButtonFormField<DealStage>(
                  value: _stage,
                  decoration: const InputDecoration(labelText: 'Stage'),
                  items: DealStage.values.map((stage) {
                    return DropdownMenuItem(
                      value: stage,
                      child: Text(stage.label),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _stage = value!),
                ),
                TextFormField(
                  initialValue: _notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                  onSaved: (value) => _notes = value ?? '',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
