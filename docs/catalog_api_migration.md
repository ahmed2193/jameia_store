# Catalogue → jm3eia API migration (working brief)

Moves the storefront (home, category browsing, product page, search, brands / collections /
offers, recipes, CMS pages) from the offline `JameiaRepository` catalogue to the backend
Catalog + Bootstrap routes. `CLAUDE.md` is the contract; the `jameia-api-integration` skill is
the recipe (`references/migrating-offline-feature.md` for legacy targets). This file holds what
is specific to this migration: the verified contract, the decisions, the shared foundation and
who owns what. Delete it when the migration ships (its facts move to `docs/api_integration.md`).

## 1. Contract — verified against the live host (2026-09-17)

`node .claude/skills/jameia-api-verify/scripts/validate_live_catalog.js` calls every public
catalogue / bootstrap GET (en + ar, every slug, every product filter, the 400 / 404 paths) and
validates the envelope with the 200 schema of `https://api.jm3eia.store/docs/json`.
Result: **249 requests, 0 spec violations, 0 undeclared fields.**

Behaviour the schema does not say (all observed live):

| Fact | Consequence in the app |
|---|---|
| Names / titles / descriptions arrive **already resolved** for `Accept-Language` (one string, not `{en, ar}`) | catalogue entities carry ONE `name`; no `nameAr`, no `nameFor()`. A language switch must **reload** the screen (§3) |
| A `variant` product's card has `price: 0` (and a junk `compareAt`); real prices are only in `GET /v1/products/:slug` → `variants[]` | `CatalogProductEntity.hasListPrice` — the card shows "Choose options" instead of `KD 0.000` (the website prints 0.000: do not copy), quick-add is refused, tap opens the product page |
| `tags[]` leaks raw 24-hex tag ids among the slugs | dropped by `CatalogProductMapper` |
| `inStock=false` behaves like "no filter" | the app only ever sends `inStock=true` |
| `categorySlug` of a parent includes its descendants' products; `productCount` is a stale counter (parent says 24, list returns 2) | never hide / badge a category by `productCount` |
| categories are a flat list, 3 levels, linked by `parentId` | `CatalogCategoryTree` |
| `GET /v1/pages/:slug` — slug is an enum (`about`, `contact`, `faq`, `privacy`, `terms`); an unknown slug is `400 VALIDATION_ERROR`, not 404 | |
| `page` beyond the end → `200` with `data: []`, `hasMore: false` | |
| unknown product / category slug → `404 RESOURCE_NOT_FOUND`; `limit > 100` → `400 VALIDATION_ERROR` | `ServerFailure(statusCode: 404)` → "not found" empty state, not the generic error |
| brands / collections / offers / recipes lists are paginated too (`{ data, pagination }`) | |
| `/v1/home` is ONE aggregate: `slides[]`, `sections[]` (`rail` of products / categories / brands / recipes, `promo_cards`, `promo_strip`, `banner`), `categories[]` (full tree), `announcement` | one request for the whole home screen |
| rate limit 300 requests / 60 s (`x-ratelimit-limit`) | fine for normal use; never fan out one request per row |

The website (`https://jm3eia.store`, Next.js, server-rendered from the same API) renders exactly
this flow: announcement ticker → header with the delivery zone (`init.delivery.zone.name`) →
slides → `sections` in `sortOrder` → Pro banner. Product page: badge · unit · stock → name →
description → rating → price + struck price → quantity + add → "recipes using this product" →
reviews (loaded after first paint) → sticky price + add bar. Category page: child-category
chips (`All` first) → sort → "in stock only" → product grid. Search: trending terms + popular
categories, then a product grid.

## 2. Decisions

1. **New API-shaped core entities beside the offline ones.** `CatalogProductEntity`,
   `CatalogVariantEntity`, `CatalogCategoryEntity` (+ `CatalogCategoryTree`), `BrandEntity`,
   `RecipeSummaryEntity`, `CatalogProductsPage`, `CatalogProductQuery`. Money is `int` fils with
   `…Kd` getters. The offline `ProductEntity` / `ShopEntity` / `JameiaCategoryEntity` … family is
   NOT reshaped: `test/core/domain_entities_mapper_test.dart` pins it as a verbatim port of the
   offline DTOs that cart / checkout / orders still speak. It dies when those move to the API.
2. **The app is a single store.** Marketplace concepts (shop list, shop page with
   `catId~subId~rankId`, shop detail / map / favourites, VIP ⇄ Mart store mode on home, kingkong,
   channels, meal-for-one, pick-up, client-side home filters) have no backend counterpart and
   leave the migrated screens. "VIP price" becomes the backend's **Pro price**
   (`proPrice`, applied when `AuthSessionCubit.state.customer?.isPro == true`).
3. **Never mix id spaces.** Everything reachable from an API list is API-backed: a product opens
   by **slug** through `ProductDetailArgs`, a category through `CategoryArgs`, any other product
   list through `ProductListingArgs`. No DTO and no packed string travels as a route `extra`.
4. **The cart stays local for now** (the backend Cart tag is a later migration) but accepts API
   products: `CartCubit.addCatalogProduct(product, pro:, variant:, qty:)` →
   `AddCatalogProductToCartUseCase` (refuses a variant product without a variant, an unavailable
   variant, an out-of-stock product) → `CartRepository.addCatalogLine`. The line is keyed by the
   Mongo id (`productId` or `productId:variantId`) and persists its own product snapshot, because
   the offline catalogue cannot rehydrate it. `removeProduct(id)` / `state.qtyOfProduct(id)` work
   unchanged.
5. **One shared remote datasource for shared reads.** `core/data/datasources/catalog_remote_data_source.dart`
   (`getProducts`, `getCategories`, `getBrands`), registered in `service_locator.dart`
   (`_initCatalog`). A route only one feature reads stays in that feature's own datasource.
6. **Language switch = reload.** Shell tabs are rebuilt on a language change (the shell keys its
   `IndexedStack` by language). A **pushed** catalogue page adds, in the page:
   `BlocListener<LocalizationCubit, LocalizationState>(listenWhen: (p, c) => p.locale != c.locale, listener: (context, _) => context.read<XCubit>().load())`
   (check the state's real field name). Cart lines keep the name they were added with.

## 3. Shared foundation (already built — use it, do not copy it)

| Need | Use |
|---|---|
| wire DTOs | `core/data/models/{product_model,products_page_model,category_model,brand_model,recipe_summary_model}.dart` |
| tolerant JSON readers (`string`, `integer`, `decimal`, `flag`, `object`, `strings`, `dateTime`, `rows` = skip a bad row) | `core/data/models/json_read.dart` → `JsonRead` — use it in every new DTO |
| DTO → entity | `core/data/mappers/catalog_product_mapper.dart` (`toEntity`, `toEntities`, page `toEntity`), `catalog_taxonomy_mapper.dart` (category `toEntity` / `toEntities` / `toTree`, brand, recipe), `catalog_product_query_mapper.dart` (`toQueryParameters(page:, limit:)`) |
| shared reads | `CatalogRemoteDataSource` (DI: `sl<CatalogRemoteDataSource>()` inside an injection container) |
| product card | `core/widgets/catalog_product_card.dart` — `CatalogProductCard(product:, qty:, onTap:, onAdd:, onRemove:, pro:, width:)`; cell height = `width + CatalogProductCard.textBlockHeight`. Parts: `CatalogAddControl`, `CatalogPillStepper`, `CatalogCircleAddButton`, `CatalogDiscountBadge`, `CatalogSaveBadge`, `CatalogTypeChip`, `CatalogUnavailableOverlay` |
| cart | `context.read<CartCubit>().addCatalogProduct(product, pro: isPro)` / `.removeProduct(product.id)`; quantity: `BlocSelector<CartCubit, CartState, int>(selector: (cart) => cart.qtyOfProduct(product.id))` |
| Pro member? | `context.select<AuthSessionCubit, bool>((cubit) => cubit.state.customer?.isPro ?? false)` |
| routes | `Routes.categories`, `Routes.category` (`CategoryArgs`), `Routes.productListing` (`ProductListingArgs`), `Routes.productDetail` (`ProductDetailArgs`), `Routes.brands`, `Routes.offers`, `Routes.recipes`, `Routes.recipe` (slug), `Routes.contentPage` (slug); args in `config/routes/route_args/` |
| strings | `catalog.*` in `assets/i18n/{en,ar}.json` (add_to_cart, choose_options, multiple_sizes, bundle, out_of_stock, percent_off, save_amount, view_all, per_piece / per_kg / per_litre / per_pack …) |
| money text | `Formatters.price(entity.priceKd)` — never string maths in a widget |
| state views | `AppLoader`, `ErrorView(message:, onRetry:)`, `EmptyStateView`, `BrandedRefresh`, skeletons from `core/widgets` |

## 4. Ownership while the migration runs

| Area | Owner |
|---|---|
| core foundation above, `features/cart` bridge, `features/home/**`, `config/routes/routes.dart`, `route_args/*`, `service_locator.dart` catalogue lines, `assets/i18n` `catalog.*` + `home.*`, this file | main catalogue session |
| `features/shop/**`, `feature_routes/shop_routes.dart`, `test/features/shop/**`, `test/shop_page_test.dart`; i18n `shop.*` | builder: category browsing + product listing |
| `features/product_details/**`, `feature_routes/product_details_routes.dart`, `route_args/pdp_image_viewer_args.dart`, `test/features/product_details/**`, `test/product_detail_page_test.dart`; i18n `product.*` | builder: product page |
| `features/search/**`, `feature_routes/search_routes.dart`, `test/features/search/**`; i18n `search.*` | builder: search |
| `features/address/**`, `jameia_address_entity.dart`, `address_label.dart`, `jameia_address_mapper.dart`, `address_routes.dart`, i18n `addr.*` | session keeta-clone-e9 (address API) — do not touch |
| `core/network/**`, `core/storage/**`, auth / account / language / notifications, i18n `auth.*` `profile.*` `notifications.*` | session keeta-clone-7b — do not touch |

Shared files (`en.json`, `ar.json`, `app_router_test.dart`, barrels) are patched with small
`Edit` calls after a fresh read — never rewritten, reformatted or sorted. RAM is tight and three
sessions share the machine: **builders do not run `dart analyze`, `flutter test`, `flutter run`
or `dart format`**; the main catalogue session runs them once for everybody and sends back the
diagnostics.

## 5. Catalogue browse — the shape the store settled on (2026-09-20)

The first cut gave every level of the tree its own screen (all categories → category → child
category). The reference app browses **in place**, and so does the app now:

```
CategoriesPage (Routes.shop / Routes.categories)   CategoryPage (Routes.category)
  app bar tab row   = level 0 = the roots            app bar = the category name
  circle rail       = level 1 = children of the tab  circle rail = level 0 = its children
  pill chips        = level 2 = their children       pill chips  = level 1 = grandchildren
  product grid      = GET /v1/products?categorySlug=<deepest pick>
```

- One model for both: `features/shop/domain/entities/category_browse.dart`. `optionsAt(level)`
  is what a row offers, `selectionAt(level)` what is picked (`null` = that row's "All"),
  `select(level, category)` drops every level below, `activeSlug` is what the grid filters by
  and falls back to the slug the page was opened with (an unknown slug still lists, it simply
  has nothing to browse).
- One cubit for every row: `CategoryBrowseCubit` (`param1` = base slug, `''` = the whole store).
  The page wires it to the grid with a `BlocListener` → `ProductListingCubit.setCategorySlug`.
  The store page does **not** `load()` its listing cubit: the first pick scopes the first request.
- `GET /v1/categories/:slug` is gone. The flat tree (38 rows / 8.5 KB today) answers children,
  grandchildren, names and breadcrumbs in one read, and
  `CatalogRemoteDataSourceImpl.getCategories({refresh})` keeps it for 5 minutes per request
  language (injectable clock). **Do not** copy that cache to `/v1/products` or `/v1/home`:
  those bodies depend on the Bearer.
- Listing toolbar: sort, brand (`brandSlug`, brands read once per screen, hidden when the
  listing already IS a brand), in-stock, on-sale — all server-side, all restart at page 1.
- Card: unit line for non-`piece` products and a Pro-price tag for customers who are not Pro
  (`CatalogProductCard.textBlockHeight` is s104 — the home and PDP rails size their cells off it).
