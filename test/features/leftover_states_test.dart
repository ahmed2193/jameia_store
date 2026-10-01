// I15a — screen states left over from I7 (docs/motion §9.4 #6, #17-18;
// Appendix A search / support / category rows):
//  * the help-center hub's topics card shows the dots while the topics load
//    and a Retry when they did not — the rest of the hub stays;
//  * the help topics page never shows "no results" over a list that is
//    still loading, and says why (with a Retry) when it failed;
//  * search discover: bones while its blocks load, the failure view when
//    both failed with nothing saved and no recent terms;
//  * a category page tells a failed tree read instead of silently dropping
//    the sub-category rows (a lost connection stays the banner's).
import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/design/hero_assets.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_category_entity.dart';
import 'package:hero_mart/src/core/domain/entities/screen_load.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/usecase/usecase.dart';
import 'package:hero_mart/src/core/widgets/connectivity_scope.dart';
import 'package:hero_mart/src/core/widgets/state_views.dart';
import 'package:hero_mart/src/features/search/domain/entities/recent_searches.dart';
import 'package:hero_mart/src/features/search/presentation/cubit/search_state.dart';
import 'package:hero_mart/src/features/search/presentation/widgets/search_discover_skeleton.dart';
import 'package:hero_mart/src/features/search/presentation/widgets/search_discover_view.dart';
import 'package:hero_mart/src/features/search/presentation/widgets/search_recents_section.dart';
import 'package:hero_mart/src/features/shop/presentation/cubit/category_browse_cubit.dart';
import 'package:hero_mart/src/features/shop/presentation/cubit/category_browse_state.dart';
import 'package:hero_mart/src/features/shop/domain/entities/category_browse.dart';
import 'package:hero_mart/src/features/shop/presentation/widgets/browse/category_chips.dart';
import 'package:hero_mart/src/features/shop/presentation/widgets/browse/category_tree_failure_listener.dart';
import 'package:hero_mart/src/features/support/domain/entities/faq_item.dart';
import 'package:hero_mart/src/features/support/domain/entities/support_hub.dart';
import 'package:hero_mart/src/features/support/domain/usecases/get_faqs_usecase.dart';
import 'package:hero_mart/src/features/support/domain/usecases/get_support_hub_usecase.dart';
import 'package:hero_mart/src/features/support/presentation/cubit/customer_service_cubit.dart';
import 'package:hero_mart/src/features/support/presentation/cubit/customer_service_question_cubit.dart';
import 'package:hero_mart/src/features/support/presentation/widgets/hub/customer_service_body.dart';
import 'package:hero_mart/src/features/support/presentation/widgets/hub/support_faq_pending.dart';
import 'package:hero_mart/src/features/support/presentation/widgets/hub/support_faq_row.dart';
import 'package:hero_mart/src/features/support/presentation/widgets/topics/support_faq_tile.dart';
import 'package:hero_mart/src/features/support/presentation/widgets/topics/support_no_results.dart';
import 'package:hero_mart/src/features/support/presentation/widgets/topics/support_topics_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

const FaqItem _faq = FaqItem(questionKey: 'q.one', answerKey: 'a.one');

/// A hub read the test answers by hand; counts the reads.
class _GatedHub implements GetSupportHubUseCase {
  final List<Completer<Either<Failure, SupportHub>>> reads = [];

  @override
  Future<Either<Failure, SupportHub>> call(NoParams params) {
    final read = Completer<Either<Failure, SupportHub>>();
    reads.add(read);
    return read.future;
  }
}

/// A topics read the test answers by hand; counts the reads.
class _GatedFaqs implements GetFaqsUseCase {
  final List<Completer<Either<Failure, List<FaqItem>>>> reads = [];

  @override
  Future<Either<Failure, List<FaqItem>>> call(NoParams params) {
    final read = Completer<Either<Failure, List<FaqItem>>>();
    reads.add(read);
    return read.future;
  }
}

class _MockCategoryBrowseCubit extends MockCubit<CategoryBrowseState>
    implements CategoryBrowseCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  Widget app(Widget body) => MaterialApp(
    home: ConnectivityScope(
      isOffline: false,
      reconnectEpoch: 0,
      onNudge: () {},
      child: Scaffold(body: body),
    ),
  );

  group('help-center hub topics card', () {
    testWidgets('dots while loading, Retry after a failure, then the rows', (
      tester,
    ) async {
      final hub = _GatedHub();
      final cubit = CustomerServiceCubit(hub);
      addTearDown(cubit.close);
      unawaited(cubit.load());
      await tester.pumpWidget(
        app(
          BlocProvider<CustomerServiceCubit>.value(
            value: cubit,
            child: const CustomerServiceBody(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SupportFaqPending), findsOneWidget);
      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.text('Retry'), findsNothing);

      hub.reads.single.complete(const Left(CacheFailure('unreadable')));
      await tester.pumpAndSettle();
      expect(find.text('unreadable'), findsOneWidget);
      expect(find.byType(SupportFaqRow), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(hub.reads, hasLength(2));
      hub.reads.last.complete(
        const Right(SupportHub(recentOrder: null, faqTopics: [_faq])),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SupportFaqPending), findsNothing);
      expect(find.byType(SupportFaqRow), findsOneWidget);
    });
  });

  group('help topics page', () {
    testWidgets('no "no results" while loading; a failure says why, Retry '
        'reads again', (tester) async {
      final faqs = _GatedFaqs();
      final cubit = CustomerServiceQuestionCubit(faqs);
      addTearDown(cubit.close);
      unawaited(cubit.load());
      await tester.pumpWidget(
        app(
          BlocProvider<CustomerServiceQuestionCubit>.value(
            value: cubit,
            child: const SupportTopicsBody(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SupportNoResults), findsNothing);
      expect(find.byType(AppLoader), findsOneWidget);

      faqs.reads.single.complete(const Left(CacheFailure('unreadable')));
      await tester.pumpAndSettle();
      expect(find.byWidgetPredicate(
        (w) => w is HeroStateView && w.art == HeroAssets.stateError,
      ), findsOneWidget);
      expect(find.byType(SupportNoResults), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(faqs.reads, hasLength(2));
      faqs.reads.last.complete(const Right([_faq]));
      await tester.pumpAndSettle();
      expect(find.byWidgetPredicate(
        (w) => w is HeroStateView && w.art == HeroAssets.stateError,
      ), findsNothing);
      expect(find.byType(SupportFaqTile), findsOneWidget);
    });
  });

  group('search discover', () {
    Widget discover(SearchState state, {VoidCallback? onRetry}) => app(
      SearchDiscoverView(
        state: state,
        onTerm: (_) {},
        onClearRecents: () {},
        onRetry: onRetry ?? () {},
      ),
    );

    testWidgets('bones while the blocks load, under the recent terms', (
      tester,
    ) async {
      await tester.pumpWidget(
        discover(
          const SearchState(
            recents: RecentSearches(['milk']),
            isDiscoverLoading: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SearchRecentsSection), findsOneWidget);
      expect(find.byType(SearchDiscoverSkeleton), findsOneWidget);
      expect(find.byType(FailureView), findsNothing);
    });

    testWidgets('both blocks failed and nothing else to show: the failure '
        'view, whose Retry reads again', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        discover(
          const SearchState(discoverFailure: ServerFailure('down')),
          onRetry: () => retries++,
        ),
      );
      await tester.pump();
      expect(find.byType(FailureView), findsOneWidget);
      expect(find.text('down'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('with recent terms to tap the failure stays quiet', (
      tester,
    ) async {
      await tester.pumpWidget(
        discover(
          const SearchState(
            recents: RecentSearches(['milk']),
            discoverFailure: ServerFailure('down'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(FailureView), findsNothing);
      expect(find.byType(SearchRecentsSection), findsOneWidget);
      expect(find.byType(SearchDiscoverSkeleton), findsNothing);
    });
  });

  group('category page tree', () {
    CategoryBrowseState failedWith(Failure failure) =>
        CategoryBrowseState.initial().withLoad(
          ScreenLoad(
            phase: LoadPhase.error,
            failure: failure,
            failedOn: FailedCall.read,
          ),
        );

    Future<void> pumpWith(WidgetTester tester, Failure failure) async {
      final cubit = _MockCategoryBrowseCubit();
      whenListen(
        cubit,
        Stream<CategoryBrowseState>.value(failedWith(failure)),
        initialState: CategoryBrowseState.initial(),
      );
      await tester.pumpWidget(
        app(
          BlocProvider<CategoryBrowseCubit>.value(
            value: cubit,
            child: const CategoryTreeFailureListener(child: SizedBox()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('a failed first read is told, not silent', (tester) async {
      await pumpWith(tester, const ServerFailure('Categories are down'));
      expect(find.text('Categories are down'), findsOneWidget);
    });

    testWidgets('a lost connection leaves it to the banner', (tester) async {
      await pumpWith(tester, const NetworkFailure());
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('chips that land after the page open their room', (
      tester,
    ) async {
      final tree = CatalogCategoryTree(const [
        CatalogCategoryEntity(id: 'c1', slug: 'fruit', name: 'Fruit'),
        CatalogCategoryEntity(id: 'c2', slug: 'veg', name: 'Veg'),
      ]);
      final cubit = _MockCategoryBrowseCubit();
      final arrived = StreamController<CategoryBrowseState>();
      addTearDown(arrived.close);
      whenListen(
        cubit,
        arrived.stream,
        initialState: CategoryBrowseState.initial(),
      );
      await tester.pumpWidget(
        app(
          BlocProvider<CategoryBrowseCubit>.value(
            value: cubit,
            child: const Column(children: [CategoryChips(level: 0)]),
          ),
        ),
      );
      double height() => tester.getSize(find.byType(CategoryChips)).height;
      expect(height(), 0);

      arrived.add(CategoryBrowseState(browse: CategoryBrowse.resolve(tree)));
      await tester.pump();
      await tester.pump(AppMotion.medium ~/ 2);
      expect(find.text('Fruit'), findsOneWidget);
      final opening = height();
      await tester.pump(AppMotion.medium);
      expect(opening, inExclusiveRange(0, height()));
    });
  });
}
