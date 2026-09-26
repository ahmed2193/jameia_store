import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../domain/entities/wallet_entry_entity.dart';
import '../../cubit/ledger_cubit.dart';
import '../../cubit/ledger_state.dart';
import 'wallet_balance_face.dart';

/// The wallet balance card and its one moment of motion. On open the
/// balance is simply there. When a pull-to-refresh moves it
/// ([LedgerState.changeSerial] ticks with the balance delta the cubit worked
/// out), the delta chip fades in rising into place, the digits roll a beat
/// later with a success haptic, and the chip fades away after a hold — all
/// on one timeline. Reduced motion: the chip only fades, the digits swap at
/// once; the haptic stays.
class WalletBalanceCard extends StatefulWidget {
  const WalletBalanceCard({super.key});

  @override
  State<WalletBalanceCard> createState() => _WalletBalanceCardState();
}

class _WalletBalanceCardState extends State<WalletBalanceCard>
    with SingleTickerProviderStateMixin {
  static const double _rise = AppSpacing.s8;
  static const Duration _rollAfter = AppMotion.microPop;

  /// How long the chip stays up between its entrance and its exit.
  static final Duration _hold = AppMotion.page * 5;
  static const Duration _exit = AppMotion.fast;

  late final AnimationController _chip = AnimationController(vsync: this);
  Animation<double> _opacity = kAlwaysDismissedAnimation;
  Animation<double> _offset = kAlwaysDismissedAnimation;

  /// The delta on show; 0 = no chip.
  int _delta = 0;

  /// From the chip appearing until the roll: the old balance stays up.
  bool _holding = false;
  double _rollAt = 0;

  @override
  void initState() {
    super.initState();
    _chip
      ..addListener(_maybeRoll)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _delta = 0);
        }
      });
  }

  @override
  void dispose() {
    _chip.dispose();
    super.dispose();
  }

  void _play(int delta) {
    if (delta == 0) return;
    final reduced = MotionGuard.reduced(context);
    final enter = reduced ? AppMotion.fast : AppMotion.slow;
    final total = enter + _hold + _exit;
    double share(Duration part) => part.inMicroseconds / total.inMicroseconds;
    _chip.duration = total;
    _rollAt = share(_rollAfter);
    _opacity = _chip.drive(
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0,
            end: 1,
          ).chain(CurveTween(curve: AppMotion.signature)),
          weight: share(enter),
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(1),
          weight: share(_hold),
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1,
            end: 0,
          ).chain(CurveTween(curve: AppMotion.exit)),
          weight: share(_exit),
        ),
      ]),
    );
    _offset = _chip.drive(
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: reduced ? 0 : _rise,
            end: 0,
          ).chain(CurveTween(curve: AppMotion.emphasizedDecelerate)),
          weight: share(enter),
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(0),
          weight: share(_hold + _exit),
        ),
      ]),
    );
    setState(() {
      _delta = delta;
      _holding = true;
    });
    _chip.forward(from: 0);
  }

  void _maybeRoll() {
    if (!_holding || _chip.value < _rollAt) return;
    setState(() => _holding = false);
    Haptics.success();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      LedgerCubit<WalletEntryEntity>,
      LedgerState<WalletEntryEntity>
    >(
      listenWhen: (previous, current) =>
          previous.changeSerial != current.changeSerial,
      listener: (_, state) => _play(state.change.balanceDelta),
      child:
          BlocSelector<
            LedgerCubit<WalletEntryEntity>,
            LedgerState<WalletEntryEntity>,
            int
          >(
            selector: (state) => state.ledger.balance,
            builder: (_, balance) => WalletBalanceFace(
              balanceFils: _holding ? balance - _delta : balance,
              deltaFils: _delta,
              chipOpacity: _opacity,
              chipRise: _offset,
            ),
          ),
    );
  }
}
