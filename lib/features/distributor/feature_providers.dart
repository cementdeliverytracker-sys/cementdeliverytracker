import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'data/repositories/distributor_repository.dart';
import 'data/services/distributor_service.dart';
import 'data/services/visit_service.dart';

/// Provider setup for distributor feature
class DistributorFeatureProviders {
  /// Get all providers needed for the distributor feature
  static List<SingleChildWidget> getProviders() {
    return [
      // Services
      ChangeNotifierProvider(create: (_) => DistributorService()),
      ChangeNotifierProvider(create: (_) => VisitService()),

      // Repository (depends on services)
      ChangeNotifierProxyProvider2<
        DistributorService,
        VisitService,
        DistributorRepository
      >(
        create: (context) {
          final distributorService = context.read<DistributorService>();
          final visitService = context.read<VisitService>();
          return DistributorRepository(
            distributorService: distributorService,
            visitService: visitService,
          );
        },
        update: (context, distributorService, visitService, repository) {
          return repository ??
              DistributorRepository(
                distributorService: distributorService,
                visitService: visitService,
              );
        },
      ),
    ];
  }
}

/// Example usage in main.dart:
///
/// ```dart
/// void main() {
///   runApp(
///     MultiProvider(
///       providers: [
///         ...DistributorFeatureProviders.getProviders(),
///         // Other providers...
///       ],
///       child: const MyApp(),
///     ),
///   );
/// }
/// ```
///
/// Then in your navigation:
///
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (context) => const EmployeeVisitScreen(
///       employeeId: 'employee123',
///       employeeName: 'John Doe',
///     ),
///   ),
/// );
/// ```
