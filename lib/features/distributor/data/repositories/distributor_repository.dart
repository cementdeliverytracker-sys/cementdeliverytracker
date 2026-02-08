import 'package:flutter/foundation.dart';
import '../models/distributor_model.dart';
import '../models/visit_model.dart';
import '../services/distributor_service.dart';
import '../services/visit_service.dart';

/// Repository layer to abstract business logic from UI
class DistributorRepository extends ChangeNotifier {
  final DistributorService _distributorService;
  final VisitService _visitService;

  DistributorRepository({
    required DistributorService distributorService,
    required VisitService visitService,
  }) : _distributorService = distributorService,
       _visitService = visitService;

  // Expose services through repository
  DistributorService get distributorService => _distributorService;
  VisitService get visitService => _visitService;

  // Distributor methods
  Future<List<Distributor>> getDistributors({
    bool forceRefresh = false,
    String? adminId,
  }) {
    return _distributorService.getDistributors(
      forceRefresh: forceRefresh,
      adminId: adminId,
    );
  }

  Future<Distributor?> getDistributorById(String id) {
    return _distributorService.getDistributorById(id);
  }

  Future<String> addDistributor({
    required String name,
    required String contact,
    required String address,
    double? latitude,
    double? longitude,
    required String adminId,
  }) {
    return _distributorService.addDistributor(
      name: name,
      contact: contact,
      address: address,
      latitude: latitude,
      longitude: longitude,
      adminId: adminId,
    );
  }

  Future<void> updateDistributor(
    String id, {
    String? name,
    String? contact,
    String? address,
    double? latitude,
    double? longitude,
    bool? isActive,
  }) {
    return _distributorService.updateDistributor(
      id,
      name: name,
      contact: contact,
      address: address,
      latitude: latitude,
      longitude: longitude,
      isActive: isActive,
    );
  }

  Future<void> deleteDistributor(String id) {
    return _distributorService.deleteDistributor(id);
  }

  List<Distributor> searchDistributors(String query) {
    return _distributorService.searchDistributors(query);
  }

  List<Distributor> getNearbyDistributors(
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    return _distributorService.getNearbyDistributors(
      latitude,
      longitude,
      radiusKm,
    );
  }

  // Visit methods
  Future<Visit?> getActiveVisit(String employeeId) {
    return _visitService.getActiveVisit(employeeId);
  }

  Future<List<Visit>> getTodayVisits(String employeeId) {
    return _visitService.getTodayVisits(employeeId);
  }

  Future<List<Visit>> getVisitsByDate(String employeeId, DateTime date) {
    return _visitService.getVisitsByDate(employeeId, date);
  }

  Future<List<Visit>> getVisitsByDateRange(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _visitService.getVisitsByDateRange(employeeId, startDate, endDate);
  }

  Future<String> checkIn({
    required String employeeId,
    String? adminId,
    required String distributorId,
    required String distributorName,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) {
    return _visitService.checkIn(
      employeeId: employeeId,
      adminId: adminId,
      distributorId: distributorId,
      distributorName: distributorName,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );
  }

  Future<void> addTask({
    required String visitId,
    required TaskType taskType,
    required String description,
    Map<String, dynamic>? metadata,
  }) {
    return _visitService.addTask(
      visitId: visitId,
      taskType: taskType,
      description: description,
      metadata: metadata,
    );
  }

  Future<void> checkOut({
    required String visitId,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) {
    return _visitService.checkOut(
      visitId: visitId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );
  }

  Future<Visit?> getVisitById(String id) {
    return _visitService.getVisitById(id);
  }

  Future<List<Visit>> getDistributorVisits(
    String distributorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _visitService.getDistributorVisits(
      distributorId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<Map<String, dynamic>> getVisitStats(String employeeId) {
    return _visitService.getVisitStats(employeeId);
  }

  // Cache management
  void clearCache() {
    _distributorService.clearCache();
    _visitService.clearCache();
    notifyListeners();
  }
}
