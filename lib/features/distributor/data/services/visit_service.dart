import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cementdeliverytracker/core/services/api_usage_monitoring_service.dart';
import '../models/visit_model.dart';

/// Service for managing visit operations with Firestore and Firestore transactions
/// Optimized with API usage monitoring and efficient caching
class VisitService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final APIUsageMonitoringService _apiMonitor = APIUsageMonitoringService();

  // Local cache with TTL awareness
  final Map<String, _CachedVisit> _visitCache = {};
  final Map<String, _CachedVisitList> _todayVisitsCache = {};
  static const Duration _cacheTTL = Duration(minutes: 5);

  Visit? _activeVisit;
  List<Visit> _todayVisits = [];
  bool _isLoading = false;
  String? _error;

  VisitService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Visit? get activeVisit => _activeVisit;
  List<Visit> get todayVisits => _todayVisits;

  /// Get active visit for employee (if any)
  Future<Visit?> getActiveVisit(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First check if we have an active visit in cache for this employee
      if (_activeVisit != null &&
          _activeVisit!.employeeId == employeeId &&
          _activeVisit!.isActive) {
        _isLoading = false;
        notifyListeners();
        return _activeVisit;
      }

      // Otherwise query Firestore
      _apiMonitor.recordFirestoreRead(
        collection: 'visits',
        operation: 'getActiveVisit',
      );

      final snapshot = await _firestore
          .collection('visits')
          .where('employeeId', isEqualTo: employeeId)
          .where('isCompleted', isEqualTo: false)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        _activeVisit = null;
      } else {
        _activeVisit = Visit.fromFirestore({
          ...snapshot.docs.first.data(),
          'id': snapshot.docs.first.id,
        });
        _visitCache[_activeVisit!.id] = _CachedVisit(
          _activeVisit!,
          DateTime.now(),
        );
      }

      _isLoading = false;
      notifyListeners();
      return _activeVisit;
    } catch (e) {
      _error = 'Failed to load active visit: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Get all visits for today (with caching)
  Future<List<Visit>> getTodayVisits(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check cache first
      final cacheKey = 'today_$employeeId';
      if (_todayVisitsCache.containsKey(cacheKey)) {
        final cached = _todayVisitsCache[cacheKey]!;
        final age = DateTime.now().difference(cached.timestamp);

        if (age < _cacheTTL) {
          _todayVisits = cached.visits;
          _isLoading = false;
          notifyListeners();
          return _todayVisits;
        } else {
          _todayVisitsCache.remove(cacheKey);
        }
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      _apiMonitor.recordFirestoreRead(
        collection: 'visits',
        operation: 'getTodayVisits',
      );

      final snapshot = await _firestore
          .collection('visits')
          .where('employeeId', isEqualTo: employeeId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('createdAt', isLessThan: endOfDay)
          .orderBy('createdAt', descending: true)
          .get();

      _todayVisits = snapshot.docs
          .map((doc) => Visit.fromFirestore({...doc.data(), 'id': doc.id}))
          .toList();

      // Update both caches
      for (final visit in _todayVisits) {
        _visitCache[visit.id] = _CachedVisit(visit, DateTime.now());
      }
      _todayVisitsCache[cacheKey] = _CachedVisitList(
        _todayVisits,
        DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
      return _todayVisits;
    } catch (e) {
      _error = 'Failed to load today\'s visits: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Get visits for a specific date
  Future<List<Visit>> getVisitsByDate(String employeeId, DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      _apiMonitor.recordFirestoreRead(
        collection: 'visits',
        operation: 'getVisitsByDate',
      );

      final snapshot = await _firestore
          .collection('visits')
          .where('employeeId', isEqualTo: employeeId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('createdAt', isLessThan: endOfDay)
          .orderBy('createdAt', descending: true)
          .get();

      final visits = snapshot.docs
          .map((doc) => Visit.fromFirestore({...doc.data(), 'id': doc.id}))
          .toList();

      // Update cache
      for (final visit in visits) {
        _visitCache[visit.id] = _CachedVisit(visit, DateTime.now());
      }

      _isLoading = false;
      notifyListeners();
      return visits;
    } catch (e) {
      _error = 'Failed to load visits: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Get visits for a date range
  Future<List<Visit>> getVisitsByDateRange(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('visits')
          .where('employeeId', isEqualTo: employeeId)
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThan: end)
          .orderBy('createdAt', descending: true)
          .get();

      final visits = snapshot.docs
          .map((doc) => Visit.fromFirestore({...doc.data(), 'id': doc.id}))
          .toList();

      for (final visit in visits) {
        _visitCache[visit.id] = _CachedVisit(visit, DateTime.now());
      }

      _isLoading = false;
      notifyListeners();
      return visits;
    } catch (e) {
      _error = 'Failed to load visits: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Create check-in (start a new visit)
  Future<String> checkIn({
    required String employeeId,
    String? adminId,
    required String distributorId,
    required String distributorName,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final visit = Visit(
        id: '', // Will be set by Firestore
        employeeId: employeeId,
        adminId: adminId,
        distributorId: distributorId,
        distributorName: distributorName,
        checkInTime: DateTime.now(),
        checkOutTime: null,
        checkInLat: latitude,
        checkInLng: longitude,
        checkInAccuracy: accuracy,
        checkOutLat: null,
        checkOutLng: null,
        checkOutAccuracy: null,
        tasks: [],
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _apiMonitor.recordFirestoreWrite(
        collection: 'visits',
        operation: 'checkIn',
      );

      final docRef = await _firestore
          .collection('visits')
          .add(visit.toFirestore());

      _activeVisit = visit.copyWith(id: docRef.id);
      _visitCache[docRef.id] = _CachedVisit(_activeVisit!, DateTime.now());

      // Invalidate today's visits cache
      _todayVisitsCache.remove('today_$employeeId');

      notifyListeners();
      return docRef.id;
    } catch (e) {
      _error = 'Failed to check in: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Add task to active visit
  Future<void> addTask({
    required String visitId,
    required TaskType taskType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final cached = _visitCache[visitId];
      if (cached == null) {
        throw Exception('Visit not found');
      }
      final visit = cached.visit;

      if (!visit.isActive) {
        throw Exception('Cannot add task to inactive visit');
      }

      final task = VisitTask(
        id: _firestore.collection('visits').doc().id, // Generate ID
        visitId: visitId,
        type: taskType,
        description: description,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
      );

      final updatedTasks = [...visit.tasks, task];
      final updatedVisit = visit.copyWith(
        tasks: updatedTasks,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('visits')
          .doc(visitId)
          .update(updatedVisit.toFirestore());

      _visitCache[visitId] = _CachedVisit(updatedVisit, DateTime.now());
      _activeVisit = updatedVisit;

      notifyListeners();
    } catch (e) {
      _error = 'Failed to add task: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Check out (complete the active visit)
  Future<void> checkOut({
    required String visitId,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final cached = _visitCache[visitId];
      if (cached == null) {
        throw Exception('Visit not found');
      }
      final visit = cached.visit;

      if (!visit.isActive) {
        throw Exception('Visit is already completed');
      }

      final updatedVisit = visit.copyWith(
        checkOutTime: DateTime.now(),
        checkOutLat: latitude,
        checkOutLng: longitude,
        checkOutAccuracy: accuracy,
        isCompleted: true,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('visits')
          .doc(visitId)
          .update(updatedVisit.toFirestore());

      _visitCache[visitId] = _CachedVisit(updatedVisit, DateTime.now());
      // Keep the completed visit visible instead of clearing it
      _activeVisit = updatedVisit;

      // Update today's visits
      final index = _todayVisits.indexWhere((v) => v.id == visitId);
      if (index != -1) {
        _todayVisits[index] = updatedVisit;
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to check out: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Get visit by ID (with caching)
  Future<Visit?> getVisitById(String id) async {
    // Check cache first
    if (_visitCache.containsKey(id)) {
      final cached = _visitCache[id]!;
      final age = DateTime.now().difference(cached.timestamp);

      if (age < _cacheTTL) {
        return cached.visit;
      } else {
        _visitCache.remove(id);
      }
    }

    try {
      _apiMonitor.recordFirestoreRead(
        collection: 'visits',
        operation: 'getVisitById',
      );

      final doc = await _firestore.collection('visits').doc(id).get();
      if (!doc.exists) {
        return null;
      }

      final visit = Visit.fromFirestore({...doc.data()!, 'id': doc.id});
      _visitCache[id] = _CachedVisit(visit, DateTime.now());
      return visit;
    } catch (e) {
      _error = 'Failed to load visit: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Get all visits for a distributor (for admin reporting)
  Future<List<Visit>> getDistributorVisits(
    String distributorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _error = null;
    notifyListeners();

    try {
      var query = _firestore
          .collection('visits')
          .where('distributorId', isEqualTo: distributorId);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs
          .map((doc) => Visit.fromFirestore({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      _error = 'Failed to load distributor visits: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Get visit statistics for employee
  Future<Map<String, dynamic>> getVisitStats(String employeeId) async {
    try {
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = DateTime(now.year, now.month + 1, 1);

      final snapshot = await _firestore
          .collection('visits')
          .where('employeeId', isEqualTo: employeeId)
          .where('createdAt', isGreaterThanOrEqualTo: thisMonthStart)
          .where('createdAt', isLessThan: nextMonthStart)
          .get();

      final visits = snapshot.docs
          .map((doc) => Visit.fromFirestore({...doc.data(), 'id': doc.id}))
          .toList();

      int totalVisits = visits.length;
      int completedVisits = visits.where((v) => v.isCompleted).length;
      int totalTasks = visits.fold(0, (sum, v) => sum + v.tasks.length);
      int totalMinutes = visits.fold(0, (sum, v) => sum + v.durationMinutes);

      return {
        'totalVisits': totalVisits,
        'completedVisits': completedVisits,
        'activeVisits': totalVisits - completedVisits,
        'totalTasks': totalTasks,
        'totalMinutes': totalMinutes,
        'averageVisitDuration': totalVisits > 0
            ? totalMinutes ~/ totalVisits
            : 0,
      };
    } catch (e) {
      _error = 'Failed to load visit stats: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Clear active visit cache
  void clearActiveVisit() {
    _activeVisit = null;
    notifyListeners();
  }

  /// Clear all caches
  void clearCache() {
    _visitCache.clear();
    _todayVisitsCache.clear();
    _activeVisit = null;
    _todayVisits.clear();
    _error = null;
    notifyListeners();
  }
}

/// Internal class for cached visit with timestamp
class _CachedVisit {
  final Visit visit;
  final DateTime timestamp;

  _CachedVisit(this.visit, this.timestamp);
}

/// Internal class for cached visit list with timestamp
class _CachedVisitList {
  final List<Visit> visits;
  final DateTime timestamp;

  _CachedVisitList(this.visits, this.timestamp);
}
