/// Location caching manager with TTL support
/// Reduces redundant Firestore reads for admin location
/// Default TTL: 24 hours

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/features/dashboard/data/exceptions/location_exceptions.dart';

/// Singleton cache manager for admin location data
class AdminLocationCache {
  static final AdminLocationCache _instance = AdminLocationCache._internal();

  static const Duration _cacheTTL = Duration(hours: 24);

  final Map<String, _CachedAdminLocation> _cache = {};

  factory AdminLocationCache() => _instance;

  AdminLocationCache._internal();

  /// Get admin location with caching
  /// Returns cached location if valid, otherwise fetches from Firestore
  /// Implements 24-hour TTL for cache validity
  Future<Map<String, dynamic>> getAdminLocation(String adminId) async {
    // Check memory cache first
    if (_cache.containsKey(adminId)) {
      final cached = _cache[adminId]!;
      final age = DateTime.now().difference(cached.timestamp);

      if (age < _cacheTTL) {
        return cached.location;
      } else {
        // Cache expired
        _cache.remove(adminId);
      }
    }

    // Fetch from Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.enterprisesCollection)
          .doc(adminId)
          .get();

      if (!doc.exists || doc.data() == null) {
        throw Exception('Admin location not found');
      }

      final location = doc.data()?['location'] as Map<String, dynamic>?;
      if (location == null) {
        throw Exception('Location data is missing for admin $adminId');
      }

      // Validate location has required fields
      if (!location.containsKey('latitude') ||
          !location.containsKey('longitude')) {
        throw InvalidLocationException(
          location['latitude'] as double? ?? 0,
          location['longitude'] as double? ?? 0,
        );
      }

      // Cache the location
      _cache[adminId] = _CachedAdminLocation(location, DateTime.now());

      return location;
    } catch (e) {
      rethrow;
    }
  }

  /// Invalidate cache for specific admin
  /// Call this when admin location is updated
  void invalidateCache(String adminId) {
    _cache.remove(adminId);
  }

  /// Clear all cached locations
  /// Useful for logout or settings reset
  void clearAllCache() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final stats = <String, dynamic>{
      'totalCached': _cache.length,
      'entries': <String, dynamic>{},
    };

    for (final entry in _cache.entries) {
      final age = DateTime.now().difference(entry.value.timestamp);
      stats['entries'][entry.key] = {
        'ageMinutes': age.inMinutes,
        'isValid': age < _cacheTTL,
      };
    }

    return stats;
  }
}

/// Internal class for cached location data
class _CachedAdminLocation {
  final Map<String, dynamic> location;
  final DateTime timestamp;

  _CachedAdminLocation(this.location, this.timestamp);
}
