
import 'package:flutter/material.dart';
import '../../models/deal_model.dart';

class DealDetailScreen extends StatelessWidget {
  final DealModel deal;

  const DealDetailScreen({super.key, required this.deal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(deal.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deal.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(deal.stage.label),
              backgroundColor: deal.stage.color.withOpacity(0.1),
              labelStyle: TextStyle(
                color: deal.stage.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.attach_money, color: Colors.green),
                title: Text(
                  '₹${deal.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                subtitle: const Text('Deal Value'),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.business),
              title: Text('${deal.contactName} (${deal.companyName})'),
              subtitle: const Text('Contact & Company'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(deal.assignedTo),
              subtitle: const Text('Assigned To'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(deal.expectedCloseDate.toIso8601String().split('T')[0]),
               subtitle: const Text('Expected Close Date'),
            ),
             if (deal.notes != null)
             ListTile(
              leading: const Icon(Icons.note),
              title: Text(deal.notes!),
              subtitle: const Text('Notes'),
            ),
          ],
        ),
      ),
    );
  }
}
