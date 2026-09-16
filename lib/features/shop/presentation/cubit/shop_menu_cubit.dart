import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';

/// UI-coordination state for the shop menu screen.
///
/// Extracted from `_ShopMenuState` + `_SubCategoryTabState` in
/// `shop_screen.dart`. This cubit holds NO repository / model data — it only
/// owns the scroll/selection coordination that drives the collapsing hero, the
/// sub-category tabs and the rank rail↔body two-way sync.
///
/// ── The per-scroll-tick rebuild fix (the main lag) ──────────────────────────
/// The old `_SubCategoryTabState` called `setState(() => _active = index)` on
/// EVERY body scroll tick (`_onPositions`). That rebuilt the whole tab subtree
/// (rail ListView + the visible section cards) on every frame of a scroll — the
/// dominant source of jank.
///
/// To fix this WITHOUT rebuilding the whole list on each tick, the active rank
/// is exposed as a [ValueNotifier] ([activeRank]) IN ADDITION to (a coarse)
/// cubit [state]. The rail's items each wrap in a `ValueListenableBuilder` on
/// [activeRank], so when the active index flips from `a` → `b` only those two
/// rail items rebuild (the one losing selection + the one gaining it) — never
/// the whole rail and never the body. The cubit `emit`s a state change only for
/// coarse, user-facing transitions (e.g. tab switches) — not per scroll tick.
///
/// The hero collapse is now handled natively by a `SliverPersistentHeader`
/// delegate (`ShopHeroHeader`) via `shrinkOffset`, so this cubit no longer owns
/// any collapse notifier — only the rank-rail↔body two-way sync state.
class ShopMenuCubit extends Cubit<ShopMenuState>
    with SafeCubitMixin<ShopMenuState> {
  ShopMenuCubit({int initialTabIndex = 0, int initialRankIndex = 0})
      : activeRank = ValueNotifier<int>(initialRankIndex),
        super(ShopMenuState(
          activeTabIndex: initialTabIndex,
          activeRankIndex: initialRankIndex,
        ));

  /// The selected sub-category rank index. A notifier so the rail rebuilds ONLY
  /// the two items whose selected-state flips (see class doc) instead of the
  /// whole list on every scroll tick.
  final ValueNotifier<int> activeRank;

  // ── Programmatic-scroll guard + user-intent window (ported verbatim) ────────
  // So a body-scroll highlight does not fight a tap that is still animating.
  bool _isProgrammaticScroll = false;
  Timer? _programmaticScrollTimer;
  int? _userIntentIndex;
  DateTime _userIntentAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _userIntentWindow = AppMotion.slow;

  /// True while a tap-initiated programmatic scroll is in flight; the body
  /// position listener should ignore reports during this window.
  bool get isProgrammaticScroll => _isProgrammaticScroll;

  // ── Tab selection ───────────────────────────────────────────────────────────

  /// Switch the active sub-category tab. The body swap + scroll is handled by the
  /// screen; this only records the active index + resets the active rank to 0.
  void selectTab(int index) {
    if (index == state.activeTabIndex) return;
    activeRank.value = 0;
    safeEmit(state.copyWith(activeTabIndex: index, activeRankIndex: 0));
  }

  // ── Rank selection (rail tap) ───────────────────────────────────────────────

  /// Select a rank.
  ///
  /// [userInitiated] true → a rail TAP: opens the user-intent window and arms
  /// the programmatic-scroll guard so the body→rail sync won't fight the
  /// in-flight scroll animation (ported from `_onSelectRank`).
  ///
  /// [userInitiated] false → a body→rail highlight: respects the active
  /// user-intent window, refusing to override a tap that is still settling
  /// (ported from `_onPositions`). The caller should also gate on
  /// [isProgrammaticScroll] before calling this.
  void selectRank(int index, {bool userInitiated = false}) {
    if (userInitiated) {
      _userIntentIndex = index;
      _userIntentAt = DateTime.now();
      beginProgrammaticScroll();
      _setActiveRank(index);
      return;
    }
    // Don't fight a tap that is still inside its intent window.
    if (_userIntentIndex != null &&
        DateTime.now().difference(_userIntentAt) < _userIntentWindow &&
        index != _userIntentIndex) {
      return;
    }
    _setActiveRank(index);
  }

  /// Body→rail report of the top-most visible section index. Convenience wrapper
  /// over [selectRank] for the position listener; no-ops while a programmatic
  /// scroll is in flight (mirrors the `_onPositions` guard).
  void reportActiveRank(int index) {
    if (_isProgrammaticScroll) return;
    selectRank(index, userInitiated: false);
  }

  void _setActiveRank(int index) {
    if (index == activeRank.value && index == state.activeRankIndex) return;
    activeRank.value = index;
    // Emit a coarse state change too so screen-level listeners (and tests) see
    // the active rank — but the rail itself listens to [activeRank] directly so
    // it does not rebuild from this emit.
    safeEmit(state.copyWith(activeRankIndex: index));
  }

  // ── Programmatic-scroll guard ───────────────────────────────────────────────

  /// Arm the guard (a tap started a programmatic scroll). Auto-disarms after the
  /// user-intent window (ported from `_setProgrammaticScroll(true)`).
  void beginProgrammaticScroll() {
    _isProgrammaticScroll = true;
    _programmaticScrollTimer?.cancel();
    _programmaticScrollTimer = Timer(_userIntentWindow, () {
      _isProgrammaticScroll = false;
    });
  }

  /// Disarm the guard immediately (e.g. the scroll animation completed early).
  void endProgrammaticScroll() {
    _isProgrammaticScroll = false;
    _programmaticScrollTimer?.cancel();
  }

  @override
  Future<void> close() {
    _programmaticScrollTimer?.cancel();
    activeRank.dispose();
    return super.close();
  }
}

/// Coarse, user-facing menu state. Per-scroll-tick coordination lives in the
/// [ShopMenuCubit.collapse] / [ShopMenuCubit.activeRank] notifiers, NOT here, so
/// scrolling does not churn this state (see [ShopMenuCubit] doc).
class ShopMenuState extends Equatable {
  const ShopMenuState({
    this.activeTabIndex = 0,
    this.activeRankIndex = 0,
  });

  /// Index of the active sub-category tab.
  final int activeTabIndex;

  /// Index of the selected rank (mirror of [ShopMenuCubit.activeRank] for
  /// non-rail listeners / tests).
  final int activeRankIndex;

  ShopMenuState copyWith({int? activeTabIndex, int? activeRankIndex}) =>
      ShopMenuState(
        activeTabIndex: activeTabIndex ?? this.activeTabIndex,
        activeRankIndex: activeRankIndex ?? this.activeRankIndex,
      );

  @override
  List<Object?> get props => [activeTabIndex, activeRankIndex];
}
