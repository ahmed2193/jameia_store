import 'package:flutter/widgets.dart';

import '../widgets/hero_confirm_dialog.dart';
import 'navigation.dart';

/// Asks the customer to confirm through the one confirmation dialog
/// ([HeroConfirmDialog], popping in like the home popups) and answers `true`
/// only on the confirm pill — cancel, a barrier tap and the back gesture all
/// answer `false`. See [HeroConfirmDialog] for the fields.
Future<bool> showHeroConfirmDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? message,
  String? note,
  IconData? icon,
  Widget? art,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final confirmed = await showHeroDialog<bool>(
    context,
    barrierLabel: title,
    pop: true,
    pageBuilder: (_) => HeroConfirmDialog(
      title: title,
      confirmLabel: confirmLabel,
      message: message,
      note: note,
      icon: icon,
      art: art,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return confirmed ?? false;
}
