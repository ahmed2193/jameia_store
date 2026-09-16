import 'package:equatable/equatable.dart';

/// A single FAQ entry — question header + expandable answer body.
///
/// The live KeeTa page sources these from `/api/faq/faqList`; the offline clone
/// ships the same fixed help-center topics as a scripted list built by the
/// support datasource. A pure domain entity (no JSON) since there is no backend.
class FaqItem extends Equatable {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  List<Object?> get props => [question, answer];
}
