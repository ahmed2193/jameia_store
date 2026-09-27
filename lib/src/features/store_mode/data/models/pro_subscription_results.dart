import '../../../../core/data/models/json_read.dart';
import 'pro_subscription_model.dart';

/// Parses the `results` of `GET /v1/account/subscription` — the server's
/// reply and its device copy alike: the subscription, or `null` when the
/// customer has none. A device copy cannot be `null`, so "none" is kept as
/// [none] (an object without a subscription in it).
abstract final class ProSubscriptionResults {
  /// What the device keeps for "no subscription".
  static const Map<String, Object?> none = <String, Object?>{};

  /// `null` for none; throws `ParsingException` for a subscription without
  /// an id.
  static ProSubscriptionModel? parse(Object? results) {
    final json = JsonRead.object(results);
    return json == null || json.isEmpty
        ? null
        : ProSubscriptionModel.fromJson(json);
  }

  /// [results] as the device keeps it.
  static Object keep(Object? results) => results ?? none;
}
