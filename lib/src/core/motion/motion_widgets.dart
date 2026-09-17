/// **core/motion/motion_widgets.dart** — the reusable motion PRIMITIVES every
/// feature composes from. Each wrapper reads its timing/curve from [AppMotion]
/// and routes through [MotionGuard], so the OS "remove animations" flag degrades
/// the whole app to instant in one place. Feature code should reach for these
/// instead of hand-rolling `AnimatedSwitcher` / `AnimationController`.
///
/// Mirrors Jameia's recurring interaction grammar: value flips (price / cart
/// total / free-ship threshold), tap press-scale, grow-from-zero pops (badges /
/// chips / check marks) and staggered list entrances.
library;

export 'flip_value.dart';
export 'pop_scale.dart';
export 'press_scale.dart';
export 'stagger_entrance.dart';
