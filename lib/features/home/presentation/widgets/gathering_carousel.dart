import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entities/gathering_card_entity.dart';
import '../util/gathering_card_display.dart';
import 'home_section_header.dart';

/// KeeTa home "gathering" carousel (`home_page_header_gathering_card_v3`): a
/// paged strip of 240×140 r16 promo cards with a bottom gradient
/// (`#030303ab → #6c372600`), a title + price band, and a dot indicator.
class GatheringCarousel extends StatefulWidget {
  const GatheringCarousel({
    super.key,
    required this.title,
    required this.cards,
    required this.onOpen,
    this.onSeeAll,
  });

  final String title;
  final List<GatheringCardEntity> cards;
  final void Function(String scheme) onOpen;
  final VoidCallback? onSeeAll;

  @override
  State<GatheringCarousel> createState() => _GatheringCarouselState();
}

class _GatheringCarouselState extends State<GatheringCarousel> {
  final _controller = PageController(viewportFraction: 0.66);
  Timer? _autoplay;

  // OS reduce-motion / screen-reader guard (resolved in didChangeDependencies).
  bool _reduced = false;

  // Whether this carousel is actually on-screen. The home tab lives inside the
  // shell's IndexedStack, so it stays mounted (and ticking) while the user is on
  // other tabs; off-tab children are Offstage and report 0% visible. Autoplay is
  // paused whenever this is false so the timer does not burn CPU off-screen.
  bool _visible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Real gathering carousel auto-loops at 3000ms (digest `enableCarouse`).
    // Skip autoplay entirely under OS reduce-motion / screen-reader — an
    // unsolicited moving carousel is disorienting and hijacks focus. Resolved
    // here (not initState) so MediaQuery is available for the guard.
    _reduced =
        MotionGuard.reduced(context) ||
        MediaQuery.accessibleNavigationOf(context);
    _syncAutoplay();
  }

  /// Runs the autoplay timer only while it should be running — visible AND not
  /// reduce-motion AND more than one card — and cancels it otherwise.
  void _syncAutoplay() {
    final shouldRun = _visible && !_reduced && widget.cards.length > 1;
    if (shouldRun) {
      _autoplay ??= Timer.periodic(AppMotion.carousel, (_) {
        if (!_controller.hasClients) return;
        final next =
            ((_controller.page ?? 0).round() + 1) % widget.cards.length;
        _controller.animateToPage(
          next,
          duration: AppMotion.slow,
          curve: AppMotion.signature,
        );
      });
    } else {
      _autoplay?.cancel();
      _autoplay = null;
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    final visible = info.visibleFraction > 0;
    if (visible == _visible) return;
    _visible = visible;
    _syncAutoplay();
  }

  @override
  void dispose() {
    _autoplay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    if (cards.isEmpty) return const SizedBox.shrink();
    return VisibilityDetector(
      key: const ValueKey('gathering-carousel-visibility'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeader(title: widget.title, onSeeAll: widget.onSeeAll),
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _controller,
              padEnds: false,
              itemCount: cards.length,
              itemBuilder: (_, i) => Padding(
                padding: EdgeInsetsDirectional.only(
                  start: i == 0 ? AppSpacing.pageMargin : 0,
                  end: AppSpacing.s8,
                ),
                child: _GatheringCardView(
                  card: cards[i],
                  onTap: () => widget.onOpen(cards[i].scheme),
                ),
              ),
            ),
          ),
          if (cards.length > 1)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.s8,
                bottom: AppSpacing.s4,
              ),
              child: SmoothPageIndicator(
                controller: _controller,
                count: cards.length,
                effect: const ExpandingDotsEffect(
                  dotHeight: 3,
                  dotWidth: 3,
                  expansionFactor: 3.33,
                  spacing: 2,
                  radius: 3,
                  activeDotColor: AppColors.primaryText,
                  dotColor: AppColors.dotInactive,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GatheringCardView extends StatelessWidget {
  const _GatheringCardView({required this.card, this.onTap});
  final GatheringCardEntity card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.r16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            KeetaImage(url: card.image, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 1.0],
                  colors: [
                    AppColors.gatheringScrimTop,
                    AppColors.gatheringScrimBottom,
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              start: 8,
              end: 8,
              bottom: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppSize.font13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  if (card.displaySubtitle.isNotEmpty || card.price > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (card.displaySubtitle.isNotEmpty)
                          Flexible(
                            child: Text(
                              card.displaySubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: AppSize.font10,
                                color: AppColors.subtitleOverlay,
                              ),
                            ),
                          ),
                        if (card.price > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            Formatters.price(card.price),
                            style: AppTextStyles.digits(14).copyWith(
                              color: AppColors.white,
                              fontWeight: AppTextStyles.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
