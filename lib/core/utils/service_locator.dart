import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:uuid/uuid.dart';

// --- Remote Data Sources ---
import '../../data/datasources/remote/customer_remote_datasource.dart';
import '../../data/datasources/remote/product_remote_datasource.dart';
import '../../data/datasources/remote/distribution_remote_datasource.dart';
import '../../data/datasources/remote/supplier_remote_datasource.dart';
import '../../data/datasources/remote/purchase_remote_datasource.dart';

// --- Repositories ---
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/distribution_repository_impl.dart';
import '../../data/repositories/supplier_repository_impl.dart';
import '../../data/repositories/purchase_repository_impl.dart';

// --- Domain Interfaces ---
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/distribution_repository.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../../domain/repositories/purchase_repository.dart';

// --- ViewModels ---
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/customer_viewmodel.dart';
import '../../presentation/viewmodels/product_viewmodel.dart';
import '../../presentation/viewmodels/distribution_viewmodel.dart';
import '../../presentation/viewmodels/report_viewmodel.dart';
import '../../presentation/viewmodels/supplier_viewmodel.dart';
import '../../presentation/viewmodels/purchase_viewmodel.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ---------------------------------------------------------------------------
  // 1. External Services
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton(() => FirebaseAuth.instance);
  getIt.registerLazySingleton(() => Connectivity());
  getIt.registerLazySingleton(() => InternetConnectionChecker());
  getIt.registerLazySingleton(() => Uuid());

  // ---------------------------------------------------------------------------
  // 2. Data Sources (Remote Only)
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<SupplierRemoteDataSource>(() => SupplierRemoteDataSourceImpl(getIt()));
  getIt.registerLazySingleton<PurchaseRemoteDataSource>(() => PurchaseRemoteDataSourceImpl(getIt()));
  getIt.registerLazySingleton<DistributionRemoteDataSource>(
    () => DistributionRemoteDataSourceImpl(getIt()),
  );

  // * Note: Local DataSources and SyncManager have been removed *

  // ---------------------------------------------------------------------------
  // 3. Repositories
  // ---------------------------------------------------------------------------
  getIt.registerLazySingleton<CustomerRepository>(() => CustomerRepositoryImpl(
        remoteDataSource: getIt(),
        firebaseAuth: getIt(),
      ));

  getIt.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(
        remoteDataSource: getIt(),
        firebaseAuth: getIt(),
      ));

  getIt.registerLazySingleton<DistributionRepository>(() => DistributionRepositoryImpl(
        remoteDataSource: getIt(),
        // تم إضافة الاعتمادات الجديدة للتعامل مع العلاقات عن بعد
        customerRemoteDataSource: getIt(),
        productRemoteDataSource: getIt(),
        firebaseAuth: getIt(),
      ));
  getIt.registerLazySingleton<SupplierRepository>(() => SupplierRepositoryImpl(
        remoteDataSource: getIt(),
        firebaseAuth: getIt(),
      ));
  getIt.registerLazySingleton<PurchaseRepository>(() => PurchaseRepositoryImpl(
        remoteDataSource: getIt(),
        firebaseAuth: getIt(),
      ));

  // ---------------------------------------------------------------------------
  // 4. ViewModels
  // ---------------------------------------------------------------------------
  getIt.registerFactory(() => AuthViewModel(getIt()));
  
  // نفترض أن CustomerViewModel يعتمد على الواجهة (Interface) للمستودع، لذا لا نحتاج لتغيير هذا
  getIt.registerFactory(() => CustomerViewModel(getIt(), getIt(), getIt<DistributionRepository>()));
  
  getIt.registerFactory(() => ProductViewModel(getIt(), getIt()));
  getIt.registerFactory(() => DistributionViewModel(getIt(), getIt()));
  
  // --- تحديث حقن SupplierViewModel ---
  getIt.registerFactory(() => SupplierViewModel(
    getIt<SupplierRepository>(),
    getIt<PurchaseRepository>(),
    getIt<Uuid>(),
  ));
  
  getIt.registerFactory(() => PurchaseViewModel(getIt(), getIt()));
  
  // --- تحديث حقن ReportViewModel (إضافة المستودعات الجديدة) ---
  getIt.registerFactory(() => ReportViewModel(
        getIt<DistributionRepository>(),
        getIt<CustomerRepository>(),
        getIt<ProductRepository>(),
        getIt<PurchaseRepository>(), // التبعية الجديدة
        getIt<SupplierRepository>(), // التبعية الجديدة
      ));
}