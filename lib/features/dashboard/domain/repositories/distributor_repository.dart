import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

/// Repository interface for distributor management operations.
/// Defines contracts for distributor-related business logic.
abstract class DistributorRepository {
  /// Get stream of distributors for an admin
  Stream<Either<Failure, QuerySnapshot<Map<String, dynamic>>>>
  getDistributorsStream(String adminId);

  /// Add a new distributor
  Future<Either<Failure, void>> addDistributor({
    required String adminId,
    required String name,
    String? phone,
    String? email,
    String? location,
    String? region,
    double? latitude,
    double? longitude,
    String? createdByUserId,
    String? createdByName,
    String? createdByType,
  });

  /// Update an existing distributor
  Future<Either<Failure, void>> updateDistributor({
    required String distributorId,
    required String name,
    String? phone,
    String? email,
    String? location,
    String? region,
    double? latitude,
    double? longitude,
  });

  /// Delete a distributor
  Future<Either<Failure, void>> deleteDistributor(String distributorId);
}
