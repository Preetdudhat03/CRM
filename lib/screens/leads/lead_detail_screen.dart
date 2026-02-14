
import 'package:flutter/material.dart';
import '../../models/lead_model.dart';

class LeadDetailScreen extends StatelessWidget {
  final LeadModel lead;

  const LeadDetailScreen({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lead.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lead.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Status: ${lead.status.label}'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(lead.email),
            ),
             ListTile(
              leading: const Icon(Icons.phone),
              title: Text(lead.phone),
            ),
             ListTile(
              leading: const Icon(Icons.source),
              title: Text('Source: ${lead.source}'),
            ),
              ListTile(
              leading: const Icon(Icons.person),
              title: Text('Assigned to: ${lead.assignedTo}'),
            ),
             if (lead.estimatedValue != null)
              ListTile(
              leading: const Icon(Icons.attach_money),
              title: Text('Estimated Value: ₹${lead.estimatedValue!.toStringAsFixed(0)}'),
            ),
          ],
        ),
      ),
    );
  }
}
