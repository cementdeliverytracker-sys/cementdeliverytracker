import 'package:cementdeliverytracker/core/network/network_info.dart';
import 'package:cementdeliverytracker/core/services/geocoding_cache_service.dart';
import 'package:cementdeliverytracker/core/services/employee_metadata_cache_service.dart';
import 'package:cementdeliverytracker/core/services/api_usage_monitoring_service.dart';
import 'package:cementdeliverytracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:cementdeliverytracker/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cementdeliverytracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:cementdeliverytracker/features/auth/domain/usecases/auth_usecases.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:cementdeliverytracker/features/dashboard/data/datasources/employee_remote_data_source.dart';
import 'package:cementdeliverytracker/features/dashboard/data/datasources/distributor_remote_data_source.dart';
import 'package:cementdeliverytracker/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:cementdeliverytracker/features/dashboard/data/repositories/employee_repository_impl.dart';
import 'package:cementdeliverytracker/features/dashboard/data/repositories/distributor_repository_impl.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/repositories/employee_repository.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/repositories/distributor_repository.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/usecases/employee_usecases.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/usecases/distributor_usecases.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:cementdeliverytracker/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:cementdeliverytracker/features/orders/data/repositories/order_repository_impl.dart';
import 'package:cementdeliverytracker/features/orders/domain/repositories/order_repository.dart';
import 'package:cementdeliverytracker/features/orders/domain/usecases/create_order.dart';
import 'package:cementdeliverytracker/features/orders/domain/usecases/delete_order.dart';
import 'package:cementdeliverytracker/features/orders/domain/usecases/get_orders.dart';
import 'package:cementdeliverytracker/features/orders/domain/usecases/update_order.dart';
import 'package:cementdeliverytracker/features/orders/presentation/providers/orders_provider.dart';
import 'package:cementdeliverytracker/features/distributor/feature_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class DependencyInjection {
  static List<SingleChildWidget> getProviders() {
    // Network
    final connectivity = Connectivity();
    final networkInfo = NetworkInfoImpl(connectivity: connectivity);

    // Core Services (Singleton instances)
    final geocodingCacheService = GeocodingCacheService();
    final employeeMetadataCacheService = EmployeeMetadataCacheService();
    final apiUsageMonitoringService = APIUsageMonitoringService();

    // Firebase instances
    final firebaseAuth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    // Auth Data Source
    final authRemoteDataSource = AuthRemoteDataSourceImpl(
      firebaseAuth: firebaseAuth,
      firestore: firestore,
      storage: storage,
    );

    // Auth Repository
    final AuthRepository authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
      networkInfo: networkInfo,
    );

    // Auth Use Cases
    final loginUseCase = LoginUseCase(authRepository);
    final signupUseCase = SignupUseCase(authRepository);
    final logoutUseCase = LogoutUseCase(authRepository);
    final getAuthStateUseCase = GetAuthStateUseCase(authRepository);
    final getCurrentUserUseCase = GetCurrentUserUseCase(authRepository);
    final changePasswordUseCase = ChangePasswordUseCase(authRepository);
    final getUserProfileUseCase = GetUserProfileUseCase(authRepository);
    final ensureEmployeeIdUseCase = EnsureEmployeeIdUseCase(authRepository);
    final submitEmployeeJoinRequestUseCase = SubmitEmployeeJoinRequestUseCase(
      authRepository,
    );
    final submitAdminRequestUseCase = SubmitAdminRequestUseCase(authRepository);

    // Auth Provider
    final authNotifier = AuthNotifier(
      loginUseCase: loginUseCase,
      signupUseCase: signupUseCase,
      logoutUseCase: logoutUseCase,
      getAuthStateUseCase: getAuthStateUseCase,
      getCurrentUserUseCase: getCurrentUserUseCase,
      changePasswordUseCase: changePasswordUseCase,
      getUserProfileUseCase: getUserProfileUseCase,
      ensureEmployeeIdUseCase: ensureEmployeeIdUseCase,
      submitEmployeeJoinRequestUseCase: submitEmployeeJoinRequestUseCase,
      submitAdminRequestUseCase: submitAdminRequestUseCase,
    );

    // Dashboard Data Source
    final dashboardRemoteDataSource = DashboardRemoteDataSourceImpl(
      firestore: firestore,
    );

    // Dashboard Repository
    final DashboardRepository dashboardRepository = DashboardRepositoryImpl(
      remoteDataSource: dashboardRemoteDataSource,
      networkInfo: networkInfo,
    );

    // Dashboard Use Cases
    final getUserDashboardDataUseCase = GetUserDashboardDataUseCase(
      dashboardRepository,
    );
    final approveUserUseCase = ApproveUserUseCase(dashboardRepository);
    final getPendingUsersUseCase = GetPendingUsersUseCase(dashboardRepository);

    // Dashboard Provider
    final dashboardProvider = DashboardProvider(
      getUserDashboardDataUseCase: getUserDashboardDataUseCase,
      approveUserUseCase: approveUserUseCase,
      getPendingUsersUseCase: getPendingUsersUseCase,
    );

    // Employee Data Source
    final employeeRemoteDataSource = EmployeeRemoteDataSourceImpl(
      firestore: firestore,
    );

    // Employee Repository
    final EmployeeRepository employeeRepository = EmployeeRepositoryImpl(
      remoteDataSource: employeeRemoteDataSource,
      networkInfo: networkInfo,
    );

    // Employee Use Cases
    final approveEmployeeUseCase = ApproveEmployeeUseCase(employeeRepository);
    final rejectEmployeeUseCase = RejectEmployeeUseCase(employeeRepository);
    final removeEmployeeUseCase = RemoveEmployeeUseCase(employeeRepository);
    final getEmployeesStreamUseCase = GetEmployeesStreamUseCase(
      employeeRepository,
    );
    final getPendingEmployeesStreamUseCase = GetPendingEmployeesStreamUseCase(
      employeeRepository,
    );
    final logoffAllEmployeesUseCase = LogoffAllEmployeesUseCase(
      employeeRepository,
    );

    // Distributor Data Source
    final distributorRemoteDataSource = DistributorRemoteDataSourceImpl(
      firestore: firestore,
    );

    // Distributor Repository
    final DistributorRepository distributorRepository =
        DistributorRepositoryImpl(
          remoteDataSource: distributorRemoteDataSource,
          networkInfo: networkInfo,
        );

    // Distributor Use Cases
    final getDistributorsStreamUseCase = GetDistributorsStreamUseCase(
      distributorRepository,
    );
    final addDistributorUseCase = AddDistributorUseCase(distributorRepository);
    final updateDistributorUseCase = UpdateDistributorUseCase(
      distributorRepository,
    );
    final deleteDistributorUseCase = DeleteDistributorUseCase(
      distributorRepository,
    );

    // Orders Data Source
    final orderRemoteDataSource = OrderRemoteDataSourceImpl(
      firestore: firestore,
    );

    // Orders Repository
    final OrderRepository orderRepository = OrderRepositoryImpl(
      remoteDataSource: orderRemoteDataSource,
    );

    // Orders Use Cases
    final getOrdersUseCase = GetOrders(orderRepository);
    final createOrderUseCase = CreateOrder(orderRepository);
    final updateOrderUseCase = UpdateOrder(orderRepository);
    final deleteOrderUseCase = DeleteOrder(orderRepository);

    // Orders Provider
    final ordersProvider = OrdersProvider(
      getOrdersUseCase: getOrdersUseCase,
      createOrderUseCase: createOrderUseCase,
      updateOrderUseCase: updateOrderUseCase,
      deleteOrderUseCase: deleteOrderUseCase,
    );

    return [
      ...DistributorFeatureProviders.getProviders(),
      // Core Services
      Provider<GeocodingCacheService>.value(value: geocodingCacheService),
      Provider<EmployeeMetadataCacheService>.value(
        value: employeeMetadataCacheService,
      ),
      Provider<APIUsageMonitoringService>.value(
        value: apiUsageMonitoringService,
      ),
      // Network & Repositories
      Provider<NetworkInfo>.value(value: networkInfo),
      Provider<AuthRepository>.value(value: authRepository),
      Provider<DashboardRepository>.value(value: dashboardRepository),
      Provider<EmployeeRepository>.value(value: employeeRepository),
      Provider<DistributorRepository>.value(value: distributorRepository),
      Provider<OrderRepository>.value(value: orderRepository),
      // Use Cases
      Provider<ApproveEmployeeUseCase>.value(value: approveEmployeeUseCase),
      Provider<RejectEmployeeUseCase>.value(value: rejectEmployeeUseCase),
      Provider<RemoveEmployeeUseCase>.value(value: removeEmployeeUseCase),
      Provider<GetEmployeesStreamUseCase>.value(
        value: getEmployeesStreamUseCase,
      ),
      Provider<GetPendingEmployeesStreamUseCase>.value(
        value: getPendingEmployeesStreamUseCase,
      ),
      Provider<LogoffAllEmployeesUseCase>.value(
        value: logoffAllEmployeesUseCase,
      ),
      Provider<GetDistributorsStreamUseCase>.value(
        value: getDistributorsStreamUseCase,
      ),
      Provider<AddDistributorUseCase>.value(value: addDistributorUseCase),
      Provider<UpdateDistributorUseCase>.value(value: updateDistributorUseCase),
      Provider<DeleteDistributorUseCase>.value(value: deleteDistributorUseCase),
      // Notifiers
      ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
      ChangeNotifierProvider<DashboardProvider>.value(value: dashboardProvider),
      ChangeNotifierProvider<OrdersProvider>.value(value: ordersProvider),
    ];
  }
}
