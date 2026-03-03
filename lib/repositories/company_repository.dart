import '../services/company_service.dart';
import '../models/company_model.dart';

class CompanyRepository {
  final CompanyService _service;

  CompanyRepository(this._service);

  Future<List<CompanyModel>> getCompanies({
    int page = 0,
    int pageSize = 20,
  }) async {
    return _service.getCompanies(page: page, pageSize: pageSize);
  }

  Future<CompanyModel> getCompanyById(String id) async {
    return _service.getCompanyById(id);
  }

  Future<List<CompanyModel>> searchCompanies(
    String query, {
    int page = 0,
    int pageSize = 20,
  }) async {
    return _service.searchCompanies(query, page: page, pageSize: pageSize);
  }

  Future<CompanyModel> addCompany(CompanyModel company) async {
    return _service.addCompany(company);
  }

  Future<CompanyModel> updateCompany(CompanyModel company) async {
    return _service.updateCompany(company);
  }

  Future<void> deleteCompany(String id) async {
    return _service.deleteCompany(id);
  }

  Future<Map<String, dynamic>> getStats() async {
    return _service.getStats();
  }
}
