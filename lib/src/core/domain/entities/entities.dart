/// Barrel for the shared, framework-free domain entities.
///
/// Every entity here is consumed by more than one feature and/or by core UI
/// (`core/widgets`). DTO ⇄ entity mapping lives in `core/data/mappers/`.
library;

export '../localization/localized_pick.dart';
export 'auth_customer_entity.dart';
export 'benefit_item_entity.dart';
export 'cart_item_entity.dart';
export 'coupon_entity.dart';
export 'featured_section_entity.dart';
export 'gathering_card_entity.dart';
export 'geo_point_entity.dart';
export 'home_banner_entity.dart';
export 'home_popup_entity.dart';
export 'home_tile_entity.dart';
export 'jameia_category_entity.dart';
export 'jameia_rank_entity.dart';
export 'jameia_sub_category_entity.dart';
export 'jameia_address_entity.dart';
export 'jameia_order_entity.dart';
export 'kingkong_item_entity.dart';
export 'menu_section_entity.dart';
export 'order_item_entity.dart';
export 'product_entity.dart';
export 'product_variant_entity.dart';
export 'promo_tag_entity.dart';
export 'rider_entity.dart';
export 'shop_entity.dart';
export 'store_settings_entity.dart';
export 'user_profile_entity.dart';
export 'vip_card_entity.dart';
