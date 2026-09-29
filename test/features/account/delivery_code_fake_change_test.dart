// B1-15 "fake change on open": the delivery code's first load is not a
// change (its digits appear at once); only a save that changes the code is
// one, and only then do the digits flip.
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/motion/flip_value.dart';
import 'package:hero_mart/src/core/usecase/usecase.dart';
import 'package:hero_mart/src/features/account/domain/usecases/get_delivery_code_usecase.dart';
import 'package:hero_mart/src/features/account/presentation/cubit/delivery_code_cubit.dart';

class _FakeGetDeliveryCode implements GetDeliveryCodeUseCase {
  _FakeGetDeliveryCode(this.code);

  final String code;

  @override
  Future<Either<Failure, String>> call(NoParams params) async => Right(code);
}

void main() {
  group('DeliveryCodeCubit', () {
    blocTest<DeliveryCodeCubit, DeliveryCodeState>(
      'the first load is not a change',
      build: () => DeliveryCodeCubit(_FakeGetDeliveryCode('4821')),
      wait: Duration.zero,
      verify: (cubit) {
        expect(cubit.state.status, DeliveryCodeStatus.loaded);
        expect(cubit.state.savedCode, '4821');
        expect(cubit.state.savedRevision, 0);
      },
    );

    blocTest<DeliveryCodeCubit, DeliveryCodeState>(
      'a save that changes the code is one change; a no-op save is none',
      build: () => DeliveryCodeCubit(_FakeGetDeliveryCode('4821')),
      act: (cubit) async {
        await Future<void>.delayed(Duration.zero);
        cubit
          ..save() // nothing new to save
          ..edit('1357')
          ..save();
      },
      verify: (cubit) {
        expect(cubit.state.savedCode, '1357');
        expect(cubit.state.savedRevision, 1);
      },
    );
  });

  group('FlipValue', () {
    Widget flip(String value, {required bool animate}) => Directionality(
      textDirection: TextDirection.ltr,
      child: FlipValue(flipKey: value, animate: animate, child: Text(value)),
    );

    testWidgets('a key change that is not a real change swaps in place', (
      tester,
    ) async {
      await tester.pumpWidget(flip('', animate: false));
      await tester.pumpWidget(flip('4', animate: false));
      await tester.pump();

      expect(find.byType(Text), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('a real change flips: old and new share the frame', (
      tester,
    ) async {
      await tester.pumpWidget(flip('4', animate: true));
      await tester.pumpWidget(flip('7', animate: true));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('4'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('4'), findsNothing);
    });
  });
}
