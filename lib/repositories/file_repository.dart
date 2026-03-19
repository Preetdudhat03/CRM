import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/file_model.dart';

class FileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<FileModel>> getFiles(String relatedType, String relatedId) async {
    final response = await _supabase
        .from('files')
        .select()
        .eq('related_type', relatedType)
        .eq('related_id', relatedId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => FileModel.fromJson(json)).toList();
  }

  Future<FileModel> insertFile(FileModel file) async {
    final response = await _supabase
        .from('files')
        .insert(file.toJson())
        .select()
        .maybeSingle();
    
    if (response == null) throw Exception('Failed to insert file record');
    
    return FileModel.fromJson(response);
  }

  Future<void> deleteFile(String id) async {
    await _supabase.from('files').delete().eq('id', id);
  }
}
