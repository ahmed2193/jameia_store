import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/product_detail_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';
import 'jameia_search_bar.dart';
import 'search_discover_view.dart';
import 'search_suggestions_view.dart';

/// The search tab: the entry bar over either the discover blocks (empty field)
/// or the live product suggestions (typing). Committing a term remembers it
/// and opens the results — the product listing scoped by that text.
class SearchBody extends StatefulWidget {
  const SearchBody({super.key});

  @override
  State<SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<SearchBody> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit(String term) async {
    final text = term.trim();
    if (text.isEmpty) return;
    final cubit = context.read<SearchCubit>()..addRecent(text);
    _focus.unfocus();
    await context.push(Routes.searchShop, extra: text);
    // Back from the results: the entry screen shows discover again.
    if (!mounted) return;
    _controller.clear();
    cubit.clearQuery();
  }

  void _clear() {
    _controller.clear();
    context.read<SearchCubit>().clearQuery();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    return ColoredBox(
      color: AppColors.white,
      child: Column(
        children: [
          SearchEntryBar(
            controller: _controller,
            focusNode: _focus,
            onChanged: cubit.onQueryChanged,
            onSubmit: _submit,
            onClear: _clear,
            onBack: () => context.canPop() ? context.pop() : _focus.unfocus(),
          ),
          Expanded(
            child: ContentClamp(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) => state.isTyping
                    ? SearchSuggestionsView(
                        state: state,
                        onSeeAll: () => _submit(state.query),
                        onOpenProduct: (product) => context.push(
                          Routes.productDetail,
                          extra: ProductDetailArgs.of(product),
                        ),
                      )
                    : SearchDiscoverView(
                        state: state,
                        onTerm: _submit,
                        onClearRecents: cubit.clearRecents,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
