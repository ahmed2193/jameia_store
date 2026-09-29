import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../auth/presentation/cubit/auth_session_state.dart';

/// Rebuilds the shell's tab bodies ([child]) from scratch when a NEW session
/// begins (CLAUDE.md §3.2: page cubits are rebuilt for a new session): a
/// guest signs in, or another customer does. A `go` back to the shell keeps
/// the shell (docs/motion B1-09), so a sign-in from a login page pushed over
/// it (the Mine header, the Pro page) would otherwise land on tabs still
/// holding the guest's cubits.
///
/// Nothing else rebuilds them: an ordinary `go(shell)`, the launch restore
/// settling (the session was not known yet, or a signed-in session learns
/// its customer), a fresher customer record. A sign-in is told apart from
/// the restore by the state's sign-in count, so one that lands while the
/// restore is still unknown starts a session too. A session that ends always
/// leaves through `go(login)`, which drops the shell itself.
class ShellSessionKeyed extends StatefulWidget {
  const ShellSessionKeyed({super.key, required this.child});

  final Widget child;

  /// Whether going from [previous] to [next] starts a new session.
  static bool startsSession(AuthSessionState previous, AuthSessionState next) {
    if (!next.isSignedIn) return false;
    // The OTP page signed someone in (never the restore).
    if (next.signIns != previous.signIns) return true;
    if (previous.status == AuthSessionStatus.unknown) return false;
    if (!previous.isSignedIn) return true;
    final was = previous.customer?.id;
    final now = next.customer?.id;
    return was != null && now != null && was != now;
  }

  @override
  State<ShellSessionKeyed> createState() => _ShellSessionKeyedState();
}

class _ShellSessionKeyedState extends State<ShellSessionKeyed> {
  int _session = 0;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthSessionCubit, AuthSessionState>(
      listenWhen: ShellSessionKeyed.startsSession,
      listener: (context, _) => setState(() => _session++),
      child: KeyedSubtree(key: ValueKey<int>(_session), child: widget.child),
    );
  }
}
