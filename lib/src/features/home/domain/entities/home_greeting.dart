import 'package:equatable/equatable.dart';

/// The part of the day a greeting speaks to.
enum HomeDayPart { morning, afternoon, evening, night }

/// How the home tab greets the customer: by the part of the day, and by
/// first name when the account has a real one.
class HomeGreeting extends Equatable {
  const HomeGreeting({required this.dayPart, this.firstName = ''});

  /// The greeting for [now], for a customer called [fullName] ('' when
  /// signed out or still unnamed).
  factory HomeGreeting.at(DateTime now, {String fullName = ''}) {
    final words = fullName.trim().split(_spaces);
    return HomeGreeting(
      dayPart: dayPartOf(now),
      firstName: words.isEmpty ? '' : words.first,
    );
  }

  final HomeDayPart dayPart;
  final String firstName;

  bool get hasName => firstName.isNotEmpty;

  static final RegExp _spaces = RegExp(r'\s+');

  /// First hours of each part of the day.
  static const int _morningFrom = 5;
  static const int _afternoonFrom = 12;
  static const int _eveningFrom = 17;
  static const int _nightFrom = 21;

  static HomeDayPart dayPartOf(DateTime time) {
    final hour = time.hour;
    if (hour >= _morningFrom && hour < _afternoonFrom) {
      return HomeDayPart.morning;
    }
    if (hour >= _afternoonFrom && hour < _eveningFrom) {
      return HomeDayPart.afternoon;
    }
    if (hour >= _eveningFrom && hour < _nightFrom) return HomeDayPart.evening;
    return HomeDayPart.night;
  }

  @override
  List<Object?> get props => [dayPart, firstName];
}
