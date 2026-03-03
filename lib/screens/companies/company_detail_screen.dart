import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/company_model.dart';
import '../../providers/company_provider.dart';
import '../../providers/contact_provider.dart';
import '../../providers/deal_provider.dart';
import '../contacts/widgets/contact_card.dart';
import '../deals/widgets/deal_card.dart';
import '../contacts/contact_detail_screen.dart';
import '../deals/add_edit_deal_screen.dart'; // Using for detail if needed or its own
import 'add_edit_company_screen.dart';
import 'package:intl/intl.dart';
import '../../providers/user_management_provider.dart';
import '../../widgets/activity_timeline.dart';

class CompanyDetailScreen extends ConsumerStatefulWidget {
  final CompanyModel company;

  const CompanyDetailScreen({super.key, required this.company});

  @override
  ConsumerState<CompanyDetailScreen> createState() =>
      _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends ConsumerState<CompanyDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesProvider);
    final company =
        companiesAsync.value?.firstWhere(
          (c) => c.id == widget.company.id,
          orElse: () => widget.company,
        ) ??
        widget.company;

    return Scaffold(
      appBar: AppBar(
        title: Text(company.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditCompanyScreen(company: company),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Contacts'),
            Tab(text: 'Deals'),
            Tab(text: 'Activities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(company),
          _buildContactsTab(company),
          _buildDealsTab(company),
          _buildActivitiesTab(company),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(CompanyModel company) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(company, currencyFormat),
          const SizedBox(height: 24),
          if (company.notes != null && company.notes!.isNotEmpty) ...[
            const Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  company.notes!,
                  style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(CompanyModel company, NumberFormat currencyFormat) {
    final usersAsync = ref.watch(userManagementProvider);
    String managerName = 'Not assigned';

    if (company.assignedTo != null) {
      usersAsync.whenData((users) {
        try {
          managerName = users
              .firstWhere((u) => u.id == company.assignedTo)
              .name;
        } catch (_) {}
      });
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.person_pin_outlined,
              'Account Manager',
              managerName,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.category_outlined,
              'Industry',
              company.industry ?? 'Not specified',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.monetization_on_outlined,
              'Won Revenue',
              currencyFormat.format(company.revenue),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.people_outline,
              'Employees',
              company.employeeCount?.toString() ?? 'Not specified',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.language_outlined,
              'Website',
              company.website ?? 'Not specified',
              isLink: true,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.phone_outlined,
              'Phone',
              company.phone ?? 'Not specified',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Address',
              company.address ?? 'Not specified',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isLink ? Colors.blue : Colors.grey.shade900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactsTab(CompanyModel company) {
    final contactsAsync = ref.watch(contactsProvider);

    return contactsAsync.when(
      data: (contacts) {
        final companyContacts = contacts
            .where((c) => c.companyId == company.id)
            .toList();

        if (companyContacts.isEmpty) {
          return _buildEmptyState(
            Icons.people_outlined,
            'No contacts linked to this company.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: companyContacts.length,
          itemBuilder: (context, index) {
            final contact = companyContacts[index];
            return ContactCard(
              contact: contact,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContactDetailScreen(contact: contact),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading contacts: $e')),
    );
  }

  Widget _buildDealsTab(CompanyModel company) {
    final dealsAsync = ref.watch(dealsProvider);

    return dealsAsync.when(
      data: (deals) {
        final companyDeals = deals
            .where((d) => d.companyId == company.id)
            .toList();

        if (companyDeals.isEmpty) {
          return _buildEmptyState(
            Icons.handshake_outlined,
            'No deals linked to this company.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: companyDeals.length,
          itemBuilder: (context, index) {
            final deal = companyDeals[index];
            return DealCard(
              deal: deal,
              onTap: () {
                // Navigate to deal detail
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading deals: $e')),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab(CompanyModel company) {
    return ActivityTimeline(relatedType: 'company', relatedId: company.id);
  }
}
