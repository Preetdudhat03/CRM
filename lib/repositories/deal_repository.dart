import '../services/deal_service.dart';
import '../models/deal_model.dart';

class DealRepository {
  final DealService _service;

  DealRepository(this._service);

  Future<List<DealModel>> getDeals() async {
    return _service.getDeals();
  }

  Future<DealModel> addDeal(DealModel deal) async {
    return _service.addDeal(deal);
  }

  Future<DealModel> updateDeal(DealModel deal) async {
    return _service.updateDeal(deal);
  }

  Future<void> deleteDeal(String id) async {
    return _service.deleteDeal(id);
  }
}
