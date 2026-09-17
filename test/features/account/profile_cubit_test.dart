import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/account/domain/entities/profile_update.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/profile_cubit.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/profile_state.dart';

import 'account_test_fakes.dart';

void main() {
  late FakeGetProfileUseCase getProfile;
  late FakeUpdateProfileUseCase updateProfile;

  final fresh = kProfileCustomer.copyWithName('Ahmed Ali');

  ProfileCubit build({AuthCustomerEntity? initial}) => ProfileCubit(
    getProfile: getProfile,
    updateProfile: updateProfile,
    initial: initial,
  );

  setUp(() {
    getProfile = FakeGetProfileUseCase(Right(fresh));
    updateProfile = FakeUpdateProfileUseCase(Right(fresh));
  });

  group('load', () {
    blocTest<ProfileCubit, ProfileState>(
      'without a known customer: loading → ready with the server record',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        ProfileState.fromCustomer(fresh),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'seeded from the session: form is ready at once, then refreshed',
      build: () => build(initial: kProfileCustomer),
      act: (cubit) => cubit.load(),
      expect: () => [ProfileState.fromCustomer(fresh)],
      verify: (cubit) => expect(cubit.state.name, 'Ahmed Ali'),
    );

    blocTest<ProfileCubit, ProfileState>(
      'a refresh never overwrites a draft the user already edited',
      build: () => build(initial: kProfileCustomer),
      act: (cubit) async {
        cubit.nameChanged('My edit');
        await cubit.load();
      },
      verify: (cubit) {
        expect(cubit.state.name, 'My edit');
        expect(cubit.state.customer, fresh);
      },
    );

    blocTest<ProfileCubit, ProfileState>(
      'failure without a customer → error; with one → stays ready',
      build: () {
        getProfile.result = const Left(NetworkFailure());
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        const ProfileState(
          status: ProfileStatus.error,
          failure: NetworkFailure(),
        ),
      ],
    );
  });

  group('save', () {
    blocTest<ProfileCubit, ProfileState>(
      'invalid form → shows errors, no request',
      build: () => build(initial: kProfileCustomer),
      act: (cubit) async {
        cubit.nameChanged('   ');
        await cubit.save();
      },
      verify: (cubit) {
        expect(cubit.state.showNameError, isTrue);
        expect(updateProfile.calls, isEmpty);
      },
    );

    blocTest<ProfileCubit, ProfileState>(
      'unchanged form → nothing sent',
      build: () => build(initial: kProfileCustomer),
      act: (cubit) => cubit.save(),
      expect: () => <ProfileState>[],
      verify: (_) => expect(updateProfile.calls, isEmpty),
    );

    blocTest<ProfileCubit, ProfileState>(
      'sends the diff; saved state carries the server customer',
      build: () => build(initial: kProfileCustomer),
      act: (cubit) async {
        cubit.nameChanged('Ahmed Ali');
        cubit.emailChanged('');
        cubit.genderChanged(null);
        await cubit.save();
      },
      verify: (cubit) {
        expect(
          updateProfile.calls.single.update,
          const ProfileUpdate(name: 'Ahmed Ali', email: '', clearGender: true),
        );
        expect(cubit.state.status, ProfileStatus.saved);
        expect(cubit.state.customer, fresh);
        expect(cubit.state.isDirty, isFalse);
      },
    );

    test('a refresh landing mid-save never re-enables the button', () async {
      getProfile.gate = Completer<void>();
      updateProfile.gate = Completer<void>();
      final cubit = build(initial: kProfileCustomer);
      final statuses = <ProfileStatus>[];
      final subscription = cubit.stream.listen((s) => statuses.add(s.status));

      final loading = cubit.load(); // held
      cubit.nameChanged('Ahmed Ali');
      final saving = cubit.save(); // held → status saving
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.isSaving, isTrue);

      getProfile.gate!.complete(); // the refresh lands DURING the save
      await loading;
      expect(cubit.state.isSaving, isTrue, reason: 'load must not flip it');
      expect(cubit.state.canSave, isFalse);
      await cubit.save(); // a second tap is still a no-op
      expect(updateProfile.calls, hasLength(1));

      updateProfile.gate!.complete();
      await saving;
      await Future<void>.delayed(Duration.zero); // let the stream deliver
      expect(cubit.state.status, ProfileStatus.saved);
      await subscription.cancel();
      await cubit.close();

      expect(
        statuses.skipWhile((s) => s != ProfileStatus.saving),
        isNot(contains(ProfileStatus.ready)),
      );
    });

    blocTest<ProfileCubit, ProfileState>(
      'backend rejection → error with the failure, draft kept',
      build: () {
        updateProfile.result = const Left(
          ServerFailure(
            'Validation failed',
            statusCode: 400,
            code: 'VALIDATION_ERROR',
          ),
        );
        return build(initial: kProfileCustomer);
      },
      act: (cubit) async {
        cubit.nameChanged('Ahmed Ali');
        await cubit.save();
      },
      verify: (cubit) {
        expect(cubit.state.status, ProfileStatus.error);
        expect(cubit.state.failure, isA<ServerFailure>());
        expect(cubit.state.name, 'Ahmed Ali');
      },
    );
  });
}

extension on AuthCustomerEntity {
  AuthCustomerEntity copyWithName(String name) => AuthCustomerEntity(
    id: this.id,
    phone: phone,
    nameEn: name,
    nameAr: name,
    email: email,
    language: language,
    walletFils: walletFils,
    gender: gender,
  );
}
