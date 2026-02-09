// DEPRECATED: Use domain layer use cases instead
// This file is kept for backwards compatibility only
// Migrate to:
// - lib/features/dashboard/domain/usecases/distributor_usecases.dart

export 'package:cementdeliverytracker/features/dashboard/data/datasources/distributor_remote_data_source.dart';

@Deprecated(
  'Use GetDistributorsStreamUseCase, AddDistributorUseCase, etc. from domain/usecases/distributor_usecases.dart',
)
class AdminDistributorService {
  /// This class is deprecated. Please inject and use the appropriate use cases:
  /// - GetDistributorsStreamUseCase
  /// - AddDistributorUseCase
  /// - UpdateDistributorUseCase
  /// - DeleteDistributorUseCase
  ///
  /// These are available via Provider context.read<T>() or context.watch<T>()
  AdminDistributorService() {
    throw UnimplementedError(
      'AdminDistributorService is deprecated. Use domain layer use cases instead.',
    );
  }
}
