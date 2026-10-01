import '../../../../core/domain/localization/text_direction_estimate.dart';

/// The direction an assistant message reads in: [TextDirectionEstimate]
/// (shared with the rider chat), under the name the assistant's widgets use.
abstract final class AssistantTextDirection {
  /// `true` right-to-left, `false` left-to-right, `null` when [text] has no
  /// letter at all (digits, punctuation, emoji) — follow the app then.
  static bool? isRtl(String text) => TextDirectionEstimate.isRtl(text);
}
