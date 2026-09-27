import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/back_to_top_overlay.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../../../core/widgets/screen_stale_notice.dart';
import '../../domain/entities/home_bootstrap.dart';
import '../../domain/entities/home_feed.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'home_announcement_ticker.dart';
import 'home_confetti.dart';
import 'home_greeting_strip.dart';
import 'home_header_sliver.dart';
import 'home_layout.dart';
import 'home_pro_banner.dart';
import 'home_reveal.dart';
import 'home_section_view.dart';
import 'home_slides_carousel.dart';

/// The loaded home feed, in the backend's order: header (store, delivery
/// place, search, notifications) → "Updated … ago" over a saved copy
/// (offline / failed refresh) → a hello for the hour → announcement
/// ticker → hero banners → the ordered content blocks → Pro banner. Blocks are built lazily while
/// scrolling, and each enters as it is first seen: the ones on screen at
/// launch one after another under the header, the rest as they are reached.
/// Well down the feed, a round button in the corner takes the customer back
/// to the top; confetti from a card flies over the whole feed.
class HomeFeedView extends StatelessWidget {
  const HomeFeedView({super.key, required this.feed, required this.bootstrap});

  final HomeFeed feed;
  final HomeBootstrap bootstrap;

  /// The launch cascade: greeting, ticker, banners, then the blocks in order.
  static const int _tickerOrder = 1;
  static const int _slidesOrder = 2;
  static const int _sectionsOrder = 3;

  @override
  Widget build(BuildContext context) {
    return ContentClamp(
      child: BackToTopOverlay(
        margin: HomeLayout.gutter,
        child: HomeConfetti(
          child: BrandedRefresh(
            onRefresh: () => context.read<HomeCubit>().refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Only this sliver rebuilds when the default address or the
                // unread badge changes.
                HomeHeaderSliver(bootstrap: bootstrap),
                // Selects only the freshness: never rebuilds the feed.
                const SliverToBoxAdapter(
                  child: ScreenStaleNotice<HomeCubit, HomeState>(),
                ),
                const SliverToBoxAdapter(
                  child: HomeReveal(child: HomeGreetingStrip()),
                ),
                if (feed.announcements.isNotEmpty)
                  SliverToBoxAdapter(
                    child: HomeReveal(
                      order: _tickerOrder,
                      child: HomeAnnouncementTicker(items: feed.announcements),
                    ),
                  ),
                if (feed.slides.isNotEmpty)
                  SliverToBoxAdapter(
                    child: HomeReveal(
                      order: _slidesOrder,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          bottom: HomeLayout.blockGap,
                        ),
                        child: HomeSlidesCarousel(slides: feed.slides),
                      ),
                    ),
                  ),
                SliverList.builder(
                  itemCount: feed.sections.length,
                  itemBuilder: (context, index) => HomeReveal(
                    key: ValueKey(feed.sections[index].id),
                    order: index + _sectionsOrder,
                    child: HomeSectionView(section: feed.sections[index]),
                  ),
                ),
                if (bootstrap.pro.enabled)
                  SliverToBoxAdapter(
                    child: HomeReveal(
                      order: feed.sections.length + _sectionsOrder,
                      child: HomeProBanner(
                        pro: bootstrap.pro,
                        onTap: () => context.push(Routes.proMembership),
                      ),
                    ),
                  ),
                // Clears the shell's bottom bar.
                const SliverToBoxAdapter(child: SizedBox(height: AppSize.s80)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
