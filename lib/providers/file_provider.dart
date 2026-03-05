import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_model.dart';
import '../services/file_service.dart';

class FileState {
  final List<FileModel> files;
  final bool isLoading;
  final String? error;

  FileState({
    required this.files,
    this.isLoading = false,
    this.error,
  });

  FileState copyWith({
    List<FileModel>? files,
    bool? isLoading,
    String? error,
  }) {
    return FileState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final FileService _fileService = FileService();
  final String relatedType;
  final String relatedId;

  FileNotifier({required this.relatedType, required this.relatedId})
      : super(FileState(files: [])) {
    loadFiles();
  }

  Future<void> loadFiles() async {
    state = state.copyWith(isLoading: true);
    try {
      final files = await _fileService.getFiles(relatedType, relatedId);
      state = state.copyWith(files: files, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> uploadFile(File file, String organizationId) async {
    state = state.copyWith(isLoading: true);
    try {
      final uploadedFile = await _fileService.uploadFile(
        file: file,
        relatedType: relatedType,
        relatedId: relatedId,
        organizationId: organizationId,
      );
      if (uploadedFile != null) {
        state = state.copyWith(
          files: [uploadedFile, ...state.files],
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteFile(FileModel file) async {
    state = state.copyWith(isLoading: true);
    try {
      await _fileService.deleteFile(file);
      state = state.copyWith(
        files: state.files.where((f) => f.id != file.id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final fileProvider = StateNotifierProvider.family<FileNotifier, FileState, String>((ref, arg) {
  // arg is "relatedType:relatedId"
  final parts = arg.split(':');
  return FileNotifier(relatedType: parts[0], relatedId: parts[1]);
});
