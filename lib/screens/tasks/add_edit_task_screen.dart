
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task_model.dart';
import '../../providers/contact_provider.dart';
import '../../providers/deal_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_management_provider.dart';
import '../../widgets/animations/fade_in_slide.dart';

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
    final usersAsync = ref.watch(userManagementProvider);

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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
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
                        initialValue: _title,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter a title' : null,
                        onSaved: (value) => _title = value!,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInSlide(
                      delay: 0.1,
                      child: TextFormField(
                        initialValue: _description,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        maxLines: 3,
                        onSaved: (value) => _description = value ?? '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInSlide(
                      delay: 0.2,
                      child: Card(
                         elevation: 0,
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(12),
                           side: BorderSide(color: Theme.of(context).dividerColor),
                         ),
                         child: ListTile(
                          title: Text('Due Date: ${_dueDate.toIso8601String().split('T')[0]}'),
                          leading: const Icon(Icons.calendar_today),
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInSlide(
                      delay: 0.3,
                      child: usersAsync.when(
                        data: (users) {
                          String? selectedValue;
                          if (_assignedTo.isNotEmpty && users.any((u) => u.name == _assignedTo)) {
                            selectedValue = _assignedTo;
                          } else if (_assignedTo.isNotEmpty) {
                             // Keep the old value mapped if not found to prevent crash, or add it to the list dynamically
                             selectedValue = _assignedTo;
                          }
                          
                          final allItems = users.map((u) => u.name).toList();
                          if (selectedValue != null && !allItems.contains(selectedValue)) {
                             allItems.add(selectedValue);
                          }

                          return DropdownButtonFormField<String>(
                            value: selectedValue,
                            decoration: const InputDecoration(
                              labelText: 'Assigned To',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            items: allItems.map((uName) {
                              return DropdownMenuItem<String>(
                                value: uName,
                                child: Text(uName),
                              );
                            }).toList(),
                            validator: (value) => (value == null || value.isEmpty) ? 'Please assign a user' : null,
                            onChanged: (value) {
                              setState(() {
                                if (value != null) _assignedTo = value;
                              });
                            },
                            onSaved: (value) {
                              if (value != null) _assignedTo = value;
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Error loading users'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInSlide(
                      delay: 0.4,
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TaskStatus>(
                              value: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                              items: TaskStatus.values.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(
                                    status.label,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _status = value!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<TaskPriority>(
                              value: _priority,
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                              items: TaskPriority.values.map((priority) {
                                return DropdownMenuItem(
                                  value: priority,
                                  child: Text(
                                    priority.label,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _priority = value!),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInSlide(
                      delay: 0.5,
                      child: Text('Related To (Optional)', style: Theme.of(context).textTheme.titleSmall),
                    ),
                    const SizedBox(height: 8),
                    FadeInSlide(
                      delay: 0.6,
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _relatedEntityType,
                              decoration: const InputDecoration(
                                labelText: 'Type',
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
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
                                      decoration: const InputDecoration(
                                        labelText: 'Select Contact',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                      ),
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
                                          decoration: const InputDecoration(
                                            labelText: 'Select Deal',
                                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                          ),
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
                          widget.task == null ? 'Create Task' : 'Update Task',
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
