
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the gallery
  Future<XFile?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Resize/compress to avoid huge uploads
        maxWidth: 1024,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Uploads an avatar image to Supabase Storage
  /// Returns the public URL of the uploaded image
  /// - [file]: The image file to upload (XFile for cross-platform support)
  /// - [path]: The storage path (e.g. 'users/user_id_123.jpg' or 'contacts/contact_id_456.jpg')
  Future<String?> uploadAvatar(XFile file, String path) async {
    try {
      final fileExt = file.path.split('.').last.toLowerCase();
      // Ensure valid extension
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(fileExt)) {
        throw Exception('Invalid file type');
      }
      
      final storagePath = '$path.$fileExt'; // e.g. users/123.jpg

      String mimeType;
      switch (fileExt) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'application/octet-stream';
      }

      final bytes = await file.readAsBytes();

      // Upload file (upsert: true overwrites existing file at same path)
      await _supabase.storage.from('avatars').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: mimeType,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(storagePath);
      
      return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      rethrow;
    }
  }
}
