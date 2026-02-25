
import 'package:flutter/material.dart';

enum DealStage {
  qualification,
  needsAnalysis,
  proposal,
  negotiation,
  closedWon,
  closedLost,
}

extension DealStageExtension on DealStage {
  String get label {
    switch (this) {
      case DealStage.qualification:
        return 'Qualification';
      case DealStage.needsAnalysis:
        return 'Needs Analysis';
      case DealStage.proposal:
        return 'Proposal';
      case DealStage.negotiation:
        return 'Negotiation';
      case DealStage.closedWon:
        return 'Closed Won';
      case DealStage.closedLost:
        return 'Closed Lost';
    }
  }

  Color get color {
    switch (this) {
      case DealStage.qualification:
        return Colors.blueGrey;
      case DealStage.needsAnalysis:
        return Colors.blue;
      case DealStage.proposal:
        return Colors.orange;
      case DealStage.negotiation:
        return Colors.purple;
      case DealStage.closedWon:
        return Colors.green;
      case DealStage.closedLost:
        return Colors.red;
    }
  }
}

class DealModel {
  final String id;
  final String title;
  final String contactId;
  final String contactName; // Denormalized for simpler UI
  final String companyName; // Denormalized for simpler UI
  final double value;
  final DealStage stage;
  final String assignedTo;
  final DateTime expectedCloseDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DealModel({
    required this.id,
    required this.title,
    required this.contactId,
    required this.contactName,
    required this.companyName,
    required this.value,
    required this.stage,
    required this.assignedTo,
    required this.expectedCloseDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  DealModel copyWith({
    String? id,
    String? title,
    String? contactId,
    String? contactName,
    String? companyName,
    double? value,
    DealStage? stage,
    String? assignedTo,
    DateTime? expectedCloseDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DealModel(
      id: id ?? this.id,
      title: title ?? this.title,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      companyName: companyName ?? this.companyName,
      value: value ?? this.value,
      stage: stage ?? this.stage,
      assignedTo: assignedTo ?? this.assignedTo,
      expectedCloseDate: expectedCloseDate ?? this.expectedCloseDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  factory DealModel.fromJson(Map<String, dynamic> json) {
    // Convert snake_case stage to camelCase for enum matching
    final rawStage = (json['stage'] ?? 'qualification') as String;
    final stageName = rawStage.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (m) => m.group(1)!.toUpperCase(),
    );
    return DealModel(
      id: json['id'],
      title: json['title'] ?? '',
      contactId: json['contact_id'] ?? '',
      contactName: json['contact_name'] ?? '',
      companyName: json['company_name'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      stage: DealStage.values.firstWhere(
        (e) => e.name == stageName,
        orElse: () => DealStage.qualification,
      ),
      assignedTo: json['assigned_to'] ?? '',
      expectedCloseDate: json['expected_close_date'] != null
          ? DateTime.parse(json['expected_close_date'])
          : DateTime.now().add(const Duration(days: 30)),
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    // Convert camelCase stage to snake_case for DB
    final stageSnake = stage.name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
    return {
      'title': title,
      'contact_id': contactId.isEmpty ? null : contactId,
      'company_name': companyName,
      'value': value,
      'stage': stageSnake,
      'assigned_to': assignedTo.isEmpty ? null : assignedTo,
      'expected_close_date': expectedCloseDate.toIso8601String(),
    };
  }
}
