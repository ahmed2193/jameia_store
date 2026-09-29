import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/rotating_line.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/home_announcement_item.dart';
import 'home_announcement_dots.dart';
import 'home_announcement_line.dart';
import 'home_layout.dart';

/// The announcement strip of the home feed ("Free delivery over 5.000 KWD"):
/// a dark card under the header that rolls through the store's notices on
/// the app's one ticker ([RotatingLine]: the next line rises into place as
/// the one on screen leaves above), while the dots on the trailing edge say
/// how many there are and which one shows.
///
/// Rolling is ambient motion: it stands still with a single notice, under
/// reduced motion, with a screen reader, while the tab is hidden, off screen
/// or in the background, and it rolls for at most the ambient budget each
/// time it comes into view. A screen reader hears every notice at once.
class HomeAnnouncementTicker extends StatefulWidget {
  const HomeAnnouncementTicker({super.key, required this.items});

  final List<HomeAnnouncementItem> items;

  @override
  State<HomeAnnouncementTicker> createState() => _HomeAnnouncementTickerState();
}

class _HomeAnnouncementTickerState extends State<HomeAnnouncementTicker> {
  static const double _height = AppSize.s44;
  static const String _readSeparator = '\n';

  /// The notice on screen, for the dots.
  int _index = 0;

  @override
  void didUpdateWidget(covariant HomeAnnouncementTicker old) {
    super.didUpdateWidget(old);
    if (_index >= widget.items.length) _index = 0;
  }

  void _shown(int index) {
    if (index != _index) setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        HomeLayout.gutter,
        0,
        HomeLayout.gutter,
        HomeLayout.blockGap,
      ),
      child: Container(
        height: _height,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s10,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(HomeLayout.radius),
          boxShadow: AppShadows.low,
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                container: true,
                label: items.map((item) => item.text).join(_readSeparator),
                child: RotatingLine(
                  items: [
                    for (final item in items)
                      RotatingLineItem(
                        id: item.id,
                        child: HomeAnnouncementLine(item: item),
                      ),
                  ],
                  onShown: _shown,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s10),
            HomeAnnouncementDots(count: items.length, index: _index),
          ],
        ),
      ),
    );
  }
}
