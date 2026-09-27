import 'package:equatable/equatable.dart';

/// A single FAQ entry — question header + expandable answer body, as i18n
/// keys (the widgets resolve them in the active locale).
///
/// The live Hero page sources these from `/api/faq/faqList`; the offline clone
/// ships the same fixed help-center topics as a scripted list.
class FaqItem extends Equatable {
  const FaqItem({required this.questionKey, required this.answerKey});

  final String questionKey;
  final String answerKey;

  /// Whether a lower-cased [query] occurs in the resolved [question] or
  /// [answer] (an empty query matches everything).
  static bool textMatches(
    String query, {
    required String question,
    required String answer,
  }) =>
      query.isEmpty ||
      question.toLowerCase().contains(query) ||
      answer.toLowerCase().contains(query);

  @override
  List<Object?> get props => [questionKey, answerKey];
}
