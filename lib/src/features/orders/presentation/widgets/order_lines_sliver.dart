import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../../../core/domain/entities/order_line_entity.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/list_item_transition.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/widgets/thin_divider.dart';
import '../../domain/entities/order_line_changes.dart';
import 'order_line_row.dart';
import 'order_lines_card_section.dart';
import 'order_lines_receipt_section.dart';
import 'order_offer_line_row.dart';

/// The order's items as a sliver section, in one of two looks:
///
/// * the receipt (invoice): a "Your items" heading, flat rows split by
///   hairlines, the order total under them;
/// * the order page ([card]): the rows on a white hairline card under a
///   [leading] block (the store and the item count), with product photos
///   ([showThumbs]), folded to the first [collapsedCount] rows behind a
///   "Show N more" button that opens the rest in place (height, then
///   fade) and folds them back.
///
/// Either way each paid row says what picking did to it ([changes]: an
/// "Unavailable" tag, or "Replaced with …"). Lazy — a 60-line order builds
/// only the rows on screen. It keeps what it built: a tracking poll that
/// moves the status but not the lines gets the identical section back, so
/// the heading, the rows and the total do not rebuild.
class OrderLinesSliver extends StatefulWidget {
  const OrderLinesSliver({
    super.key,
    required this.orderId,
    required this.lines,
    required this.offerLines,
    required this.totalKd,
    this.showInvoiceLink = true,
    this.changes = OrderLineChanges.empty,
    this.card = false,
    this.leading,
    this.leadingKey,
    this.collapsedCount,
    this.showThumbs = false,
    this.showUnitPrice = false,
  });

  final String orderId;
  final List<OrderLineEntity> lines;
  final List<OrderOfferLineEntity> offerLines;
  final double totalKd;

  /// `false` on the invoice page itself, where the link would push a second
  /// copy of the page the customer is already reading. The receipt look
  /// only.
  final bool showInvoiceLink;
  final OrderLineChanges changes;

  /// The order page's look (see the class doc): no heading, no total.
  final bool card;

  /// Drawn at the top of the [card], above the rows.
  final Widget? leading;

  /// What [leading] shows (a value with `==`): the kept section is built
  /// again only when it changes — a new [leading] instance alone does not.
  final Object? leadingKey;

  /// Rows shown while folded; `null` = every row, no button.
  final int? collapsedCount;
  final bool showThumbs;

  /// Each row adds its unit price when more than one was bought (the
  /// invoice).
  final bool showUnitPrice;

  bool _showsSameAs(OrderLinesSliver other) =>
      orderId == other.orderId &&
      showInvoiceLink == other.showInvoiceLink &&
      totalKd == other.totalKd &&
      card == other.card &&
      (leading == null) == (other.leading == null) &&
      leadingKey == other.leadingKey &&
      collapsedCount == other.collapsedCount &&
      showThumbs == other.showThumbs &&
      showUnitPrice == other.showUnitPrice &&
      changes == other.changes &&
      listEquals(lines, other.lines) &&
      listEquals(offerLines, other.offerLines);

  @override
  State<OrderLinesSliver> createState() => _OrderLinesSliverState();
}

class _OrderLinesSliverState extends State<OrderLinesSliver>
    with SingleTickerProviderStateMixin {
  /// The section last built, and the language it was built in.
  Widget? _section;
  Locale? _sectionLocale;

  /// Every row is laid out (open, or folding back).
  bool _open = false;

  /// Height + fade of the rows past [OrderLinesSliver.collapsedCount].
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );

  static String _offerKey(OrderOfferLineEntity line) =>
      'offer:${line.offerId}:${line.productId}';

  int get _total => widget.lines.length + widget.offerLines.length;

  /// Rows past the fold (0 when nothing folds).
  int get _hidden {
    final limit = widget.collapsedCount;
    return limit == null || limit >= _total ? 0 : _total - limit;
  }

  /// Folding applies: there is a limit and more rows than it.
  bool get _foldable {
    final limit = widget.collapsedCount;
    return limit != null && _total > limit;
  }

  @override
  void didUpdateWidget(OrderLinesSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget._showsSameAs(oldWidget)) _section = null;
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _toggle() {
    Haptics.pick();
    final reduced = MotionGuard.reduced(context);
    if (!_open || _reveal.status == AnimationStatus.reverse) {
      setState(() {
        _open = true;
        _section = null;
      });
      if (reduced) {
        _reveal.value = 1;
      } else {
        _reveal.forward();
      }
      return;
    }
    // The toggle reads "Show N more" at once; the rows fold, then leave.
    setState(() => _section = null);
    if (reduced) {
      _reveal.value = 0;
      setState(() => _open = false);
      return;
    }
    _reveal.reverse().then((_) {
      if (mounted && _reveal.isDismissed) {
        setState(() {
          _open = false;
          _section = null;
        });
      }
    });
  }

  /// The toggle's own state: open unless folding back.
  bool get _expanded => _open && _reveal.status != AnimationStatus.reverse;

  @override
  Widget build(BuildContext context) {
    // Depends on the language, so a switch rebuilds the texts below.
    final locale = context.locale;
    final cached = _section;
    if (cached != null && locale == _sectionLocale) return cached;

    final orderId = widget.orderId;
    final lines = widget.lines;
    final offers = widget.offerLines;
    final changes = widget.changes;
    final foldable = _foldable;
    final limit = widget.collapsedCount ?? _total;
    final count = foldable && !_open ? limit : _total;
    // Item index by row key, so a poll that changes the lines keeps each
    // row's element (and its place) instead of rebuilding by position.
    final indexOf = <String, int>{
      for (var i = 0; i < lines.length; i++) lines[i].key: i,
      for (var i = 0; i < offers.length; i++)
        _offerKey(offers[i]): lines.length + i,
    };
    final list = SliverList.builder(
      itemCount: count,
      findChildIndexCallback: (key) =>
          key is ValueKey<String> ? indexOf[key.value] : null,
      itemBuilder: (_, index) {
        final String key;
        final Widget row;
        if (index < lines.length) {
          final line = lines[index];
          key = line.key;
          row = OrderLineRow(
            line: line,
            showThumb: widget.showThumbs,
            showUnitPrice: widget.showUnitPrice,
            outcome: changes.outcomeOf(line.key),
            substitution: changes.substitutionOf(line.key),
          );
        } else {
          final offer = offers[index - lines.length];
          key = _offerKey(offer);
          row = OrderOfferLineRow(line: offer, showThumb: widget.showThumbs);
        }
        final body = index == 0
            ? row
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [const ThinDivider(), row],
              );
        // Rows past the fold open and close together; the shape stays the
        // same while they are laid out, so none of them re-mounts.
        return foldable && index >= limit
            ? ListItemTransition(
                key: ValueKey<String>(key),
                animation: _reveal,
                child: body,
              )
            : KeyedSubtree(key: ValueKey<String>(key), child: body);
      },
    );
    final section = widget.card
        ? OrderLinesCardSection(
            list: list,
            leading: widget.leading,
            foldable: foldable,
            expanded: _expanded,
            hidden: _hidden,
            onToggle: _toggle,
          )
        : OrderLinesReceiptSection(
            list: list,
            orderId: orderId,
            totalKd: widget.totalKd,
            showInvoiceLink: widget.showInvoiceLink,
          );
    _section = section;
    _sectionLocale = locale;
    return section;
  }
}
