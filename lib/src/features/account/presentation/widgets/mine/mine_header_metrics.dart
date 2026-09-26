import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';

/// Geometry of the collapsing Mine header, sized from the status-bar inset
/// and the reader's text scale so the open header never clips its own text.
///
///   * Open — the avatar centred under the status bar, then the name and
///     phone (a guest: the sign-in title, a two-line subtitle and the
///     sign-in pill).
///   * Collapsed — a [toolbar]-tall bar: the avatar docked at the start at
///     [avatarDockedScale], the compact name beside it, the actions at the
///     end.
class MineHeaderMetrics extends Equatable {
  const MineHeaderMetrics({
    required this.topInset,
    required this.textScaler,
    required this.isGuest,
  });

  static const double toolbar = AppSize.s56;
  static const double avatar = AppSize.s72;
  static const double avatarDockedScale = 0.5;

  /// The avatar's top edge, open or docked: centred in the bar once docked.
  static const double avatarTop = (toolbar - avatar * avatarDockedScale) / 2;

  static const double sideMargin = AppSpacing.s16;
  static const double action = AppSize.s44;
  static const double detailsGap = AppSpacing.s12;
  static const double lineGap = AppSpacing.s4;
  static const double ctaGap = AppSpacing.s12;
  static const double cta = AppSize.s40;
  static const double bottomGap = AppSpacing.s20;

  /// Where the compact title starts / stops in the collapsed bar.
  static const double compactStart =
      sideMargin + avatar * avatarDockedScale + AppSpacing.s12;
  static const double compactEnd = sideMargin + action + AppSpacing.s8;

  /// Line heights of the title (`headingLarge`) and subtitle (`bodyLarge`).
  static const double _titleLine = AppSize.s24;
  static const double _subtitleLine = AppSize.s19;
  static const int guestSubtitleLines = 2;

  /// The status-bar inset the header sits below.
  final double topInset;

  /// The reader's text scale; the open header grows with it.
  final TextScaler textScaler;

  /// Signed out: the header carries the two-line pitch and the sign-in pill.
  final bool isGuest;

  double get minExtent => topInset + toolbar;

  /// Top of the name / phone block while the header is open.
  double get detailsTop => topInset + avatarTop + avatar + detailsGap;

  double get _detailsHeight {
    final subtitleLines = isGuest ? guestSubtitleLines : 1;
    final pill = isGuest ? ctaGap + cta : 0.0;
    return textScaler.scale(_titleLine) +
        lineGap +
        textScaler.scale(_subtitleLine) * subtitleLines +
        pill;
  }

  double get maxExtent => detailsTop + _detailsHeight + bottomGap;

  /// 0 open → 1 collapsed for a header shrunk by [shrinkOffset].
  double progress(double shrinkOffset) {
    final range = maxExtent - minExtent;
    if (range <= 0) return 1;
    return (shrinkOffset / range).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [topInset, textScaler, isGuest];
}
