import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/error/failures.dart';

enum OffersStatus { initial, loading, loaded, error }

class OffersState extends Equatable {
  const OffersState({
    this.status = OffersStatus.initial,
    this.offers = const <OfferEntity>[],
    this.freshness = DataFreshness.none,
    this.failure,
  });

  final OffersStatus status;
  final List<OfferEntity> offers;

  /// How fresh [offers] is (the device copy, a failed refresh …).
  final DataFreshness freshness;

  /// Transient with [OffersStatus.loaded] (cleared on the next [copyWith]);
  /// with [OffersStatus.error] the reason for the full-screen state, kept
  /// while the status stays `error`. The page localizes it.
  final Failure? failure;

  bool get isLoaded => status == OffersStatus.loaded;
  bool get isEmpty => isLoaded && offers.isEmpty;

  OffersState copyWith({
    OffersStatus? status,
    List<OfferEntity>? offers,
    DataFreshness? freshness,
    Failure? failure,
  }) {
    final nextStatus = status ?? this.status;
    return OffersState(
      status: nextStatus,
      offers: offers ?? this.offers,
      freshness: freshness ?? this.freshness,
      failure:
          failure ?? (nextStatus == OffersStatus.error ? this.failure : null),
    );
  }

  @override
  List<Object?> get props => [status, offers, freshness, failure];
}
