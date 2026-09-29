// I4 / B1-09 follow-up: the shell is kept on `go(Routes.shell)`, so a
// sign-in over it (login pushed from Mine / Pro) must still hand the tabs
// fresh page cubits (CLAUDE.md §3.2) — and nothing else may rebuild them.
import 'package:dartz/dartz.dart' show Right;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_state.dart';
import 'package:hero_mart/src/features/shell/presentation/widgets/shell_session_keyed.dart';

import '../auth/auth_test_fakes.dart';

const AuthCustomerEntity _other = AuthCustomerEntity(
  id: 'someone-else',
  phone: '+96599998888',
  nameEn: 'Sara',
  nameAr: 'سارة',
);

/// Stands in for a tab page: its State (and so its page cubit) either
/// survives or is created anew.
class _Tab extends StatefulWidget {
  const _Tab({required this.label});

  final String label;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  int taps = 0;

  @override
  Widget build(BuildContext context) =>
      Text('${widget.label} $taps', textDirection: TextDirection.ltr);
}

void main() {
  late AuthSessionCubit session;

  AuthSessionCubit build({AuthCustomerEntity? saved}) => AuthSessionCubit(
    restoreSession: FakeRestoreSessionUseCase(Right(saved)),
    logout: FakeLogoutUseCase(),
    watchExpiry: FakeWatchSessionExpiryUseCase(),
    getCachedCustomer: FakeGetCachedCustomerUseCase(Right(saved)),
    saveCachedCustomer: FakeSaveCachedCustomerUseCase(),
    clearCachedCustomer: FakeClearCachedCustomerUseCase(),
  );

  tearDown(() => session.close());

  /// The shell's body: its label changes on every "go" so the parent
  /// rebuilds the keyed subtree like `MainShellPage.didUpdateWidget` does.
  Widget shell(String arrival) => BlocProvider<AuthSessionCubit>.value(
    value: session,
    child: ShellSessionKeyed(child: _Tab(label: arrival)),
  );

  _TabState tab(WidgetTester tester) =>
      tester.state<_TabState>(find.byType(_Tab));

  testWidgets('a guest who signs in over the shell gets fresh tabs', (
    tester,
  ) async {
    session = build();
    await session.restore();
    expect(session.state.status, AuthSessionStatus.signedOut);
    await tester.pumpWidget(shell('home'));
    final guest = tab(tester)..taps = 3;

    session.signedIn(kCustomer);
    // The cubit's stream delivers on a microtask; the rebuild is the next frame.
    await tester.pump();
    await tester.pump();

    expect(tab(tester), isNot(same(guest)));
    expect(tab(tester).taps, 0);
  });

  testWidgets('an ordinary go(shell) keeps the tabs and their state', (
    tester,
  ) async {
    session = build();
    await session.restore();
    await tester.pumpWidget(shell('home'));
    final kept = tab(tester)..taps = 3;

    await tester.pumpWidget(shell('home again'));

    expect(tab(tester), same(kept));
    expect(find.text('home again 3'), findsOneWidget);
  });

  testWidgets('the launch restore and a fresher customer record keep them', (
    tester,
  ) async {
    session = build(saved: kCustomer);
    await tester.pumpWidget(shell('home'));
    final kept = tab(tester)..taps = 2;

    await session.restore();
    await tester.pump();
    expect(session.state.isSignedIn, isTrue);
    session.updateCustomer(
      const AuthCustomerEntity(
        id: '507f1f77bcf86cd799439011',
        phone: '+96512345678',
        nameEn: 'Ahmed F.',
        nameAr: 'أحمد',
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tab(tester), same(kept));
  });

  testWidgets('another customer signing in rebuilds them', (tester) async {
    session = build(saved: kCustomer);
    await session.restore();
    await tester.pumpWidget(shell('home'));
    final first = tab(tester);

    session.signedIn(_other);
    await tester.pump();
    await tester.pump();

    expect(tab(tester), isNot(same(first)));
  });

  testWidgets('a sign-in that lands while the launch restore is still '
      'unknown gets fresh tabs too', (tester) async {
    session = build();
    expect(session.state.status, AuthSessionStatus.unknown);
    await tester.pumpWidget(shell('home'));
    final before = tab(tester)..taps = 1;

    session.signedIn(kCustomer);
    await tester.pump();
    await tester.pump();

    expect(tab(tester), isNot(same(before)));
    expect(tab(tester).taps, 0);
  });

  test('a session that ends does not rebuild (go(login) drops the shell)', () {
    const signedIn = AuthSessionState(
      status: AuthSessionStatus.signedIn,
      customer: kCustomer,
    );
    const signedOut = AuthSessionState(status: AuthSessionStatus.signedOut);
    expect(ShellSessionKeyed.startsSession(signedIn, signedOut), isFalse);
    expect(ShellSessionKeyed.startsSession(signedOut, signedIn), isTrue);
    expect(
      ShellSessionKeyed.startsSession(const AuthSessionState(), signedIn),
      isFalse,
    );
  });
}
