/// Read/write boundary for the global **store mode** (VIP ⇄ Mart).
///
/// The active mode is app-wide state (home hero, shop rows, product pricing all
/// read it). Presentation talks to this interface via [StoreModeCubit] instead
/// of reaching into `core/data/jameia_repository.dart` directly. The value is
/// pure in-memory and cannot fail, so the surface is plain sync (no
/// `Either<Failure, T>` ceremony).
abstract class StoreModeRepository {
  /// `true` → VIP pricing, `false` → Mart.
  bool get isVip;

  /// Set the active mode. Implementations write through to the shared catalogue
  /// so `product.priceFor(isVip)` / `modeCard` stay consistent everywhere.
  void setVip(bool value);
}
