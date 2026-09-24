import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/checkout_draft.dart';
import '../../domain/entities/delivery_selection_entity.dart';
import '../../domain/entities/delivery_slot_entity.dart';
import '../models/branch_model.dart';
import '../models/delivery_selection_model.dart';
import '../models/delivery_slot_model.dart';

extension BranchMapper on BranchModel {
  BranchEntity toEntity() => BranchEntity(
    id: id,
    name: name,
    code: code,
    address: address,
    phone: phone,
    location: lat == null || lng == null
        ? null
        : GeoPointEntity(lat: lat!, lng: lng!),
    supportsDelivery: delivery,
    supportsPickup: pickup,
    supportsExpress: express,
    minOrderFils: minOrder,
    etaMinutes: etaMinutes,
  );
}

extension BranchListMapper on List<BranchModel> {
  List<BranchEntity> toEntities() => [
    for (final model in this) model.toEntity(),
  ];
}

extension DeliverySlotMapper on DeliverySlotModel {
  DeliverySlotEntity toEntity() => DeliverySlotEntity(
    templateId: templateId,
    date: date,
    start: start,
    end: end,
    startAt: startAt,
    endAt: endAt,
    label: label,
    capacity: capacity,
    booked: booked,
    remaining: remaining,
    available: available,
  );
}

extension DeliverySlotDayMapper on DeliverySlotDayModel {
  DeliverySlotDayEntity toEntity() => DeliverySlotDayEntity(
    date: date,
    label: label,
    slots: [for (final slot in slots) slot.toEntity()],
  );
}

extension DeliverySlotDayListMapper on List<DeliverySlotDayModel> {
  List<DeliverySlotDayEntity> toEntities() => [
    for (final model in this) model.toEntity(),
  ];
}

extension DeliverySelectionMapper on DeliverySelectionModel {
  DeliverySelectionEntity toEntity() => DeliverySelectionEntity(
    mode: FulfillmentMode.fromWire(mode),
    addressId: addressId,
    addressLabel: addressLabel,
    areaName: areaName,
    governorateName: governorateName,
    branchId: branchId,
    branchName: branchName,
    branchAddress: address,
    zoneId: zoneId,
    zoneName: zoneName,
    deliveryFeeFils: deliveryFee,
    minOrderFils: minOrder,
    etaMinutes: etaMinutes,
  );
}

/// `POST /v1/orders` body from the draft: the address / branch were
/// already selected on the server, so only payment, notes and the booked
/// slot travel.
extension CheckoutDraftMapper on CheckoutDraft {
  static const String paymentMethodField = 'paymentMethod';
  static const String notesField = 'notes';
  static const String deliverySlotField = 'deliverySlot';
  static const String templateIdField = 'templateId';
  static const String dateField = 'date';

  Map<String, dynamic> toBody() {
    final slot = this.slot;
    final trimmedNotes = notes.trim();
    return <String, dynamic>{
      paymentMethodField: paymentMethod.wireValue,
      if (trimmedNotes.isNotEmpty) notesField: trimmedNotes,
      if (timing == DeliveryTiming.scheduled && slot != null)
        deliverySlotField: <String, dynamic>{
          templateIdField: slot.templateId,
          dateField: slot.date,
        },
    };
  }
}
