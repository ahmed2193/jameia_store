import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';

/// KeeTa global search (`c_search` + `c_search_shop`) — a faithful 1:1 clone.
///
/// • Query EMPTY → Discover landing: hot-word chips + recent-searches list.
/// • Query TYPED → live shop/dish results from [KeetaRepository.searchShops]
///   rendered with [ShopCard]; tap → [Routes.shop] (arg: shop.id).
/// • No matches → empty-results state.
///
/// Page-scoped state lives in the [State] + a [TextEditingController]; the dummy
/// data is read straight from the get_it-registered repository (no cubit needed
/// for this read-only, in-frame filter).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _repo = sl<KeetaRepository>();

  /// Session-lived recent searches (most-recent first). KeeTa persists these
  /// server-side; the clone keeps them in-memory for the page lifetime.
  final List<String> _recent = <String>[];

  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final q = _controller.text;
    if (q == _query) return;
    setState(() => _query = q);
  }

  /// Hot-word chips — derived from the most common shop tags in the catalog,
  /// mirroring KeeTa's server-driven `hotword` block.
  List<String> get _hotWords {
    final seen = <String>{};
    final words = <String>[];
    for (final s in _repo.shops) {
      for (final t in s.tags) {
        if (seen.add(t)) words.add(t);
        if (words.length >= 10) return words;
      }
    }
    return words;
  }

  void _submit(String term) {
    final t = term.trim();
    if (t.isEmpty) return;
    _recent.remove(t);
    _recent.insert(0, t);
    if (_recent.length > 10) _recent.removeLast();
    _controller
      ..text = t
      ..selection = TextSelection.collapsed(offset: t.length);
    _focus.requestFocus();
    setState(() => _query = t);
  }

  void _clearField() {
    _controller.clear();
    _focus.requestFocus();
    setState(() => _query = '');
  }

  void _clearRecent() => setState(_recent.clear);

  void _openShop(String shopId) {
    if (_query.trim().isNotEmpty) {
      _recent.remove(_query.trim());
      _recent.insert(0, _query.trim());
      if (_recent.length > 10) _recent.removeLast();
    }
    Navigator.pushNamed(context, Routes.shop, arguments: shopId);
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.trim().isNotEmpty;
    final results = hasQuery ? _repo.searchShops(_query) : const <Shop>[];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _controller,
              focusNode: _focus,
              showClear: _controller.text.isNotEmpty,
              onClear: _clearField,
              onSubmit: _submit,
              onBack: () => Navigator.maybePop(context),
            ),
            const ThinDivider(),
            Expanded(
              child: AnimatedSwitcher(
                duration:
                    MotionGuard.duration(context, AppMotion.fast),
                switchInCurve: AppMotion.signature,
                child: !hasQuery
                    ? _DiscoverLanding(
                        key: const ValueKey('discover'),
                        hotWords: _hotWords,
                        recent: _recent,
                        onTapWord: _submit,
                        onClearRecent: _clearRecent,
                      )
                    : results.isEmpty
                        ? _EmptyResults(
                            key: const ValueKey('empty'), query: _query)
                        : _Results(
                            key: const ValueKey('results'),
                            shops: results,
                            onTapShop: _openShop,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.showClear,
    required this.onClear,
    required this.onSubmit,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showClear;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.pageMargin, vertical: AppSpacing.s8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(KeetaIcons.back,
                size: 22, color: AppColors.primaryText),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Container(
              height: 40,
              padding:
                  const EdgeInsetsDirectional.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.mediumBackground,
                borderRadius: BorderRadius.circular(AppRadius.r1),
              ),
              child: Row(
                children: [
                  const Icon(KeetaIcons.search,
                      size: 18, color: AppColors.tertiaryText),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: onSubmit,
                      style: AppTextStyles.bodyLarge,
                      cursorColor: AppColors.primaryText,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Search shops & dishes',
                        hintStyle: AppTextStyles.bodyLarge
                            .copyWith(color: AppColors.tertiaryText),
                      ),
                    ),
                  ),
                  if (showClear)
                    GestureDetector(
                      onTap: onClear,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsetsDirectional.only(start: 4),
                        child: Icon(KeetaIcons.searchClear,
                            size: 16, color: AppColors.tertiaryText),
                      ),
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onSubmit(controller.text),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding:
                  const EdgeInsetsDirectional.only(start: AppSpacing.s8),
              child: Text('Search',
                  style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: AppTextStyles.bold,
                      color: AppColors.primaryText)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Discover landing (empty query) ──────────────────────────────────────────

class _DiscoverLanding extends StatelessWidget {
  const _DiscoverLanding({
    super.key,
    required this.hotWords,
    required this.recent,
    required this.onTapWord,
    required this.onClearRecent,
  });

  final List<String> hotWords;
  final List<String> recent;
  final ValueChanged<String> onTapWord;
  final VoidCallback onClearRecent;

  @override
  Widget build(BuildContext context) {
    return ContentClamp(
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s24),
        children: [
          if (recent.isNotEmpty) ...[
            _RecentHeader(onClear: onClearRecent),
            ...recent.map((t) => _RecentRow(
                  term: t,
                  onTap: () => onTapWord(t),
                )),
            const SizedBox(height: AppSpacing.s8),
          ],
          if (hotWords.isNotEmpty) ...[
            const _HotHeader(),
            _HotWordWrap(words: hotWords, onTap: onTapWord),
          ],
        ],
      ),
    );
  }
}

class _HotHeader extends StatelessWidget {
  const _HotHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.pageMargin,
          AppSpacing.s16, AppSpacing.pageMargin, AppSpacing.s8),
      child: Row(
        children: [
          const Icon(KeetaIcons.flame, size: 16, color: AppColors.accent1),
          const SizedBox(width: AppSpacing.s4),
          Text('Hot searches',
              style: AppTextStyles.headingMedium
                  .copyWith(fontWeight: AppTextStyles.bold)),
        ],
      ),
    );
  }
}

class _RecentHeader extends StatelessWidget {
  const _RecentHeader({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.pageMargin,
          AppSpacing.s16, AppSpacing.pageMargin, AppSpacing.s8),
      child: Row(
        children: [
          Expanded(
            child: Text('Recent searches',
                style: AppTextStyles.headingMedium
                    .copyWith(fontWeight: AppTextStyles.bold)),
          ),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: const Icon(KeetaIcons.delete,
                size: 18, color: AppColors.tertiaryText),
          ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.term, required this.onTap});
  final String term;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.pageMargin, vertical: AppSpacing.s12),
        child: Row(
          children: [
            const Icon(KeetaIcons.time,
                size: 16, color: AppColors.tertiaryText),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Text(term,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge),
            ),
            const Icon(KeetaIcons.arrowRightSmall,
                size: 16, color: AppColors.disabledText),
          ],
        ),
      ),
    );
  }
}

class _HotWordWrap extends StatelessWidget {
  const _HotWordWrap({required this.words, required this.onTap});
  final List<String> words;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.pageMargin),
      child: Wrap(
        spacing: AppSpacing.s8,
        runSpacing: AppSpacing.s8,
        children: [
          for (final w in words)
            GestureDetector(
              onTap: () => onTap(w),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.mediumBackground,
                  borderRadius: BorderRadius.circular(AppRadius.r1),
                ),
                child: Text(w,
                    style: AppTextStyles.captionLarge
                        .copyWith(color: AppColors.secondaryText)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Live results (typing) ───────────────────────────────────────────────────

class _Results extends StatelessWidget {
  const _Results({
    super.key,
    required this.shops,
    required this.onTapShop,
  });

  final List<Shop> shops;
  final ValueChanged<String> onTapShop;

  @override
  Widget build(BuildContext context) {
    return ContentClamp(
      child: ListView.separated(
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: AppSpacing.s24),
        itemCount: shops.length,
        separatorBuilder: (_, _) =>
            const ThinDivider(indent: AppSpacing.pageMargin),
        itemBuilder: (_, i) => ShopCard(
          shop: shops[i],
          onTap: () => onTapShop(shops[i].id),
        ),
      ),
    );
  }
}

// ── Empty results ───────────────────────────────────────────────────────────

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.search_off_rounded,
      message: 'No results for "${query.trim()}"',
    );
  }
}
