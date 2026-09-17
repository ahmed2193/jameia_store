import '../../domain/entities/otp_challenge.dart';
import '../../domain/entities/phone_number.dart';
import '../models/otp_challenge_model.dart';

extension OtpChallengeMapper on OtpChallengeModel {
  OtpChallenge toEntity(PhoneNumber phone) =>
      OtpChallenge(phone: phone, message: message, debugCode: code);
}
