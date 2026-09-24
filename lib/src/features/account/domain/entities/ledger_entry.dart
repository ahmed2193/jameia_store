import 'package:equatable/equatable.dart';

/// One line of an account ledger (the wallet or the loyalty points): what a
/// [Ledger] needs to page through them — a stable id to de-duplicate on.
abstract class LedgerEntry extends Equatable {
  const LedgerEntry();

  String get id;
}
