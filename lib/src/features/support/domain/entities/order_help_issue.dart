import 'package:equatable/equatable.dart';

import 'support_category.dart';
import 'support_category_entity.dart';

/// One answer to "What went wrong with this order?": a category and its
/// topic (none for "Something else"), and whether the customer must say
/// which items it concerns.
class OrderHelpIssue extends Equatable {
  const OrderHelpIssue({
    required this.category,
    this.topic,
    this.requireProducts = false,
  });

  /// "Something else": a ticket in [SupportCategory.other], about the order.
  static const OrderHelpIssue somethingElse = OrderHelpIssue(
    category: SupportCategory.other,
  );

  final SupportCategory category;
  final SupportTopic? topic;
  final bool requireProducts;

  /// i18n key of the option's name.
  String get labelKey => topic?.labelKey ?? 'support.topic_something_else';

  @override
  List<Object?> get props => [category, topic, requireProducts];
}

/// The issues of one category, as the help page groups them.
class OrderHelpIssueGroup extends Equatable {
  const OrderHelpIssueGroup({required this.category, required this.issues});

  /// The groups an ORDER can be helped with, in the API's order: every
  /// category whose tickets name an order (or have a topic that does), each
  /// with its topics; then "Something else". Categories about the account,
  /// the wallet or a subscription are not order problems and are left out.
  static List<OrderHelpIssueGroup> listOf(
    List<SupportCategoryEntity> categories,
  ) => [
    for (final category in categories)
      if (category.category != SupportCategory.other &&
          (category.requireOrder ||
              category.topics.any((topic) => topic.requireOrder)))
        OrderHelpIssueGroup(
          category: category.category,
          issues: [
            if (category.topics.isEmpty)
              OrderHelpIssue(
                category: category.category,
                requireProducts: category.requireProducts,
              ),
            for (final topic in category.topics)
              OrderHelpIssue(
                category: category.category,
                topic: topic.topic,
                requireProducts:
                    topic.requireProducts || category.requireProducts,
              ),
          ],
        ),
    const OrderHelpIssueGroup(
      category: SupportCategory.other,
      issues: [OrderHelpIssue.somethingElse],
    ),
  ];

  final SupportCategory category;
  final List<OrderHelpIssue> issues;

  @override
  List<Object?> get props => [category, issues];
}
