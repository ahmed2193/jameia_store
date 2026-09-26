import '../../../../core/data/models/brand_model.dart';
import '../../../../core/data/models/category_model.dart';
import '../../../../core/data/models/json_read.dart';
import '../../../../core/data/models/product_model.dart';
import '../../../../core/data/models/recipe_summary_model.dart';
import '../../../../core/error/exceptions.dart';
import 'assistant_cart_action_item_model.dart';
import 'assistant_cart_snapshot_model.dart';
import 'assistant_offer_model.dart';
import 'assistant_order_summary_model.dart';
import 'assistant_slot_day_model.dart';
import 'assistant_small_block_models.dart';

/// One `blocks[]` item: `{ kind, …fields }`, switched on `kind`.
///
/// [AssistantBlockModel.fromJson] throws [ParsingException] for an unknown
/// kind (the backend adds kinds without an app release — "ignore unknown
/// kinds") and for a block missing its identity; callers parse through
/// `JsonRead.rows` / `AssistantBlockModel.listFrom`, which log and SKIP it,
/// so one bad card never drops the message.
sealed class AssistantBlockModel {
  const AssistantBlockModel();

  static const String kindKey = 'kind';
  static const String logName = 'AssistantBlockModel';

  static const String textKind = 'text';
  static const String productsKind = 'products';
  static const String productDetailKind = 'product_detail';
  static const String cartActionKind = 'cart_action';
  static const String cartSummaryKind = 'cart_summary';
  static const String orderKind = 'order';
  static const String orderStatusKind = 'order_status';
  static const String offersKind = 'offers';
  static const String recipeKind = 'recipe';
  static const String faqKind = 'faq';
  static const String categoriesKind = 'categories';
  static const String brandsKind = 'brands';
  static const String deliverySlotsKind = 'delivery_slots';
  static const String deliveryInfoKind = 'delivery_info';
  static const String locationsKind = 'locations';
  static const String handoffKind = 'handoff';
  static const String actionsKind = 'actions';
  static const String errorKind = 'error';

  static const String textKey = 'text';
  static const String productsKey = 'products';
  static const String productKey = 'product';
  static const String actionIdKey = 'actionId';
  static const String itemsKey = 'items';
  static const String statusKey = 'status';
  static const String estimatedTotalKey = 'estimatedTotal';
  static const String cartKey = 'cart';
  static const String orderKey = 'order';
  static const String offersKey = 'offers';
  static const String couponCodeKey = 'couponCode';
  static const String recipeKey = 'recipe';
  static const String servingsKey = 'servings';
  static const String ingredientCountKey = 'ingredientCount';
  static const String categoriesKey = 'categories';
  static const String brandsKey = 'brands';
  static const String daysKey = 'days';
  static const String areaNameKey = 'areaName';
  static const String zoneNameKey = 'zoneName';
  static const String feeKey = 'fee';
  static const String etaMinutesKey = 'etaMinutes';
  static const String ticketIdKey = 'ticketId';
  static const String ticketNumberKey = 'ticketNumber';
  static const String suggestionsKey = 'suggestions';
  static const String codeKey = 'code';
  static const String messageKey = 'message';

  /// Every parseable block of [value] (a `blocks[]` array).
  static List<AssistantBlockModel> listFrom(Object? value) =>
      JsonRead.rows(value, AssistantBlockModel.fromJson, logName: logName);

  factory AssistantBlockModel.fromJson(Map<String, dynamic> json) {
    final kind = JsonRead.string(json[kindKey]);
    return switch (kind) {
      textKind => AssistantTextBlockModel(JsonRead.string(json[textKey]) ?? ''),
      productsKind => AssistantProductsBlockModel(
        JsonRead.rows(
          json[productsKey],
          ProductModel.fromJson,
          logName: logName,
        ),
      ),
      productDetailKind => AssistantProductDetailBlockModel(
        ProductModel.fromJson(_object(json, productKey)),
      ),
      cartActionKind => AssistantCartActionBlockModel.fromJson(json),
      cartSummaryKind => AssistantCartSummaryBlockModel(
        AssistantCartSnapshotModel.fromJson(_object(json, cartKey)),
      ),
      orderKind || orderStatusKind => AssistantOrderBlockModel(
        AssistantOrderSummaryModel.fromJson(_object(json, orderKey)),
        isStatusUpdate: kind == orderStatusKind,
      ),
      offersKind => AssistantOffersBlockModel(
        JsonRead.rows(
          json[offersKey],
          AssistantOfferModel.fromJson,
          logName: logName,
        ),
        couponCode: JsonRead.string(json[couponCodeKey]),
      ),
      recipeKind => AssistantRecipeBlockModel(
        RecipeSummaryModel.fromJson(_object(json, recipeKey)),
        servings: JsonRead.integer(json[servingsKey]) ?? 0,
        ingredientCount: JsonRead.integer(json[ingredientCountKey]) ?? 0,
      ),
      faqKind => AssistantFaqBlockModel(
        JsonRead.rows(
          json[itemsKey],
          AssistantFaqItemModel.fromJson,
          logName: logName,
        ),
      ),
      categoriesKind => AssistantCategoriesBlockModel(
        JsonRead.rows(
          json[categoriesKey],
          CategoryModel.fromJson,
          logName: logName,
        ),
      ),
      brandsKind => AssistantBrandsBlockModel(
        JsonRead.rows(json[brandsKey], BrandModel.fromJson, logName: logName),
      ),
      deliverySlotsKind => AssistantDeliverySlotsBlockModel(
        JsonRead.rows(
          json[daysKey],
          AssistantSlotDayModel.fromJson,
          logName: logName,
        ),
      ),
      deliveryInfoKind => AssistantDeliveryInfoBlockModel(
        areaName: JsonRead.string(json[areaNameKey]),
        zoneName: JsonRead.string(json[zoneNameKey]),
        // `0` is a real fee (free delivery): only an absent key is "none".
        fee: JsonRead.integer(json[feeKey]),
        etaMinutes: JsonRead.integer(json[etaMinutesKey]),
      ),
      locationsKind => AssistantLocationsBlockModel(
        JsonRead.rows(
          json[itemsKey],
          AssistantLocationModel.fromJson,
          logName: logName,
        ),
      ),
      handoffKind => AssistantHandoffBlockModel.fromJson(json),
      actionsKind => AssistantActionsBlockModel(
        JsonRead.rows(
          json[suggestionsKey],
          AssistantSuggestionModel.fromJson,
          logName: logName,
        ),
      ),
      errorKind => AssistantErrorBlockModel(
        code: JsonRead.string(json[codeKey]) ?? '',
        message: JsonRead.string(json[messageKey]),
      ),
      _ => throw ParsingException('unknown block kind "$kind"'),
    };
  }

  static Map<String, dynamic> _object(Map<String, dynamic> json, String key) {
    final object = JsonRead.object(json[key]);
    if (object == null) throw ParsingException('block: "$key" missing');
    return object;
  }
}

final class AssistantTextBlockModel extends AssistantBlockModel {
  const AssistantTextBlockModel(this.text);

  final String text;
}

final class AssistantProductsBlockModel extends AssistantBlockModel {
  const AssistantProductsBlockModel(this.products);

  final List<ProductModel> products;
}

final class AssistantProductDetailBlockModel extends AssistantBlockModel {
  const AssistantProductDetailBlockModel(this.product);

  final ProductModel product;
}

final class AssistantCartActionBlockModel extends AssistantBlockModel {
  const AssistantCartActionBlockModel({
    required this.actionId,
    this.items = const <AssistantCartActionItemModel>[],
    this.status = '',
    this.estimatedTotal,
  });

  /// Throws without an `actionId`: a proposal that cannot be confirmed is
  /// not worth a card.
  factory AssistantCartActionBlockModel.fromJson(Map<String, dynamic> json) {
    final actionId = JsonRead.string(json[AssistantBlockModel.actionIdKey]);
    if (actionId == null) {
      throw const ParsingException('cart_action: actionId missing');
    }
    return AssistantCartActionBlockModel(
      actionId: actionId,
      items: JsonRead.rows(
        json[AssistantBlockModel.itemsKey],
        AssistantCartActionItemModel.fromJson,
        logName: AssistantBlockModel.logName,
      ),
      status: JsonRead.string(json[AssistantBlockModel.statusKey]) ?? '',
      estimatedTotal: JsonRead.integer(
        json[AssistantBlockModel.estimatedTotalKey],
      ),
    );
  }

  final String actionId;
  final List<AssistantCartActionItemModel> items;
  final String status;
  final int? estimatedTotal;
}

final class AssistantCartSummaryBlockModel extends AssistantBlockModel {
  const AssistantCartSummaryBlockModel(this.cart);

  final AssistantCartSnapshotModel cart;
}

final class AssistantOrderBlockModel extends AssistantBlockModel {
  const AssistantOrderBlockModel(this.order, {this.isStatusUpdate = false});

  final AssistantOrderSummaryModel order;
  final bool isStatusUpdate;
}

final class AssistantOffersBlockModel extends AssistantBlockModel {
  const AssistantOffersBlockModel(this.offers, {this.couponCode});

  final List<AssistantOfferModel> offers;
  final String? couponCode;
}

final class AssistantRecipeBlockModel extends AssistantBlockModel {
  const AssistantRecipeBlockModel(
    this.recipe, {
    this.servings = 0,
    this.ingredientCount = 0,
  });

  final RecipeSummaryModel recipe;
  final int servings;
  final int ingredientCount;
}

final class AssistantFaqBlockModel extends AssistantBlockModel {
  const AssistantFaqBlockModel(this.items);

  final List<AssistantFaqItemModel> items;
}

final class AssistantCategoriesBlockModel extends AssistantBlockModel {
  const AssistantCategoriesBlockModel(this.categories);

  final List<CategoryModel> categories;
}

final class AssistantBrandsBlockModel extends AssistantBlockModel {
  const AssistantBrandsBlockModel(this.brands);

  final List<BrandModel> brands;
}

final class AssistantDeliverySlotsBlockModel extends AssistantBlockModel {
  const AssistantDeliverySlotsBlockModel(this.days);

  final List<AssistantSlotDayModel> days;
}

final class AssistantDeliveryInfoBlockModel extends AssistantBlockModel {
  const AssistantDeliveryInfoBlockModel({
    this.areaName,
    this.zoneName,
    this.fee,
    this.etaMinutes,
  });

  final String? areaName;
  final String? zoneName;
  final int? fee;
  final int? etaMinutes;
}

final class AssistantLocationsBlockModel extends AssistantBlockModel {
  const AssistantLocationsBlockModel(this.items);

  final List<AssistantLocationModel> items;
}

final class AssistantHandoffBlockModel extends AssistantBlockModel {
  const AssistantHandoffBlockModel({
    required this.ticketId,
    required this.ticketNumber,
  });

  factory AssistantHandoffBlockModel.fromJson(Map<String, dynamic> json) {
    final ticketId = JsonRead.string(json[AssistantBlockModel.ticketIdKey]);
    if (ticketId == null) {
      throw const ParsingException('handoff: ticketId missing');
    }
    return AssistantHandoffBlockModel(
      ticketId: ticketId,
      ticketNumber:
          JsonRead.string(json[AssistantBlockModel.ticketNumberKey]) ?? '',
    );
  }

  final String ticketId;
  final String ticketNumber;
}

final class AssistantActionsBlockModel extends AssistantBlockModel {
  const AssistantActionsBlockModel(this.suggestions);

  final List<AssistantSuggestionModel> suggestions;
}

final class AssistantErrorBlockModel extends AssistantBlockModel {
  const AssistantErrorBlockModel({required this.code, this.message});

  final String code;
  final String? message;
}
