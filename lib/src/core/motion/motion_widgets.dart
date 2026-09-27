/// **core/motion/motion_widgets.dart** — the reusable motion PRIMITIVES every
/// feature composes from. Each wrapper reads its timing/curve from [AppMotion]
/// and routes through [MotionGuard], so the OS "remove animations" flag degrades
/// the whole app to instant in one place. Feature code should reach for these
/// instead of hand-rolling `AnimatedSwitcher` / `AnimationController`.
///
/// Mirrors Jameia's recurring interaction grammar: value flips (price / cart
/// total / free-ship threshold), tap press-scale, grow-from-zero pops (badges /
/// chips / check marks), one-line tickers, shared countdown clocks,
/// staggered list entrances, one-shot colour washes and sparkles on a real
/// change, and entrances that wait for their route to settle.
library;

export 'confetti_burst.dart';
export 'count_up_text.dart';
export 'flip_value.dart';
export 'float_loop.dart';
export 'glow_pulse.dart';
export 'on_route_settled.dart';
export 'pop_scale.dart';
export 'pop_switcher.dart';
export 'press_scale.dart';
export 'rotating_line.dart';
export 'scroll_reveal.dart';
export 'second_clock.dart';
export 'second_clock_scope.dart';
export 'shake_x.dart';
export 'sparkle_burst.dart';
export 'stagger_entrance.dart';
export 'tint_flash.dart';
