import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../models/file_model.dart';
import '../repositories/file_repository.dart';
import 'activity_service.dart';

class FileService {
  final FileRepository _fileRepository = FileRepository();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<FileModel>> getFiles(String relatedType, String relatedId) async {
    return _fileRepository.getFiles(relatedType, relatedId);
  }

  Future<FileModel?> uploadFile({
    required File file,
    required String relatedType,
    required String relatedId,
    required String organizationId,
  }) async {
    try {
      final fileName = path.basename(file.path);
      final fileExt = path.extension(file.path).replaceAll('.', '');
      final userId = _supabase.auth.currentUser?.id;
      
      // 1. Upload to Storage
      // Path: organization_id/related_type/related_id/timestamp_filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = organizationId.isEmpty
          ? '$relatedType/$relatedId/${timestamp}_$fileName'
          : '$organizationId/$relatedType/$relatedId/${timestamp}_$fileName';
      
      await _supabase.storage.from('crm-files').upload(
        storagePath,
        file,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      // 2. Get Public URL
      final fileUrl = _supabase.storage.from('crm-files').getPublicUrl(storagePath);

      // 3. Save Metadata
      final fileModel = FileModel(
        id: '',
        organizationId: organizationId,
        relatedType: relatedType,
        relatedId: relatedId,
        fileName: fileName,
        fileUrl: fileUrl,
        fileSize: await file.length(),
        mimeType: _getMimeType(fileExt),
        uploadedBy: userId,
        createdAt: DateTime.now(),
      );

      final savedFile = await _fileRepository.insertFile(fileModel);

      // 4. Log Activity
      await ActivityService.log(
        relatedType: relatedType,
        relatedId: relatedId,
        activityType: 'file_uploaded',
        title: 'File uploaded',
        description: 'Uploaded $fileName',
        metadata: {
          'file_name': fileName,
          'file_url': fileUrl,
        },
        organizationId: organizationId,
      );

      return savedFile;
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(FileModel file) async {
    try {
      // 1. Delete from Storage
      // Need to extract storage path from URL or store it in model
      // For now, let's assume we can derive it or we store it. 
      // Simplified: derive from URL if it's a standard Supabase URL
      final uri = Uri.parse(file.fileUrl);
      final pathSegments = uri.pathSegments;
      final storagePath = pathSegments.sublist(pathSegments.indexOf('crm-files') + 1).join('/');
      
      await _supabase.storage.from('crm-files').remove([storagePath]);

      // 2. Delete from DB
      await _fileRepository.deleteFile(file.id);
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'doc':
      case 'docx': return 'application/msword';
      case 'xls':
      case 'xlsx': return 'application/vnd.ms-excel';
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      default: return 'application/octet-stream';
    }
  }
}
