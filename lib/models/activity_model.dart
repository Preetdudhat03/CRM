
enum ActivityType {
  call,
  meeting,
  email,
  note,
  task,
}

class ActivityModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final ActivityType type;
  final String relatedId; // ID of related contact, deal, etc.
  final String relatedType; // 'Contact', 'Deal', etc.

  ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    required this.relatedId,
    required this.relatedType,
  });
}
