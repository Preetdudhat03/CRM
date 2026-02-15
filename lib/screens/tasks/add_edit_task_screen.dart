
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task_model.dart';
import '../../providers/contact_provider.dart';
import '../../providers/deal_provider.dart';
import '../../providers/task_provider.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final TaskModel? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late DateTime _dueDate;
  late TaskStatus _status;
  late TaskPriority _priority;
  late String _assignedTo;
  String? _relatedEntityId;
  String? _relatedEntityType;
  String? _relatedEntityName;

  @override
  void initState() {
    super.initState();
    _title = widget.task?.title ?? '';
    _description = widget.task?.description ?? '';
    _dueDate = widget.task?.dueDate ?? DateTime.now();
    _status = widget.task?.status ?? TaskStatus.pending;
    _priority = widget.task?.priority ?? TaskPriority.medium;
    _assignedTo = widget.task?.assignedTo ?? '';
    _relatedEntityId = widget.task?.relatedEntityId;
    _relatedEntityType = widget.task?.relatedEntityType;
    _relatedEntityName = widget.task?.relatedEntityName;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final task = TaskModel(
        id: widget.task?.id ?? '',
        title: _title,
        description: _description,
        dueDate: _dueDate,
        status: _status,
        priority: _priority,
        assignedTo: _assignedTo,
        relatedEntityId: _relatedEntityId,
        relatedEntityType: _relatedEntityType,
        relatedEntityName: _relatedEntityName,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
      );

      if (widget.task == null) {
        ref.read(tasksProvider.notifier).addTask(task);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added successfully')),
        );
      } else {
        ref.read(tasksProvider.notifier).updateTask(task);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully')),
        );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);
    final dealsAsync = ref.watch(dealsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: _title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a title' : null,
                  onSaved: (value) => _title = value!,
                ),
                TextFormField(
                  initialValue: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  onSaved: (value) => _description = value ?? '',
                ),
                ListTile(
                  title: Text('Due Date: ${_dueDate.toIso8601String().split('T')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  contentPadding: EdgeInsets.zero,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setState(() => _dueDate = picked);
                    }
                  },
                ),
                TextFormField(
                  initialValue: _assignedTo,
                  decoration: const InputDecoration(labelText: 'Assigned To'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please assign a user' : null,
                  onSaved: (value) => _assignedTo = value!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskStatus>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: TaskStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _status = value!),
                ),
                DropdownButtonFormField<TaskPriority>(
                  value: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: TaskPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority.label),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _priority = value!),
                ),
                const SizedBox(height: 16),
                Text('Related To (Optional)', style: Theme.of(context).textTheme.titleSmall),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _relatedEntityType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('None')),
                          DropdownMenuItem(value: 'Contact', child: Text('Contact')),
                          DropdownMenuItem(value: 'Deal', child: Text('Deal')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _relatedEntityType = value;
                            _relatedEntityId = null;
                            _relatedEntityName = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _relatedEntityType == 'Contact'
                          ? contactsAsync.when(
                              data: (contacts) => DropdownButtonFormField<String>(
                                value: _relatedEntityId,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Select Contact'),
                                items: contacts.map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                                )).toList(),
                                onChanged: (value) {
                                  final contact = contacts.firstWhere((c) => c.id == value);
                                  setState(() {
                                    _relatedEntityId = value;
                                    _relatedEntityName = contact.name;
                                  });
                                },
                              ),
                              loading: () => const LinearProgressIndicator(),
                              error: (_, __) => const Text('Error'),
                            )
                          : _relatedEntityType == 'Deal'
                              ? dealsAsync.when(
                                  data: (deals) => DropdownButtonFormField<String>(
                                    value: _relatedEntityId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(labelText: 'Select Deal'),
                                    items: deals.map((d) => DropdownMenuItem(
                                      value: d.id,
                                      child: Text(d.title, overflow: TextOverflow.ellipsis),
                                    )).toList(),
                                    onChanged: (value) {
                                      final deal = deals.firstWhere((d) => d.id == value);
                                      setState(() {
                                        _relatedEntityId = value;
                                        _relatedEntityName = deal.title;
                                      });
                                    },
                                  ),
                                  loading: () => const LinearProgressIndicator(),
                                  error: (_, __) => const Text('Error'),
                                )
                              : Container(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
