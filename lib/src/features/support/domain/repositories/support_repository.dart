import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/faq_item.dart';
import '../entities/support_hub.dart';

/// Read boundary for the customer-service help center. Offline, all methods
/// resolve from the scripted support source; they still return
/// `Either<Failure, T>` so the presentation layer handles failure uniformly.
abstract class SupportRepository {
  /// Recent-order help card + the FAQ topics of the hub.
  Future<Either<Failure, SupportHub>> getSupportHub();

  /// Full FAQ list (question + answer) for the self-serve topics page.
  Future<Either<Failure, List<FaqItem>>> getFaqs();

  /// Name of the rider of the first order that has one, `null` when none.
  Future<Either<Failure, String?>> getActiveRiderName();
}
