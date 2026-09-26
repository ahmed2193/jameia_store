import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/route_args/category_args.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../core/domain/entities/catalog_category_entity.dart';
import 'assistant_pill_chip.dart';
import 'assistant_pill_rail.dart';

/// `categories`: sections to browse; a pill opens the section.
class AssistantCategoriesRail extends StatelessWidget {
  const AssistantCategoriesRail({super.key, required this.categories});

  final List<CatalogCategoryEntity> categories;

  @override
  Widget build(BuildContext context) {
    return AssistantPillRail(
      title: 'assistant.categories_title'.tr(),
      children: [
        for (final category in categories)
          AssistantPillChip(
            key: ValueKey(category.id),
            label: category.name,
            imageUrl: category.image,
            initial: category.initial,
            onTap: () =>
                context.push(Routes.category, extra: CategoryArgs.of(category)),
          ),
      ],
    );
  }
}
