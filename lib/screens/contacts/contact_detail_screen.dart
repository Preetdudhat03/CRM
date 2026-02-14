
import 'package:flutter/material.dart';
import '../../models/contact_model.dart';

class ContactDetailScreen extends StatelessWidget {
  final ContactModel contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(contact.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: contact.avatarUrl != null
                  ? NetworkImage(contact.avatarUrl!)
                  : null,
              child: contact.avatarUrl == null
                  ? Text(
                      contact.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 40),
                    )
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              contact.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              '${contact.position} at ${contact.company}',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(contact.email),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(contact.phone),
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: Text(contact.company),
            ),
          ],
        ),
      ),
    );
  }
}
