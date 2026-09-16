import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/shop_entity.dart';
import '../cubit/search_cubit.dart';
import '../widgets/keeta_search_bar.dart';
import '../widgets/popular_brands_grid.dart';
import '../widgets/suggestion_list.dart';

/// KeeTa global search entry (`c_search`) — a faithful rebuild of the real
/// screen. A grey search field at the very top; below it the empty state shows
/// **Recent searches** (r6 chips) + **Popular searches** (r50 pills, the first
/// promoted) + **Popular brands** (2-row logo grid). Typing swaps the body for
/// the KeeTa suggestion list. Committing a query navigates to the results page
/// ([Routes.searchShop]).
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchCubit>()..loadDiscover(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  SearchCubit get _cubit => context.read<SearchCubit>();

  void _submit(String term) {
    final t = term.trim();
    if (t.isEmpty) return;
    _cubit.addRecent(t);
    _focus.unfocus();
    Navigator.pushNamed(context, Routes.searchShop, arguments: t)
        .then((_) => _resetField());
  }

  /// Coming back from results: clear the field so the entry screen shows the
  /// discover state again (KeeTa returns to the empty search).
  void _resetField() {
    if (!mounted) return;
    _controller.clear();
    _cubit.clearActiveResults();
  }

  void _onClear() {
    _controller.clear();
    _cubit.clearQuery();
    _focus.requestFocus();
  }

  void _openShop(String shopId) =>
      Navigator.pushNamed(context, Routes.shop, arguments: shopId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SearchEntryBar(
            controller: _controller,
            focusNode: _focus,
            onChanged: _cubit.onQueryChanged,
            onSubmit: _submit,
            onClear: _onClear,
            onBack: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                final typing = state.query.trim().isNotEmpty;
                return ContentClamp(
                  child: typing
                      ? SuggestionList(
                          suggestions: state.suggestions,
                          query: state.query,
                          onTap: _submit,
                        )
                      : _DiscoverBody(
                          recent: state.recent,
                          hotWords: state.hotWords,
                          brands: state.brands,
                          onTerm: _submit,
                          onClearRecent: () => _cubit.clearRecent(),
                          onOpenShop: _openShop,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Discover body (empty query): recent + popular + brands ───────────────────
class _DiscoverBody extends StatelessWidget {
  const _DiscoverBody({
    required this.recent,
    required this.hotWords,
    required this.brands,
    required this.onTerm,
    required this.onClearRecent,
    required this.onOpenShop,
  });

  final List<String> recent;
  final List<String> hotWords;
  final List<ShopEntity> brands;
  final ValueChanged<String> onTerm;
  final VoidCallback onClearRecent;
  final void Function(String shopId) onOpenShop;

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      children: [
        if (recent.isNotEmpty) ...[
          _SectionHeader(
            title: 'search.recent_searches'.tr(),
            trailing: GestureDetector(
              onTap: onClearRecent,
              behavior: HitTestBehavior.opaque,
              child: const Icon(KeetaIcons.delete,
                  size: 20, color: AppColors.tertiaryText),
            ),
          ),
          _ChipWrap(
            children: [
              for (final t in recent)
                _RectChip(label: t, onTap: () => onTerm(t)),
            ],
          ),
        ],
        if (hotWords.isNotEmpty) ...[
          _SectionHeader(title: 'search.popular_searches'.tr()),
          _ChipWrap(
            children: [
              for (var i = 0; i < hotWords.length; i++)
                _PillChip(
                  label: hotWords[i],
                  highlighted: i == 0,
                  onTap: () => onTerm(hotWords[i]),
                ),
            ],
          ),
        ],
        if (brands.isNotEmpty) ...[
          _SectionHeader(title: '${'search.popular_brands'.tr()} 🔥'),
          const SizedBox(height: AppSpacing.s2),
          PopularBrandsGrid(brands: brands, onOpen: onOpenShop),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
          16, AppSpacing.s20, 16, AppSpacing.s8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.headingMedium
                  .copyWith(fontWeight: AppTextStyles.bold),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      child: Wrap(spacing: 0, runSpacing: 0, children: children),
    );
  }
}

/// Recent-search chip — rounded rectangle (`#F5F6FA`, r6, 30dp).
class _RectChip extends StatelessWidget {
  const _RectChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 10, bottom: 10),
      child: PressScale(
        onTap: onTap,
        // No fixed height / alignment — a bounded Wrap would stretch an aligned
        // Container to full width. Vertical padding gives the 30dp chip height.
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 15, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.mediumBackground, // #F5F6FA
            borderRadius: BorderRadius.circular(AppRadius.r6),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primaryText,
                fontWeight: AppTextStyles.regular,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Popular-search chip — full pill (`#F0F1F5`, r50). The first/promoted chip is
/// tinted (light-red bg + red text), mirroring KeeTa's hot-word highlight.
class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8, bottom: 8),
      child: PressScale(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.finalPriceBg // light red #FFF1F0
                : AppColors.smallBackground, // #F0F1F5
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyLarge.copyWith(
                color: highlighted ? AppColors.finalPrice : AppColors.black,
                fontWeight: AppTextStyles.regular,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
