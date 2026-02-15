
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
}
