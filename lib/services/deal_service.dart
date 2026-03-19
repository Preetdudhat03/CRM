import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/deal_model.dart';
import 'activity_service.dart';
import 'audit_log_service.dart';

class DealService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<DealModel>> getDeals({int page = 0, int pageSize = 20}) async {
    final start = page * pageSize;
    final end = start + pageSize - 1;

    final response = await _supabase
        .from('deals')
        .select('*, contacts(name, company)')
        .order('created_at', ascending: false)
        .range(start, end);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) {
      final contact = json['contacts'];
      if (contact != null) {
        json['contact_name'] = contact['name'];
        if (json['company_name'] == null) {
          json['company_name'] = contact['company'];
        }
      }
      return DealModel.fromJson(json);
    }).toList();
  }

  Future<DealModel> addDeal(DealModel deal) async {
    final json = deal.toJson();
    json.remove('contact_name');

    final response = await _supabase
        .from('deals')
        .insert(json)
        .select('*, contacts(name, company)')
        .maybeSingle();

    if (response == null) throw Exception('Failed to create deal');

    final contact = response['contacts'];
    if (contact != null) {
      response['contact_name'] = contact['name'];
    }

    final newDeal = DealModel.fromJson(response);

    // Log Activity: Deal Created
    ActivityService.log(
      relatedType: 'deal',
      relatedId: newDeal.id,
      activityType: 'created',
      title: 'Deal Created',
      description:
          'Deal "${newDeal.title}" added for \$${newDeal.value.toStringAsFixed(2)}',
      metadata: {'value': newDeal.value, 'stage': newDeal.stage.name},
      organizationId: newDeal.organizationId,
    );

    // Audit Log
    AuditLogService.log(
      action: 'deal_created',
      entityType: 'deal',
      entityId: newDeal.id,
      newValues: newDeal.toJson(),
      organizationId: newDeal.organizationId,
    );

    return newDeal;
  }

  Future<DealModel> updateDeal(DealModel deal) async {
    final json = deal.toJson();
    json.remove('contact_name');

    final response = await _supabase
        .from('deals')
        .update(json)
        .eq('id', deal.id)
        .select('*, contacts(name, company)')
        .maybeSingle();

    if (response == null) throw Exception('Deal not found or access denied');

    final contact = response['contacts'];
    if (contact != null) {
      response['contact_name'] = contact['name'];
    }

    final updatedDeal = DealModel.fromJson(response);

    // Log Activity
    ActivityService.log(
      relatedType: 'deal',
      relatedId: updatedDeal.id,
      activityType: 'stage_changed', // Assuming stage change is the main update
      title: 'Deal Updated',
      description: 'Stage: ${updatedDeal.stage.displayName}',
      metadata: {'stage': updatedDeal.stage.name, 'value': updatedDeal.value},
      organizationId: updatedDeal.organizationId,
    );

    // Audit Log
    AuditLogService.log(
      action: deal.stage != updatedDeal.stage ? 'deal_stage_changed' : 'deal_updated',
      entityType: 'deal',
      entityId: updatedDeal.id,
      oldValues: deal.toJson(),
      newValues: updatedDeal.toJson(),
      organizationId: updatedDeal.organizationId,
    );

    return updatedDeal;
  }

  Future<void> deleteDeal(String id) async {
    // Fetch deal to get old values before deleting
    final oldRecord = await _supabase.from('deals').select().eq('id', id).maybeSingle();
    
    await _supabase.from('deals').delete().eq('id', id);

    if (oldRecord != null) {
      AuditLogService.log(
        action: 'deal_deleted',
        entityType: 'deal',
        entityId: id,
        oldValues: oldRecord,
        organizationId: oldRecord['organization_id'],
      );
    }
  }
}
