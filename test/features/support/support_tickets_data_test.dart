import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/network/dio_consumer.dart';
import 'package:hero_mart/src/features/support/data/datasources/support_remote_data_source.dart';
import 'package:hero_mart/src/features/support/data/mappers/support_tickets_mapper.dart';
import 'package:hero_mart/src/features/support/data/models/support_category_model.dart';
import 'package:hero_mart/src/features/support/data/repositories/support_tickets_repository_impl.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_category.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_category_entity.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_ticket_draft.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_ticket_receipt.dart';

import '../../core/network/network_test_fakes.dart';

/// `GET /v1/support/categories` as the live API answers it, with a few
/// rows this build cannot use.
Map<String, dynamic> categoriesJson() => <String, dynamic>{
  'data': <Object?>[
    <String, dynamic>{
      'key': 'order',
      'requireOrder': true,
      'requireProducts': false,
      'children': <Object?>[
        <String, dynamic>{
          'key': 'missing_items',
          'requireOrder': true,
          'requireProducts': true,
        },
        <String, dynamic>{'key': 'late', 'requireOrder': true},
        <String, dynamic>{'key': 'teleported'}, // unknown topic
        <String, dynamic>{'requireOrder': true}, // no key
        'not a row',
      ],
    },
    <String, dynamic>{'key': 'hologram'}, // unknown category
    <String, dynamic>{
      'key': 'account',
      'children': <Object?>[
        <String, dynamic>{'key': 'login'},
      ],
    },
    <String, dynamic>{'key': 'other'},
  ],
};

const SupportTicketDraft _draft = SupportTicketDraft(
  subject: '  Order #1001: Missing items ',
  category: SupportCategory.order,
  topic: SupportTopic.missingItems,
  orderId: 'o1',
  productIds: <String>['p1', 'p2'],
  body: ' Two bags never came. ',
);

void main() {
  late FakeHttpClientAdapter adapter;

  SupportRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
    adapter = transport;
    return SupportRemoteDataSourceImpl(
      DioConsumer(Dio()..httpClientAdapter = transport),
    );
  }

  RequestOptions request() => adapter.requests.single;
  Map<String, dynamic> body() =>
      jsonDecode(jsonEncode(request().data)) as Map<String, dynamic>;

  group('categories', () {
    test('GETs the taxonomy; unknown keys and bad rows are left out', () async {
      final dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody(categoriesJson())),
      );

      final categories = (await dataSource.getCategories()).toEntities();

      expect(request().method, 'GET');
      expect(request().path, '/v1/support/categories');
      expect(categories, const <SupportCategoryEntity>[
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
        SupportCategoryEntity(
          category: SupportCategory.account,
          topics: <SupportTopicEntity>[
            SupportTopicEntity(topic: SupportTopic.login),
          ],
        ),
        SupportCategoryEntity(category: SupportCategory.other),
      ]);
    });

    test('a category without a key is skipped, not the list', () {
      final model = SupportCategoriesModel.fromJson(<String, dynamic>{
        'data': <Object?>[
          <String, dynamic>{'requireOrder': true},
          <String, dynamic>{'key': 'delivery'},
        ],
      });

      expect(model.categories.map((row) => row.key), <String>['delivery']);
    });

    test('a payload without data is an empty taxonomy', () {
      expect(
        SupportCategoriesModel.fromJson(<String, dynamic>{}).categories,
        isEmpty,
      );
    });
  });

  group('tickets', () {
    test('the body carries only what the ticket has, trimmed', () {
      expect(_draft.toBody(), <String, dynamic>{
        'subject': 'Order #1001: Missing items',
        'category': 'order',
        'subcategory': 'missing_items',
        'orderId': 'o1',
        'productIds': <String>['p1', 'p2'],
        'body': 'Two bags never came.',
      });
      expect(
        const SupportTicketDraft(
          subject: 'Help',
          category: SupportCategory.other,
          body: 'Something else',
        ).toBody(),
        <String, dynamic>{
          'subject': 'Help',
          'category': 'other',
          'body': 'Something else',
        },
      );
    });

    test('POSTs the ticket and reads the receipt', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => envelope(
            status: 201,
            statusMessage: 'SUCCESS',
            results: <String, dynamic>{
              'message': 'Ticket created',
              'ticketId': 't-42',
            },
          ),
        ),
      );

      final receipt = (await dataSource.createTicket(_draft.toBody()))
          .toEntity();

      expect(request().method, 'POST');
      expect(request().path, '/v1/support/tickets');
      expect(body()['orderId'], 'o1');
      expect(body()['productIds'], <Object?>['p1', 'p2']);
      expect(
        receipt,
        const SupportTicketReceipt(ticketId: 't-42', message: 'Ticket created'),
      );
    });

    test('a receipt without a ticket id is a parsing error', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody(<String, dynamic>{'message': 'ok'}),
        ),
      );

      expect(
        () => dataSource.createTicket(_draft.toBody()),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('repository', () {
    test('a 401 is UnauthorizedFailure (the page sends to sign in)', () async {
      final repository = SupportTicketsRepositoryImpl(
        build(
          FakeHttpClientAdapter(
            (_, _) => envelope(
              status: 401,
              statusMessage: 'UNAUTHORIZED',
              errorMessage: 'Sign in first',
            ),
          ),
        ),
      );

      final result = await repository.createTicket(_draft);

      expect(
        result.fold((failure) => failure, (_) => null),
        isA<UnauthorizedFailure>(),
      );
    });

    test('no connection is NetworkFailure', () async {
      final repository = SupportTicketsRepositoryImpl(
        build(
          FakeHttpClientAdapter(
            (options, _) => throw DioException.connectionError(
              requestOptions: options,
              reason: 'refused',
            ),
          ),
        ),
      );

      final result = await repository.getCategories();

      expect(
        result.fold((failure) => failure, (_) => null),
        isA<NetworkFailure>(),
      );
    });

    test('the categories map to entities', () async {
      final repository = SupportTicketsRepositoryImpl(
        build(FakeHttpClientAdapter((_, _) => okBody(categoriesJson()))),
      );

      final result = await repository.getCategories();

      expect(
        result
            .getOrElse(() => const <SupportCategoryEntity>[])
            .map((category) => category.category),
        <SupportCategory>[
          SupportCategory.order,
          SupportCategory.account,
          SupportCategory.other,
        ],
      );
    });
  });
}
