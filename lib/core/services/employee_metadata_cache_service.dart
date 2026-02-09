/// Employee metadata cache service with configurable TTL
/// Reduces redundant Firestore reads for employee data that changes infrequently
/// Caches: employee profiles, admin assignments, distributor assignments
/// Default TTL: 1 hour for employee metadata

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cementdeliverytracker/core/constants/app_constants.dart';

/// Singleton cache manager for employee metadata
class EmployeeMetadataCacheService {
  static final EmployeeMetadataCacheService _instance =
      EmployeeMetadataCacheService._internal();

  // Configurable TTL - default 1 hour for employee data
  static const Duration _defaultCacheTTL = Duration(hours: 1);
  Duration _cacheTTL = _defaultCacheTTL;

  final Map<String, _CachedEmployeeData> _employeeCache = {};
  final Map<String, _CachedDistributorList> _distributorListCache = {};

  // Statistics tracking
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _firestoreReads = 0;

  factory EmployeeMetadataCacheService() => _instance;

  EmployeeMetadataCacheService._internal();

  /// Configure cache TTL
  void configureTTL(Duration ttl) {
    _cacheTTL = ttl;
  }

  /// Get employee data with caching
  Future<Map<String, dynamic>?> getEmployeeData(String employeeId) async {
    // Check cache first
    if (_employeeCache.containsKey(employeeId)) {
      final cached = _employeeCache[employeeId]!;
      final age = DateTime.now().difference(cached.timestamp);

      if (age < _cacheTTL) {
        _cacheHits++;
        return cached.data;
      } else {
        // Cache expired
        _employeeCache.remove(employeeId);
      }
    }

    // Cache miss - fetch from Firestore
    _cacheMisses++;
    _firestoreReads++;

    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(employeeId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final data = doc.data()!;

      // Cache the result
      _employeeCache[employeeId] = _CachedEmployeeData(data, DateTime.now());

      return data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get admin ID for employee with caching
  Future<String?> getEmployeeAdminId(String employeeId) async {
    final data = await getEmployeeData(employeeId);
    return data?['adminId'] as String?;
  }

  /// Get distributors list for admin with caching
  Future<List<Map<String, dynamic>>> getDistributorsForAdmin(
    String adminId,
  ) async {
    // Check cache first
    if (_distributorListCache.containsKey(adminId)) {
      final cached = _distributorListCache[adminId]!;
      final age = DateTime.now().difference(cached.timestamp);

      if (age < _cacheTTL) {
        _cacheHits++;
        return cached.distributors;
      } else {
        // Cache expired
        _distributorListCache.remove(adminId);
      }
    }

    // Cache miss - fetch from Firestore
    _cacheMisses++;
    _firestoreReads++;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.distributorsCollection)
          .where('adminId', isEqualTo: adminId)
          .get();

      final distributors = snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      // Cache the result
      _distributorListCache[adminId] = _CachedDistributorList(
        distributors,
        DateTime.now(),
      );

      return distributors;
    } catch (e) {
      rethrow;
    }
  }

  /// Invalidate employee cache for specific employee
  void invalidateEmployeeCache(String employeeId) {
    _employeeCache.remove(employeeId);
  }

  /// Invalidate distributors cache for specific admin
  void invalidateDistributorsCache(String adminId) {
    _distributorListCache.remove(adminId);
  }

  /// Clear all cached data
  void clearAllCache() {
    _employeeCache.clear();
    _distributorListCache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final total = _cacheHits + _cacheMisses;
    final hitRate = total > 0 ? (_cacheHits / total * 100) : 0.0;

    return {
      'employeesCache': _employeeCache.length,
      'distributorsCache': _distributorListCache.length,
      'totalCached': _employeeCache.length + _distributorListCache.length,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'firestoreReads': _firestoreReads,
      'hitRate': '${hitRate.toStringAsFixed(2)}%',
      'cacheTTL': '${_cacheTTL.inMinutes} minutes',
      'employeeEntries': _getEmployeeEntriesStats(),
      'distributorEntries': _getDistributorEntriesStats(),
    };
  }

  Map<String, dynamic> _getEmployeeEntriesStats() {
    final stats = <String, dynamic>{};

    for (final entry in _employeeCache.entries) {
      final age = DateTime.now().difference(entry.value.timestamp);
      stats[entry.key] = {
        'ageMinutes': age.inMinutes,
        'isValid': age < _cacheTTL,
      };
    }

    return stats;
  }

  Map<String, dynamic> _getDistributorEntriesStats() {
    final stats = <String, dynamic>{};

    for (final entry in _distributorListCache.entries) {
      final age = DateTime.now().difference(entry.value.timestamp);
      stats[entry.key] = {
        'ageMinutes': age.inMinutes,
        'distributorCount': entry.value.distributors.length,
        'isValid': age < _cacheTTL,
      };
    }

    return stats;
  }

  /// Reset statistics
  void resetStatistics() {
    _cacheHits = 0;
    _cacheMisses = 0;
    _firestoreReads = 0;
  }
}

/// Internal class for cached employee data
class _CachedEmployeeData {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  _CachedEmployeeData(this.data, this.timestamp);
}

/// Internal class for cached distributor list
class _CachedDistributorList {
  final List<Map<String, dynamic>> distributors;
  final DateTime timestamp;

  _CachedDistributorList(this.distributors, this.timestamp);
}
