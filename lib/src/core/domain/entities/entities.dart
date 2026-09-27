/// Barrel for the shared, framework-free domain entities.
///
/// Every entity here is consumed by more than one feature and/or by core UI
/// (`core/widgets`). DTO ⇄ entity mapping lives in `core/data/mappers/`.
library;

export '../localization/localized_pick.dart';
export 'address_label.dart';
export 'auth_customer_entity.dart';
export 'brand_entity.dart';
export 'cart_applied_offer_entity.dart';
export 'cart_coupon_entity.dart';
export 'cart_entity.dart';
export 'cart_item_request.dart';
export 'cart_line_entity.dart';
export 'cart_line_ref.dart';
export 'cart_loyalty_entity.dart';
export 'cart_offer_line_entity.dart';
export 'cart_offer_progress_entity.dart';
export 'cart_savings.dart';
export 'cart_top_saving.dart';
export 'cart_totals_entity.dart';
export 'catalog_category_entity.dart';
export 'catalog_merch_tag.dart';
export 'catalog_product_entity.dart';
export 'catalog_product_query.dart';
export 'catalog_products_page.dart';
export 'catalog_variant_entity.dart';
export 'coupon_entity.dart';
export 'delivery_slot_entity.dart';
export 'geo_point_entity.dart';
export 'hero_address_entity.dart';
export 'loyalty_program.dart';
export 'offer_entity.dart';
export 'offer_reward_entity.dart';
export 'order_entity.dart';
export 'order_fulfillment_entities.dart';
export 'order_line_entity.dart';
export 'order_progress_entities.dart';
export 'order_status.dart';
export 'recipe_summary_entity.dart';
