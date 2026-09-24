import 'ledger_entry.dart';

/// Why the wallet balance moved (`type` of a wallet transaction). Unknown
/// wire values are [other]: the backend may add kinds without an app release.
enum WalletEntryKind {
  refund,
  checkout,
  cashback,
  adminAdjustment,
  promo,
  other,
}

/// One wallet transaction. [amountFils] is signed: credits > 0, debits < 0.
class WalletEntryEntity extends LedgerEntry {
  const WalletEntryEntity({
    required this.id,
    required this.kind,
    required this.amountFils,
    required this.createdAt,
    this.note = '',
  });

  static const int filsPerDinar = 1000;

  @override
  final String id;
  final WalletEntryKind kind;
  final int amountFils;
  final DateTime createdAt;

  /// Free text from the store (a refund reason, a promo name); may be empty.
  final String note;

  bool get isCredit => amountFils > 0;

  /// The signed amount in Kuwaiti dinar (−1250 fils → −1.25).
  double get amountKd => kdOf(amountFils);

  /// [fils] in Kuwaiti dinar — also the wallet balance of a ledger.
  static double kdOf(int fils) => fils / filsPerDinar;

  @override
  List<Object?> get props => [id, kind, amountFils, createdAt, note];
}
