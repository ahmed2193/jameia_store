import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/product_detail_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/motion/fade_through_switcher.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';
import 'search_discover_view.dart';
import 'search_entry_bar.dart';
import 'search_suggestions_view.dart';

/// The search screen: the pill field over either the discover blocks (empty
/// field) or the live suggestions (typing), cross-faded. Committing a term
/// remembers it and opens the results — the product listing scoped by that
/// text. Back from the results the field is empty again, unless their search
/// pill sent the customer back to edit the text: the results route then pops
/// with the text to put back in the field.
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
    final edit = await context.push<String>(Routes.searchShop, extra: text);
    if (!mounted) return;
    if (edit == null) {
      // Back from the results: the entry screen shows discover again.
      _controller.clear();
      cubit.clearQuery();
      return;
    }
    _fill(edit);
  }

  /// Puts [text] in the field (cursor at its end) and goes on typing from
  /// there: a past term to refine, the text the results sent back, or ''.
  void _fill(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    final cubit = context.read<SearchCubit>();
    if (text.trim().isEmpty) {
      cubit.clearQuery();
    } else {
      cubit.onQueryChanged(text);
    }
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
            onClear: () => _fill(''),
          ),
          Expanded(
            child: ContentClamp(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) => FadeThroughSwitcher(
                  stateKey: state.isTyping,
                  alignment: AlignmentDirectional.topCenter,
                  child: state.isTyping
                      ? SearchSuggestionsView(
                          state: state,
                          onSearch: _submit,
                          onRefine: _fill,
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
          ),
        ],
      ),
    );
  }
}
