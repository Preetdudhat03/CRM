class CompanyModel {
  final String id;
  final String? organizationId;
  final String name;
  final String? industry;
  final String? website;
  final String? phone;
  final String? address;
  final double revenue;
  final int? employeeCount;
  final String? notes;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CompanyModel({
    required this.id,
    this.organizationId,
    required this.name,
    this.industry,
    this.website,
    this.phone,
    this.address,
    this.revenue = 0.0,
    this.employeeCount,
    this.notes,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  CompanyModel copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? industry,
    String? website,
    String? phone,
    String? address,
    double? revenue,
    int? employeeCount,
    String? notes,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      industry: industry ?? this.industry,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      revenue: revenue ?? this.revenue,
      employeeCount: employeeCount ?? this.employeeCount,
      notes: notes ?? this.notes,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] ?? '',
      organizationId: json['organization_id'],
      name: json['name'] ?? '',
      industry: json['industry'],
      website: json['website'],
      phone: json['phone'],
      address: json['address'],
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      employeeCount: json['employee_count'],
      notes: json['notes'],
      assignedTo: json['assigned_to'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'organization_id': (organizationId != null && organizationId!.isEmpty) ? null : organizationId,
      'name': name,
      'industry': industry,
      'website': website,
      'phone': phone,
      'address': address,
      'revenue': revenue,
      'employee_count': employeeCount,
      'notes': notes,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
