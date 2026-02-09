/// Geocoding cache service with configurable TTL
/// Reduces redundant reverse geocoding API calls by caching address lookups
/// Default TTL: 7 days (addresses rarely change for coordinates)

import 'package:geocoding/geocoding.dart';

/// Singleton cache manager for geocoding results
class GeocodingCacheService {
  static final GeocodingCacheService _instance =
      GeocodingCacheService._internal();

  // Configurable TTL - default 7 days for stable address data
  static const Duration _defaultCacheTTL = Duration(days: 7);
  Duration _cacheTTL = _defaultCacheTTL;

  final Map<String, _CachedGeocodingResult> _cache = {};

  // Statistics tracking
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _apiCalls = 0;

  factory GeocodingCacheService() => _instance;

  GeocodingCacheService._internal();

  /// Configure cache TTL (useful for testing or specific requirements)
  void configureTTL(Duration ttl) {
    _cacheTTL = ttl;
  }

  /// Get placemarks from coordinates with caching
  /// Rounds coordinates to 6 decimal places (~0.11m precision) for cache key
  Future<List<Placemark>> getPlacemarksFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    // Generate cache key with 6 decimal precision
    final key = _generateCacheKey(latitude, longitude);

    // Check cache first
    if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      final age = DateTime.now().difference(cached.timestamp);

      if (age < _cacheTTL) {
        _cacheHits++;
        return cached.placemarks;
      } else {
        // Cache expired
        _cache.remove(key);
      }
    }

    // Cache miss - fetch from API
    _cacheMisses++;
    _apiCalls++;

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      // Cache the result
      _cache[key] = _CachedGeocodingResult(placemarks, DateTime.now());

      return placemarks;
    } catch (e) {
      // On error, don't cache anything
      rethrow;
    }
  }

  /// Generate consistent cache key with precision rounding
  String _generateCacheKey(double latitude, double longitude) {
    // Round to 6 decimal places (~0.11m precision)
    final lat = latitude.toStringAsFixed(6);
    final lng = longitude.toStringAsFixed(6);
    return '$lat,$lng';
  }

  /// Invalidate specific cache entry
  void invalidateCache(double latitude, double longitude) {
    final key = _generateCacheKey(latitude, longitude);
    _cache.remove(key);
  }

  /// Clear all cached geocoding results
  void clearAllCache() {
    _cache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    // Note: Don't reset _apiCalls to maintain historical tracking
  }

  /// Get cache statistics for monitoring and optimization
  Map<String, dynamic> getCacheStats() {
    final total = _cacheHits + _cacheMisses;
    final hitRate = total > 0 ? (_cacheHits / total * 100) : 0.0;

    return {
      'totalCached': _cache.length,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'apiCalls': _apiCalls,
      'hitRate': hitRate.toStringAsFixed(2) + '%',
      'cacheTTL': _cacheTTL.inDays.toString() + ' days',
      'entries': _getEntriesStats(),
    };
  }

  Map<String, dynamic> _getEntriesStats() {
    final stats = <String, dynamic>{};

    for (final entry in _cache.entries) {
      final age = DateTime.now().difference(entry.value.timestamp);
      stats[entry.key] = {
        'ageMinutes': age.inMinutes,
        'ageDays': age.inDays,
        'isValid': age < _cacheTTL,
      };
    }

    return stats;
  }

  /// Reset statistics (useful for monitoring intervals)
  void resetStatistics() {
    _cacheHits = 0;
    _cacheMisses = 0;
    _apiCalls = 0;
  }
}

/// Internal class for cached geocoding result
class _CachedGeocodingResult {
  final List<Placemark> placemarks;
  final DateTime timestamp;

  _CachedGeocodingResult(this.placemarks, this.timestamp);
}
