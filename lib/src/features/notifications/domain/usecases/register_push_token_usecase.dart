import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/notifications_repository.dart';

class RegisterPushTokenParams extends Equatable {
  const RegisterPushTokenParams({required this.token, required this.platform});

  /// Backend accepts 10–256 characters.
  static const int minTokenLength = 10;
  static const int maxTokenLength = 256;

  static const String platformIos = 'ios';
  static const String platformAndroid = 'android';

  final String token;

  /// [platformIos] or [platformAndroid].
  final String platform;

  bool get isValid =>
      token.length >= minTokenLength &&
      token.length <= maxTokenLength &&
      (platform == platformIos || platform == platformAndroid);

  @override
  List<Object?> get props => [token, platform];
}

/// Registers the device push token for the signed-in customer. An invalid
/// token / platform never reaches the network.
class RegisterPushTokenUseCase
    implements UseCase<Unit, RegisterPushTokenParams> {
  const RegisterPushTokenUseCase(this._repository);

  static const String invalidParamsMessage = 'Invalid push token or platform';

  final NotificationsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(RegisterPushTokenParams params) async {
    if (!params.isValid) {
      return const Left(UnexpectedFailure(invalidParamsMessage));
    }
    return _repository.registerPushToken(
      token: params.token,
      platform: params.platform,
    );
  }
}
