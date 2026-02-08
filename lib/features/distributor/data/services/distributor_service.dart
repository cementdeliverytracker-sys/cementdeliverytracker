import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/distributor_model.dart';

/// Service for managing distributor operations with Firestore and local caching
class DistributorService extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  // Local cache
  final Map<String, Distributor> _distributorCache = {};
  List<Distributor> _allDistributors = [];
  bool _isLoading = false;
  String? _error;

  DistributorService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Distributor> get allDistributors => _allDistributors;
  int get distributorCount => _allDistributors.length;

  /// Get all distributors (from cache if available, otherwise fetch from Firestore)
  Future<List<Distributor>> getDistributors({
    bool forceRefresh = false,
    String? adminId,
  }) async {
    // Validate adminId is provided
    if (adminId == null || adminId.isEmpty) {
      _error = 'Admin ID is required to load distributors';
      _isLoading = false;
      _allDistributors = [];
      notifyListeners();
      throw Exception('Admin ID is required to load distributors');
    }

    // Return cached data if available and not forcing refresh
    if (_allDistributors.isNotEmpty && !forceRefresh) {
      return _allDistributors;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('distributors')
          .where('adminId', isEqualTo: adminId)
          .orderBy('createdAt', descending: true)
          .get();

      _allDistributors = snapshot.docs
          .map(
            (doc) => Distributor.fromFirestore({...doc.data(), 'id': doc.id}),
          )
          .toList();

      // Update cache
      for (final distributor in _allDistributors) {
        _distributorCache[distributor.id] = distributor;
      }

      _isLoading = false;
      notifyListeners();
      return _allDistributors;
    } catch (e) {
      _error = 'Failed to load distributors: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Get distributor by ID (from cache if available)
  Future<Distributor?> getDistributorById(String id) async {
    // Check cache first
    if (_distributorCache.containsKey(id)) {
      return _distributorCache[id];
    }

    try {
      final doc = await _firestore.collection('distributors').doc(id).get();
      if (!doc.exists) {
        return null;
      }

      final distributor = Distributor.fromFirestore({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      });
      _distributorCache[id] = distributor;
      return distributor;
    } catch (e) {
      _error = 'Failed to load distributor: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Add a new distributor
  Future<String> addDistributor({
    required String name,
    required String contact,
    required String address,
    double? latitude,
    double? longitude,
    required String adminId,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final distributor = Distributor(
        id: '', // Will be set by Firestore
        name: name,
        contact: contact,
        address: address,
        latitude: latitude ?? 0.0,
        longitude: longitude ?? 0.0,
        adminId: adminId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      final docRef = await _firestore
          .collection('distributors')
          .add(distributor.toFirestore());

      final newDistributor = distributor.copyWith(id: docRef.id);
      _distributorCache[docRef.id] = newDistributor;
      _allDistributors.add(newDistributor);
      _allDistributors.sort((a, b) => a.name.compareTo(b.name));

      notifyListeners();
      return docRef.id;
    } catch (e) {
      _error = 'Failed to add distributor: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing distributor
  Future<void> updateDistributor(
    String id, {
    String? name,
    String? contact,
    String? address,
    double? latitude,
    double? longitude,
    bool? isActive,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final currentDistributor = _distributorCache[id];
      if (currentDistributor == null) {
        throw Exception('Distributor not found in cache');
      }

      final updatedDistributor = currentDistributor.copyWith(
        name: name,
        contact: contact,
        address: address,
        latitude: latitude,
        longitude: longitude,
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('distributors')
          .doc(id)
          .update(updatedDistributor.toFirestore());

      _distributorCache[id] = updatedDistributor;

      // Update in the list
      final index = _allDistributors.indexWhere((d) => d.id == id);
      if (index != -1) {
        _allDistributors[index] = updatedDistributor;
        _allDistributors.sort((a, b) => a.name.compareTo(b.name));
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to update distributor: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Soft delete a distributor (mark as inactive)
  Future<void> deleteDistributor(String id) async {
    _error = null;
    notifyListeners();

    try {
      await updateDistributor(id, isActive: false);
      _allDistributors.removeWhere((d) => d.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete distributor: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Search distributors by name or contact
  List<Distributor> searchDistributors(String query) {
    if (query.isEmpty) {
      return _allDistributors;
    }

    final lowerQuery = query.toLowerCase();
    return _allDistributors.where((d) {
      return d.name.toLowerCase().contains(lowerQuery) ||
          d.contact.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Clear cache
  void clearCache() {
    _distributorCache.clear();
    _allDistributors.clear();
    _error = null;
    notifyListeners();
  }

  /// Get nearby distributors (within radius in km)
  List<Distributor> getNearbyDistributors(
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    return _allDistributors.where((d) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        d.latitude,
        d.longitude,
      );

      return distance <= radiusKm;
    }).toList();
  }

  /// Calculate distance between two coordinates using Haversine formula
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * asin(sqrt(a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
