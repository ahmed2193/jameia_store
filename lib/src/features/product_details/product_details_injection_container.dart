import '../../config/di/service_locator.dart';
import '../../core/data/jameia_repository.dart';
import 'data/datasources/product_details_dummy_data_source.dart';
import 'data/repositories/product_details_repository_impl.dart';
import 'domain/repositories/product_details_repository.dart';

/// Product-details feature DI — mirrors the shop/cart templates (offline chain).
///
/// Called from `main.dart` after [setupServiceLocator] (which registers the
/// loaded [JameiaRepository]). The datasource / repository are
/// `registerLazySingleton`. The page cubit ([ProductDetailCubit]) is NOT
/// registered here — it needs a runtime `Product` arg, so it is built inline in
/// the screen's `BlocProvider` (the `ShopSkuCubit` precedent), pulling
/// [ProductDetailsRepository] + [StoreModeRepository] from `sl`. The
/// pass-through `GetProductDetailsUseCase` was collapsed into a direct
/// repository call.
void initProductDetailsFeature() {
  if (sl.isRegistered<ProductDetailsRepository>()) return; // idempotent

  // Data
  sl.registerLazySingleton<ProductDetailsDummyDataSource>(
    () => ProductDetailsDummyDataSourceImpl(sl<JameiaRepository>()),
  );
  sl.registerLazySingleton<ProductDetailsRepository>(
    () => ProductDetailsRepositoryImpl(
      local: sl<ProductDetailsDummyDataSource>(),
    ),
  );
}
