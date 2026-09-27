import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../domain/entities/category_browse.dart';

class CategoryBrowseState extends Equatable
    implements ScreenLoadState<CategoryBrowseState> {
  const CategoryBrowseState({
    required this.browse,
    this.load = const ScreenLoad(),
  });

  CategoryBrowseState.initial({String? baseSlug})
    : this(browse: CategoryBrowse.initial(baseSlug: baseSlug));

  /// The tree's read, its freshness (the device copy, a failed refresh …)
  /// and the failure that goes with them.
  @override
  final ScreenLoad load;

  /// The tree plus what is picked at every level.
  final CategoryBrowse browse;

  LoadPhase get status => load.phase;
  Failure? get failure => load.failure;
  bool get isLoaded => load.isLoaded;

  /// The store has no categories at all (not a failure).
  bool get isEmpty => isLoaded && browse.tree.isEmpty;

  @override
  CategoryBrowseState withLoad(ScreenLoad load) => copyWith(load: load);

  CategoryBrowseState copyWith({ScreenLoad? load, CategoryBrowse? browse}) =>
      CategoryBrowseState(
        load: load ?? this.load.settled(),
        browse: browse ?? this.browse,
      );

  @override
  List<Object?> get props => [load, browse];
}
