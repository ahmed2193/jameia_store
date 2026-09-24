import 'json_read.dart';
import 'localized_text_model.dart';

/// `picking.substitutedLines[]`.
class OrderSubstitutionModel {
  const OrderSubstitutionModel({
    required this.lineKey,
    this.productName = LocalizedTextModel.empty,
    this.variantName = LocalizedTextModel.empty,
  });

  static const String lineKeyKey = 'lineKey';
  static const String productKey = 'product';
  static const String variantKey = 'variant';
  static const String nameKey = 'name';

  static OrderSubstitutionModel? tryParse(Map<String, dynamic> json) {
    final lineKey = JsonRead.string(json[lineKeyKey]);
    if (lineKey == null) return null;
    final product = JsonRead.object(json[productKey]);
    final variant = JsonRead.object(json[variantKey]);
    return OrderSubstitutionModel(
      lineKey: lineKey,
      productName: product == null
          ? LocalizedTextModel.empty
          : LocalizedTextModel.parse(product[nameKey]),
      variantName: variant == null
          ? LocalizedTextModel.empty
          : LocalizedTextModel.parse(variant[nameKey]),
    );
  }

  final String lineKey;
  final LocalizedTextModel productName;
  final LocalizedTextModel variantName;
}

/// `picking`.
class OrderPickingModel {
  const OrderPickingModel({
    this.pickerName = '',
    this.startedAt,
    this.unavailableLineKeys = const <String>[],
    this.substitutions = const <OrderSubstitutionModel>[],
  });

  static const String pickerKey = 'picker';
  static const String nameKey = 'name';
  static const String startedAtKey = 'startedAt';
  static const String unavailableLinesKey = 'unavailableLines';
  static const String substitutedLinesKey = 'substitutedLines';
  static const String lineKeyKey = 'lineKey';

  factory OrderPickingModel.fromJson(Map<String, dynamic> json) {
    final picker = JsonRead.object(json[pickerKey]);
    final unavailable = json[unavailableLinesKey];
    return OrderPickingModel(
      pickerName: picker == null ? '' : JsonRead.string(picker[nameKey]) ?? '',
      startedAt: JsonRead.dateTime(json[startedAtKey]),
      unavailableLineKeys: unavailable is List
          ? <String>[
              for (final row in unavailable)
                if (row is Map && JsonRead.string(row[lineKeyKey]) != null)
                  JsonRead.string(row[lineKeyKey])!,
            ]
          : const <String>[],
      substitutions: _rows(json[substitutedLinesKey]),
    );
  }

  static List<OrderSubstitutionModel> _rows(Object? value) => value is List
      ? <OrderSubstitutionModel>[
          for (final row in value)
            if (row is Map)
              ?OrderSubstitutionModel.tryParse(row.cast<String, dynamic>()),
        ]
      : const <OrderSubstitutionModel>[];

  final String pickerName;
  final DateTime? startedAt;
  final List<String> unavailableLineKeys;
  final List<OrderSubstitutionModel> substitutions;
}

/// `delivery.attempts[]`.
class OrderDeliveryAttemptModel {
  const OrderDeliveryAttemptModel({
    required this.at,
    this.outcome = '',
    this.note = '',
  });

  static const String atKey = 'at';
  static const String outcomeKey = 'outcome';
  static const String noteKey = 'note';

  static OrderDeliveryAttemptModel? tryParse(Map<String, dynamic> json) {
    final at = JsonRead.dateTime(json[atKey]);
    if (at == null) return null;
    return OrderDeliveryAttemptModel(
      at: at,
      outcome: JsonRead.string(json[outcomeKey]) ?? '',
      note: JsonRead.string(json[noteKey]) ?? '',
    );
  }

  final DateTime at;
  final String outcome;
  final String note;
}

/// `delivery`.
class OrderDeliveryModel {
  const OrderDeliveryModel({
    this.driverName = '',
    this.pickedUpAt,
    this.deliveredAt,
    this.attempts = const <OrderDeliveryAttemptModel>[],
    this.lastFailureReason,
  });

  static const String driverKey = 'driver';
  static const String nameKey = 'name';
  static const String pickedUpAtKey = 'pickedUpAt';
  static const String deliveredAtKey = 'deliveredAt';
  static const String attemptsKey = 'attempts';
  static const String lastFailureReasonKey = 'lastFailureReason';

  factory OrderDeliveryModel.fromJson(Map<String, dynamic> json) {
    final driver = JsonRead.object(json[driverKey]);
    final attempts = json[attemptsKey];
    return OrderDeliveryModel(
      driverName: driver == null ? '' : JsonRead.string(driver[nameKey]) ?? '',
      pickedUpAt: JsonRead.dateTime(json[pickedUpAtKey]),
      deliveredAt: JsonRead.dateTime(json[deliveredAtKey]),
      attempts: attempts is List
          ? <OrderDeliveryAttemptModel>[
              for (final row in attempts)
                if (row is Map)
                  ?OrderDeliveryAttemptModel.tryParse(
                    row.cast<String, dynamic>(),
                  ),
            ]
          : const <OrderDeliveryAttemptModel>[],
      lastFailureReason: JsonRead.string(json[lastFailureReasonKey]),
    );
  }

  final String driverName;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final List<OrderDeliveryAttemptModel> attempts;
  final String? lastFailureReason;
}

/// `cancellation`.
class OrderCancellationModel {
  const OrderCancellationModel({
    this.reason = '',
    this.cancelledBy = '',
    this.cancelledAt,
    this.note = '',
  });

  static const String reasonKey = 'reason';
  static const String cancelledByKey = 'cancelledBy';
  static const String cancelledAtKey = 'cancelledAt';
  static const String noteKey = 'note';

  factory OrderCancellationModel.fromJson(Map<String, dynamic> json) =>
      OrderCancellationModel(
        reason: JsonRead.string(json[reasonKey]) ?? '',
        cancelledBy: JsonRead.string(json[cancelledByKey]) ?? '',
        cancelledAt: JsonRead.dateTime(json[cancelledAtKey]),
        note: JsonRead.string(json[noteKey]) ?? '',
      );

  final String reason;
  final String cancelledBy;
  final DateTime? cancelledAt;
  final String note;
}
