import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/order_line_entity.dart';
import '../../../../core/widgets/jameia_money_text.dart';
import '../../../../core/widgets/jameia_section_header.dart';
import '../../../../core/widgets/jameia_summary_line.dart';
import '../../../../core/widgets/thin_divider.dart';
import 'order_line_row.dart';
import 'order_offer_line_row.dart';

/// "Your items" as a sliver section of the tracking / invoice page: the
/// heading (with an underlined "Invoice" link unless this IS the invoice),
/// the paid lines then the free offer lines as flat rows split by hairlines,
/// and the order total. Lazy — a 60-line order builds only the rows on
/// screen, not every row in the first frame of the page transition.
///
/// Takes only the slice of the order it shows and keeps what it built: a
/// tracking poll that moves the status but not the lines gets the identical
/// section back, so the header, the rows and the total do not rebuild.
class OrderLinesSliver extends StatefulWidget {
  const OrderLinesSliver({
    super.key,
    required this.orderId,
    required this.lines,
    required this.offerLines,
    required this.totalKd,
    this.showInvoiceLink = true,
  });

  final String orderId;
  final List<OrderLineEntity> lines;
  final List<OrderOfferLineEntity> offerLines;
  final double totalKd;

  /// `false` on the invoice page itself, where the link would push a second
  /// copy of the page the customer is already reading.
  final bool showInvoiceLink;

  bool _showsSameAs(OrderLinesSliver other) =>
      orderId == other.orderId &&
      showInvoiceLink == other.showInvoiceLink &&
      totalKd == other.totalKd &&
      listEquals(lines, other.lines) &&
      listEquals(offerLines, other.offerLines);

  @override
  State<OrderLinesSliver> createState() => _OrderLinesSliverState();
}

class _OrderLinesSliverState extends State<OrderLinesSliver> {
  /// The section last built, and the language it was built in.
  Widget? _section;
  Locale? _sectionLocale;

  static String _offerKey(OrderOfferLineEntity line) =>
      'offer:${line.offerId}:${line.productId}';

  @override
  void didUpdateWidget(OrderLinesSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget._showsSameAs(oldWidget)) _section = null;
  }

  @override
  Widget build(BuildContext context) {
    // Depends on the language, so a switch rebuilds the texts below.
    final locale = context.locale;
    final cached = _section;
    if (cached != null && locale == _sectionLocale) return cached;

    final orderId = widget.orderId;
    final lines = widget.lines;
    final offers = widget.offerLines;
    // Item index by row key, so a poll that changes the lines keeps each
    // row's element (and its place) instead of rebuilding by position.
    final indexOf = <String, int>{
      for (var i = 0; i < lines.length; i++) lines[i].key: i,
      for (var i = 0; i < offers.length; i++)
        _offerKey(offers[i]): lines.length + i,
    };
    final section = SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: JameiaSectionHeader(
            title: 'orders.items_title'.tr(),
            titleStyle: AppTextStyles.groupTitle,
            seeAllLabel: 'orders.invoice'.tr(),
            onSeeAll: widget.showInvoiceLink
                ? () => context.push(Routes.orderInvoice, extra: orderId)
                : null,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.gutter,
          ),
          sliver: SliverList.separated(
            itemCount: lines.length + offers.length,
            findItemIndexCallback: (key) =>
                key is ValueKey<String> ? indexOf[key.value] : null,
            separatorBuilder: (_, _) => const ThinDivider(),
            itemBuilder: (_, index) {
              if (index < lines.length) {
                final line = lines[index];
                return OrderLineRow(
                  key: ValueKey<String>(line.key),
                  line: line,
                );
              }
              final offer = offers[index - lines.length];
              return OrderOfferLineRow(
                key: ValueKey<String>(_offerKey(offer)),
                line: offer,
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.gutter,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const ThinDivider(),
                const SizedBox(height: AppSpacing.s6),
                JameiaSummaryLine(
                  label: 'orders.total'.tr(),
                  emphasized: true,
                  value: JameiaMoneyText(kd: widget.totalKd),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    _section = section;
    _sectionLocale = locale;
    return section;
  }
}
