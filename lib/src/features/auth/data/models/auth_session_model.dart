import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/auth_tokens.dart';
import '../../../../core/data/models/customer_model.dart';

/// `results` of `POST /v1/auth/verify-otp`:
/// `{ customer: {...}, accessToken, refreshToken, tokenType, expiresIn }`.
class AuthSessionModel {
  const AuthSessionModel({required this.customer, required this.tokens});

  static const String customerKey = 'customer';

  /// Throws [ParsingException] when the customer object or a token is missing.
  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final customer = json[customerKey];
    if (customer is! Map) {
      throw const ParsingException('verify-otp: customer missing');
    }
    return AuthSessionModel(
      customer: CustomerModel.fromJson(customer.cast<String, dynamic>()),
      tokens: AuthTokens.fromJson(json),
    );
  }

  final CustomerModel customer;
  final AuthTokens tokens;
}
