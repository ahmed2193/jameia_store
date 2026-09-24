import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/category_browse.dart';

enum CategoryBrowseStatus { initial, loading, loaded, error }

class CategoryBrowseState extends Equatable {
  const CategoryBrowseState({
    required this.browse,
    this.status = CategoryBrowseStatus.initial,
    this.failure,
  });

  CategoryBrowseState.initial({String? baseSlug})
    : this(browse: CategoryBrowse.initial(baseSlug: baseSlug));

  final CategoryBrowseStatus status;

  /// The tree plus what is picked at every level.
  final CategoryBrowse browse;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  bool get isLoaded => status == CategoryBrowseStatus.loaded;

  /// The store has no categories at all (not a failure).
  bool get isEmpty => isLoaded && browse.tree.isEmpty;

  CategoryBrowseState copyWith({
    CategoryBrowseStatus? status,
    CategoryBrowse? browse,
    Failure? failure,
  }) => CategoryBrowseState(
    status: status ?? this.status,
    browse: browse ?? this.browse,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, browse, failure];
}
