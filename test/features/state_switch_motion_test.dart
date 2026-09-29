// B1-06: the screens that used to cut hard between their states now switch
// through FadeThroughSwitcher — for a moment the old state and the new one
// are both on screen (skeleton screens cross-fade, the rest fade through).
import 'dart:async';
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
import 'package:hero_mart/src/core/domain/entities/screen_load.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/motion/fade_through_switcher.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/state_views.dart';
import 'package:hero_mart/src/features/account/presentation/cubit/loyalty_rewards_cubit.dart';
import 'package:hero_mart/src/features/account/presentation/cubit/loyalty_rewards_state.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/rewards/rewards_body.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_book_state.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_list/address_list_body.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_list/address_list_skeleton.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_availability_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_availability_state.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_chat_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_chat_state.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_history_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_history_state.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/chat/assistant_chat_body.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/chat/assistant_thread_skeleton.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/history/assistant_history_body.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/history/assistant_history_skeleton.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRewardsCubit extends MockCubit<LoyaltyRewardsState>
    implements LoyaltyRewardsCubit {}

class _MockAddressBookCubit extends MockCubit<AddressBookState>
    implements AddressBookCubit {}

class _MockHistoryCubit extends MockCubit<AssistantHistoryState>
    implements AssistantHistoryCubit {}

class _MockChatCubit extends MockCubit<AssistantChatState>
    implements AssistantChatCubit {}

class _MockAvailabilityCubit extends MockCubit<AssistantAvailabilityState>
    implements AssistantAvailabilityCubit {}

const Failure _failure = ServerFailure('Something went wrong');

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

  Widget app(Widget body) => MaterialApp(home: Scaffold(body: body));

  /// Emits the next state, then checks a frame partway through the swap:
  /// both the old view and the new one are drawn, under the switcher.
  Future<void> expectBothMidSwap(
    WidgetTester tester,
    StreamController<Object> states,
    Object next, {
    required Finder before,
    required Finder after,
  }) async {
    expect(before, findsOneWidget);
    expect(
      find.ancestor(of: before, matching: find.byType(FadeThroughSwitcher)),
      findsOneWidget,
    );
    states.add(next);
    await tester.pump();
    await tester.pump(AppMotion.fast ~/ 2);
    expect(before, findsOneWidget, reason: 'the old state fades out');
    expect(after, findsOneWidget, reason: 'the new state is coming in');
    await tester.pumpAndSettle();
    expect(before, findsNothing);
    expect(after, findsOneWidget);
  }

  testWidgets('Loyalty rewards: loader → error fades through', (tester) async {
    final cubit = _MockRewardsCubit();
    final states = StreamController<LoyaltyRewardsState>();
    addTearDown(states.close);
    whenListen(
      cubit,
      states.stream,
      initialState: const LoyaltyRewardsState(
        status: LoyaltyRewardsStatus.loading,
      ),
    );
    await tester.pumpWidget(
      app(
        BlocProvider<LoyaltyRewardsCubit>.value(
          value: cubit,
          child: const RewardsBody(),
        ),
      ),
    );
    await expectBothMidSwap(
      tester,
      states,
      const LoyaltyRewardsState(
        status: LoyaltyRewardsStatus.error,
        failure: _failure,
      ),
      before: find.byType(AppLoader),
      after: find.byType(ErrorView),
    );
  });

  testWidgets('Address list: the bones cross-fade into the next state', (
    tester,
  ) async {
    final cubit = _MockAddressBookCubit();
    final states = StreamController<AddressBookState>();
    addTearDown(states.close);
    whenListen(
      cubit,
      states.stream,
      initialState: const AddressBookState(status: AddressBookStatus.loading),
    );
    await tester.pumpWidget(
      app(
        BlocProvider<AddressBookCubit>.value(
          value: cubit,
          child: const AddressListBody(),
        ),
      ),
    );
    await expectBothMidSwap(
      tester,
      states,
      const AddressBookState(
        status: AddressBookStatus.error,
        loadFailure: _failure,
      ),
      before: find.byType(AddressListSkeleton),
      after: find.byType(ErrorView),
    );
  });

  testWidgets('Assistant history: the bones cross-fade into the next state', (
    tester,
  ) async {
    final cubit = _MockHistoryCubit();
    final states = StreamController<AssistantHistoryState>();
    addTearDown(states.close);
    whenListen(
      cubit,
      states.stream,
      initialState: const AssistantHistoryState(
        load: ScreenLoad(phase: LoadPhase.loading),
      ),
    );
    await tester.pumpWidget(
      app(
        BlocProvider<AssistantHistoryCubit>.value(
          value: cubit,
          child: const AssistantHistoryBody(),
        ),
      ),
    );
    await expectBothMidSwap(
      tester,
      states,
      const AssistantHistoryState(
        load: ScreenLoad(phase: LoadPhase.error, failure: _failure),
      ),
      before: find.byType(AssistantHistorySkeleton),
      after: find.byType(FailureView),
    );
  });

  testWidgets('Assistant chat: loading → error fades through', (tester) async {
    final chat = _MockChatCubit();
    final availability = _MockAvailabilityCubit();
    final states = StreamController<AssistantChatState>();
    addTearDown(states.close);
    whenListen(
      chat,
      states.stream,
      initialState: const AssistantChatState(
        status: AssistantChatStatus.loading,
      ),
    );
    whenListen(
      availability,
      const Stream<AssistantAvailabilityState>.empty(),
      initialState: const AssistantAvailabilityState(
        status: AssistantAvailabilityStatus.available,
      ),
    );
    await tester.pumpWidget(
      app(
        MultiBlocProvider(
          providers: [
            BlocProvider<AssistantChatCubit>.value(value: chat),
            BlocProvider<AssistantAvailabilityCubit>.value(value: availability),
          ],
          child: const AssistantChatBody(),
        ),
      ),
    );
    await expectBothMidSwap(
      tester,
      states,
      const AssistantChatState(
        status: AssistantChatStatus.error,
        failure: _failure,
      ),
      before: find.byType(AssistantThreadSkeleton),
      after: find.byType(ErrorView),
    );
  });
}
