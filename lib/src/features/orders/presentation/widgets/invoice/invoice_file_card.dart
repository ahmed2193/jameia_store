import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/size_fade_switcher.dart';
import '../../../../../core/widgets/hero_bidi_text.dart';
import '../../../../../core/widgets/hero_icon_plate.dart';
import '../../../../../core/widgets/hero_surface_card.dart';
import '../../../domain/entities/invoice_document.dart';
import '../../cubit/invoice_export_cubit.dart';
import '../../cubit/invoice_export_state.dart';
import 'invoice_file_status.dart';

/// The file as it will be saved: a document plate, its name (known before
/// it is made, so it never jumps), and where it stands under it — being
/// made, ready with its pages and size, or failed.
class InvoiceFileCard extends StatelessWidget {
  const InvoiceFileCard({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceExportCubit, InvoiceExportState>(
      buildWhen: (previous, current) =>
          previous.language != current.language ||
          previous.status != current.status ||
          previous.document != current.document,
      builder: (context, state) => HeroSurfaceCard(
        tone: HeroSurfaceTone.muted,
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Row(
          children: [
            const HeroIconPlate(HeroIcons.document),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Two lines before it is cut: the name is what the
                  // customer looks for in their files.
                  HeroBidiText(
                    InvoiceDocument.fileNameFor(orderNumber, state.language),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.itemTitleStrong,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  SizeFadeSwitcher(
                    stateKey: state.status,
                    child: InvoiceFileStatus(
                      status: state.status,
                      document: state.document,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
