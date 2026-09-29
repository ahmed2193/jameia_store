import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/screen_load.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/support/domain/entities/order_help_issue.dart';
import 'package:hero_mart/src/features/support/domain/entities/order_help_request.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_category.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_category_entity.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_ticket_draft.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_ticket_receipt.dart';
import 'package:hero_mart/src/features/support/domain/repositories/support_tickets_repository.dart';
import 'package:hero_mart/src/features/support/domain/usecases/create_support_ticket_usecase.dart';
import 'package:hero_mart/src/features/support/domain/usecases/get_support_categories_usecase.dart';
import 'package:hero_mart/src/features/support/presentation/cubit/order_help_cubit.dart';

const List<SupportCategoryEntity> _categories = <SupportCategoryEntity>[
  SupportCategoryEntity(
    category: SupportCategory.order,
    requireOrder: true,
    topics: <SupportTopicEntity>[
      SupportTopicEntity(
        topic: SupportTopic.missingItems,
        requireOrder: true,
        requireProducts: true,
      ),
      SupportTopicEntity(topic: SupportTopic.late, requireOrder: true),
    ],
  ),
];

const OrderHelpIssue _missing = OrderHelpIssue(
  category: SupportCategory.order,
  topic: SupportTopic.missingItems,
  requireProducts: true,
);
const OrderHelpIssue _late = OrderHelpIssue(
  category: SupportCategory.order,
  topic: SupportTopic.late,
);

/// Every call waits for the test to answer it.
class _GatedRepository implements SupportTicketsRepository {
  final List<Completer<Either<Failure, List<SupportCategoryEntity>>>> reads =
      [];
  final List<Completer<Either<Failure, SupportTicketReceipt>>> sends = [];
  final List<SupportTicketDraft> drafts = [];

  @override
  Future<Either<Failure, List<SupportCategoryEntity>>> getCategories() {
    final call = Completer<Either<Failure, List<SupportCategoryEntity>>>();
    reads.add(call);
    return call.future;
  }

  @override
  Future<Either<Failure, SupportTicketReceipt>> createTicket(
    SupportTicketDraft draft,
  ) {
    drafts.add(draft);
    final call = Completer<Either<Failure, SupportTicketReceipt>>();
    sends.add(call);
    return call.future;
  }
}

void main() {
  late _GatedRepository repository;
  late OrderHelpCubit cubit;
  final at = DateTime.utc(2026, 9, 28, 12);

  setUp(() {
    repository = _GatedRepository();
    cubit = OrderHelpCubit(
      getCategories: GetSupportCategoriesUseCase(repository),
      createTicket: CreateSupportTicketUseCase(repository),
      clock: () => at,
    );
  });

  tearDown(() => cubit.close());

  Future<void> loaded() async {
    final load = cubit.load();
    repository.reads.last.complete(const Right(_categories));
    await load;
  }

  Future<bool> send() => cubit.send(
    orderId: 'o1',
    subject: 'Order #1001: Missing items',
    fallbackBody: 'Problem with order #1001: Missing items.',
  );

  test('the skeleton, then the grouped options', () async {
    final load = cubit.load();
    expect(cubit.state.load.phase, LoadPhase.loading);

    repository.reads.single.complete(const Right(_categories));
    await load;

    expect(cubit.state.load.isLoaded, isTrue);
    expect(cubit.state.groups, OrderHelpIssueGroup.listOf(_categories));
    expect(cubit.state.groups.last.issues, <OrderHelpIssue>[
      OrderHelpIssue.somethingElse,
    ]);
  });

  test('a failed read is the full-screen state; the connection back reads '
      'again', () async {
    final load = cubit.load();
    repository.reads.single.complete(const Left(NetworkFailure()));
    await load;

    expect(cubit.state.loadFailure, isA<NetworkFailure>());
    expect(cubit.state.load.needsRefresh, isTrue);

    final again = cubit.onReconnected();
    expect(repository.reads, hasLength(2));
    repository.reads.last.complete(const Right(_categories));
    await again;

    expect(cubit.state.loadFailure, isNull);
    expect(cubit.state.load.isLoaded, isTrue);

    // Loaded: a returning connection has nothing to read.
    await cubit.onReconnected();
    expect(repository.reads, hasLength(2));
  });

  test('a reply older than the last request is dropped', () async {
    final first = cubit.load();
    final second = cubit.load();

    repository.reads[1].complete(const Right(_categories));
    await second;
    repository.reads[0].complete(const Left(ServerFailure('late 500')));
    await first;

    expect(cubit.state.load.isLoaded, isTrue);
    expect(cubit.state.loadFailure, isNull);
  });

  test('the picks and the note build the request', () async {
    await loaded();

    cubit
      ..selectIssue(_missing)
      ..toggleProduct('p2')
      ..toggleProduct('p1')
      ..setNote('Two bags never came');

    expect(
      cubit.state.request,
      const OrderHelpRequest(
        issue: _missing,
        productIds: <String>{'p1', 'p2'},
        note: 'Two bags never came',
      ),
    );
    expect(cubit.state.canSend, isTrue);
  });

  test('sending opens one ticket; the page thanks the customer', () async {
    await loaded();
    cubit
      ..selectIssue(_missing)
      ..toggleProduct('p2')
      ..toggleProduct('p1');

    final sending = send();
    expect(cubit.state.isSending, isTrue);
    expect(cubit.state.canSend, isFalse);

    repository.sends.single.complete(
      const Right(SupportTicketReceipt(ticketId: 't-42')),
    );
    expect(await sending, isTrue);

    expect(cubit.state.isSending, isFalse);
    expect(cubit.state.sent, isTrue);
    expect(cubit.state.receipt?.ticketId, 't-42');
    expect(
      repository.drafts.single,
      const SupportTicketDraft(
        subject: 'Order #1001: Missing items',
        category: SupportCategory.order,
        topic: SupportTopic.missingItems,
        orderId: 'o1',
        productIds: <String>['p1', 'p2'],
        body: 'Problem with order #1001: Missing items.',
      ),
    );

    // Sent: nothing changes the request any more, nothing sends again.
    cubit
      ..selectIssue(_late)
      ..setNote('more');
    expect(cubit.state.request.issue, _missing);
    expect(await send(), isFalse);
    expect(repository.sends, hasLength(1));
  });

  test('a second tap while sending sends nothing', () async {
    await loaded();
    cubit.selectIssue(_late);

    final first = send();
    final second = send();
    expect(await second, isFalse);
    expect(repository.sends, hasLength(1));

    repository.sends.single.complete(
      const Right(SupportTicketReceipt(ticketId: 't1')),
    );
    expect(await first, isTrue);
  });

  test('a failed send keeps every pick and word, and is told as an '
      'action', () async {
    await loaded();
    cubit
      ..selectIssue(_missing)
      ..toggleProduct('p1')
      ..setNote('Two bags never came');
    final request = cubit.state.request;

    final sending = send();
    repository.sends.single.complete(const Left(NetworkFailure()));
    expect(await sending, isFalse);

    expect(cubit.state.isSending, isFalse);
    expect(cubit.state.sent, isFalse);
    expect(cubit.state.request, request);
    expect(cubit.state.load.isLoaded, isTrue);
    expect(cubit.state.load.toldFailure, isA<NetworkFailure>());
    expect(cubit.state.load.failedOnAction, isTrue);

    // The next change drops the told failure; a retry sends again.
    cubit.setNote('Two bags never came, again');
    expect(cubit.state.load.toldFailure, isNull);
    final retry = send();
    repository.sends.last.complete(
      const Right(SupportTicketReceipt(ticketId: 't2')),
    );
    expect(await retry, isTrue);
    expect(repository.sends, hasLength(2));
  });

  test('nothing is sent while something is missing', () async {
    await loaded();
    expect(await send(), isFalse);

    cubit.selectIssue(_missing);
    expect(cubit.state.request.gap, OrderHelpGap.products);
    expect(await send(), isFalse);
    expect(repository.sends, isEmpty);
  });
}
