import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/faq_item.dart';
import '../entities/rider_entity.dart';
import '../entities/support_hub.dart';

/// Read boundary for the customer-service help center. Offline, all methods
/// resolve from the scripted support source; they still return
/// `Either<Failure, T>` so the presentation layer handles failure uniformly.
abstract class SupportRepository {
  /// Recent-order help card + scripted FAQ topic list for the hub.
  Future<Either<Failure, SupportHub>> getSupportHub();

  /// Full FAQ list (question + answer) for the self-serve topics page.
  Future<Either<Failure, List<FaqItem>>> getFaqs();

  /// Rider for the IM chat — the first active order's rider (or a generic
  /// fallback). Sourced in the data layer so presentation stays off
  /// `core/data/keeta_repository.dart`.
  Future<Either<Failure, RiderEntity>> getActiveRider();
}
