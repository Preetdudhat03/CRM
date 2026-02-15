
import '../models/deal_model.dart';
import 'dart:math';

class DealService {
  // Mock data as per examples
  static final List<DealModel> _mockDeals = [
    DealModel(
      id: 'd1',
      title: 'Tesla CRM Development',
      contactId: 'c2',
      contactName: 'Rahul Patel',
      companyName: 'Tesla',
      value: 500000,
      stage: DealStage.negotiation,
      assignedTo: 'Preet Dudhat',
      expectedCloseDate: DateTime.now().add(const Duration(days: 15)),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    DealModel(
      id: 'd2',
      title: 'Infosys Mobile App',
      contactId: 'c4',
      contactName: 'Amit Shah',
      companyName: 'Infosys',
      value: 300000,
      stage: DealStage.proposal,
      assignedTo: 'Mike Ross',
      expectedCloseDate: DateTime.now().add(const Duration(days: 45)),
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    DealModel(
      id: 'd3',
      title: 'Google Dashboard',
      contactId: 'c3',
      contactName: 'John Smith',
      companyName: 'Google',
      value: 1000000,
      stage: DealStage.qualification,
      assignedTo: 'Preet Dudhat',
      expectedCloseDate: DateTime.now().add(const Duration(days: 90)),
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DealModel(
      id: 'd4',
      title: 'CompanyX Upgrade',
      contactId: 'c1',
      contactName: 'Preet Dudhat',
      companyName: 'CompanyX',
      value: 150000,
      stage: DealStage.closedWon,
      assignedTo: 'Sarah Connor',
      expectedCloseDate: DateTime.now().subtract(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  Future<List<DealModel>> getDeals() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network latency
    return List.from(_mockDeals);
  }

  Future<DealModel> addDeal(DealModel deal) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newDeal = deal.copyWith(
      id: 'd${_mockDeals.length + 1 + Random().nextInt(1000)}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _mockDeals.add(newDeal);
    return newDeal;
  }

  Future<DealModel> updateDeal(DealModel deal) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockDeals.indexWhere((d) => d.id == deal.id);
    if (index != -1) {
      final updatedDeal = deal.copyWith(updatedAt: DateTime.now());
      _mockDeals[index] = updatedDeal;
      return updatedDeal;
    }
    throw Exception('Deal not found');
  }

  Future<void> deleteDeal(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockDeals.removeWhere((d) => d.id == id);
  }
}
