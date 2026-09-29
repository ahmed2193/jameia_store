import 'package:equatable/equatable.dart';

/// How a snack bar reads at a glance (docs/motion §9.4 #15, B3-03): its
/// glyph and the glyph's colour; the words say the rest.
enum HeroSnackTone {
  /// Plain information: no glyph.
  info,

  /// What the customer did went through.
  success,

  /// Not done, and the customer can change that (a limit, a reason).
  warning,

  /// The server refused or failed.
  error,

  /// It needs the internet.
  offline,
}

/// What one snack bar says: its words and their [HeroSnackTone].
class HeroSnackMessage extends Equatable {
  const HeroSnackMessage(this.text, {this.tone = HeroSnackTone.info});

  final String text;
  final HeroSnackTone tone;

  @override
  List<Object?> get props => [text, tone];
}
