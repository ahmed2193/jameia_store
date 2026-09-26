import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// One window of a `delivery_slots` day (the `GET /v1/delivery/slots` slot
/// shape). The checkout feature's DTO stays private to it.
class AssistantSlotModel {
  const AssistantSlotModel({
    required this.templateId,
    required this.date,
    this.start = '',
    this.end = '',
    this.startAt,
    this.endAt,
    this.label = '',
    this.capacity = 0,
    this.booked = 0,
    this.remaining = 0,
    this.available = false,
  });

  static const String templateIdKey = 'templateId';
  static const String dateKey = 'date';
  static const String startKey = 'start';
  static const String endKey = 'end';
  static const String startAtKey = 'startAt';
  static const String endAtKey = 'endAt';
  static const String labelKey = 'label';
  static const String capacityKey = 'capacity';
  static const String bookedKey = 'booked';
  static const String remainingKey = 'remaining';
  static const String availableKey = 'available';

  final String templateId;
  final String date;
  final String start;
  final String end;
  final DateTime? startAt;
  final DateTime? endAt;
  final String label;
  final int capacity;
  final int booked;
  final int remaining;
  final bool available;

  factory AssistantSlotModel.fromJson(Map<String, dynamic> json) {
    final templateId = JsonRead.string(json[templateIdKey]);
    final date = JsonRead.string(json[dateKey]);
    if (templateId == null || date == null) {
      throw const ParsingException('slot: templateId / date missing');
    }
    return AssistantSlotModel(
      templateId: templateId,
      date: date,
      start: JsonRead.string(json[startKey]) ?? '',
      end: JsonRead.string(json[endKey]) ?? '',
      startAt: JsonRead.dateTime(json[startAtKey]),
      endAt: JsonRead.dateTime(json[endAtKey]),
      label: JsonRead.string(json[labelKey]) ?? '',
      capacity: JsonRead.integer(json[capacityKey]) ?? 0,
      booked: JsonRead.integer(json[bookedKey]) ?? 0,
      remaining: JsonRead.integer(json[remainingKey]) ?? 0,
      available: JsonRead.flag(json[availableKey]),
    );
  }
}

/// A day of a `delivery_slots` block: `{ date, label, slots[] }`.
class AssistantSlotDayModel {
  const AssistantSlotDayModel({
    required this.date,
    this.label = '',
    this.slots = const <AssistantSlotModel>[],
  });

  static const String dateKey = 'date';
  static const String labelKey = 'label';
  static const String slotsKey = 'slots';
  static const String _logName = 'AssistantSlotDayModel';

  final String date;
  final String label;
  final List<AssistantSlotModel> slots;

  factory AssistantSlotDayModel.fromJson(Map<String, dynamic> json) {
    final date = JsonRead.string(json[dateKey]);
    if (date == null) throw const ParsingException('slot day: date missing');
    return AssistantSlotDayModel(
      date: date,
      label: JsonRead.string(json[labelKey]) ?? '',
      slots: JsonRead.rows(
        json[slotsKey],
        AssistantSlotModel.fromJson,
        logName: _logName,
      ),
    );
  }
}
