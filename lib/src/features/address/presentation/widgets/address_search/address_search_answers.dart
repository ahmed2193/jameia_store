import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../domain/entities/place_suggestion.dart';
import 'google_maps_credit.dart';
import 'place_suggestion_row.dart';
import 'search_row_divider.dart';
import 'use_my_location_row.dart';

/// The answers of the address search under "Use my current location",
/// Google Maps style: hairlines between the rows, each with its ↖
/// ([onFill]). While a newer search runs the last answers stay up, dimmed
/// (the dots stand in for them when there are none yet); answers from
/// Google end with the "Google Maps" credit.
class AddressSearchAnswers extends StatelessWidget {
  const AddressSearchAnswers({
    super.key,
    required this.suggestions,
    required this.searching,
    required this.lookingUpId,
    required this.creditsGoogle,
    required this.onPick,
    required this.onFill,
    required this.onMyLocation,
  });

  final List<PlaceSuggestion> suggestions;

  /// A newer search is running.
  final bool searching;

  /// The id of the answer whose point is being looked up.
  final String? lookingUpId;
  final bool creditsGoogle;
  final ValueChanged<PlaceSuggestion> onPick;

  /// The ↖ of an answer: its name goes into the search box.
  final ValueChanged<PlaceSuggestion> onFill;
  final VoidCallback onMyLocation;

  static const double _dimmed = 0.5;

  @override
  Widget build(BuildContext context) {
    final busy = lookingUpId != null;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s24),
      children: [
        UseMyLocationRow(onTap: onMyLocation),
        if (suggestions.isEmpty && searching)
          const Padding(
            padding: EdgeInsetsDirectional.all(AppSpacing.s24),
            child: AppLoader.inline(size: AppSize.s28),
          )
        else
          AnimatedOpacity(
            opacity: searching ? _dimmed : 1,
            duration: MotionGuard.duration(context, AppMotion.fast),
            curve: AppMotion.signature,
            child: Column(
              children: [
                for (final suggestion in suggestions) ...[
                  const SearchRowDivider(),
                  PlaceSuggestionRow(
                    suggestion: suggestion,
                    lookingUp: suggestion.id == lookingUpId,
                    onTap: busy ? null : () => onPick(suggestion),
                    onFill: () => onFill(suggestion),
                  ),
                ],
                if (creditsGoogle) const GoogleMapsCredit(),
              ],
            ),
          ),
      ],
    );
  }
}
