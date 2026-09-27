import 'dart:ui' show lerpDouble;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../motion/motion.dart';
import '../responsive/app_size.dart';
import 'brand_backdrop.dart';
import 'brand_sheet_scope.dart';
import 'brand_sheet_surface.dart';
import 'hero_lockup.dart';

/// The brand sheet page — a food-app sign-in look in Hero's own colours: the
/// living green [BrandBackdrop] with the [HeroLockup] fills the top of the
/// screen, under a see-through status bar, and a white sheet with rounded
/// top corners holds [child] (scrollable content; it pads its own bottom
/// inset). [leading] sits at the top start, over the green (a back or close
/// button).
///
/// Motion:
/// * [rise] — the sheet rises into place as the page opens, the spread
///   fades in and the logo settles (the first page of a flow; the next step
///   keeps the same header and only swaps the sheet, so it passes `false`).
/// * The keyboard — the header folds down to a strip under the status bar:
///   the sheet slides up over the green, the logo shrinks into the strip and
///   the spread stops turning, so a field and its button stay in view. What
///   the sheet holds can fold with it ([BrandSheetScope]).
///
/// Only [child]'s top edge moves while folding; the rise and the logo move
/// by transforms. Reduced motion: everything at once.
class BrandSheetScaffold extends StatefulWidget {
  const BrandSheetScaffold({
    super.key,
    required this.child,
    required this.logoLabel,
    this.leading,
    this.rise = true,
  });

  final Widget child;

  /// What the logo reads as (the app's name).
  final String logoLabel;
  final Widget? leading;
  final bool rise;

  /// Where the sheet's top rests: a share of the screen height, kept
  /// between [minHeader] and [maxHeader].
  static const double headerShare = 0.31;
  static const double minHeader = AppSize.s200;
  static const double maxHeader = AppSize.s300;

  /// Height of the folded header under the status bar.
  static const double foldedStrip = AppSize.s64;

  /// Height of the logo's name: a share of the screen width, kept between
  /// [minWord] and [maxWord]; and how small the logo gets folded.
  static const double wordShare = 0.1;
  static const double minWord = AppSize.s30;
  static const double maxWord = AppSize.s44;
  static const double foldedLogoScale = 0.42;

  /// The logo settles from this scale as the sheet rises.
  static const double logoSettleFrom = 0.92;

  /// The rise waits this long (the page's own fade shows the green first).
  static const Duration riseDelay = Duration(milliseconds: 120);
  static const Duration riseDuration = AppMotion.sheetLarge;

  @override
  State<BrandSheetScaffold> createState() => _BrandSheetScaffoldState();
}

class _BrandSheetScaffoldState extends State<BrandSheetScaffold>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const SystemUiOverlayStyle _statusBar = SystemUiOverlayStyle(
    statusBarColor: AppColors.scrimTransparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  late final AnimationController _rise = AnimationController(
    vsync: this,
    duration: BrandSheetScaffold.riseDelay + BrandSheetScaffold.riseDuration,
    value: widget.rise ? 0 : 1,
  );
  late final CurvedAnimation _riseCurve = CurvedAnimation(
    parent: _rise,
    curve: Interval(
      BrandSheetScaffold.riseDelay.inMicroseconds /
          (BrandSheetScaffold.riseDelay + BrandSheetScaffold.riseDuration)
              .inMicroseconds,
      1,
      curve: AppMotion.emphasizedDecelerate,
    ),
  );
  late final Animation<Offset> _sheetOffset = _riseCurve.drive(
    Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero),
  );
  late final Animation<double> _logoScale = _riseCurve.drive(
    Tween<double>(begin: BrandSheetScaffold.logoSettleFrom, end: 1),
  );
  late final AnimationController _fold = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );
  late final CurvedAnimation _foldCurve = CurvedAnimation(
    parent: _fold,
    curve: AppMotion.signature,
  );
  bool? _keyboardUp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionGuard.reduced(context)) {
      _rise.value = 1;
    } else if (!_rise.isCompleted && !_rise.isAnimating) {
      _rise.forward();
    }
    // A build follows: no setState here.
    _syncKeyboard(rebuild: false);
  }

  @override
  void didChangeMetrics() => _syncKeyboard(rebuild: true);

  /// Reacts only when "keyboard up" flips, never while it slides.
  void _syncKeyboard({required bool rebuild}) {
    if (!mounted) return;
    final up = View.of(context).viewInsets.bottom > 0;
    if (up == _keyboardUp) return;
    final firstLayout = _keyboardUp == null;
    if (rebuild) {
      setState(() => _keyboardUp = up);
    } else {
      _keyboardUp = up;
    }
    final target = up ? 1.0 : 0.0;
    if (firstLayout || MotionGuard.reduced(context)) {
      _fold.value = target;
    } else {
      _fold.animateTo(target);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _foldCurve.dispose();
    _fold.dispose();
    _riseCurve.dispose();
    _rise.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final statusBar = MediaQuery.paddingOf(context).top;
    final openTop = (screen.height * BrandSheetScaffold.headerShare).clamp(
      BrandSheetScaffold.minHeader,
      BrandSheetScaffold.maxHeader,
    );
    final foldedTop = statusBar + BrandSheetScaffold.foldedStrip;
    final band = Rect.fromLTRB(0, statusBar, screen.width, openTop);
    final foldShift = (foldedTop + statusBar) / 2 - band.center.dy;
    final wordHeight = (screen.width * BrandSheetScaffold.wordShare).clamp(
      BrandSheetScaffold.minWord,
      BrandSheetScaffold.maxWord,
    );
    final leading = widget.leading;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _statusBar,
      child: BrandSheetScope(
        fold: _foldCurve,
        child: Stack(
          children: [
            Positioned.fill(
              child: BrandBackdrop(
                band: band,
                animate: _keyboardUp != true,
                reveal: widget.rise,
              ),
            ),
            Positioned.fromRect(
              rect: band,
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_foldCurve, _logoScale]),
                  builder: (context, child) {
                    final fold = _foldCurve.value;
                    return Transform.translate(
                      offset: Offset(0, foldShift * fold),
                      child: Transform.scale(
                        scale:
                            _logoScale.value *
                            lerpDouble(
                              1,
                              BrandSheetScaffold.foldedLogoScale,
                              fold,
                            )!,
                        child: child,
                      ),
                    );
                  },
                  child: HeroLockup(
                    wordHeight: wordHeight,
                    semanticLabel: widget.logoLabel,
                    alive: _keyboardUp != true,
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _foldCurve,
              builder: (context, child) => Positioned(
                top: lerpDouble(openTop, foldedTop, _foldCurve.value),
                left: 0,
                right: 0,
                bottom: 0,
                child: child!,
              ),
              child: SlideTransition(
                position: _sheetOffset,
                child: BrandSheetSurface(child: widget.child),
              ),
            ),
            if (leading != null)
              PositionedDirectional(
                top: statusBar + AppSpacing.s8,
                start: AppSpacing.s12,
                child: leading,
              ),
          ],
        ),
      ),
    );
  }
}
