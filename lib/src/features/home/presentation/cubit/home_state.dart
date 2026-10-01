import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../domain/entities/home_bootstrap.dart';
import '../../domain/entities/home_feed.dart';

class HomeState extends Equatable implements ScreenLoadState<HomeState> {
  const HomeState({
    this.load = const ScreenLoad(),
    required this.feed,
    this.bootstrap = HomeBootstrap.empty,
    this.welcomeDue = false,
    this.duePopups = const <HomeMarketingPopup>[],
    this.popupsShown = false,
  });

  HomeState.initial() : this(feed: HomeFeed.empty);

  /// The feed's read, how fresh it is (the device copy, a failed refresh …)
  /// and the failure that goes with them: a failed refresh is told once over
  /// the feed; with nothing on screen it is the reason for the full-screen
  /// state (offline vs error), kept while the launch snapshot lands.
  @override
  final ScreenLoad load;
  final HomeFeed feed;

  /// Delivery place, Pro programme, popups. Stays at its last good value when
  /// its request fails: home renders without it.
  final HomeBootstrap bootstrap;

  /// The first-order free-delivery gift opens the popup queue (the store runs
  /// it and the customer has no order yet).
  final bool welcomeDue;

  /// Marketing popups allowed to show now (frequency already applied).
  final List<HomeMarketingPopup> duePopups;

  /// The popup queue was shown in this session — never shown twice.
  final bool popupsShown;

  LoadPhase get status => load.phase;
  DataFreshness get freshness => load.freshness;
  Failure? get failure => load.failure;
  bool get isLoaded => load.isLoaded;
  bool get isEmpty => isLoaded && feed.isEmpty;
  bool get hasPendingPopups =>
      isLoaded && !popupsShown && (welcomeDue || duePopups.isNotEmpty);

  @override
  HomeState withLoad(ScreenLoad load) => copyWith(load: load);

  HomeState copyWith({
    ScreenLoad? load,
    HomeFeed? feed,
    HomeBootstrap? bootstrap,
    bool? welcomeDue,
    List<HomeMarketingPopup>? duePopups,
    bool? popupsShown,
  }) => HomeState(
    load: load ?? this.load.settled(),
    feed: feed ?? this.feed,
    bootstrap: bootstrap ?? this.bootstrap,
    welcomeDue: welcomeDue ?? this.welcomeDue,
    duePopups: duePopups ?? this.duePopups,
    popupsShown: popupsShown ?? this.popupsShown,
  );

  @override
  List<Object?> get props => [
    load,
    feed,
    bootstrap,
    welcomeDue,
    duePopups,
    popupsShown,
  ];
}
