import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/customer_local_datasource.dart';
import '../../data/datasources/local/product_local_datasource.dart';
import '../../data/datasources/local/distribution_local_datasource.dart';
import '../../data/datasources/remote/customer_remote_datasource.dart';
import '../../data/datasources/remote/product_remote_datasource.dart';
import '../../data/datasources/remote/distribution_remote_datasource.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/distribution_repository_impl.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/distribution_repository.dart';
import 'package:logger/logger.dart';
import '../../core/network/network_info.dart';
import '../../core/network/sync_manager.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/customer_viewmodel.dart';
import '../../presentation/viewmodels/product_viewmodel.dart';
import '../../presentation/viewmodels/distribution_viewmodel.dart';
import '../../presentation/viewmodels/report_viewmodel.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // External
  getIt.registerLazySingleton(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton(() => FirebaseAuth.instance);
  getIt.registerLazySingleton(() => Connectivity());
  getIt.registerLazySingleton(() => InternetConnectionChecker());
  getIt.registerLazySingleton(() => Uuid());

  // Database
  getIt.registerLazySingleton(() => DatabaseHelper.instance);

  // Local Data Sources
  getIt.registerLazySingleton<CustomerLocalDataSource>(
    () => CustomerLocalDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<DistributionLocalDataSource>(
    () => DistributionLocalDataSourceImpl(getIt()),
  );

  // Remote Data Sources
  getIt.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<DistributionRemoteDataSource>(
    () => DistributionRemoteDataSourceImpl(getIt()),
  );

  // Network & Sync
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => SyncManager(
        databaseHelper: getIt(),
        networkInfo: getIt(),
        logger: Logger(),
      ));

  // Repositories
  getIt.registerLazySingleton<CustomerRepository>(() => CustomerRepositoryImpl(
        localDataSource: getIt(),
        remoteDataSource: getIt(),
        networkInfo: getIt(),
        syncManager: getIt(),
        firebaseAuth: getIt(),
      ));

  getIt.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(
        localDataSource: getIt(),
        remoteDataSource: getIt(),
        networkInfo: getIt(),
        syncManager: getIt(),
        firebaseAuth: getIt(),
      ));

  getIt.registerLazySingleton<DistributionRepository>(() => DistributionRepositoryImpl(
        localDataSource: getIt(),
        remoteDataSource: getIt(),
        customerLocalDataSource: getIt(),
        productLocalDataSource: getIt(),
        networkInfo: getIt(),
        syncManager: getIt(),
        firebaseAuth: getIt(),
      ));

  // ViewModels
  getIt.registerFactory(() => AuthViewModel(getIt()));
  getIt.registerFactory(() => CustomerViewModel(getIt(), getIt()));
  getIt.registerFactory(() => ProductViewModel(getIt(), getIt()));
  getIt.registerFactory(() => DistributionViewModel(getIt(), getIt()));
  getIt.registerFactory(() => ReportViewModel(
        getIt<DistributionRepository>(),
        getIt<CustomerRepository>(),
        getIt<ProductRepository>(),
      ));
}
