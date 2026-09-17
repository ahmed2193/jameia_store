import 'dart:convert';

import '../../../../core/storage/local_storage.dart';
import '../models/cart_model.dart';

/// Local (offline) persistence for the cart. Mirrors Ttapasco's
/// `cart_local_data_source` — but where Ttapasco left the on-device store
/// disabled (its server was the source of truth), jameia_mart is offline so
/// THIS is the source of truth, backed by [LocalStorage] (shared_preferences).
abstract class CartLocalDataSource {
  /// Read the persisted cart, or null if none / on decode error.
  CartModel? read();
  Future<void> write(CartModel model);
  Future<void> clear();
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  final LocalStorage storage;
  CartLocalDataSourceImpl(this.storage);

  static const String _key = 'jameia.cart.v1';

  @override
  CartModel? read() {
    final raw = storage.getString(_key);
    if (raw == null) return null;
    try {
      return CartModel.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // corrupt payload → treat as an empty cart
    }
  }

  @override
  Future<void> write(CartModel model) =>
      storage.setString(_key, json.encode(model.toJson()));

  @override
  Future<void> clear() => storage.remove(_key);
}
