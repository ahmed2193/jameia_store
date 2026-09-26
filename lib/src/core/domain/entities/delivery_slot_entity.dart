import 'package:equatable/equatable.dart';

/// One bookable delivery window (`GET /v1/delivery/slots` → `data[].slots[]`).
class DeliverySlotEntity extends Equatable {
  const DeliverySlotEntity({
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

  final String templateId;

  /// `YYYY-MM-DD`.
  final String date;

  /// `HH:mm`.
  final String start;
  final String end;
  final DateTime? startAt;
  final DateTime? endAt;

  /// Already resolved for the request language ("10:00 – 12:00").
  final String label;
  final int capacity;
  final int booked;
  final int remaining;
  final bool available;

  bool get isBookable => available && remaining > 0;

  /// What `POST /v1/orders` needs to book it.
  bool get isSelectable => isBookable && templateId.isNotEmpty;

  @override
  List<Object?> get props => [
    templateId,
    date,
    start,
    end,
    startAt,
    endAt,
    label,
    capacity,
    booked,
    remaining,
    available,
  ];
}

/// A day of slots (`data[]`).
class DeliverySlotDayEntity extends Equatable {
  const DeliverySlotDayEntity({
    required this.date,
    this.label = '',
    this.slots = const <DeliverySlotEntity>[],
  });

  final String date;
  final String label;
  final List<DeliverySlotEntity> slots;

  bool get hasBookableSlot => slots.any((slot) => slot.isBookable);

  /// [date] as a date, so a page can write it in the customer's language.
  DateTime? get day => DateTime.tryParse(date);

  /// Whether [label] is a name worth showing ("Today", "Tomorrow").
  ///
  /// The server names only the near days and repeats the raw `yyyy-MM-dd`
  /// for the rest — which is not a date any customer wants to read, so those
  /// days are written from [day] instead.
  bool get hasNamedLabel => label.isNotEmpty && label != date;

  @override
  List<Object?> get props => [date, label, slots];
}
