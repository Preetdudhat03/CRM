import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/company_model.dart';
import '../../providers/company_provider.dart';

class CompanyPicker extends ConsumerWidget {
  final String? selectedCompanyId;
  final ValueChanged<CompanyModel?> onSelected;
  final String label;

  const CompanyPicker({
    super.key,
    this.selectedCompanyId,
    required this.onSelected,
    this.label = 'Select Company',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(companiesProvider);

    return companiesAsync.when(
      data: (companies) {
        // Find current selection
        CompanyModel? currentValue;
        if (selectedCompanyId != null && selectedCompanyId!.isNotEmpty) {
          try {
            currentValue = companies.firstWhere(
              (c) => c.id == selectedCompanyId,
            );
          } catch (_) {
            currentValue = null;
          }
        }

        return DropdownButtonFormField<CompanyModel>(
          value: currentValue,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.business_outlined),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          items: [
            const DropdownMenuItem<CompanyModel>(
              value: null,
              child: Text('No Company'),
            ),
            ...companies.map(
              (company) => DropdownMenuItem(
                value: company,
                child: Text(company.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onSelected,
        );
      },
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (_, __) => const Text('Error loading companies'),
    );
  }
}
