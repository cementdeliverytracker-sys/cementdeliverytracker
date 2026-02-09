// DEPRECATED: Use domain layer use cases instead
// This file is kept for backwards compatibility only
// Migrate to:
// - lib/features/dashboard/domain/usecases/employee_usecases.dart

export 'package:cementdeliverytracker/features/dashboard/data/datasources/employee_remote_data_source.dart';

@Deprecated(
  'Use ApproveEmployeeUseCase, RejectEmployeeUseCase, etc. from domain/usecases/employee_usecases.dart',
)
class AdminEmployeeService {
  /// This class is deprecated. Please inject and use the appropriate use cases:
  /// - ApproveEmployeeUseCase
  /// - RejectEmployeeUseCase
  /// - RemoveEmployeeUseCase
  /// - GetEmployeesStreamUseCase
  /// - GetPendingEmployeesStreamUseCase
  /// - LogoffAllEmployeesUseCase
  ///
  /// These are available via Provider context.read<T>() or context.watch<T>()
  AdminEmployeeService() {
    throw UnimplementedError(
      'AdminEmployeeService is deprecated. Use domain layer use cases instead.',
    );
  }
}
