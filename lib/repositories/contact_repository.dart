import '../services/contact_service.dart';
import '../models/contact_model.dart';

class ContactRepository {
  final ContactService _service;

  ContactRepository(this._service);

  Future<List<ContactModel>> getContacts({int page = 0, int pageSize = 20}) async {
    return _service.getContacts(page: page, pageSize: pageSize);
  }

  Future<ContactModel> addContact(ContactModel contact) async {
    return _service.addContact(contact);
  }

  Future<ContactModel> updateContact(ContactModel contact) async {
    return _service.updateContact(contact);
  }

  Future<void> deleteContact(String id) async {
    return _service.deleteContact(id);
  }

  Future<void> toggleFavorite(String id, bool currentStatus) async {
    return _service.toggleFavorite(id, currentStatus);
  }
}
