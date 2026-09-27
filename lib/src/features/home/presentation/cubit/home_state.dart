import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_freshness.dart';
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
    this.freshness = DataFreshness.none,
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

  /// How fresh [feed] is (the device copy, a failed refresh …).
  final DataFreshness freshness;

  /// With [HomeStatus.loaded], a failed refresh (snack bar, content stays):
  /// transient, cleared on the next [copyWith]. With [HomeStatus.error], the
  /// reason for the full-screen state (offline vs error): kept while the
  /// status stays `error` — the launch snapshot may land meanwhile.
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
    DataFreshness? freshness,
    Failure? failure,
  }) {
    final nextStatus = status ?? this.status;
    return HomeState(
      status: nextStatus,
      feed: feed ?? this.feed,
      bootstrap: bootstrap ?? this.bootstrap,
      duePopups: duePopups ?? this.duePopups,
      popupsShown: popupsShown ?? this.popupsShown,
      freshness: freshness ?? this.freshness,
      failure:
          failure ?? (nextStatus == HomeStatus.error ? this.failure : null),
    );
  }

  @override
  List<Object?> get props => [
    status,
    feed,
    bootstrap,
    duePopups,
    popupsShown,
    freshness,
    failure,
  ];
}
