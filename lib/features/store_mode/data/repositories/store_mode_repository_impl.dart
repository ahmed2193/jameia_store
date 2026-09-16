import '../../../../core/data/keeta_repository.dart';
import '../../domain/repositories/store_mode_repository.dart';

/// Offline store-mode repository — the active mode lives on the shared
/// [KeetaRepository] `isVip` [ValueNotifier] (which the catalogue's
/// `product.priceFor(...)` / `modeCard` read). Writing here mutates that
/// notifier, so any remaining `ValueListenableBuilder(valueListenable: isVip)`
/// consumers still repaint while presentation migrates onto [StoreModeCubit].
class StoreModeRepositoryImpl implements StoreModeRepository {
  StoreModeRepositoryImpl(this._catalog);

  final KeetaRepository _catalog;

  @override
  bool get isVip => _catalog.isVip.value;

  @override
  void setVip(bool value) => _catalog.isVip.value = value;
}
