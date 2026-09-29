import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/order_line_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/support/domain/entities/order_help_issue.dart';
import 'package:hero_mart/src/features/support/domain/entities/order_help_request.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_category.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_category_entity.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_ticket_draft.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_ticket_receipt.dart';
import 'package:hero_mart/src/features/support/domain/repositories/support_tickets_repository.dart';
import 'package:hero_mart/src/features/support/domain/usecases/create_support_ticket_usecase.dart';

const OrderHelpIssue _missing = OrderHelpIssue(
  category: SupportCategory.order,
  topic: SupportTopic.missingItems,
  requireProducts: true,
);
const OrderHelpIssue _late = OrderHelpIssue(
  category: SupportCategory.delivery,
  topic: SupportTopic.late,
);

const List<OrderLineEntity> _lines = <OrderLineEntity>[
  OrderLineEntity(key: 'l1', productId: 'p1', nameEn: 'Milk', quantity: 2),
  OrderLineEntity(key: 'l2', productId: 'p2', nameEn: 'Bread', quantity: 1),
  OrderLineEntity(key: 'l3', productId: 'p3', nameEn: 'Eggs', quantity: 1),
];

class _RecordingRepository implements SupportTicketsRepository {
  final List<SupportTicketDraft> sent = <SupportTicketDraft>[];

  @override
  Future<Either<Failure, List<SupportCategoryEntity>>> getCategories() async =>
      const Right(<SupportCategoryEntity>[]);

  @override
  Future<Either<Failure, SupportTicketReceipt>> createTicket(
    SupportTicketDraft draft,
  ) async {
    sent.add(draft);
    return const Right(SupportTicketReceipt(ticketId: 't1'));
  }
}

void main() {
  group('OrderHelpIssueGroup.listOf', () {
    const categories = <SupportCategoryEntity>[
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
      // Account problems are not about an order.
      SupportCategoryEntity(
        category: SupportCategory.account,
        topics: <SupportTopicEntity>[
          SupportTopicEntity(topic: SupportTopic.login),
        ],
      ),
      // One topic names the order: the category is an order problem.
      SupportCategoryEntity(
        category: SupportCategory.payment,
        requireProducts: true,
        topics: <SupportTopicEntity>[
          SupportTopicEntity(
            topic: SupportTopic.doubleCharge,
            requireOrder: true,
          ),
        ],
      ),
      // A category without topics is one issue of its own.
      SupportCategoryEntity(
        category: SupportCategory.product,
        requireOrder: true,
        requireProducts: true,
      ),
      // The API's "other" never doubles the page's own "Something else".
      SupportCategoryEntity(
        category: SupportCategory.other,
        requireOrder: true,
      ),
    ];

    test('keeps the order problems in the API order, then Something else', () {
      final groups = OrderHelpIssueGroup.listOf(categories);

      expect(groups.map((group) => group.category), <SupportCategory>[
        SupportCategory.order,
        SupportCategory.payment,
        SupportCategory.product,
        SupportCategory.other,
      ]);
      expect(groups.last.issues, <OrderHelpIssue>[
        OrderHelpIssue.somethingElse,
      ]);
    });

    test('an issue needs items when its topic or its category says so', () {
      final groups = OrderHelpIssueGroup.listOf(categories);

      expect(groups[0].issues, <OrderHelpIssue>[
        _missing,
        const OrderHelpIssue(
          category: SupportCategory.order,
          topic: SupportTopic.late,
        ),
      ]);
      expect(groups[1].issues.single.requireProducts, isTrue);
      expect(groups[2].issues, <OrderHelpIssue>[
        const OrderHelpIssue(
          category: SupportCategory.product,
          requireProducts: true,
        ),
      ]);
    });

    test('with nothing from the API, Something else still helps', () {
      expect(
        OrderHelpIssueGroup.listOf(const <SupportCategoryEntity>[]),
        const <OrderHelpIssueGroup>[
          OrderHelpIssueGroup(
            category: SupportCategory.other,
            issues: <OrderHelpIssue>[OrderHelpIssue.somethingElse],
          ),
        ],
      );
    });

    test('every option has a name key', () {
      expect(_missing.labelKey, 'support.topic_missing_items');
      expect(
        OrderHelpIssue.somethingElse.labelKey,
        'support.topic_something_else',
      );
      expect(SupportCategory.delivery.labelKey, 'support.category_delivery');
    });
  });

  group('OrderHelpRequest', () {
    test('says what is missing, first gap first', () {
      const empty = OrderHelpRequest();
      expect(empty.gap, OrderHelpGap.issue);
      expect(empty.canSend, isFalse);

      final missing = empty.withIssue(_missing);
      expect(missing.gap, OrderHelpGap.products);

      final ticked = missing.toggleProduct('p2');
      expect(ticked.gap, isNull);
      expect(ticked.canSend, isTrue);

      final tooLong = ticked.withNote(
        'x' * (SupportTicketDraft.maxBodyLength + 1),
      );
      expect(tooLong.gap, OrderHelpGap.noteTooLong);
      expect(tooLong.canSend, isFalse);
    });

    test('an issue about no items can be sent at once', () {
      expect(const OrderHelpRequest().withIssue(_late).canSend, isTrue);
    });

    test('ticking twice unticks', () {
      final request = const OrderHelpRequest()
          .withIssue(_missing)
          .toggleProduct('p1')
          .toggleProduct('p1');

      expect(request.productIds, isEmpty);
    });

    test('ticks count only under an issue about items', () {
      final ticked = const OrderHelpRequest()
          .withIssue(_missing)
          .toggleProduct('p3')
          .toggleProduct('p1');

      expect(ticked.pickedLines(_lines).map((line) => line.key), <String>[
        'l1',
        'l3',
      ]);
      // Switched to "late": the ticks are kept but not part of it.
      final late = ticked.withIssue(_late);
      expect(late.productIds, <String>{'p1', 'p3'});
      expect(late.picks('p1'), isFalse);
      expect(late.pickedLines(_lines), isEmpty);
    });

    test('the draft: the note, the items sorted, the subject clipped', () {
      final draft = const OrderHelpRequest()
          .withIssue(_missing)
          .toggleProduct('p3')
          .toggleProduct('p1')
          .withNote('  Two bags never came  ')
          .toDraft(
            orderId: 'o1',
            subject: 's' * (SupportTicketDraft.maxSubjectLength + 20),
            fallbackBody: 'unused',
          );

      expect(draft, isNotNull);
      expect(draft!.subject.length, SupportTicketDraft.maxSubjectLength);
      expect(draft.category, SupportCategory.order);
      expect(draft.topic, SupportTopic.missingItems);
      expect(draft.orderId, 'o1');
      expect(draft.productIds, <String>['p1', 'p3']);
      expect(draft.body, 'Two bags never came');
      expect(draft.isValid, isTrue);
    });

    test('without a note the page wording is the body; no items sent', () {
      final draft = const OrderHelpRequest()
          .withIssue(_missing)
          .toggleProduct('p1')
          .withIssue(_late)
          .withNote('   ')
          .toDraft(
            orderId: 'o1',
            subject: 'Order #1001: My order is late',
            fallbackBody: ' Problem with order #1001. ',
          );

      expect(draft!.body, 'Problem with order #1001.');
      expect(draft.productIds, isEmpty);
    });

    test('no draft while it cannot be sent', () {
      expect(
        const OrderHelpRequest()
            .withIssue(_missing)
            .toDraft(orderId: 'o1', subject: 's', fallbackBody: 'b'),
        isNull,
      );
    });
  });

  group('CreateSupportTicketUseCase', () {
    test('a ticket the API would refuse never leaves the app', () async {
      final repository = _RecordingRepository();
      final useCase = CreateSupportTicketUseCase(repository);

      final result = await useCase(
        const CreateSupportTicketParams(
          SupportTicketDraft(
            subject: '  ',
            category: SupportCategory.other,
            body: 'text',
          ),
        ),
      );

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((failure) => failure, (_) => null),
        isA<ValidationFailure>(),
      );
      expect(repository.sent, isEmpty);
    });

    test('a valid ticket goes to the repository', () async {
      final repository = _RecordingRepository();
      const draft = SupportTicketDraft(
        subject: 'Help',
        category: SupportCategory.other,
        body: 'text',
      );

      final result = await CreateSupportTicketUseCase(repository)(
        const CreateSupportTicketParams(draft),
      );

      expect(
        result,
        const Right<Failure, SupportTicketReceipt>(
          SupportTicketReceipt(ticketId: 't1'),
        ),
      );
      expect(repository.sent, <SupportTicketDraft>[draft]);
    });
  });
}
