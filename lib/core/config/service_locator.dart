import 'package:get_it/get_it.dart';

import '../data/keeta_repository.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';

/// The single `get_it` root. Mirrors the one_day reference: one `sl`, a
/// [setupServiceLocator] bootstrap, and per-feature init hooks.
///
/// DI lifecycle invariant: page-scoped cubits consumed via
/// `BlocProvider(create: (_) => sl<X>())` MUST be `registerFactory` (fresh per
/// mount). Stateless collaborators (repository) are `registerLazySingleton`.
final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ── Core singletons ─────────────────────────────────────────────────────────
  final repo = KeetaRepository();
  await repo.load(); // load dummy dataset once before first screen
  sl.registerSingleton<KeetaRepository>(repo);

  // ── Long-lived cubits (provided once at app root) ────────────────────────────
  sl.registerFactory<CartCubit>(() => CartCubit());

  _initFeatures();
}

/// Per-feature get_it registrations are wired here as features are added.
void _initFeatures() {
  // initHomeFeature(); initShopFeature(); ... (registered by each feature IC)
}
