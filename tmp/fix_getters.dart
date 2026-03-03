import 'dart:io';

void main() {
  File getFile(String path) => File(path);
  
  // 1. TaskModel isCompleted
  var fTask = getFile('lib/models/task_model.dart');
  var contentTask = fTask.readAsStringSync();
  if (!contentTask.contains('bool get isCompleted')) {
    contentTask = contentTask.replaceFirst(
      'final DateTime createdAt;', 
      'final DateTime createdAt;\n\n  bool get isCompleted => status == TaskStatus.completed;'
    );
    fTask.writeAsStringSync(contentTask);
    print('Fixed TaskModel');
  }

  // 2. LeadModel firstName, lastName, leadSource
  var fLead = getFile('lib/models/lead_model.dart');
  var contentLead = fLead.readAsStringSync();
  if (!contentLead.contains('String get firstName')) {
    contentLead = contentLead.replaceFirst(
      'final DateTime? convertedAt;',
      'final DateTime? convertedAt;\n\n  String get firstName => name.split(\' \').first;\n  String get lastName => name.split(\' \').length > 1 ? name.split(\' \').sublist(1).join(\' \') : \'\';\n  String get leadSource => source;'
    );
    fLead.writeAsStringSync(contentLead);
    print('Fixed LeadModel');
  }
}
