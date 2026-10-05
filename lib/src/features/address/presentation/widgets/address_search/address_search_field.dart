import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/typed_text_direction.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../cubit/place_search_cubit.dart';
import '../../cubit/place_search_state.dart';
import '../address_edit/address_field_clear_button.dart';

/// The search pill of the address search (muted fill, pill radius, 48 dp):
/// a magnifier, the words and — while there are words — a ⊗ that empties
/// it. It opens focused; every keystroke goes to the search, which asks
/// once the typing pauses. An answer's ↖ writes its name here, the caret
/// at the end, the keyboard up. The words read in their own direction
/// ([TypedTextDirection]).
class AddressSearchField extends StatefulWidget {
  const AddressSearchField({super.key});

  static const double height = AppSize.s48;

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  static const OutlineInputBorder _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
    borderSide: BorderSide.none,
  );

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  final TypedTextDirection _direction = TypedTextDirection();

  void _changed(String text) {
    _direction.follow(text);
    context.read<PlaceSearchCubit>().queryChanged(
      text,
      languageCode: context.locale.languageCode,
    );
  }

  void _clear() {
    _controller.clear();
    _changed('');
  }

  /// An answer's ↖: its [words] in the box; the search already asks.
  void _fill(String words) {
    _controller.value = TextEditingValue(
      text: words,
      selection: TextSelection.collapsed(offset: words.length),
    );
    _direction.follow(words);
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _direction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = Directionality.of(context);
    return BlocListener<PlaceSearchCubit, PlaceSearchState>(
      listenWhen: (_, next) => next.fill != null,
      listener: (_, state) {
        final words = state.fill;
        if (words != null) _fill(words);
      },
      child: SizedBox(
        height: AddressSearchField.height,
        child: ValueListenableBuilder<bool?>(
          valueListenable: _direction,
          builder: (context, _, _) => TextField(
            controller: _controller,
            focusNode: _focus,
            textDirection: _direction.directionIn(layout),
            textAlign: TypedTextDirection.startOf(layout),
            autofocus: true,
            onChanged: _changed,
            textInputAction: TextInputAction.search,
            textAlignVertical: TextAlignVertical.center,
            style: AppTextStyles.itemTitle,
            cursorColor: AppColors.primaryText,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.smallBackground,
              hintText: 'addr.search.hint'.tr(),
              hintMaxLines: 1,
              hintStyle: AppTextStyles.itemTitle.copyWith(
                color: AppColors.secondaryText,
              ),
              contentPadding: const EdgeInsetsDirectional.only(
                end: AppSpacing.s12,
              ),
              border: _border,
              enabledBorder: _border,
              focusedBorder: _border,
              prefixIcon: const HeroIcon(
                HeroIcons.search,
                size: AppSize.s24,
                color: AppColors.primaryText,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : AddressFieldClearButton(
                        label: 'addr.search.clear'.tr(),
                        onTap: _clear,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
