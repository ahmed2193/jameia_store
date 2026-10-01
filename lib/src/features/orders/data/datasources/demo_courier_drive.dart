import 'dart:math' as math;

import '../../domain/entities/courier_route.dart';

/// When a simulated rider passes each point of a road: sampled every
/// [_step] metres at a speed that eases up from a standstill, dips into
/// each turn, and dies away at the end — plus, with [DemoCourierDrive.new]'s
/// `redLight`, one red light held just before the middle turn. On a road a
/// road service drew, `paceAt` says how fast each stretch allows (a main
/// road faster than a side street), kept to a delivery rider's pace.
class DemoCourierDrive {
  /// A drive over [length] metres with turns at [turns] metres.
  factory DemoCourierDrive(
    double length,
    List<double> turns, {
    bool redLight = false,
    double Function(double meters)? paceAt,
  }) {
    final meters = <double>[0];
    final seconds = <double>[0];
    final lightAt = redLight && turns.isNotEmpty
        ? turns[turns.length ~/ 2] - _redLightBefore
        : double.infinity;
    var along = 0.0;
    var time = 0.0;
    var waited = false;
    while (along < length) {
      final next = math.min(along + _step, length);
      final middle = (along + next) / 2;
      final cruise = paceAt == null ? _cruiseMps : _cruiseFor(paceAt(middle));
      time += (next - along) / _speedAt(middle, length, turns, cruise);
      along = next;
      meters.add(along);
      seconds.add(time);
      if (!waited && along >= lightAt) {
        waited = true;
        time += _redLightSeconds;
        meters.add(along);
        seconds.add(time);
      }
    }
    return DemoCourierDrive._(meters, seconds);
  }

  const DemoCourierDrive._(this._meters, this._seconds);

  static const double _step = 5;
  static const double _cruiseMps = 8.5;
  static const double _turnMps = 3.2;
  static const double _turnZone = 40;
  static const double _launchMps = 2.5;
  static const double _launchZone = 40;
  static const double _parkMps = 2.2;
  static const double _parkZone = 50;
  static const double _redLightSeconds = 6;
  static const double _redLightBefore = 12;

  // A rider rides a little under a road's free-flow pace, within these.
  static const double _paceShare = 0.9;
  static const double _minCruiseMps = 4;
  static const double _maxCruiseMps = 16;

  // A turn: the heading swings this much between this far before and after.
  static const double _turnDegrees = 35;
  static const double _turnReach = 15;
  static const double _fullTurn = 360;
  static const double _halfTurn = 180;

  final List<double> _meters;
  final List<double> _seconds;

  double get totalSeconds => _seconds.last;

  /// Metres of road behind the rider [seconds] into the drive.
  double metersAt(double seconds) {
    if (seconds <= 0) return 0;
    if (seconds >= totalSeconds) return _meters.last;
    var low = 0;
    var high = _seconds.length - 1;
    while (high - low > 1) {
      final mid = (low + high) ~/ 2;
      if (_seconds[mid] <= seconds) {
        low = mid;
      } else {
        high = mid;
      }
    }
    final span = _seconds[high] - _seconds[low];
    final t = span == 0 ? 0.0 : (seconds - _seconds[low]) / span;
    return _meters[low] + (_meters[high] - _meters[low]) * t;
  }

  /// The turns of [road], in metres along it: where its heading swings by
  /// [_turnDegrees] or more between [_turnReach] metres before and after —
  /// each bend counted once, at its sharpest.
  static List<double> turnsOf(CourierRoute road) {
    final turns = <double>[];
    var bendAt = -1.0;
    var bendSwing = 0.0;
    for (
      var along = _turnReach;
      along <= road.lengthMeters - _turnReach;
      along += _step
    ) {
      final swing = _swing(
        road.headingAt(along - _turnReach),
        road.headingAt(along + _turnReach),
      );
      if (swing >= _turnDegrees) {
        if (swing > bendSwing) {
          bendSwing = swing;
          bendAt = along;
        }
      } else if (bendAt >= 0) {
        turns.add(bendAt);
        bendAt = -1;
        bendSwing = 0;
      }
    }
    if (bendAt >= 0) turns.add(bendAt);
    return turns;
  }

  /// The smaller angle between two compass headings, in degrees.
  static double _swing(double from, double to) {
    final turn = (to - from).abs() % _fullTurn;
    return turn > _halfTurn ? _fullTurn - turn : turn;
  }

  static double _cruiseFor(double pace) => pace <= 0
      ? _cruiseMps
      : (pace * _paceShare).clamp(_minCruiseMps, _maxCruiseMps);

  static double _speedAt(
    double along,
    double length,
    List<double> turns,
    double cruise,
  ) {
    var speed = cruise;
    for (final turn in turns) {
      final gap = (along - turn).abs();
      if (gap < _turnZone) {
        speed = math.min(speed, _blend(_turnMps, gap / _turnZone, cruise));
      }
    }
    if (along < _launchZone) {
      speed = math.min(speed, _blend(_launchMps, along / _launchZone, cruise));
    }
    final left = length - along;
    if (left < _parkZone) {
      speed = math.min(speed, _blend(_parkMps, left / _parkZone, cruise));
    }
    return speed;
  }

  /// From [slow] (share 0) up to [cruise] (share 1), eased (smoothstep).
  static double _blend(double slow, double share, double cruise) {
    final eased = share * share * (3 - 2 * share);
    return slow + (math.max(cruise, slow) - slow) * eased;
  }
}
