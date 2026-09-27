import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/widgets/catalog_product_card.dart';
import '../../cubit/checkout_rail_cubit.dart';
import '../../cubit/checkout_rail_state.dart';
import 'checkout_band.dart';
import 'checkout_rail_header.dart';
import 'checkout_rail_list.dart';

/// Block B of the checkout: "Deals you might have missed" — on-sale,
/// in-stock products the basket does not hold yet, on a mint wash that
/// fades to white.
///
/// The page shows its content only once the rail is settled, so this block
/// is decided before the first paint: [CheckoutRailStatus.ready] shows the
/// rail at a height that never changes afterwards (a card cell at the
/// reader's text scale, whatever the products); loading and hidden take no
/// room. No skeleton, no cascade: the rail arrives with the page.
class CheckoutRailSection extends StatelessWidget {
  const CheckoutRailSection({super.key});

  /// Where the mint wash has faded to white (≈ the top 50 dp of the block).
  static const double _washEnd = 0.15;

  static const LinearGradient _wash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[AppColors.successBg, AppColors.white],
    stops: <double>[0, _washEnd],
  );

  static const List<CatalogProductEntity> _none = <CatalogProductEntity>[];

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      CheckoutRailCubit,
      CheckoutRailState,
      List<CatalogProductEntity>
    >(
      selector: (state) =>
          state.status == CheckoutRailStatus.ready ? state.products : _none,
      builder: (context, products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return CheckoutBand(
          gradient: _wash,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CheckoutRailHeader(),
              SizedBox(
                height: CatalogProductCard.cellHeight(context),
                child: CheckoutRailList(products: products),
              ),
            ],
          ),
        );
      },
    );
  }
}
