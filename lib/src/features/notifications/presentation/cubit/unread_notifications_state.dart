import 'package:equatable/equatable.dart';

/// App-global badge state: the customer's unread count and whether the live
/// (SSE) connection is being listened to.
class UnreadNotificationsState extends Equatable {
  const UnreadNotificationsState({this.unreadCount = 0, this.isLive = false});

  final int unreadCount;
  final bool isLive;

  bool get hasUnread => unreadCount > 0;

  UnreadNotificationsState copyWith({int? unreadCount, bool? isLive}) =>
      UnreadNotificationsState(
        unreadCount: unreadCount ?? this.unreadCount,
        isLive: isLive ?? this.isLive,
      );

  @override
  List<Object?> get props => [unreadCount, isLive];
}
