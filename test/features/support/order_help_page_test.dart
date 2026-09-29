// The order help page ("Get help with this order"): the options arrive
// grouped, an issue about items opens the item picker under it, the send
// pill says what is still missing, a ticket goes out with the ticked items
// and the page's own wording, and the thanks follows — in English and
// Arabic, at 360 dp and text scale 1.3 without overflow. A failed read
// offers a retry; a send answered 401 goes to sign in.
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_line_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/widgets/loader_fail_mark.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_category.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_category_entity.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_ticket_draft.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_ticket_receipt.dart';
import 'package:hero_mart/src/features/support/domain/repositories/support_tickets_repository.dart';
import 'package:hero_mart/src/features/support/domain/usecases/create_support_ticket_usecase.dart';
import 'package:hero_mart/src/features/support/domain/usecases/get_support_categories_usecase.dart';
import 'package:hero_mart/src/features/support/presentation/cubit/order_help_cubit.dart';
import 'package:hero_mart/src/features/support/presentation/pages/order_help_page.dart';
import 'package:hero_mart/src/features/support/presentation/widgets/order_help/order_help_items_picker.dart';
import 'package:hero_mart/src/features/support/presentation/widgets/order_help/order_help_sent_view.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Locale _en = Locale('en');
const Locale _ar = Locale('ar');

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
      SupportTopicEntity(topic: SupportTopic.wrongItems, requireOrder: true),
    ],
  ),
  SupportCategoryEntity(
    category: SupportCategory.delivery,
    requireOrder: true,
    topics: <SupportTopicEntity>[
      SupportTopicEntity(topic: SupportTopic.late, requireOrder: true),
    ],
  ),
  SupportCategoryEntity(
    category: SupportCategory.account,
    topics: <SupportTopicEntity>[SupportTopicEntity(topic: SupportTopic.login)],
  ),
];

final OrderEntity _order = OrderEntity(
  id: 'o1',
  orderNumber: '1001',
  totalFils: 4500,
  createdAt: DateTime.utc(2026, 9, 28, 9, 30),
  lines: const <OrderLineEntity>[
    OrderLineEntity(
      key: 'l1',
      productId: 'p1',
      nameEn: 'Fresh full-fat milk, family size bottle',
      nameAr: 'حليب طازج كامل الدسم عبوة عائلية',
      quantity: 2,
    ),
    OrderLineEntity(
      key: 'l2',
      productId: 'p2',
      nameEn: 'Bread',
      nameAr: 'خبز',
      quantity: 1,
    ),
  ],
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

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting();
  });

  setUp(() {
    repository = _GatedRepository();
    sl.registerFactory<OrderHelpCubit>(
      () => OrderHelpCubit(
        getCategories: GetSupportCategoriesUseCase(repository),
        createTicket: CreateSupportTicketUseCase(repository),
      ),
    );
  });

  tearDown(() async {
    Intl.defaultLocale = null;
    await sl.unregister<OrderHelpCubit>();
  });

  /// The order page at `/`, the help page pushed over it with [_order].
  Future<void> pump(
    WidgetTester tester, {
    Locale locale = _en,
    double textScale = 1,
    Size size = const Size(360, 740),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Intl.defaultLocale = locale.languageCode;
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('order-page')),
        ),
        GoRoute(
          path: Routes.orderHelp,
          builder: (_, state) =>
              OrderHelpPage(order: state.extra! as OrderEntity),
        ),
        GoRoute(
          path: Routes.login,
          builder: (_, _) => const Scaffold(body: Text('login')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[_en, _ar],
          path: 'assets/i18n',
          fallbackLocale: _en,
          startLocale: locale,
          saveLocale: false,
          child: Builder(
            builder: (context) => MaterialApp.router(
              routerConfig: router,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    // A locale whose file is not cached yet loads on the real event loop.
    for (var i = 0; i < 50 && find.text('order-page').evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    unawaited(router.push(Routes.orderHelp, extra: _order));
    await settle(tester);
  }

  testWidgets('the grouped options, the picker, the send and the thanks', (
    tester,
  ) async {
    await pump(tester, textScale: 1.3);

    // The skeleton until the options land.
    expect(find.text('What went wrong?'), findsNothing);
    repository.reads.single.complete(const Right(_categories));
    await settle(tester);

    expect(find.text('Get help with this order'), findsOneWidget);
    expect(find.textContaining('1001'), findsOneWidget);
    expect(find.text('What went wrong?'), findsOneWidget);
    expect(find.text('Missing items'), findsOneWidget);
    expect(find.text('My order is late'), findsOneWidget);
    // Account problems are not about this order.
    expect(find.text("I can't sign in"), findsNothing);
    expect(find.text('Choose what went wrong'), findsOneWidget);

    // Nothing chosen: the pill refuses.
    await tester.tap(find.text('Send to support'));
    await settle(tester);
    expect(repository.sends, isEmpty);

    await tester.tap(find.text('Missing items'));
    await settle(tester);
    expect(find.byType(OrderHelpItemsPicker), findsOneWidget);
    expect(find.text("Tick the items it's about"), findsNWidgets(2));

    await tester.tap(find.text('Fresh full-fat milk, family size bottle'));
    await settle(tester);
    expect(find.text('Choose what went wrong'), findsNothing);
    expect(find.text("Tick the items it's about"), findsOneWidget);

    // Another issue folds the picker away.
    await tapShown(tester, find.text('My order is late'), 120);
    expect(find.byType(OrderHelpItemsPicker), findsNothing);
    await tapShown(tester, find.text('Missing items'), -120);

    await tester.tap(find.text('Send to support'));
    await tester.pump();
    expect(
      repository.drafts.single,
      const SupportTicketDraft(
        subject: 'Order 1001: Missing items',
        category: SupportCategory.order,
        topic: SupportTopic.missingItems,
        orderId: 'o1',
        productIds: <String>['p1'],
        body:
            'Problem with order 1001: Missing items.\n'
            'Items: Fresh full-fat milk, family size bottle ×2',
      ),
    );

    repository.sends.single.complete(
      const Right(SupportTicketReceipt(ticketId: 't-42')),
    );
    await settle(tester);
    expect(find.byType(OrderHelpSentView), findsOneWidget);
    expect(find.text("We're on it"), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text('order-page'), findsOneWidget);
  });

  testWidgets('Arabic, right to left, at 360 dp and text scale 1.3', (
    tester,
  ) async {
    await pump(tester, locale: _ar, textScale: 1.3);
    repository.reads.single.complete(const Right(_categories));
    await settle(tester);

    expect(find.text('ما المشكلة؟'), findsOneWidget);
    await tester.tap(find.text('منتجات ناقصة'));
    await settle(tester);
    expect(find.text('حليب طازج كامل الدسم عبوة عائلية'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed read offers a retry that reads again', (tester) async {
    await pump(tester);
    repository.reads.single.complete(const Left(ServerFailure('boom')));
    await settle(tester);

    expect(find.text('What went wrong?'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(repository.reads, hasLength(2));

    repository.reads.last.complete(const Right(_categories));
    await settle(tester);
    expect(find.text('What went wrong?'), findsOneWidget);
  });

  testWidgets('a failed send marks the busy disc red; the draft stays', (
    tester,
  ) async {
    await pump(tester);
    repository.reads.single.complete(const Right(_categories));
    await settle(tester);

    await tester.tap(find.text('My order is late'));
    await settle(tester);
    await tester.tap(find.text('Send to support'));
    await tester.pump();
    repository.sends.single.complete(const Left(ServerFailure('Try later')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(LoaderFailMark), findsOneWidget);

    await settle(tester);
    await settle(tester);
    expect(find.byType(LoaderFailMark), findsNothing, reason: 'it leaves');
    expect(find.byType(OrderHelpSentView), findsNothing);
    expect(find.text('Send to support'), findsOneWidget);
  });

  testWidgets('a send answered 401 goes to sign in', (tester) async {
    await pump(tester);
    repository.reads.single.complete(const Right(_categories));
    await settle(tester);

    await tester.tap(find.text('My order is late'));
    await settle(tester);
    await tester.tap(find.text('Send to support'));
    await tester.pump();
    repository.sends.single.complete(const Left(UnauthorizedFailure()));
    await settle(tester);

    expect(find.text('login'), findsOneWidget);
  });
}

/// Scrolls the form by [delta] steps until [finder] is on screen (the list
/// is lazy: a row far down is not built yet), then taps it.
Future<void> tapShown(WidgetTester tester, Finder finder, double delta) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(finder);
  await settle(tester);
}

/// Bounded pumps: the skeleton shimmers for as long as it shows.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}
