import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/widgets/failure_view.dart';
import '../../../domain/entities/place_suggestion.dart';
import '../../cubit/place_search_cubit.dart';
import '../../cubit/place_search_state.dart';
import 'address_search_answers.dart';
import 'address_search_empty.dart';
import 'address_search_idle.dart';

/// Everything under the address search pill, by the search's state: the
/// start ("Use my current location" + how to search), the answers, nothing
/// found, or a failed search with a retry. The four cross-fade. A tapped
/// answer has its point looked up; the page goes on once it is known. An
/// answer's ↖ puts its name in the search box.
class AddressSearchResults extends StatelessWidget {
  const AddressSearchResults({super.key, required this.onMyLocation});

  final VoidCallback onMyLocation;

  static bool _changed(PlaceSearchState previous, PlaceSearchState next) =>
      previous.status != next.status ||
      previous.suggestions != next.suggestions ||
      previous.lookingUpId != next.lookingUpId ||
      previous.areas != next.areas ||
      previous.failure != next.failure;

  /// Loading and answers share one view: the answers stay up, dimmed.
  static PlaceSearchStatus _bucket(PlaceSearchStatus status) =>
      status == PlaceSearchStatus.loading ? PlaceSearchStatus.results : status;

  @override
  Widget build(BuildContext context) {
    void pick(PlaceSuggestion suggestion) => context
        .read<PlaceSearchCubit>()
        .pick(suggestion, languageCode: context.locale.languageCode);
    void fill(PlaceSuggestion suggestion) => context
        .read<PlaceSearchCubit>()
        .fill(suggestion, languageCode: context.locale.languageCode);
    return BlocBuilder<PlaceSearchCubit, PlaceSearchState>(
      buildWhen: _changed,
      builder: (context, state) => FadeThroughSwitcher(
        stateKey: _bucket(state.status),
        crossFade: true,
        alignment: AlignmentDirectional.topCenter,
        child: switch (state.status) {
          PlaceSearchStatus.idle => AddressSearchIdle(
            areas: state.areas,
            lookingUpId: state.lookingUpId,
            onPick: pick,
            onMyLocation: onMyLocation,
          ),
          PlaceSearchStatus.loading ||
          PlaceSearchStatus.results => AddressSearchAnswers(
            suggestions: state.suggestions,
            searching: state.status == PlaceSearchStatus.loading,
            lookingUpId: state.lookingUpId,
            creditsGoogle: state.creditsGoogle,
            onPick: pick,
            onFill: fill,
            onMyLocation: onMyLocation,
          ),
          PlaceSearchStatus.empty => AddressSearchEmpty(
            onMyLocation: onMyLocation,
          ),
          PlaceSearchStatus.failed => FailureView(
            failure: state.failure,
            onRetry: context.read<PlaceSearchCubit>().retry,
          ),
        },
      ),
    );
  }
}
