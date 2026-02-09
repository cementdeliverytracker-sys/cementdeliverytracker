import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/repositories/distributor_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

/// Use case to get stream of distributors
class GetDistributorsStreamUseCase {
  final DistributorRepository repository;

  GetDistributorsStreamUseCase(this.repository);

  Stream<Either<Failure, QuerySnapshot<Map<String, dynamic>>>> call(
    String adminId,
  ) {
    return repository.getDistributorsStream(adminId);
  }
}

/// Use case to add a new distributor
class AddDistributorUseCase {
  final DistributorRepository repository;

  AddDistributorUseCase(this.repository);

  Future<Either<Failure, void>> call({
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
  }) {
    return repository.addDistributor(
      adminId: adminId,
      name: name,
      phone: phone,
      email: email,
      location: location,
      region: region,
      latitude: latitude,
      longitude: longitude,
      createdByUserId: createdByUserId,
      createdByName: createdByName,
      createdByType: createdByType,
    );
  }
}

/// Use case to update a distributor
class UpdateDistributorUseCase {
  final DistributorRepository repository;

  UpdateDistributorUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String distributorId,
    required String name,
    String? phone,
    String? email,
    String? location,
    String? region,
    double? latitude,
    double? longitude,
  }) {
    return repository.updateDistributor(
      distributorId: distributorId,
      name: name,
      phone: phone,
      email: email,
      location: location,
      region: region,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

/// Use case to delete a distributor
class DeleteDistributorUseCase {
  final DistributorRepository repository;

  DeleteDistributorUseCase(this.repository);

  Future<Either<Failure, void>> call(String distributorId) {
    return repository.deleteDistributor(distributorId);
  }
}
