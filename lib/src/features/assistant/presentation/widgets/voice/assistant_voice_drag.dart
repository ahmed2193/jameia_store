import 'dart:math' as math;
import 'dart:ui';

import 'package:equatable/equatable.dart';

import '../../../../../core/responsive/app_size.dart';

/// Where the finger holding the mic has gone: toward the start of the line
/// (cancel) or up (lock). One direction at a time, like WhatsApp — the
/// stronger one wins once the finger leaves the [slop].
class AssistantVoiceDrag extends Equatable {
  const AssistantVoiceDrag._(this.towardStart, this.up);

  /// The finger is where it went down.
  static const AssistantVoiceDrag none = AssistantVoiceDrag._(0, 0);

  /// Movement ignored as a shaky finger.
  static const double slop = AppSize.s8;

  /// Slid this far toward the start: cancelled.
  static const double cancelAt = AppSize.s120;

  /// Slid this far up: locked (hands-free).
  static const double lockAt = AppSize.s90;

  /// Share of the finger's travel the mic follows (it lags a little).
  static const double _follow = 0.9;

  /// How far the finger went toward the start of the line (left in a
  /// left-to-right language), never negative.
  final double towardStart;

  /// How far the finger went up, never negative.
  final double up;

  /// [delta] from where the finger went down, in a [rtl] or LTR line.
  factory AssistantVoiceDrag.of(Offset delta, {required bool rtl}) {
    final towardStart = math.max(0.0, rtl ? delta.dx : -delta.dx);
    final up = math.max(0.0, -delta.dy);
    if (towardStart < slop && up < slop) return none;
    return towardStart >= up
        ? AssistantVoiceDrag._(towardStart, 0)
        : AssistantVoiceDrag._(0, up);
  }

  /// 0 at the mic, 1 at the cancel line.
  double get cancelProgress => (towardStart / cancelAt).clamp(0.0, 1.0);

  /// 0 at the mic, 1 at the lock.
  double get lockProgress => (up / lockAt).clamp(0.0, 1.0);

  bool get cancels => towardStart >= cancelAt;

  bool get locks => up >= lockAt;

  /// Where the big mic is drawn: following the finger up to each line.
  Offset micOffset({required bool rtl}) {
    final along = math.min(towardStart, cancelAt) * _follow;
    return Offset(rtl ? along : -along, -math.min(up, lockAt) * _follow);
  }

  @override
  List<Object?> get props => [towardStart, up];
}
