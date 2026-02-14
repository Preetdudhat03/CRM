
import '../models/contact_model.dart';

class ContactService {
  // Mock data for initial contact list
  static final List<ContactModel> _mockContacts = [
    ContactModel(
      id: 'c1',
      name: 'John Smith',
      email: 'john.smith@techcorp.com',
      phone: '+1 555-0101',
      company: 'TechCorp Solutions',
      position: 'CTO',
      status: ContactStatus.customer,
      lastContacted: DateTime.now().subtract(const Duration(days: 2)),
      avatarUrl: 'https://i.pravatar.cc/150?u=john',
    ),
    ContactModel(
      id: 'c2',
      name: 'Sarah Connor',
      email: 'sarah.c@skyline.net',
      phone: '+1 555-0102',
      company: 'Skyline Inc',
      position: 'Operations Manager',
      status: ContactStatus.lead,
      lastContacted: DateTime.now().subtract(const Duration(hours: 5)),
      avatarUrl: 'https://i.pravatar.cc/150?u=sarah',
    ),
    ContactModel(
      id: 'c3',
      name: 'Michael Ross',
      email: 'mike.ross@pearson.com',
      phone: '+1 555-0103',
      company: 'Pearson Hardman',
      position: 'Senior Associate',
      status: ContactStatus.churned,
      lastContacted: DateTime.now().subtract(const Duration(days: 15)),
      avatarUrl: 'https://i.pravatar.cc/150?u=mike',
    ),
    ContactModel(
      id: 'c4',
      name: 'Jessica Pearson',
      email: 'j.pearson@pearson.com',
      phone: '+1 555-0104',
      company: 'Pearson Hardman',
      position: 'Managing Partner',
      status: ContactStatus.customer,
      lastContacted: DateTime.now().subtract(const Duration(days: 1)),
      avatarUrl: 'https://i.pravatar.cc/150?u=jessica',
    ),
  ];

  Future<List<ContactModel>> getContacts() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network latency
    return List.from(_mockContacts);
  }

  Future<ContactModel> addContact(ContactModel contact) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newContact = contact.copyWith(id: 'c${_mockContacts.length + 1}');
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
