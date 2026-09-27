import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';

class OffersState extends Equatable implements ScreenLoadState<OffersState> {
  const OffersState({
    this.load = const ScreenLoad(),
    this.offers = const <OfferEntity>[],
  });

  /// The list's read, its freshness (the device copy, a failed refresh …)
  /// and the failure that goes with them. The page localizes it.
  @override
  final ScreenLoad load;
  final List<OfferEntity> offers;

  LoadPhase get status => load.phase;
  Failure? get failure => load.failure;
  bool get isLoaded => load.isLoaded;
  bool get isEmpty => isLoaded && offers.isEmpty;

  @override
  OffersState withLoad(ScreenLoad load) => copyWith(load: load);

  OffersState copyWith({ScreenLoad? load, List<OfferEntity>? offers}) =>
      OffersState(
        load: load ?? this.load.settled(),
        offers: offers ?? this.offers,
      );

  @override
  List<Object?> get props => [load, offers];
}
