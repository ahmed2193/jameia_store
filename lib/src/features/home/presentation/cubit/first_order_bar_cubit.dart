import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';

/// Shell-scoped: whether the first-order free-delivery bar stands on the
/// main shell's tab bar (Home, Search and Mine). It decides nothing itself:
/// the home tab's `HomeCubit` works it out (`HomeState.firstOrderGift`: the
/// store runs the gift and the customer has no order yet) and the home tab
/// hands every answer over ([show]) — so the bar never asks the backend
/// twice. A new session's home tab starts it over (its first answer is
/// `false` until its own check lands).
class FirstOrderBarCubit extends Cubit<bool> with SafeCubitMixin<bool> {
  FirstOrderBarCubit() : super(false);

  void show(bool due) => safeEmit(due);
}
