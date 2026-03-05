import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../providers/file_provider.dart';
import '../../models/file_model.dart';
import '../../providers/auth_provider.dart';

class FileListView extends ConsumerWidget {
  final String relatedType;
  final String relatedId;
  final String organizationId;

  const FileListView({
    super.key,
    required this.relatedType,
    required this.relatedId,
    required this.organizationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider('$relatedType:$relatedId'));
    final authState = ref.watch(authProvider);
    final isAdminOrManager = authState.role == 'admin' || authState.role == 'manager';
    final canUpload = authState.role != 'viewer';

    return Column(
      children: [
        if (canUpload)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _pickAndUploadFile(context, ref),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload File'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        Expanded(
          child: fileState.isLoading && fileState.files.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : fileState.files.isEmpty
                  ? const Center(child: Text('No files attached'))
                  : ListView.builder(
                      itemCount: fileState.files.length,
                      itemBuilder: (context, index) {
                        final file = fileState.files[index];
                        return _buildFileCard(context, ref, file, isAdminOrManager);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFileCard(BuildContext context, WidgetRef ref, FileModel file, bool canDelete) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _getFileIcon(file.fileName),
        title: Text(file.fileName),
        subtitle: Text(
          '${_formatFileSize(file.fileSize)} • ${DateFormat('MMM d, y`).format(file.createdAt)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadFile(file.fileUrl),
            ),
            if (canDelete)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteFile(context, ref, file),
              ),
          ],
        ),
      ),
    );
  }

  Widget _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'doc':
      case 'docx': return const Icon(Icons.description, color: Colors.blue);
      case 'xls':
      case 'xlsx': return const Icon(Icons.table_chart, color: Colors.green);
      case 'png':
      case 'jpg':
      case 'jpeg': return const Icon(Icons.image, color: Colors.orange);
      default: return const Icon(Icons.insert_drive_file);
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickAndUploadFile(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      await ref.read(fileProvider('$relatedType:$relatedId').notifier).uploadFile(file, organizationId);
    }
  }

  Future<void> _downloadFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _deleteFile(BuildContext context, WidgetRef ref, FileModel file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete ${file.fileName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(fileProvider('$relatedType:$relatedId').notifier).deleteFile(file);
    }
  }
}
