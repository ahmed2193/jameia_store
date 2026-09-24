import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/home_bootstrap.dart';
import '../../domain/entities/home_feed.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    required this.feed,
    this.bootstrap = HomeBootstrap.empty,
    this.duePopups = const <HomeMarketingPopup>[],
    this.popupsShown = false,
    this.failure,
  });

  HomeState.initial() : this(feed: HomeFeed.empty);

  final HomeStatus status;
  final HomeFeed feed;

  /// Delivery place, Pro programme, popups. Stays at its last good value when
  /// its request fails: home renders without it.
  final HomeBootstrap bootstrap;

  /// Marketing popups allowed to show now (frequency already applied).
  final List<HomeMarketingPopup> duePopups;

  /// The popup queue was shown in this session — never shown twice.
  final bool popupsShown;

  /// Transient — cleared on every [copyWith]; the page localizes it. With
  /// [HomeStatus.error] it is the full-screen error, with [HomeStatus.loaded]
  /// a failed refresh (snack bar, content stays).
  final Failure? failure;

  bool get isLoaded => status == HomeStatus.loaded;
  bool get isEmpty => isLoaded && feed.isEmpty;
  bool get hasPendingPopups => isLoaded && !popupsShown && duePopups.isNotEmpty;

  HomeState copyWith({
    HomeStatus? status,
    HomeFeed? feed,
    HomeBootstrap? bootstrap,
    List<HomeMarketingPopup>? duePopups,
    bool? popupsShown,
    Failure? failure,
  }) => HomeState(
    status: status ?? this.status,
    feed: feed ?? this.feed,
    bootstrap: bootstrap ?? this.bootstrap,
    duePopups: duePopups ?? this.duePopups,
    popupsShown: popupsShown ?? this.popupsShown,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    feed,
    bootstrap,
    duePopups,
    popupsShown,
    failure,
  ];
}
