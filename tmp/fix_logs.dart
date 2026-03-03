import 'dart:io';

void main() {
  final dir = Directory('lib/providers');
  if (!dir.existsSync()) return;

  var count = 0;
  for (var fileEntity in dir.listSync(recursive: true)) {
    if (fileEntity is File && fileEntity.path.endsWith('.dart')) {
      var content = fileEntity.readAsStringSync();
      var original = content;

      content = content.replaceAll(RegExp(r"type:\s*'contact'"), "relatedEntityType: 'contact'");
      content = content.replaceAll(
          RegExp(r"type:\s*'contact',"), "relatedEntityType: 'contact',");
      
      content = content.replaceAll(RegExp(r"type:\s*'deal'"), "relatedEntityType: 'deal'");
      content = content.replaceAll(
          RegExp(r"type:\s*'deal',"), "relatedEntityType: 'deal',");
      
      content = content.replaceAll(RegExp(r"type:\s*'lead'"), "relatedEntityType: 'lead'");
      content = content.replaceAll(
          RegExp(r"type:\s*'lead',"), "relatedEntityType: 'lead',");
      
      content = content.replaceAll(RegExp(r"type:\s*'task'"), "relatedEntityType: 'task'");
      content = content.replaceAll(
          RegExp(r"type:\s*'task',"), "relatedEntityType: 'task',");
      
      content = content.replaceAll(RegExp(r"type:\s*'company'"), "relatedEntityType: 'company'");
      content = content.replaceAll(
          RegExp(r"type:\s*'company',"), "relatedEntityType: 'company',");
      
      content = content.replaceAll(RegExp(r"type:\s*'organization'"), "relatedEntityType: 'organization'");
      
      content = content.replaceAll(RegExp(r"relatedEntityId:"), "relatedId:");

      if (content != original) {
        fileEntity.writeAsStringSync(content);
        count++;
        print('Fixed ${fileEntity.path}');
      }
    }
  }
  print('Fixed: \$count files');
}
