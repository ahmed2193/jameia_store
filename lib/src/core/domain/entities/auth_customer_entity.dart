import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';

/// `gender` as the backend enumerates it (`male` | `female`).
enum CustomerGender { male, female }

/// The signed-in customer as the backend returns it on OTP verification,
/// `GET /v1/account/me` and `PATCH /v1/account/profile`. Shared: the auth
/// feature produces it, the app-global session state carries it, the account
/// feature edits it, and any feature may greet the user with it.
///
/// Money is in fils (`1250` = 1.250 KWD); raw bilingual name — pick with
/// [nameFor] / [displayNameFor].
///
/// Reference: https://docs.jm3eia.store/developers/account.html
class AuthCustomerEntity extends Equatable {
  const AuthCustomerEntity({
    required this.id,
    required this.phone,
    this.nameEn = '',
    this.nameAr = '',
    this.email = '',
    this.language = '',
    this.walletFils = 0,
    this.loyaltyPoints = 0,
    this.isActive = true,
    this.isPro = false,
    this.proExpiresAt,
    this.dateOfBirth,
    this.gender,
    this.householdSize,
    this.marketingPush = true,
  });

  static const int filsPerDinar = 1000;

  final String id;
  final String phone;
  final String nameEn;
  final String nameAr;
  final String email;

  /// Preferred language (`en` / `ar`) stored on the account; empty when the
  /// customer never chose one. Drives backend notifications / emails.
  final String language;

  /// Wallet balance in fils.
  final int walletFils;
  final int loyaltyPoints;
  final bool isActive;

  /// Active Pro subscription (free delivery, points multiplier, discount).
  final bool isPro;
  final DateTime? proExpiresAt;
  final DateTime? dateOfBirth;
  final CustomerGender? gender;
  final int? householdSize;

  /// Opted in to marketing push notifications.
  final bool marketingPush;

  String nameFor(String languageCode) =>
      pickLocalized(languageCode, en: nameEn, ar: nameAr);

  /// The name in the active language, falling back to the phone number.
  String displayNameFor(String languageCode) {
    final name = nameFor(languageCode);
    return name.isNotEmpty ? name : phone;
  }

  /// Wallet balance in Kuwaiti dinar (3 decimals: 1250 fils → 1.25).
  double get walletKd => walletFils / filsPerDinar;

  bool get hasLanguagePreference => language.isNotEmpty;

  /// The raw name regardless of language — the backend stores ONE string
  /// (both fields hold it), so this is what a profile form edits.
  String get anyName => nameEn.isNotEmpty ? nameEn : nameAr;

  @override
  List<Object?> get props => [
    id,
    phone,
    nameEn,
    nameAr,
    email,
    language,
    walletFils,
    loyaltyPoints,
    isActive,
    isPro,
    proExpiresAt,
    dateOfBirth,
    gender,
    householdSize,
    marketingPush,
  ];
}
