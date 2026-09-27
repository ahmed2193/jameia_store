import '../../../../core/data/models/order_model.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/network/locale_provider.dart';
import '../models/store_rules_model.dart';

/// `POST /v1/orders` — turns the server cart into an order — and the store
/// rules the checkout obeys (`GET /v1/init`).
abstract class CheckoutRemoteDataSource {
  /// `GET /v1/init` → the `store.*` fields of [StoreRulesModel]. The store's
  /// name arrives resolved for `Accept-Language`, so the answer is kept per
  /// language and only for [CheckoutRemoteDataSourceImpl.rulesTtl].
  Future<StoreRulesModel> getStoreRules();

  /// `POST /v1/orders { paymentMethod, notes?, deliverySlot? }` → Order.
  Future<OrderModel> placeOrder(Map<String, dynamic> body);
}

class CheckoutRemoteDataSourceImpl implements CheckoutRemoteDataSource {
  CheckoutRemoteDataSourceImpl(
    this._api,
    this._locale, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ApiConsumer _api;
  final LocaleProvider _locale;

  /// Injectable so the cache window is testable.
  final DateTime Function() _now;

  /// Opening checkout twice in a row would otherwise re-read the snapshot.
  static const Duration rulesTtl = Duration(minutes: 5);

  StoreRulesModel? _rules;
  String _rulesLanguage = '';
  DateTime? _rulesReadAt;

  static const String _ordersRoute = 'orders';
  static const String _initRoute = 'init';

  @override
  Future<StoreRulesModel> getStoreRules() async {
    final language = _locale.languageCode;
    final cached = _rules;
    final readAt = _rulesReadAt;
    if (cached != null &&
        _rulesLanguage == language &&
        readAt != null &&
        _now().difference(readAt) < rulesTtl) {
      return cached;
    }
    final rules = StoreRulesModel.fromInitJson(
      ApiPayload.asMap(await _api.get(EndPoints.init), _initRoute),
    );
    _rules = rules;
    _rulesLanguage = language;
    _rulesReadAt = _now();
    return rules;
  }

  @override
  Future<OrderModel> placeOrder(Map<String, dynamic> body) async =>
      OrderModel.fromJson(
        ApiPayload.asMap(
          await _api.post(EndPoints.orders, body: body),
          _ordersRoute,
        ),
      );
}
