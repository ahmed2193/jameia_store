import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/content_page_entity.dart';

enum ContentPageStatus { initial, loading, loaded, error }

class ContentPageState extends Equatable {
  const ContentPageState({
    this.status = ContentPageStatus.initial,
    this.page,
    this.failure,
  });

  final ContentPageStatus status;
  final ContentPageEntity? page;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  bool get isLoaded => status == ContentPageStatus.loaded;

  ContentPageState copyWith({
    ContentPageStatus? status,
    ContentPageEntity? page,
    Failure? failure,
  }) => ContentPageState(
    status: status ?? this.status,
    page: page ?? this.page,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, page, failure];
}
