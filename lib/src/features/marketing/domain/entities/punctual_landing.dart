import 'package:equatable/equatable.dart';

/// One "how it works" step.
class PunctualStep extends Equatable {
  const PunctualStep({required this.title, required this.body});
  final String title;
  final String body;

  @override
  List<Object?> get props => [title, body];
}

/// One FAQ entry.
class PunctualFaq extends Equatable {
  const PunctualFaq({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  List<Object?> get props => [question, answer];
}

/// Resolved landing payload for the on-time guarantee page.
///
/// Mirrors the shape the live Jameia endpoint
/// (`v1/order/late/compensation/landing`) returns: a promise headline + body,
/// the make-up-coupon explainer copy, the ordered how-it-works steps and the FAQ
/// list. Served offline by the marketing datasource from the dummy backend.
class PunctualLanding extends Equatable {
  const PunctualLanding({
    required this.promiseTitle,
    required this.promiseBody,
    required this.couponTitle,
    required this.couponBody,
    required this.steps,
    required this.faqs,
  });

  final String promiseTitle;
  final String promiseBody;
  final String couponTitle;
  final String couponBody;
  final List<PunctualStep> steps;
  final List<PunctualFaq> faqs;

  @override
  List<Object?> get props => [
    promiseTitle,
    promiseBody,
    couponTitle,
    couponBody,
    steps,
    faqs,
  ];
}
