import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import 'collection_app_bar_delegate.dart';
import 'collection_hero.dart';

/// Builds the scroll view of a collection page from its header slivers —
/// usually by passing them to the page's list body.
typedef CollectionBodyBuilder = Widget Function(
  BuildContext context,
  List<Widget> headerSlivers,
);

/// The frame of a collection page (flash deals, best sellers, a brand, the
/// offers): a pinned top bar (back, the store's name, search) that turns
/// from the hero's warm tint to white as the hero scrolls away, the hero
/// ([CollectionHero]), optional pinned [tabs], the page's own list, and a
/// [bottomBar] (the "View cart" pill).
///
/// Follows the list through its scroll notifications, so the list keeps its
/// own controller, pull-to-refresh and "back to top".
class CollectionFrame extends StatefulWidget {
  const CollectionFrame({
    super.key,
    required this.storeName,
    required this.heading,
    required this.onSearch,
    required this.bodyBuilder,
    this.flame = false,
    this.subtitle,
    this.heroTrailing,
    this.tabs,
    this.onBack,
    this.bottomBar,
  });

  final String storeName;
  final String heading;
  final VoidCallback onSearch;
  final CollectionBodyBuilder bodyBuilder;

  /// A sale or deals page: the Hero flame follows the heading.
  final bool flame;
  final String? subtitle;

  /// Under the heading (a countdown for a flash sale).
  final Widget? heroTrailing;

  /// A pinned sliver under the hero (the category tabs), or null.
  final Widget? tabs;

  /// Null when there is nothing to go back to.
  final VoidCallback? onBack;
  final Widget? bottomBar;

  /// How much of the top the pinned bar covers (status bar included) — where
  /// a pull-to-refresh spinner starts, and where pinned tabs sit.
  static double pinnedExtent(BuildContext context) =>
      MediaQuery.paddingOf(context).top + CollectionAppBarDelegate.barHeight;

  @override
  State<CollectionFrame> createState() => _CollectionFrameState();
}

class _CollectionFrameState extends State<CollectionFrame> {
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);
  double _heroExtent = 0;
  double _pixels = 0;

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _updateProgress() {
    _progress.value = _heroExtent <= 0
        ? 0
        : (_pixels / _heroExtent).clamp(0.0, 1.0);
  }

  bool _follow(Notification notification) {
    final (metrics, depth) = switch (notification) {
      ScrollNotification(:final metrics) => (metrics, notification.depth),
      ScrollMetricsNotification(:final metrics) => (
        metrics,
        notification.depth,
      ),
      _ => (null, 0),
    };
    // Only the page's own list, not a rail inside it.
    if (metrics == null || depth != 0 || metrics.axis != Axis.vertical) {
      return false;
    }
    _pixels = metrics.pixels;
    _updateProgress();
    return false;
  }

  void _heroMeasured(double extent) {
    _heroExtent = extent;
    _updateProgress();
  }

  @override
  Widget build(BuildContext context) {
    final strings = MaterialLocalizations.of(context);
    final tabs = widget.tabs;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: NotificationListener<Notification>(
        onNotification: _follow,
        child: widget.bodyBuilder(context, [
          SliverPersistentHeader(
            pinned: true,
            delegate: CollectionAppBarDelegate(
              topInset: MediaQuery.paddingOf(context).top,
              title: widget.storeName,
              progress: _progress,
              onBack: widget.onBack,
              onSearch: widget.onSearch,
              backLabel: strings.backButtonTooltip,
              searchLabel: strings.searchFieldLabel,
              showsHairline: tabs == null,
            ),
          ),
          SliverToBoxAdapter(
            child: CollectionHero(
              heading: widget.heading,
              flame: widget.flame,
              subtitle: widget.subtitle,
              trailing: widget.heroTrailing,
              onExtent: _heroMeasured,
            ),
          ),
          ?tabs,
        ]),
      ),
      bottomNavigationBar: widget.bottomBar,
    );
  }
}
