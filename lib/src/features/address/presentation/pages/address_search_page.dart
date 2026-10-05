import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../domain/entities/map_destination.dart';
import '../cubit/place_search_cubit.dart';
import '../cubit/place_search_state.dart';
import '../widgets/address_search/address_search_header.dart';
import '../widgets/address_search/address_search_results.dart';

/// The address search over the map picker: type an area, a street or a
/// building and pick an answer (its point is looked up, then the map flies
/// there), or use the current location. Pops with a [MapDestination], or
/// nothing on back. Answers near [near] come first.
class AddressSearchPage extends StatelessWidget {
  const AddressSearchPage({super.key, this.near});

  /// Where the map looks.
  final GeoPointEntity? near;

  static bool _listenWhen(PlaceSearchState previous, PlaceSearchState next) =>
      next.picked != null || next.pickFailure != null;

  void _onState(BuildContext context, PlaceSearchState state) {
    final spot = state.picked;
    if (spot != null) {
      context.pop(PlaceDestination(spot));
      return;
    }
    final failure = state.pickFailure;
    if (failure != null) showFailureSnackBar(context, failure, action: true);
  }

  @override
  Widget build(BuildContext context) {
    // Read here: a provider's create may not listen to the locale.
    final languageCode = context.locale.languageCode;
    return BlocProvider(
      create: (_) =>
          sl<PlaceSearchCubit>(param1: near)
            ..showAreas(languageCode: languageCode),
      child: BlocListener<PlaceSearchCubit, PlaceSearchState>(
        listenWhen: _listenWhen,
        listener: _onState,
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            bottom: false,
            child: ContentClamp(
              child: Column(
                children: [
                  const AddressSearchHeader(),
                  Expanded(
                    child: AddressSearchResults(
                      onMyLocation: () =>
                          context.pop(const MyLocationDestination()),
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
