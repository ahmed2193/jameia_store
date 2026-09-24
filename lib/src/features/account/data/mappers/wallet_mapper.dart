import '../../domain/entities/ledger.dart';
import '../../domain/entities/wallet_entry_entity.dart';
import '../models/ledger_page_model.dart';
import '../models/wallet_entry_model.dart';

extension WalletEntryMapper on WalletEntryModel {
  static const String _refund = 'refund';
  static const String _checkout = 'checkout';
  static const String _cashback = 'cashback';
  static const String _adminAdjustment = 'admin_adjustment';
  static const String _promo = 'promo';

  WalletEntryEntity toEntity() => WalletEntryEntity(
    id: id,
    kind: switch (type) {
      _refund => WalletEntryKind.refund,
      _checkout => WalletEntryKind.checkout,
      _cashback => WalletEntryKind.cashback,
      _adminAdjustment => WalletEntryKind.adminAdjustment,
      _promo => WalletEntryKind.promo,
      _ => WalletEntryKind.other,
    },
    amountFils: amount,
    createdAt: createdAt,
    note: note,
  );
}

extension WalletLedgerMapper on LedgerPageModel<WalletEntryModel> {
  Ledger<WalletEntryEntity> toEntity() => Ledger<WalletEntryEntity>(
    balance: balance,
    entries: [for (final item in items) item.toEntity()],
    page: page,
    hasMore: hasMore,
  );
}
