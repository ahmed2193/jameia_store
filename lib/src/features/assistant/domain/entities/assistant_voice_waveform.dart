import 'package:equatable/equatable.dart';

/// The recording's loudness history, drawn as the waveform: the newest
/// [capacity] levels, oldest first, each 0..1. Immutable — [push] returns
/// a new one, so a state holding it compares by value.
class AssistantVoiceWaveform extends Equatable {
  const AssistantVoiceWaveform._(this.levels);

  static const AssistantVoiceWaveform empty = AssistantVoiceWaveform._(
    <double>[],
  );

  /// Bars kept: more than the widest composer draws.
  static const int capacity = 64;

  final List<double> levels;

  /// The latest level, 0 before any.
  double get latest => levels.isEmpty ? 0 : levels.last;

  /// Adds [level] (clamped to 0..1; not-a-number is silence) and drops the
  /// oldest once [capacity] is reached.
  AssistantVoiceWaveform push(double level) {
    final value = level.isNaN ? 0.0 : level.clamp(0.0, 1.0).toDouble();
    final keep = levels.length < capacity ? levels : levels.skip(1);
    return AssistantVoiceWaveform._(
      List<double>.unmodifiable(<double>[...keep, value]),
    );
  }

  @override
  List<Object?> get props => [levels];
}
