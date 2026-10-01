import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// `GET /v1/orders?page=1&limit=1` → `results.pagination.total`: how many
/// orders the signed-in customer has, every status included.
class HomeOrdersCountModel {
  const HomeOrdersCountModel({required this.total});

  static const String paginationKey = 'pagination';
  static const String totalKey = 'total';

  /// Throws [ParsingException] without `pagination.total`: the count is the
  /// whole answer, and a guess could promise a first-order gift.
  factory HomeOrdersCountModel.fromJson(Map<String, dynamic> json) {
    final pagination = JsonRead.object(json[paginationKey]);
    final total = JsonRead.integer(pagination?[totalKey]);
    if (total == null) {
      throw const ParsingException('orders count: pagination.total missing');
    }
    return HomeOrdersCountModel(total: total);
  }

  final int total;
}
