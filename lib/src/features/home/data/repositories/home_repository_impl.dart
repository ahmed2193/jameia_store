import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_data_source.dart';
import '../mappers/benefit_item_mapper.dart';
import '../mappers/featured_section_mapper.dart';
import '../mappers/gathering_card_mapper.dart';
import '../mappers/home_popup_mapper.dart';
import '../mappers/home_tile_mapper.dart';
import '../mappers/jameia_category_mapper.dart';
import '../mappers/jameia_address_mapper.dart';
import '../mappers/kingkong_item_mapper.dart';
import '../mappers/product_mapper.dart';
import '../mappers/shop_mapper.dart';
import '../mappers/store_settings_mapper.dart';
import '../mappers/user_profile_mapper.dart';

/// Offline home repository — assembles the [HomeFeed] snapshot from the scripted
/// [HomeLocalDataSource] DTOs, maps them to the feature's framework-free
/// entities, and wraps the result in `Either<Failure, T>`.
///
/// The `banners` list stays the core `HomeBanner` DTO (rendered by the shared
/// `BannerCarousel`) — see the boundary note on [HomeFeed].
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({required this.local});

  final HomeLocalDataSource local;

  @override
  Future<Either<Failure, HomeFeed>> getHomeFeed() async {
    try {
      final sections = local.sections().toEntities();
      return Right(
        HomeFeed(
          user: local.user().toEntity(),
          address: local.defaultAddress().toEntity(),
          kingkong: local.kingkong().toEntities(),
          categories: local.categories().toEntities(),
          banners: local.banners(),
          filters: local.filters(),
          shops: local.shops().toEntities(),
          channels: local.channels(),
          bannerRail: local.bannerRail().toEntities(),
          gatheringCards: local.gatheringCards().toEntities(),
          tiles: local.tiles().toEntities(),
          benefits: local.benefits().toEntities(),
          popups: local.popups().toEntities(),
          allSections: sections,
          sections: sections,
          promoProducts: local.promoProducts().toEntities(),
          settings: local.settings().toEntity(),
        ),
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  String shopArgForProduct(String sku) {
    final loc = local.locationOfSku(sku);
    if (loc != null) {
      return '${loc.categoryId}~${loc.subId}~${loc.rankId}';
    }
    final cats = local.categories();
    return cats.isNotEmpty ? cats.first.id : sku;
  }
}
