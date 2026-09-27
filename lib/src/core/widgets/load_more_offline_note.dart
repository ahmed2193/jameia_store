import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'offline_inline_note.dart';

/// The end of a paginated list whose next page could not load for want of a
/// connection: "More will load when you're back" — the list asks again by
/// itself on reconnect, so there is no button. Each list keeps its own
/// loader and retry for the other cases.
class LoadMoreOfflineNote extends StatelessWidget {
  const LoadMoreOfflineNote({
    super.key,
    this.padding = OfflineInlineNote.defaultPadding,
  });

  /// A list that already keeps its side gutters passes a vertical one.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => OfflineInlineNote(
    message: 'connectivity.load_more_offline'.tr(),
    padding: padding,
  );
}
