import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/lead_model.dart';
import '../../providers/lead_provider.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  final LeadModel lead;

  const LeadDetailScreen({super.key, required this.lead});

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  bool _isConverting = false;

  void _convertLead() async {
    setState(() {
      _isConverting = true;
    });
    try {
      await ref.read(leadsProvider.notifier).convertLead(widget.lead.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead converted to Contact successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error converting lead: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConverting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lead.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.lead.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: widget.lead.status == LeadStatus.converted || _isConverting
                      ? null
                      : _convertLead,
                  icon: _isConverting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Icon(Icons.transform),
                  label: const Text('Convert to Contact'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Status: ${widget.lead.status.label}'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(widget.lead.email),
            ),
             ListTile(
              leading: const Icon(Icons.phone),
              title: Text(widget.lead.phone),
            ),
             ListTile(
              leading: const Icon(Icons.source),
              title: Text('Source: ${widget.lead.source}'),
            ),
              ListTile(
              leading: const Icon(Icons.person),
              title: Text('Assigned to: ${widget.lead.assignedTo}'),
            ),
             if (widget.lead.estimatedValue != null)
              ListTile(
              leading: const Icon(Icons.attach_money),
              title: Text('Estimated Value: ₹${widget.lead.estimatedValue!.toStringAsFixed(0)}'),
            ),
          ],
        ),
      ),
    );
  }
}
