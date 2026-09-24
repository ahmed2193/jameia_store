import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/usecase/usecase.dart';
import 'package:jameia_mart/src/features/account/domain/entities/ledger.dart';
import 'package:jameia_mart/src/features/account/domain/entities/ledger_entry.dart';
import 'package:jameia_mart/src/features/account/domain/entities/loyalty_program.dart';
import 'package:jameia_mart/src/features/account/domain/usecases/get_ledger_usecase.dart';
import 'package:jameia_mart/src/features/account/domain/usecases/get_loyalty_program_usecase.dart';
import 'package:jameia_mart/src/features/account/domain/usecases/get_profile_usecase.dart';
import 'package:jameia_mart/src/features/account/domain/usecases/update_profile_usecase.dart';

const AuthCustomerEntity kProfileCustomer = AuthCustomerEntity(
  id: '507f1f77bcf86cd799439011',
  phone: '+96512345678',
  nameEn: 'Ahmed',
  nameAr: 'Ahmed',
  email: 'ahmed@jm3eia.com',
  language: 'en',
  walletFils: 1250,
  gender: CustomerGender.male,
);

class FakeGetProfileUseCase implements GetProfileUseCase {
  FakeGetProfileUseCase(this.result);

  Either<Failure, AuthCustomerEntity> result;
  int calls = 0;

  /// When set, the reply is held until the gate completes (in-flight races).
  Completer<void>? gate;

  @override
  Future<Either<Failure, AuthCustomerEntity>> call(NoParams params) async {
    calls++;
    await gate?.future;
    return result;
  }
}

class FakeUpdateProfileUseCase implements UpdateProfileUseCase {
  FakeUpdateProfileUseCase(this.result);

  Either<Failure, AuthCustomerEntity> result;
  final List<UpdateProfileParams> calls = [];

  /// When set, the reply is held until the gate completes (in-flight races).
  Completer<void>? gate;

  @override
  Future<Either<Failure, AuthCustomerEntity>> call(
    UpdateProfileParams params,
  ) async {
    calls.add(params);
    await gate?.future;
    return result;
  }
}

/// Answers every page request through [handler] (hold one on a gate there to
/// build an in-flight race); records the params.
class FakeGetLedgerUseCase<T extends LedgerEntry>
    implements GetLedgerUseCase<T> {
  FakeGetLedgerUseCase(this.handler);

  Future<Either<Failure, Ledger<T>>> Function(GetLedgerParams params) handler;
  final List<GetLedgerParams> calls = [];

  @override
  Future<Either<Failure, Ledger<T>>> call(GetLedgerParams params) {
    calls.add(params);
    return handler(params);
  }
}

class FakeGetLoyaltyProgramUseCase implements GetLoyaltyProgramUseCase {
  FakeGetLoyaltyProgramUseCase(this.result);

  Either<Failure, LoyaltyProgram> result;
  int calls = 0;

  @override
  Future<Either<Failure, LoyaltyProgram>> call(NoParams params) async {
    calls++;
    return result;
  }
}
