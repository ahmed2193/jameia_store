import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/orders/domain/usecases/get_order_usecase.dart';
import 'package:jameia_mart/src/features/orders/domain/usecases/submit_product_review_usecase.dart';
import 'package:jameia_mart/src/features/orders/presentation/cubit/order_review_cubit.dart';

import 'fake_orders_repository.dart';

import 'package:jameia_mart/src/features/orders/presentation/cubit/order_review_state.dart';

void main() {
  late FakeOrdersRepository repository;

  OrderReviewCubit build() {
    repository = FakeOrdersRepository();
    return OrderReviewCubit(
      getOrder: GetOrderUseCase(repository),
      submitReview: SubmitProductReviewUseCase(repository),
    );
  }

  test('nothing can be submitted before a product is rated', () async {
    final cubit = build();

    await cubit.load('o1');

    expect(cubit.state.status, OrderReviewStatus.loaded);
    expect(cubit.state.canSubmit, isFalse);
    await cubit.close();
  });

  test('submit sends one review per rated product, with the comment', () async {
    final cubit = build();
    await cubit.load('o1');

    cubit
      ..rate('p1', 5)
      ..setComment('  great  ');
    final submitted = await cubit.submit();

    expect(submitted, isTrue);
    expect(repository.reviewCalls, 1);
    expect(repository.calls, contains('review:p1:5'));
    expect(cubit.state.submitted, isTrue);
    await cubit.close();
  });

  test('a product left at zero stars is not reviewed', () async {
    final cubit = build();
    await cubit.load('o1');

    cubit
      ..rate('p1', 4)
      ..rate('p2', 0);
    await cubit.submit();

    expect(repository.reviewCalls, 1);
    await cubit.close();
  });

  test('a rejected review reports the failure and can be retried', () async {
    final cubit = build();
    await cubit.load('o1');
    cubit.rate('p1', 3);
    repository.reviewFailure = const ServerFailure('nope', statusCode: 400);

    final submitted = await cubit.submit();

    expect(submitted, isFalse);
    expect(cubit.state.submitted, isFalse);
    expect(cubit.state.failedAction, OrderReviewAction.submit);
    expect(cubit.state.canSubmit, isTrue); // the rating is kept for a retry
    await cubit.close();
  });

  test('a comment over the API limit blocks the submit', () async {
    final cubit = build();
    await cubit.load('o1');

    cubit
      ..rate('p1', 5)
      ..setComment('x' * 2001);

    expect(cubit.state.draft.commentTooLong, isTrue);
    expect(cubit.state.canSubmit, isFalse);
    await cubit.close();
  });

  test('a load failure shows the error view', () async {
    final cubit = build();
    repository.detailFailure = const UnauthorizedFailure();

    await cubit.load('o1');

    expect(cubit.state.status, OrderReviewStatus.error);
    expect(cubit.state.isSignedOut, isTrue);
    await cubit.close();
  });

  test(
    'a partial failure keeps the stars of the reviews that went through',
    () async {
      final cubit = build();
      await cubit.load('o1');
      cubit
        ..rate('p1', 5)
        ..rate('p2', 4);
      // The first review is accepted, the second is refused.
      repository.reviewFailureAfter = 1;

      final submitted = await cubit.submit();

      expect(submitted, isFalse);
      expect(cubit.state.draft.ratingOf('p1'), 5, reason: 'it was accepted');
      expect(cubit.state.draft.isSent('p1'), isTrue);
      expect(cubit.state.draft.ratingOf('p2'), 4, reason: 'it can be retried');
      expect(cubit.state.draft.isSent('p2'), isFalse);
      await cubit.close();
    },
  );

  test('a retry after a partial failure sends only what is left', () async {
    final cubit = build();
    await cubit.load('o1');
    cubit
      ..rate('p1', 5)
      ..rate('p2', 4);
    repository.reviewFailureAfter = 1;
    await cubit.submit();
    repository
      ..calls.clear()
      ..reviewFailureAfter = null;

    final submitted = await cubit.submit();

    expect(submitted, isTrue);
    expect(repository.calls, <String>['review:p2:4']);
    expect(cubit.state.submitted, isTrue);
    await cubit.close();
  });
}
