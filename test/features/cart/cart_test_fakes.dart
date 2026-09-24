import 'dart:async';

import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/features/cart/data/datasources/cart_local_data_source.dart';
import 'package:jameia_mart/src/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:jameia_mart/src/features/cart/data/models/cart_mirror_model.dart';
import 'package:jameia_mart/src/features/cart/data/models/cart_model.dart';

/// One recorded call to the fake cart API.
class CartCall {
  CartCall(this.name, {this.key, this.quantity, this.items});

  final String name;
  final String? key;
  final int? quantity;
  final List<Map<String, dynamic>>? items;

  @override
  String toString() =>
      '$name(${key ?? ''}${quantity == null ? '' : ':$quantity'}'
      '${items == null ? '' : items!.map((i) => '${i['productId']}x${i['quantity']}').join(',')})';
}

/// Scripted cart API: every call records itself and answers with whatever
/// [reply] returns for that call index (or throws [error] once).
class FakeCartRemoteDataSource implements CartRemoteDataSource {
  FakeCartRemoteDataSource(this.reply);

  /// Answers the n-th call. Throw from it to fail a call.
  Map<String, dynamic> Function(CartCall call, int index) reply;
  final List<CartCall> calls = <CartCall>[];

  /// When set, the matching call waits on this completer before answering.
  Completer<void>? gate;

  Future<CartModel> _run(CartCall call) async {
    calls.add(call);
    final index = calls.length - 1;
    final gate = this.gate;
    if (gate != null) {
      this.gate = null;
      await gate.future;
    }
    return CartModel.fromJson(reply(call, index));
  }

  @override
  Future<CartModel> getCart() => _run(CartCall('get'));

  @override
  Future<CartModel> addItems(List<Map<String, dynamic>> items) =>
      _run(CartCall('addItems', items: items));

  @override
  Future<CartModel> setLineQuantity(String key, int quantity) =>
      _run(CartCall('patch', key: key, quantity: quantity));

  @override
  Future<CartModel> removeLine(String key) =>
      _run(CartCall('delete', key: key));

  @override
  Future<CartModel> clear() => _run(CartCall('clear'));

  @override
  Future<CartModel> applyCoupon(String code) =>
      _run(CartCall('applyCoupon', key: code));

  @override
  Future<CartModel> removeCoupon() => _run(CartCall('removeCoupon'));

  @override
  Future<CartModel> applyLoyalty(int points) =>
      _run(CartCall('applyLoyalty', quantity: points));

  @override
  Future<CartModel> removeLoyalty() => _run(CartCall('removeLoyalty'));

  @override
  Future<CartModel> setExpress({required bool enabled}) =>
      _run(CartCall('express', quantity: enabled ? 1 : 0));
}

/// In-memory device mirror.
class FakeCartLocalDataSource implements CartLocalDataSource {
  CartMirrorModel? mirror;
  String? cartToken;
  int saves = 0;
  int clears = 0;

  /// Thrown by [readMirror] when set (an unreadable device copy).
  AppException? readError;

  @override
  CartMirrorModel? readMirror() {
    final error = readError;
    if (error != null) throw error;
    return mirror;
  }

  @override
  Future<void> saveMirror(CartMirrorModel mirror) async {
    this.mirror = mirror;
    saves++;
  }

  @override
  Future<void> clearMirror() async {
    mirror = null;
    clears++;
  }

  @override
  Future<void> rememberCartToken(String token) async => cartToken = token;
}
