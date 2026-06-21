import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';

/// State for the "My coupons" page — the full coupon set partitioned into the
/// three KeeTa tabs (available / used / expired).
sealed class CouponsState {
  const CouponsState();
}

class CouponsLoading extends CouponsState {
  const CouponsLoading();
}

class CouponsLoaded extends CouponsState {
  const CouponsLoaded({
    required this.available,
    required this.used,
    required this.expired,
  });

  final List<Coupon> available;
  final List<Coupon> used;
  final List<Coupon> expired;
}

/// Page-scoped cubit: reads the dummy coupon list from [KeetaRepository] and
/// buckets it into the three tabs. Constructed inline by the screen
/// (`BlocProvider(create: (_) => CouponsCubit(sl<KeetaRepository>())..load())`)
/// — NOT registered in the service locator.
class CouponsCubit extends Cubit<CouponsState> {
  CouponsCubit(this._repo) : super(const CouponsLoading());

  final KeetaRepository _repo;

  void load() {
    final all = _repo.coupons;
    final available = <Coupon>[];
    final used = <Coupon>[];
    final expired = <Coupon>[];
    for (final c in all) {
      if (c.used) {
        used.add(c);
      } else if (_isExpired(c)) {
        expired.add(c);
      } else {
        available.add(c);
      }
    }
    emit(CouponsLoaded(available: available, used: used, expired: expired));
  }

  /// Dummy data carries the human label only; treat an "Expired" marker in the
  /// expiry string as the expired bucket so all three tabs populate offline.
  static bool _isExpired(Coupon c) =>
      c.expiry.toLowerCase().contains('expired');
}
