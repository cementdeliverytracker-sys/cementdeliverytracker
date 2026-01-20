import 'package:cementdeliverytracker/core/network/network_info.dart';
import 'package:cementdeliverytracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:cementdeliverytracker/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cementdeliverytracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:cementdeliverytracker/features/auth/domain/usecases/auth_usecases.dart';
import 'package:cementdeliverytracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cementdeliverytracker/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:cementdeliverytracker/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:cementdeliverytracker/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:cementdeliverytracker/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:cementdeliverytracker/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:cementdeliverytracker/features/orders/data/repositories/order_repository_impl.dart';
import 'package:cementdeliverytracker/features/orders/domain/repositories/order_repository.dart';
import 'package:cementdeliverytracker/features/orders/domain/usecases/create_order.dart';
import 'package:cementdeliverytracker/features/orders/domain/usecases/delete_order.dart';
import 'package:cementdeliverytracker/features/orders/domain/usecases/get_orders.dart';
import 'package:cementdeliverytracker/features/orders/domain/usecases/update_order.dart';
import 'package:cementdeliverytracker/features/orders/presentation/providers/orders_provider.dart';
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

    // Auth Provider
    final authNotifier = AuthNotifier(
      loginUseCase: loginUseCase,
      signupUseCase: signupUseCase,
      logoutUseCase: logoutUseCase,
      getAuthStateUseCase: getAuthStateUseCase,
      getCurrentUserUseCase: getCurrentUserUseCase,
      changePasswordUseCase: changePasswordUseCase,
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
      Provider<NetworkInfo>.value(value: networkInfo),
      Provider<AuthRepository>.value(value: authRepository),
      Provider<DashboardRepository>.value(value: dashboardRepository),
      Provider<OrderRepository>.value(value: orderRepository),
      ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
      ChangeNotifierProvider<DashboardProvider>.value(value: dashboardProvider),
      ChangeNotifierProvider<OrdersProvider>.value(value: ordersProvider),
    ];
  }
}
