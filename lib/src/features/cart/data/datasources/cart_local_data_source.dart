import 'dart:convert';
import 'dart:developer';

import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/session_store.dart';
import '../models/cart_mirror_model.dart';

/// The on-device side of the cart: the mirror (last server cart + pending
/// changes, `LocalStorage`) and the guest cart identity (`SessionStore`).
abstract class CartLocalDataSource {
  /// The saved mirror, `null` when there is none. Throws `CacheException`
  /// when the stored text is not JSON, `ParsingException` when it is JSON
  /// but unreadable.
  CartMirrorModel? readMirror();

  Future<void> saveMirror(CartMirrorModel mirror);

  Future<void> clearMirror();

  /// Stores the `cartToken` a cart reply carried — only while signed out
  /// (a customer's cart is named by the Bearer; storing its token would
  /// hand that cart to the next guest on this device) and only when it
  /// changed (the keychain write is the slow part).
  Future<void> rememberCartToken(String token);
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  const CartLocalDataSourceImpl(this._storage, this._session);

  final LocalStorage _storage;
  final SessionStore _session;

  static const String mirrorKey = 'cart.mirror.v1';
  static const String _logName = 'CartLocalDataSource';

  @override
  CartMirrorModel? readMirror() {
    final raw = _storage.getString(mirrorKey);
    if (raw == null || raw.isEmpty) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      log('mirror unreadable: $error', name: _logName);
      throw const CacheException('cart mirror is not JSON');
    }
    if (decoded is! Map) {
      throw const ParsingException('cart mirror: not an object');
    }
    return CartMirrorModel.fromJson(decoded.cast<String, dynamic>());
  }

  @override
  Future<void> saveMirror(CartMirrorModel mirror) async {
    final saved = await _storage.setString(
      mirrorKey,
      jsonEncode(mirror.toJson()),
    );
    if (!saved) throw const CacheException('cart mirror not saved');
  }

  @override
  Future<void> clearMirror() => _storage.remove(mirrorKey);

  @override
  Future<void> rememberCartToken(String token) async {
    if (token.isEmpty || await _session.isSignedIn) return;
    if (await _session.readCartToken() == token) return;
    await _session.saveCartToken(token);
  }
}
