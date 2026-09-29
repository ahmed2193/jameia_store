import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/motion.dart';

/// The product's description in grey, folded to [foldedLines] with an inline
/// underlined "… More" at the end of the last line; opened, it runs in full
/// and ends with an underlined "Less". A description that fits gets no link.
///
/// Where the fold falls is measured once per layout (width, text style and
/// scale, direction, language), never on every build.
class PdpDescriptionText extends StatefulWidget {
  const PdpDescriptionText({super.key, required this.description});

  final String description;

  static const int foldedLines = 2;

  @override
  State<PdpDescriptionText> createState() => _PdpDescriptionTextState();
}

class _PdpDescriptionTextState extends State<PdpDescriptionText> {
  static const String _ellipsis = '… ';
  static const String _space = ' ';

  late final TapGestureRecognizer _link = TapGestureRecognizer()
    ..onTap = _toggle;
  bool _expanded = false;

  /// What the fold below was measured for.
  (double, String, TextStyle, TextScaler, TextDirection, String)? _measuredFor;

  /// How much of the description the folded text keeps; `null` = it fits.
  int? _foldAt;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  void _toggle() {
    Haptics.pick();
    setState(() => _expanded = !_expanded);
  }

  /// Where the folded text must stop so that "… More" still ends its last
  /// line. The painters are set up exactly like the [Text] that shows it
  /// ([base] carries the inherited style, width basis and line heights).
  int? _measure({
    required double width,
    required DefaultTextStyle base,
    required TextStyle style,
    required TextStyle linkStyle,
    required TextScaler scaler,
    required TextDirection direction,
    required String more,
  }) {
    TextPainter painter(InlineSpan text, {int? maxLines}) => TextPainter(
      text: text,
      maxLines: maxLines,
      textDirection: direction,
      textScaler: scaler,
      textWidthBasis: base.textWidthBasis,
      textHeightBehavior: base.textHeightBehavior,
    );
    const lines = PdpDescriptionText.foldedLines;
    final full = painter(
      TextSpan(text: widget.description, style: style),
      maxLines: lines,
    )..layout(maxWidth: width);
    if (!full.didExceedMaxLines) {
      full.dispose();
      return null;
    }
    // The logical end of the last folded line (whatever the direction of
    // the words on it), then back until "… More" fits after it.
    final lastLine = full.height - full.preferredLineHeight / 2;
    final onLastLine = full.getPositionForOffset(Offset(width / 2, lastLine));
    var cut = full.getLineBoundary(onLastLine).end;
    full.dispose();
    while (cut > 0) {
      final probe = painter(
        TextSpan(
          style: style,
          children: [
            TextSpan(text: widget.description.substring(0, cut).trimRight()),
            const TextSpan(text: _ellipsis),
            TextSpan(text: more, style: linkStyle),
          ],
        ),
        maxLines: lines,
      )..layout(maxWidth: width);
      final fits = !probe.didExceedMaxLines;
      probe.dispose();
      if (fits) break;
      cut--;
    }
    return cut;
  }

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context);
    // The inherited style included, so the measure and the text agree (a
    // theme's letter spacing moves the fold).
    final style = base.style.merge(
      AppTextStyles.bodyLarge.copyWith(color: AppColors.secondaryText),
    );
    final linkStyle = style.copyWith(
      color: AppColors.primaryText,
      fontWeight: AppTextStyles.medium,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primaryText,
    );
    final more = 'product.more'.tr();
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final key = (
          constraints.maxWidth,
          widget.description,
          style,
          scaler,
          direction,
          more,
        );
        if (key != _measuredFor) {
          _measuredFor = key;
          _foldAt = _measure(
            width: constraints.maxWidth,
            base: base,
            style: style,
            linkStyle: linkStyle,
            scaler: scaler,
            direction: direction,
            more: more,
          );
        }
        final foldAt = _foldAt;
        final Widget text = foldAt == null
            ? Text(widget.description, style: style)
            : Text.rich(
                TextSpan(
                  children: _expanded
                      ? [
                          TextSpan(text: widget.description),
                          const TextSpan(text: _space),
                          TextSpan(
                            text: 'product.less'.tr(),
                            style: linkStyle,
                            recognizer: _link,
                          ),
                        ]
                      : [
                          TextSpan(
                            text: widget.description
                                .substring(0, foldAt)
                                .trimRight(),
                          ),
                          const TextSpan(text: _ellipsis),
                          TextSpan(
                            text: more,
                            style: linkStyle,
                            recognizer: _link,
                          ),
                        ],
                ),
                style: style,
                maxLines: _expanded ? null : PdpDescriptionText.foldedLines,
              );
        return AnimatedSize(
          duration: MotionGuard.duration(context, AppMotion.medium),
          curve: AppMotion.signature,
          alignment: AlignmentDirectional.topStart,
          child: Semantics(
            expanded: foldAt == null ? null : _expanded,
            child: text,
          ),
        );
      },
    );
  }
}
