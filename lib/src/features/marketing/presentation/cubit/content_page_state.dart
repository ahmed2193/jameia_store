import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../domain/entities/content_page_entity.dart';

class ContentPageState extends Equatable
    implements ScreenLoadState<ContentPageState> {
  const ContentPageState({this.load = const ScreenLoad(), this.page});

  /// The page's read, its freshness (the device copy, a failed reload …)
  /// and the failure that goes with them.
  @override
  final ScreenLoad load;
  final ContentPageEntity? page;

  LoadPhase get status => load.phase;
  Failure? get failure => load.failure;
  bool get isLoaded => load.isLoaded;

  @override
  ContentPageState withLoad(ScreenLoad load) => copyWith(load: load);

  ContentPageState copyWith({ScreenLoad? load, ContentPageEntity? page}) =>
      ContentPageState(
        load: load ?? this.load.settled(),
        page: page ?? this.page,
      );

  @override
  List<Object?> get props => [load, page];
}
