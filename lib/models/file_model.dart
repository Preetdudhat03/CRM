class FileModel {
  final String id;
  final String organizationId;
  final String relatedType; // 'lead', 'contact', 'deal', 'company'
  final String relatedId;
  final String fileName;
  final String fileUrl;
  final int? fileSize;
  final String? mimeType;
  final String? uploadedBy;
  final DateTime createdAt;

  FileModel({
    required this.id,
    required this.organizationId,
    required this.relatedType,
    required this.relatedId,
    required this.fileName,
    required this.fileUrl,
    this.fileSize,
    this.mimeType,
    this.uploadedBy,
    required this.createdAt,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'],
      organizationId: json['organization_id'],
      relatedType: json['related_type'],
      relatedId: json['related_id'],
      fileName: json['file_name'],
      fileUrl: json['file_url'],
      fileSize: json['file_size'],
      mimeType: json['mime_type'],
      uploadedBy: json['uploaded_by'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'organization_id': organizationId,
      'related_type': relatedType,
      'related_id': relatedId,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_size': fileSize,
      'mime_type': mimeType,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
