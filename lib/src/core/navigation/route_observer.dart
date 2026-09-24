import 'package:flutter/widgets.dart';

/// The app router's route observer: a page that must know whether it is on
/// top (order tracking pauses its polling underneath another page) mixes in
/// `RouteAware` and subscribes with `ModalRoute.of(context)`.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
