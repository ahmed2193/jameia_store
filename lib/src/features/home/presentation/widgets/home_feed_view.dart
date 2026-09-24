import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../../domain/entities/home_bootstrap.dart';
import '../../domain/entities/home_feed.dart';
import '../cubit/home_cubit.dart';
import 'home_announcement_ticker.dart';
import 'home_header_sliver.dart';
import 'home_pro_banner.dart';
import 'home_section_view.dart';
import 'home_slides_carousel.dart';

/// The loaded home feed, in the backend's order: header (delivery place,
/// search, notifications) → announcement ticker → hero slides → the ordered
/// content blocks → Pro banner. Blocks are built lazily while scrolling.
class HomeFeedView extends StatelessWidget {
  const HomeFeedView({super.key, required this.feed, required this.bootstrap});

  final HomeFeed feed;
  final HomeBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    final placeName = bootstrap.delivery?.placeName ?? '';
    return ContentClamp(
      child: BrandedRefresh(
        onRefresh: () => context.read<HomeCubit>().refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Only this sliver rebuilds when the default address or the
            // unread badge changes.
            HomeHeaderSliver(fallbackPlace: placeName),
            if (feed.announcements.isNotEmpty)
              SliverToBoxAdapter(
                child: HomeAnnouncementTicker(items: feed.announcements),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s12)),
            if (feed.slides.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppSpacing.s8,
                  ),
                  child: HomeSlidesCarousel(slides: feed.slides),
                ),
              ),
            SliverList.builder(
              itemCount: feed.sections.length,
              itemBuilder: (context, index) => StaggerEntrance(
                index: index,
                child: HomeSectionView(
                  key: ValueKey(feed.sections[index].id),
                  section: feed.sections[index],
                ),
              ),
            ),
            if (bootstrap.pro.enabled)
              SliverToBoxAdapter(
                child: HomeProBanner(
                  pro: bootstrap.pro,
                  onTap: () => context.push(Routes.proMembership),
                ),
              ),
            // Clears the shell's bottom bar.
            const SliverToBoxAdapter(child: SizedBox(height: AppSize.s80)),
          ],
        ),
      ),
    );
  }
}
