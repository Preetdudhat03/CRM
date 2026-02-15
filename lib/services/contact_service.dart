
import '../models/contact_model.dart';
import 'dart:math';

class ContactService {
  // Mock data for initial contact list matching user requirements
  static final List<ContactModel> _mockContacts = [
    ContactModel(
      id: 'c1',
      name: 'Preet Dudhat',
      email: 'preet@companyx.com',
      phone: '+91 9999999999',
      company: 'CompanyX',
      position: 'CEO',
      address: 'Mumbai, India',
      notes: 'Key client, interested in expansion.',
      status: ContactStatus.customer,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lastContacted: DateTime.now().subtract(const Duration(days: 2)),
      avatarUrl: 'https://i.pravatar.cc/150?u=preet',
    ),
    ContactModel(
      id: 'c2',
      name: 'Rahul Patel',
      email: 'rahul@tesla.com',
      phone: '+1 555-0102',
      company: 'Tesla',
      position: 'Product Manager',
      address: 'Palo Alto, CA',
      notes: 'Interested in demo for Q3.',
      status: ContactStatus.lead,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastContacted: DateTime.now().subtract(const Duration(hours: 5)),
      avatarUrl: 'https://i.pravatar.cc/150?u=rahul',
    ),
    ContactModel(
      id: 'c3',
      name: 'John Smith',
      email: 'john.smith@google.com',
      phone: '+1 650-253-0000',
      company: 'Google',
      position: 'Senior Developer',
      address: 'Mountain View, CA',
      notes: 'Met at tech conference.',
      status: ContactStatus.churned,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      lastContacted: DateTime.now().subtract(const Duration(days: 15)),
      avatarUrl: 'https://i.pravatar.cc/150?u=john',
    ),
    ContactModel(
      id: 'c4',
      name: 'Amit Shah',
      email: 'amit.shah@infosys.com',
      phone: '+91 80 2852 0261',
      company: 'Infosys',
      position: 'Director',
      address: 'Bangalore, India',
      notes: 'Potential partnership opportunity.',
      status: ContactStatus.customer,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      lastContacted: DateTime.now().subtract(const Duration(days: 1)),
      avatarUrl: 'https://i.pravatar.cc/150?u=amit',
    ),
  ];

  Future<List<ContactModel>> getContacts() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network latency
    return List.from(_mockContacts);
  }

  Future<ContactModel> addContact(ContactModel contact) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newContact = contact.copyWith(
      id: 'c${_mockContacts.length + 1 + Random().nextInt(1000)}',
      createdAt: DateTime.now(),
      lastContacted: DateTime.now(),
    );
    _mockContacts.add(newContact);
    return newContact;
  }

  Future<ContactModel> updateContact(ContactModel contact) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockContacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      _mockContacts[index] = contact;
      return contact;
    }
    throw Exception('Contact not found');
  }

  Future<void> deleteContact(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockContacts.removeWhere((c) => c.id == id);
  }
}
