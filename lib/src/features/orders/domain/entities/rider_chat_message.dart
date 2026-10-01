import 'package:equatable/equatable.dart';

import '../../../../core/domain/localization/localized_pick.dart';

/// One message between the customer and their rider. A rider's message
/// arrives in both languages (translated for whoever reads it — riders and
/// customers often do not share one); the customer's is as they typed it.
class RiderChatMessage extends Equatable {
  const RiderChatMessage({
    required this.id,
    required this.fromRider,
    required this.sentAt,
    required this.textEn,
    required this.textAr,
  });

  final String id;
  final bool fromRider;
  final DateTime sentAt;
  final String textEn;
  final String textAr;

  String textFor(String languageCode) =>
      pickLocalized(languageCode, en: textEn, ar: textAr);

  @override
  List<Object?> get props => [id, fromRider, sentAt, textEn, textAr];
}
