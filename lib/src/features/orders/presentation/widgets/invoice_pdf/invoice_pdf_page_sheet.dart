import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../domain/entities/invoice_document.dart';
import '../../../domain/entities/invoice_page_image.dart';

/// One page of the PDF preview: a white sheet of paper (A4, so it keeps its
/// shape before it is drawn) with the page's picture on it, or the dots
/// while it is being drawn. Read out as "Page 1 of 2".
class InvoicePdfPageSheet extends StatelessWidget {
  const InvoicePdfPageSheet({
    super.key,
    required this.number,
    required this.pageCount,
    this.image,
  });

  /// From 1.
  final int number;
  final int pageCount;

  /// `null` until the page is drawn.
  final InvoicePageImage? image;

  static const BorderRadius _corners = BorderRadius.all(
    Radius.circular(AppSize.r4),
  );

  static const BoxDecoration _paper = BoxDecoration(
    color: AppColors.white,
    borderRadius: _corners,
    boxShadow: AppShadows.medium,
  );

  @override
  Widget build(BuildContext context) {
    final image = this.image;
    return Semantics(
      image: true,
      label: 'orders.invoice_pdf_page'.tr(
        namedArgs: {'page': '$number', 'pages': '$pageCount'},
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s16),
        child: DecoratedBox(
          decoration: _paper,
          child: ClipRRect(
            borderRadius: _corners,
            child: AspectRatio(
              aspectRatio:
                  image?.aspectRatio ?? InvoiceDocument.pageAspectRatio,
              child: FadeThroughSwitcher(
                stateKey: image != null,
                crossFade: true,
                child: image != null
                    ? Image.memory(
                        image.png,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.medium,
                        excludeFromSemantics: true,
                      )
                    : const Center(child: AppLoader.inline(size: AppSize.s24)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
