import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/content_page_entity.dart';

enum ContentPageStatus { initial, loading, loaded, error }

class ContentPageState extends Equatable {
  const ContentPageState({
    this.status = ContentPageStatus.initial,
    this.page,
    this.freshness = DataFreshness.none,
    this.failure,
  });

  final ContentPageStatus status;
  final ContentPageEntity? page;

  /// How fresh [page] is (the device copy, a failed reload …).
  final DataFreshness freshness;

  /// Transient with [ContentPageStatus.loaded] (cleared on the next
  /// [copyWith]); with [ContentPageStatus.error] the reason for the
  /// full-screen state, kept while the status stays `error`.
  final Failure? failure;

  bool get isLoaded => status == ContentPageStatus.loaded;

  ContentPageState copyWith({
    ContentPageStatus? status,
    ContentPageEntity? page,
    DataFreshness? freshness,
    Failure? failure,
  }) {
    final nextStatus = status ?? this.status;
    return ContentPageState(
      status: nextStatus,
      page: page ?? this.page,
      freshness: freshness ?? this.freshness,
      failure:
          failure ??
          (nextStatus == ContentPageStatus.error ? this.failure : null),
    );
  }

  @override
  List<Object?> get props => [status, page, freshness, failure];
}
