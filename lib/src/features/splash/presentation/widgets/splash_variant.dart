import 'splash_basket_choreography.dart';
import 'splash_burst_choreography.dart';
import 'splash_choreography.dart';
import 'splash_wordmark_choreography.dart';

/// The intros the splash can play. All start on the launch screen's frame
/// and end on the Hero lockup: the bag in its cape over the name.
///
/// Pick one at build time: `flutter run --dart-define=SPLASH_VARIANT=basket`
/// (`wordmark` when absent or unknown).
enum SplashVariant {
  /// White on green: the bag takes off and delivers the name.
  wordmark(SplashWordmarkChoreography()),

  /// Groceries drop into the bag first — the grocery run.
  basket(SplashBasketChoreography()),

  /// A white burst turns the screen into the full-colour logo on white.
  burst(SplashBurstChoreography());

  const SplashVariant(this.choreography);

  final SplashChoreography choreography;

  static const String defineKey = 'SPLASH_VARIANT';

  /// The variant this build was made with.
  static SplashVariant get configured =>
      byName(const String.fromEnvironment(defineKey));

  static SplashVariant byName(String name) => values.firstWhere(
    (variant) => variant.name == name,
    orElse: () => wordmark,
  );
}
