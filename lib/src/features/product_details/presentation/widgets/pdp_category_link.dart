import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/category_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import 'pdp_link_row.dart';
import 'pdp_section.dart';

/// "Category ›" at the end of the product page: a flat row to the products
/// of the product's category. (The brand is a link above the name.)
class PdpCategoryLink extends StatelessWidget {
  const PdpCategoryLink({super.key, required this.category});

  final CatalogCategoryEntity category;

  @override
  Widget build(BuildContext context) {
    return PdpSection(
      child: PdpLinkRow(
        label: 'product.category'.tr(),
        value: category.name,
        onTap: () =>
            context.push(Routes.category, extra: CategoryArgs.of(category)),
      ),
    );
  }
}
