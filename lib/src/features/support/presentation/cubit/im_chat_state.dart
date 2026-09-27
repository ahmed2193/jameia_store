import 'package:equatable/equatable.dart';

/// State of the IM rider-chat screen (`im_user_rider_chat`): the rider's
/// name. The message thread and composer are view state kept in the screen.
class ImChatState extends Equatable {
  const ImChatState({this.riderName = fallbackRiderName});

  /// Shown until the rider resolves, and when no order has one.
  static const String fallbackRiderName = 'Rider';

  final String riderName;

  ImChatState copyWith({String? riderName}) =>
      ImChatState(riderName: riderName ?? this.riderName);

  @override
  List<Object?> get props => [riderName];
}
