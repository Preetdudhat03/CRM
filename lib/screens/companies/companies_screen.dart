import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/company_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import 'widgets/company_card.dart';
import 'add_edit_company_screen.dart';
import '../../core/services/permission_service.dart';
import '../../widgets/skeleton_loading.dart';
import 'company_detail_screen.dart';

class CompaniesScreen extends ConsumerStatefulWidget {
  const CompaniesScreen({super.key});

  @override
  ConsumerState<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends ConsumerState<CompaniesScreen> {
  final ScrollController _scrollController = ScrollController();

  // Local Filter & Sort State
  String? _industryFilter;
  String _sortOption = 'Recently Added'; // 'Name', 'Recently Added', 'Revenue'
  String? _sizeFilter; // 'Enterprise', 'Mid-Market', 'Small Business'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(companiesProvider.notifier).loadMore();
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    CompanyModel company,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text(
          'Are you sure you want to delete ${company.name}? This will affect linked contacts and deals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(companiesProvider.notifier).deleteCompany(company.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${company.name} deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(List<CompanyModel> allCompanies) {
    final sizes = ['Enterprise', 'Mid-Market', 'Small Business'];

    return Container(
      height: 60,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: sizes.map((size) {
            final isSelected = _sizeFilter == size;

            int getCount() {
              if (size == 'Enterprise')
                return allCompanies.where((c) => c.revenue >= 1000000).length;
              if (size == 'Mid-Market')
                return allCompanies
                    .where((c) => c.revenue >= 100000 && c.revenue < 1000000)
                    .length;
              return allCompanies.where((c) => c.revenue < 100000).length;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
              child: FilterChip(
                label: Text(size),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _sizeFilter = selected ? size : null;
                  });
                },
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                checkmarkColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(filteredCompaniesProvider);
    final user = ref.watch(currentUserProvider);
    // Reuse contact permissions for companies for now
    final canCreate = PermissionService.canCreateContacts(user);
    final canEdit = PermissionService.canEditContacts(user);
    final canDelete = PermissionService.canDeleteContacts(user);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Companies',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search companies...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                        onChanged: (value) {
                          ref.read(companySearchQueryProvider.notifier).state =
                              value;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _sortOption,
                            icon: Icon(Icons.sort, color: Colors.grey.shade600),
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            items: ['Recently Added', 'Name', 'Revenue'].map((
                              sort,
                            ) {
                              return DropdownMenuItem(
                                value: sort,
                                child: Text(sort),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _sortOption = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              companiesAsync.maybeWhen(
                data: (allCompanies) => _buildFilterChips(allCompanies),
                orElse: () => const SizedBox(height: 60),
              ),
            ],
          ),
        ),
      ),
      body: companiesAsync.when(
        data: (unfilteredCompanies) {
          var companies = unfilteredCompanies;

          // Apply size filter
          if (_sizeFilter != null) {
            if (_sizeFilter == 'Enterprise') {
              companies = companies.where((c) => c.revenue >= 1000000).toList();
            } else if (_sizeFilter == 'Mid-Market') {
              companies = companies
                  .where((c) => c.revenue >= 100000 && c.revenue < 1000000)
                  .toList();
            } else {
              companies = companies.where((c) => c.revenue < 100000).toList();
            }
          }

          // Apply sorting
          if (_sortOption == 'Name') {
            companies.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          } else if (_sortOption == 'Revenue') {
            companies.sort((a, b) => b.revenue.compareTo(a.revenue));
          } else {
            companies.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(companiesProvider.notifier).refresh(),
            child: companies.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 250,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.business_outlined,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Companies Yet',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "You don't have any companies matching\n the current filters.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (canCreate)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddEditCompanyScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Company'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    itemCount: companies.length + 1,
                    itemBuilder: (context, index) {
                      if (index == companies.length) {
                        final notifier = ref.read(companiesProvider.notifier);
                        if (notifier.isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final company = companies[index];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: CompanyCard(
                            company: company,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CompanyDetailScreen(company: company),
                                ),
                              );
                            },
                            onEdit: canEdit
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddEditCompanyScreen(
                                              company: company,
                                            ),
                                      ),
                                    );
                                  }
                                : null,
                            onDelete: canDelete
                                ? () => _showDeleteConfirmation(
                                    context,
                                    ref,
                                    company,
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
        loading: () => ListView.builder(
          itemCount: 6,
          padding: const EdgeInsets.only(top: 8),
          itemBuilder: (context, index) => SkeletonCard(height: 100),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Failed to load companies',
                style: TextStyle(color: Colors.grey.shade800, fontSize: 16),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.read(companiesProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              heroTag: 'companies_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditCompanyScreen(),
                  ),
                );
              },
              backgroundColor: Theme.of(context).primaryColor,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
