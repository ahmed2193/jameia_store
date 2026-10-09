// I15a — Home keeps ONE header across its states (App A #25 P22): the
// skeleton, the failure and the feed are slivers under the same header
// element, so the header's one-shot cues never replay because the state
// below it changed.
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
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
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/widgets/state_views.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_book_state.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_availability_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_availability_state.dart';
import 'package:hero_mart/src/features/home/domain/entities/home_bootstrap.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_failure_view.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_frame.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_loading_view.dart';
import 'package:hero_mart/src/features/notifications/presentation/cubit/unread_notifications_cubit.dart';
import 'package:hero_mart/src/features/notifications/presentation/cubit/unread_notifications_state.dart';
import 'package:hero_mart/src/features/store_mode/presentation/cubit/pro_status_cubit.dart';
import 'package:hero_mart/src/features/store_mode/presentation/cubit/pro_status_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAddressBookCubit extends MockCubit<AddressBookState>
    implements AddressBookCubit {}

class _MockUnreadCubit extends MockCubit<UnreadNotificationsState>
    implements UnreadNotificationsCubit {}

class _MockAvailabilityCubit extends MockCubit<AssistantAvailabilityState>
    implements AssistantAvailabilityCubit {}

class _MockProStatusCubit extends MockCubit<ProStatusState>
    implements ProStatusCubit {}

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

  testWidgets('skeleton → failure → skeleton: the same header element', (
    tester,
  ) async {
    final addresses = _MockAddressBookCubit();
    final unread = _MockUnreadCubit();
    final availability = _MockAvailabilityCubit();
    final pro = _MockProStatusCubit();
    whenListen(
      addresses,
      const Stream<AddressBookState>.empty(),
      initialState: const AddressBookState(),
    );
    whenListen(
      unread,
      const Stream<UnreadNotificationsState>.empty(),
      initialState: const UnreadNotificationsState(),
    );
    whenListen(
      availability,
      const Stream<AssistantAvailabilityState>.empty(),
      initialState: const AssistantAvailabilityState(),
    );
    whenListen(
      pro,
      const Stream<ProStatusState>.empty(),
      initialState: const ProStatusState(),
    );

    Widget frame(Widget body, {bool loaded = false}) => MultiBlocProvider(
      providers: [
        BlocProvider<AddressBookCubit>.value(value: addresses),
        BlocProvider<UnreadNotificationsCubit>.value(value: unread),
        BlocProvider<AssistantAvailabilityCubit>.value(value: availability),
        BlocProvider<ProStatusCubit>.value(value: pro),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: HomeFrame(
            bootstrap: HomeBootstrap.empty,
            loaded: loaded,
            body: body,
          ),
        ),
      ),
    );

    await tester.pumpWidget(frame(const HomeLoadingView()));
    await tester.pump();
    final header = tester.element(find.byType(SliverPersistentHeader));

    await tester.pumpWidget(
      frame(
        HomeFailureView(failure: const ServerFailure('down'), onRetry: () {}),
      ),
    );
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (w) => w is HeroStateView && w.art == HeroAssets.stateError,
      ),
      findsOneWidget,
    );
    expect(
      tester.element(find.byType(SliverPersistentHeader)),
      same(header),
      reason: 'the header is not rebuilt from scratch for a new state',
    );

    await tester.pumpWidget(frame(const HomeLoadingView()));
    await tester.pump();
    expect(tester.element(find.byType(SliverPersistentHeader)), same(header));
  });
}
