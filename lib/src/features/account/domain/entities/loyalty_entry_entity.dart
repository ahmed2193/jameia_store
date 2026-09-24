import 'ledger_entry.dart';

/// Why the points balance moved (`type` of a points transaction). Unknown
/// wire values are [other]: the backend may add kinds without an app release.
enum LoyaltyEntryKind {
  earn,
  redeem,
  expire,
  welcomeBonus,
  profileBonus,
  refundRestore,
  adminAdjustment,
  other,
}

/// One points transaction. [points] is signed: earned > 0, spent < 0.
class LoyaltyEntryEntity extends LedgerEntry {
  const LoyaltyEntryEntity({
    required this.id,
    required this.kind,
    required this.points,
    required this.createdAt,
    this.expiresAt,
  });

  @override
  final String id;
  final LoyaltyEntryKind kind;
  final int points;
  final DateTime createdAt;

  /// When points earned by this line lapse; `null` when they do not.
  final DateTime? expiresAt;

  bool get isCredit => points > 0;

  @override
  List<Object?> get props => [id, kind, points, createdAt, expiresAt];
}
