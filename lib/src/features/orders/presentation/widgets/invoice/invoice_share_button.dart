import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/widgets/hero_secondary_button.dart';
import '../../../domain/entities/invoice_share_origin.dart';
import '../../cubit/invoice_export_cubit.dart';

/// "Share": hands the file to the system share sheet, which an iPad shows as
/// a popover pointing at this button (phones ignore where it came from).
class InvoiceShareButton extends StatelessWidget {
  const InvoiceShareButton({super.key, required this.enabled});

  final bool enabled;

  void _share(BuildContext context) {
    final box = context.findRenderObject();
    final origin = box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    context.read<InvoiceExportCubit>().share(
      origin: origin == null
          ? null
          : InvoiceShareOrigin(
              left: origin.left,
              top: origin.top,
              width: origin.width,
              height: origin.height,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HeroSecondaryButton(
      label: 'orders.invoice_pdf_share'.tr(),
      icon: HeroIcons.share,
      expanded: true,
      onPressed: enabled ? () => _share(context) : null,
    );
  }
}
