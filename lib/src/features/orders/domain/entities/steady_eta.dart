import 'package:equatable/equatable.dart';

/// The minutes the customer reads, held steady against a feed's noise: a
/// drop shows at once (good news is never held back), and so does a rise of
/// [bigRise] minutes or more; a smaller rise shows only once [riseHold]
/// fixes in a row carry it — one noisy fix never turns "5 min" into "6".
class SteadyEta extends Equatable {
  const SteadyEta({this.minutes, this.risingFixes = 0});

  /// A rise this large is real news: shown at once.
  static const int bigRise = 2;

  /// Fixes in a row a smaller rise must hold before it shows.
  static const int riseHold = 3;

  /// What the customer reads; `null` when there is nothing to promise.
  final int? minutes;

  /// Fixes in a row that asked for more than [minutes].
  final int risingFixes;

  /// The next reading after a fix that says [fresh].
  SteadyEta next(int? fresh) {
    final shown = minutes;
    if (fresh == null || shown == null || fresh <= shown) {
      return SteadyEta(minutes: fresh);
    }
    final held = risingFixes + 1;
    if (fresh - shown >= bigRise || held >= riseHold) {
      return SteadyEta(minutes: fresh);
    }
    return SteadyEta(minutes: shown, risingFixes: held);
  }

  @override
  List<Object?> get props => [minutes, risingFixes];
}
