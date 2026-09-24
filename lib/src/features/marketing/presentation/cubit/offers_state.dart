import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/offer_entity.dart';

enum OffersStatus { initial, loading, loaded, error }

class OffersState extends Equatable {
  const OffersState({
    this.status = OffersStatus.initial,
    this.offers = const <OfferEntity>[],
    this.failure,
  });

  final OffersStatus status;
  final List<OfferEntity> offers;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  bool get isLoaded => status == OffersStatus.loaded;
  bool get isEmpty => isLoaded && offers.isEmpty;

  OffersState copyWith({
    OffersStatus? status,
    List<OfferEntity>? offers,
    Failure? failure,
  }) => OffersState(
    status: status ?? this.status,
    offers: offers ?? this.offers,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, offers, failure];
}
