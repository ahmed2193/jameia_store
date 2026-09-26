import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/widgets/jameia_title_bar.dart';
import '../../../../core/widgets/round_back_button.dart';
import 'search_field.dart';

/// Top of the search screen (docs/design_system.md title bar): white with a
/// hairline shadow, the round back button only when there is a screen to go
/// back to — the Search tab has none — then the pill search field.
class SearchEntryBar extends StatelessWidget {
  const SearchEntryBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    // What an AppBar asks: is there a route under this one to go back to?
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          boxShadow: AppShadows.barBottom,
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: JameiaTitleBar.height,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: canPop ? AppSpacing.s12 : AppSpacing.gutter,
                end: AppSpacing.gutter,
              ),
              child: Row(
                children: [
                  if (canPop) ...[
                    const RoundBackButton(),
                    const SizedBox(width: AppSpacing.s12),
                  ],
                  Expanded(
                    child: SearchField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      onSubmit: onSubmit,
                      onClear: onClear,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
