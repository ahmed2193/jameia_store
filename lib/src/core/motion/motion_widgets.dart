/// **core/motion/motion_widgets.dart** — the reusable motion PRIMITIVES every
/// feature composes from. Each wrapper reads its timing/curve from [AppMotion]
/// and routes through [MotionGuard], so the OS "remove animations" flag degrades
/// the whole app to instant in one place. Feature code should reach for these
/// instead of hand-rolling `AnimatedSwitcher` / `AnimationController`.
///
/// Mirrors Hero's recurring interaction grammar: value flips (price / cart
/// total / free-ship threshold), tap press-scale, grow-from-zero pops (badges /
/// chips / check marks), one-line tickers, shared countdown clocks,
/// staggered list entrances, one-shot colour washes and sparkles on a real
/// change, and entrances that wait for their route to settle.
library;

export 'after_arrival.dart';
export 'ambient_loop.dart';
export 'collapse_reveal.dart';
export 'confetti_burst.dart';
export 'count_up_text.dart';
export 'deferred_value.dart';
export 'entrance_arrival.dart';
export 'entrance_cascade.dart';
export 'entrance_cascade_item.dart';
export 'fade_through_switcher.dart';
export 'flip_value.dart';
export 'float_loop.dart';
export 'idle_loop.dart';
export 'motion_beat.dart';
export 'on_screen_gate.dart';
export 'play_when_on_screen.dart';
export 'pop_scale.dart';
export 'pop_switcher.dart';
export 'press_scale.dart';
export 'rolling_number.dart';
export 'rolling_number_text.dart';
export 'rotating_line.dart';
export 'scroll_reveal.dart';
export 'second_clock.dart';
export 'second_clock_follower.dart';
export 'second_clock_scope.dart';
export 'shake_x.dart';
export 'size_fade_switcher.dart';
export 'size_fade_transition.dart';
export 'tint_flash.dart';
export 'vertical_swap_transition.dart';
