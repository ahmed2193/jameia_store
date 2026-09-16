import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/keeta_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// KeeTa `c_search` top bar (first view + typing). Back chevron in a 40dp left
/// gutter, then a grey field (`#F0F1F5`, 40dp tall, r10). A right cluster holds
/// a 1×24dp separator (`#00000014`) and the magnifier "search" button; a clear
/// `X` fades in while typing. Optional mic / list-search entries sit inside the
/// field while it is empty. All directional + text-scale safe.
class SearchEntryBar extends StatelessWidget {
  const SearchEntryBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
    required this.onBack,
    this.onMic,
    this.onListSearch,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;
  final VoidCallback onBack;
  final VoidCallback? onMic;
  final VoidCallback? onListSearch;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            top: AppSpacing.s8,
            bottom: AppSpacing.s8,
            end: 18,
          ),
          child: Row(
            children: [
              // 40dp back gutter.
              SizedBox(
                width: 40,
                child: IconButton(
                  onPressed: onBack,
                  icon: const Icon(KeetaIcons.back,
                      size: 16, color: AppColors.primaryText),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.smallBackground, // #F0F1F5
                          borderRadius: BorderRadius.circular(AppRadius.r5),
                        ),
                      ),
                      // Start-aligned, vertically-centered input; end padding
                      // clears the right cluster (magnifier / clear).
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                              start: 16, end: 60),
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            autofocus: true,
                            textAlign: TextAlign.start,
                            // Vertically center within the tight 40dp field.
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.search,
                            onChanged: onChanged,
                            onSubmitted: onSubmit,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.primaryText,
                              fontWeight: AppTextStyles.medium,
                            ),
                            cursorColor: AppColors.primaryText,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              // App-store style hint (14/medium/#696969).
                              hintText: 'search.store_hint'.tr(),
                              hintStyle: AppTextStyles.bodyLarge.copyWith(
                                color: kJameiaSearchHint,
                                fontWeight: AppTextStyles.medium,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Right cluster: [empty→mic/list | typing→X] + separator + magnifier.
                      PositionedDirectional(
                        end: 0,
                        top: 0,
                        bottom: 0,
                        child: ListenableBuilder(
                          listenable: controller,
                          builder: (context, _) {
                            final typing = controller.text.isNotEmpty;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (typing)
                                  _FieldIcon(
                                    icon: KeetaIcons.searchClear,
                                    color: AppColors.tertiaryText,
                                    onTap: onClear,
                                  )
                                else ...[
                                  if (onMic != null)
                                    _FieldIcon(
                                      icon: Icons.mic_none_rounded,
                                      color: AppColors.tertiaryText,
                                      onTap: onMic!,
                                    ),
                                  if (onListSearch != null)
                                    _FieldIcon(
                                      icon: Icons.fact_check_outlined,
                                      color: AppColors.tertiaryText,
                                      onTap: onListSearch!,
                                    ),
                                ],
                                // 1×24dp separator #00000014.
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: AppColors.overlayDivider,
                                ),
                                _FieldIcon(
                                  icon: KeetaIcons.search,
                                  size: 18,
                                  color: AppColors.primaryText,
                                  onTap: () => onSubmit(controller.text),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldIcon extends StatelessWidget {
  const _FieldIcon({
    required this.icon,
    required this.onTap,
    this.size = 16,
    this.color = AppColors.tertiaryText,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 30,
        height: 40,
        child: Center(child: Icon(icon, size: size, color: color)),
      ),
    );
  }
}

/// KeeTa `c_search_shop` results bar: back chevron + a fully-rounded grey pill
/// (`#F5F6FA`, 46dp, r23) with a LEFT magnifier, the committed query, and a
/// trailing clear `X`. The pill is read-only — tapping it returns to the search
/// entry screen for re-editing (matches KeeTa).
class ResultsSearchBar extends StatelessWidget {
  const ResultsSearchBar({
    super.key,
    required this.query,
    required this.onBack,
    required this.onTapField,
    required this.onClear,
  });

  final String query;
  final VoidCallback onBack;
  final VoidCallback onTapField;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            top: AppSpacing.s8,
            bottom: AppSpacing.s8,
            end: 14,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: IconButton(
                  onPressed: onBack,
                  icon: const Icon(KeetaIcons.back,
                      size: 18, color: AppColors.primaryText),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onTapField,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 46,
                    padding:
                        const EdgeInsetsDirectional.only(start: 12, end: 10),
                    decoration: BoxDecoration(
                      color: AppColors.mediumBackground, // #F5F6FA
                      borderRadius: BorderRadius.circular(AppSize.r23),
                    ),
                    child: Row(
                      children: [
                        const Icon(KeetaIcons.search,
                            size: 20, color: AppColors.tertiaryText),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: Text(
                            query.trim().isEmpty
                                ? 'search.shop_search_hint'.tr()
                                : query,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: query.trim().isEmpty
                                  ? AppColors.tertiaryText
                                  : AppColors.primaryText,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onClear,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.disabledText,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 12, color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
