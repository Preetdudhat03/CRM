import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/organization_model.dart';
import '../models/organization_member_model.dart';
import '../services/organization_service.dart';
import '../repositories/organization_repository.dart';

// Service & Repository Providers
final organizationServiceProvider = Provider<OrganizationService>(
  (ref) => OrganizationService(),
);

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository(ref.watch(organizationServiceProvider));
});

// ============================================================
// Current Organization State
// ============================================================
class OrganizationNotifier extends StateNotifier<AsyncValue<OrganizationModel?>> {
  final OrganizationRepository _repository;

  OrganizationNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final org = await _repository.getCurrentOrganization();
      state = AsyncValue.data(org);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createOrganization(String name) async {
    try {
      final org = await _repository.createOrganization(name);
      state = AsyncValue.data(org);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateOrganization(OrganizationModel org) async {
    try {
      final updated = await _repository.updateOrganization(org);
      state = AsyncValue.data(updated);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      final org = await _repository.getCurrentOrganization();
      state = AsyncValue.data(org);
    } catch (e, stack) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, stack);
      }
    }
  }
}

final currentOrganizationProvider =
    StateNotifierProvider<OrganizationNotifier, AsyncValue<OrganizationModel?>>(
  (ref) => OrganizationNotifier(ref.watch(organizationRepositoryProvider)),
);

// ============================================================
// Organization Members
// ============================================================
class OrganizationMembersNotifier
    extends StateNotifier<AsyncValue<List<OrganizationMemberModel>>> {
  final OrganizationRepository _repository;
  final String? _orgId;

  OrganizationMembersNotifier(this._repository, this._orgId)
      : super(const AsyncValue.loading()) {
    if (_orgId != null) load();
  }

  Future<void> load() async {
    if (_orgId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      state = const AsyncValue.loading();
      final members = await _repository.listMembers(_orgId);
      state = AsyncValue.data(members);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> inviteMember(String email, {String role = 'member'}) async {
    if (_orgId == null) throw Exception('No organization');
    final member = await _repository.inviteMember(
      orgId: _orgId,
      email: email,
      role: role,
    );
    state.whenData((members) {
      state = AsyncValue.data([...members, member]);
    });
  }

  Future<void> removeMember(String memberId) async {
    await _repository.removeMember(memberId);
    state.whenData((members) {
      state = AsyncValue.data(
        members.where((m) => m.id != memberId).toList(),
      );
    });
  }

  Future<void> updateMemberRole(String memberId, String newRole) async {
    await _repository.updateMemberRole(memberId, newRole);
    state.whenData((members) {
      state = AsyncValue.data([
        for (final m in members)
          if (m.id == memberId) m.copyWith(role: newRole) else m,
      ]);
    });
  }

  Future<void> refresh() async => load();
}

final organizationMembersProvider = StateNotifierProvider<
    OrganizationMembersNotifier,
    AsyncValue<List<OrganizationMemberModel>>>((ref) {
  final orgAsync = ref.watch(currentOrganizationProvider);
  final orgId = orgAsync.valueOrNull?.id;
  return OrganizationMembersNotifier(
    ref.watch(organizationRepositoryProvider),
    orgId,
  );
});
