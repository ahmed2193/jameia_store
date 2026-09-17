// Shared domain entities + core DTO ⇄ entity mappers.
//
// Verifies:
// - lossless round-trips for every entity that flows back into a
//   JameiaRepository write API / local persistence (address, order, cart line,
//   product, variant);
// - the pure `nameFor(languageCode)` family picks exactly what the DTO
//   `display*` getters pick under `Intl.defaultLocale` (en / ar / blank-ar);
// - pricing + dummy-backend getters are verbatim ports of the DTO getters;
// - GeoPointEntity <-> LatLng mapping.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:intl/intl.dart';
import 'package:jameia_mart/src/core/data/jameia/jameia_loader.dart';
import 'package:jameia_mart/src/core/data/jameia/jameia_models.dart';
import 'package:jameia_mart/src/core/data/mappers/mappers.dart';
import 'package:jameia_mart/src/core/data/models/models.dart';
import 'package:jameia_mart/src/core/domain/entities/entities.dart';
import 'package:jameia_mart/src/core/utils/jameia_geocode.dart';

/// Runs [body] with `Intl.defaultLocale` set to [locale] (the source the DTO
/// `display*` getters read), restoring the previous value afterwards.
T _withLocale<T>(String locale, T Function() body) {
  final previous = Intl.defaultLocale;
  Intl.defaultLocale = locale;
  try {
    return body();
  } finally {
    Intl.defaultLocale = previous;
  }
}

const _languages = ['en', 'ar'];

void main() {
  late Map<String, dynamic> jameiaData;
  late JameiaCatalog catalog;

  setUpAll(() {
    jameiaData =
        json.decode(File('assets/data/jameia_data.json').readAsStringSync())
            as Map<String, dynamic>;
    catalog = parseJameiaCatalog(
      File('assets/data/jameia/jameia_catalog.json').readAsStringSync(),
    );
  });

  List<Map<String, dynamic>> rows(Object? list) =>
      (list as List).cast<Map<String, dynamic>>();

  group('pickLocalized', () {
    test('Arabic wins only for ar* codes with a non-blank Arabic value', () {
      expect(pickLocalized('en', en: 'Milk', ar: 'حليب'), 'Milk');
      expect(pickLocalized('ar', en: 'Milk', ar: 'حليب'), 'حليب');
      expect(pickLocalized('ar_KW', en: 'Milk', ar: 'حليب'), 'حليب');
      expect(pickLocalized('ar', en: 'Milk', ar: ''), 'Milk');
      expect(pickLocalized('ar', en: 'Milk', ar: '   '), 'Milk');
      // English is returned even when empty (same as the DTO rule).
      expect(pickLocalized('en', en: '', ar: 'حليب'), '');
    });

    test('inverted *En sources (gathering card) keep the DTO fallback', () {
      const card = GatheringCard(id: 'g', title: 'عرض', titleEn: '');
      final entity = card.toEntity();
      for (final lang in _languages) {
        expect(
          entity.titleFor(lang),
          _withLocale(lang, () => card.displayTitle),
          reason: lang,
        );
      }
      expect(entity.titleFor('en'), '');
      expect(entity.titleFor('ar'), 'عرض');
    });
  });

  group('Product', () {
    test('toEntity().toModel() is lossless (incl. variants)', () {
      const dto = Product(
        id: 'sku-1',
        name: 'Milk 1L',
        nameAr: 'حليب',
        image: 'https://x/milk.png',
        price: 0.5,
        originalPrice: 0.75,
        desc: 'Fresh',
        soldCount: 42,
        kcal: 120,
        categoryId: 'dairy',
        bestSelling: true,
        variants: [
          ProductVariant(
            sku: 'sku-1-l',
            label: 'L',
            price: 0.9,
            oldPrice: 1.1,
            image: 'https://x/l.png',
            inStock: false,
          ),
        ],
        vipPrice: 0.45,
        available: false,
        maxQty: 3,
        showDiscount: true,
        firstUnitsQty: 2,
        gallery: ['https://x/1.png', 'https://x/2.png'],
        brand: 'Almarai',
        weight: '1 L',
        storage: 'Chilled',
      );
      final entity = dto.toEntity();
      final back = entity.toModel();

      expect(back.toEntity(), entity);
      expect(back.id, dto.id);
      expect(back.nameAr, dto.nameAr);
      expect(back.originalPrice, dto.originalPrice);
      expect(back.vipPrice, dto.vipPrice);
      expect(back.available, dto.available);
      expect(back.maxQty, dto.maxQty);
      expect(back.showDiscount, dto.showDiscount);
      expect(back.firstUnitsQty, dto.firstUnitsQty);
      expect(back.gallery, dto.gallery);
      expect(back.brand, dto.brand);
      expect(back.weight, dto.weight);
      expect(back.storage, dto.storage);
      expect(back.variants.single.sku, 'sku-1-l');
      expect(back.variants.single.oldPrice, 1.1);
      expect(back.variants.single.inStock, isFalse);
    });

    test('pricing getters match the DTO across the whole jameia catalogue', () {
      final products = catalog.productsBySku.values.toList();
      expect(products, isNotEmpty);
      for (final p in products) {
        final e = p.toEntity();
        expect(e.priceFor(true), p.priceFor(true), reason: p.id);
        expect(e.priceFor(false), p.priceFor(false), reason: p.id);
        expect(e.hasVipPrice, p.hasVipPrice, reason: p.id);
        expect(e.hasDiscount, p.hasDiscount, reason: p.id);
        expect(e.discountPercent, p.discountPercent, reason: p.id);
        expect(e.hasPromo, p.hasPromo, reason: p.id);
        expect(e.hasVariants, p.hasVariants, reason: p.id);
        expect(e.sku, p.sku, reason: p.id);
        expect(e.resolvedGallery, p.resolvedGallery, reason: p.id);
      }
      expect(
        products.where((p) => p.toEntity().hasVipPrice),
        isNotEmpty,
        reason: 'fixture must exercise the VIP branch',
      );
    });

    test('nameFor matches Product.displayName for en / ar', () {
      final sample = catalog.productsBySku.values.take(300).toList();
      expect(
        sample.any((p) => p.toEntity().nameFor('ar') != p.name),
        isTrue,
        reason: 'fixture must exercise the Arabic branch',
      );
      for (final lang in _languages) {
        for (final p in sample) {
          expect(
            p.toEntity().nameFor(lang),
            _withLocale(lang, () => p.displayName),
            reason: '${p.id} [$lang]',
          );
        }
      }
    });

    test(
      'mapping is memoized per DTO instance (shared catalogue identity)',
      () {
        final p = catalog.productsBySku.values.first;
        expect(identical(p.toEntity(), p.toEntity()), isTrue);
      },
    );
  });

  group('Shop', () {
    test('graph mapping + derived getters match the DTO', () {
      final shops = [
        ...catalog.shops,
        ...rows(jameiaData['shops']).map(Shop.fromJson),
      ];
      expect(shops, isNotEmpty);
      for (final s in shops) {
        final e = s.toEntity();
        expect(e.allProducts.length, s.allProducts.length, reason: s.id);
        expect(e.displayFeatures, s.displayFeatures, reason: s.id);
        expect(e.isRestaurant, s.isRestaurant, reason: s.id);
        expect(e.sections.length, s.sections.length, reason: s.id);
        for (final lang in _languages) {
          expect(
            e.nameFor(lang),
            _withLocale(lang, () => s.displayName),
            reason: '${s.id} [$lang]',
          );
        }
      }
    });

    test('resolvedPromoTags mirrors Shop.displayTags synthesis', () {
      String upToOff(int percent) => 'up to $percent% off';
      const discounted = ProductEntity(
        id: 'p',
        name: 'P',
        image: '',
        price: 8,
        originalPrice: 10, // 20% off
      );

      const explicit = ShopEntity(
        id: 's1',
        name: 'S',
        promoTags: [PromoTagEntity(text: 'BOGO', style: 'pill')],
        freeDelivery: true,
      );
      expect(
        explicit.resolvedPromoTags(
          upToOffLabel: upToOff,
          freeDeliveryLabel: 'Free delivery',
        ),
        const [PromoTagEntity(text: 'BOGO', style: 'pill')],
      );

      const synthesized = ShopEntity(
        id: 's2',
        name: 'S',
        promo: 'ignored when a >=5% discount exists',
        freeDelivery: true,
        sections: [
          MenuSectionEntity(title: 'Deals', products: [discounted]),
        ],
      );
      expect(synthesized.maxDiscountPercent, 20);
      expect(
        synthesized.resolvedPromoTags(
          upToOffLabel: upToOff,
          freeDeliveryLabel: 'Free delivery',
        ),
        const [
          PromoTagEntity(text: 'up to 20% off'),
          PromoTagEntity(
            text: 'Free delivery',
            bg: '#E2F6F0',
            fg: '#008C65',
            style: 'coupon',
          ),
        ],
      );

      const promoOnly = ShopEntity(id: 's3', name: 'S', promo: 'KD 1 off');
      expect(
        promoOnly.resolvedPromoTags(
          upToOffLabel: upToOff,
          freeDeliveryLabel: 'Free delivery',
        ),
        const [PromoTagEntity(text: 'KD 1 off')],
      );
    });

    test('effectiveDeliveryFee zeroes the fee for free-delivery shops', () {
      const paid = ShopEntity(id: 'a', name: 'A', deliveryFee: 0.5);
      const free = ShopEntity(
        id: 'b',
        name: 'B',
        deliveryFee: 0.5,
        freeDelivery: true,
      );
      expect(paid.effectiveDeliveryFee, 0.5);
      expect(free.effectiveDeliveryFee, 0.0);
    });
  });

  group('JameiaAddress', () {
    const full = JameiaAddress(
      id: 'addr_1',
      label: 'Work',
      line: 'Block 7, Street 22, Avenue 3, Tower One',
      area: 'Salmiya',
      recipient: 'Ahmed',
      phone: '+96550001122',
      isDefault: true,
      lat: 29.3340,
      lng: 48.0780,
      structType: StructType.office,
      labelType: LabelType.work,
      dropOff: DropOff.leaveAtSpot,
      dropSpot: 'frontDesk',
      altLocation: 'Reception desk',
      poiName: 'Tower One',
      brief: 'Salmiya, Block 7, Street 22',
      detail: 'Floor 12, Acme Co.',
      buildingName: 'Tower One',
      aptNumber: '1204',
      unitOrFloor: 'Floor 12',
      companyName: 'Acme Co.',
      street: '22',
      block: '7',
      avenue: '3',
      additionalDirection: 'Next to the blue mosque',
      note: 'Call on arrival',
    );

    test('toEntity().toModel() is lossless (every persisted field)', () {
      final entity = full.toEntity();
      expect(entity.structTypeCode, StructType.office.code);
      expect(entity.labelTypeCode, LabelType.work.code);
      expect(entity.dropOffLeaveAtSpot, isTrue);

      final back = entity.toModel();
      expect(back.toJson(), full.toJson());
      expect(back.structType, StructType.office);
      expect(back.labelType, LabelType.work);
      expect(back.dropOff, DropOff.leaveAtSpot);
    });

    test('seed addresses round-trip + display getters match the DTO', () {
      final seeds = rows(jameiaData['addresses']).map(JameiaAddress.fromJson);
      for (final a in [...seeds, full, JameiaAddress.empty]) {
        final e = a.toEntity();
        expect(e.toModel().toJson(), a.toJson(), reason: a.id);
        expect(e.fullText, a.fullText, reason: a.id);
        expect(e.displayTitle, a.displayTitle, reason: a.id);
      }
    });

    test('entity defaults mirror JameiaAddress.fromJson defaults', () {
      const slim = JameiaAddressEntity(id: 'x', label: 'Home');
      final fromJson = JameiaAddress.fromJson(const {'id': 'x'});
      expect(slim.toModel().toJson(), fromJson.toJson());
    });
  });

  group('GeoPoint', () {
    test('LatLng <-> GeoPointEntity', () {
      const latLng = LatLng(29.3759, 47.9774);
      final point = latLng.toEntity();
      expect(point, const GeoPointEntity(lat: 29.3759, lng: 47.9774));
      expect(point.toLatLng(), latLng);
    });
  });

  group('JameiaOrder', () {
    List<JameiaOrder> orders() => [
      ...rows(jameiaData['orders']).map(JameiaOrder.fromJson),
      const JameiaOrder(
        id: 'o1700000000000',
        shopName: 'Jameia',
        shopNameAr: 'الجمعية',
        shopId: 's1',
        shopLogo: '',
        status: 'preparing',
        statusStep: 1,
        total: 12.5,
        date: 'Today, 10:05',
        dateAr: 'اليوم، 10:05',
        items: [OrderItem(name: 'Milk', nameAr: 'حليب', qty: 2, price: 1)],
        rider: null,
      ),
    ];

    test('toEntity().toModel() is lossless (persisted JSON identical)', () {
      for (final o in orders()) {
        expect(o.toEntity().toModel().toJson(), o.toJson(), reason: o.id);
      }
    });

    test('shopIdOverride replaces only the shop id', () {
      final o = orders().first;
      final overridden = o.toEntity(shopIdOverride: 'nav-shop');
      final raw = o.toEntity();
      expect(overridden.shopId, 'nav-shop');
      expect(raw.shopId, o.shopId);
      final rest = List<Object?>.of(overridden.props)..removeAt(3);
      final rawRest = List<Object?>.of(raw.props)..removeAt(3);
      expect(rest, rawRest);
    });

    test('dummy-backend + locale getters match the DTO', () {
      for (final o in orders()) {
        final e = o.toEntity();
        expect(e.isActive, o.isActive, reason: o.id);
        expect(e.itemCount, o.itemCount, reason: o.id);
        expect(e.etaMinutes, o.etaMinutes, reason: o.id);
        expect(e.deliveryCode, o.deliveryCode, reason: o.id);
        expect(e.platformFee, o.platformFee, reason: o.id);
        expect(e.dropOffMethod, o.dropOffMethod, reason: o.id);
        expect(e.paymentId, o.paymentId, reason: o.id);
        expect(e.riderHeading, o.riderHeading, reason: o.id);
        if (e.paymentMethodCase != 2) {
          // Case 2 is the localized COD label (`.tr()` in the DTO).
          expect(
            e.paymentMethodLabel(cashOnDelivery: 'COD'),
            o.paymentMethod,
            reason: o.id,
          );
        } else {
          expect(e.paymentMethodLabel(cashOnDelivery: 'COD'), 'COD');
        }
        for (final lang in _languages) {
          _withLocale(lang, () {
            expect(e.shopNameFor(lang), o.displayShopName, reason: o.id);
            expect(e.dateFor(lang), o.displayDate, reason: o.id);
            for (var i = 0; i < o.items.length; i++) {
              expect(
                e.items[i].nameFor(lang),
                o.items[i].displayName,
                reason: '${o.id} item $i',
              );
            }
          });
        }
        final rider = o.rider;
        if (rider != null) {
          expect(e.rider!.rating, rider.rating, reason: o.id);
          expect(e.rider!.reviews, rider.reviews, reason: o.id);
        }
      }
    });

    test('copyWith advances status and keeps everything else', () {
      final e = orders().first.toEntity();
      const rider = RiderEntity(name: 'R', phone: '1', vehicle: 'car');
      final next = e.copyWith(status: 'completed', statusStep: 5, rider: rider);
      expect(next.status, 'completed');
      expect(next.statusStep, 5);
      expect(next.rider, rider);
      expect(next.id, e.id);
      expect(next.items, e.items);
      expect(next.total, e.total);
    });
  });

  group('CartItem', () {
    const product = Product(
      id: 'sku-9',
      name: 'Rice',
      nameAr: 'أرز',
      image: 'https://x/rice.png',
      price: 2,
      originalPrice: 0,
      desc: '',
      soldCount: 0,
      kcal: 0,
      vipPrice: 1.8,
      variants: [
        ProductVariant(sku: '5kg', label: '5 kg', price: 4, image: ''),
        ProductVariant(
          sku: '10kg',
          label: '10 kg',
          price: 7.5,
          image: 'https://x/10.png',
        ),
      ],
    );

    List<CartItem> lines() => [
      const CartItem(product: product, shopId: 'jameia', qty: 3),
      const CartItem(
        product: product,
        shopId: 'jameia',
        qty: 2,
        unitPriceOverride: 1.8,
      ),
      CartItem(
        product: product,
        shopId: 'jameia',
        variant: product.variants[0],
      ),
      CartItem(
        product: product,
        shopId: 'jameia',
        variant: product.variants[1],
        qty: 4,
      ),
    ];

    test('toEntity().toModel() is lossless', () {
      for (final line in lines()) {
        final back = line.toEntity().toModel();
        expect(back, line); // CartItem Equatable: lineKey/shop/qty/snapshot.
        expect(back.product.toEntity(), line.product.toEntity());
        expect(back.variant?.toEntity(), line.variant?.toEntity());
      }
    });

    test('line math + display getters match the DTO', () {
      for (final line in lines()) {
        final e = line.toEntity();
        expect(e.lineKey, line.lineKey);
        expect(e.unitPrice, line.unitPrice);
        expect(e.lineTotal, line.lineTotal);
        expect(e.displayImage, line.displayImage);
        expect(e.copyWith(qty: 9).qty, line.copyWith(qty: 9).qty);
        for (final lang in _languages) {
          expect(
            e.nameFor(lang),
            _withLocale(lang, () => line.displayName),
            reason: '${line.lineKey} [$lang]',
          );
        }
      }
    });
  });

  group('Coupon / profile', () {
    test('coupon fields + titleFor/subtitleFor match the DTO', () {
      final coupons = rows(jameiaData['coupons']).map(Coupon.fromJson).toList();
      expect(coupons, isNotEmpty);
      for (final c in coupons) {
        final e = c.toEntity();
        expect(e.amount, c.amount);
        expect(e.minSpend, c.minSpend);
        expect(e.used, c.used);
        for (final lang in _languages) {
          _withLocale(lang, () {
            expect(e.titleFor(lang), c.displayTitle, reason: c.id);
            expect(e.subtitleFor(lang), c.displaySubtitle, reason: c.id);
          });
        }
      }
    });

    test('user profile maps every field', () {
      final u = UserProfile.fromJson(
        jameiaData['user'] as Map<String, dynamic>,
      );
      expect(
        u.toEntity(),
        UserProfileEntity(
          id: u.id,
          name: u.name,
          phone: u.phone,
          avatar: u.avatar,
          deliveryCode: u.deliveryCode,
        ),
      );
    });
  });

  group('Home modules', () {
    test('localized getters match the DTO display getters', () {
      final home = jameiaData['home'] as Map<String, dynamic>;
      final kingkong = [
        ...catalog.kingkong,
        ...rows(jameiaData['kingkong']).map(KingKongItem.fromJson),
      ];
      final banners = [
        ...catalog.banners,
        ...rows(jameiaData['banners']).map(HomeBanner.fromJson),
      ];
      final cards = rows(home['gatheringCards']).map(GatheringCard.fromJson);
      final tiles = rows(home['tiles']).map(HomeTile.fromJson);
      final benefits = rows(home['benefits']).map(BenefitItem.fromJson);
      final popups = rows(home['popups']).map(HomePopup.fromJson);

      for (final lang in _languages) {
        _withLocale(lang, () {
          for (final k in kingkong) {
            expect(k.toEntity().titleFor(lang), k.displayTitle, reason: k.id);
            expect(k.toEntity().hasImage, k.hasImage, reason: k.id);
          }
          for (final b in banners) {
            expect(b.toEntity().titleFor(lang), b.displayTitle, reason: b.id);
          }
          for (final c in cards) {
            final e = c.toEntity();
            expect(e.titleFor(lang), c.displayTitle, reason: c.id);
            expect(e.subtitleFor(lang), c.displaySubtitle, reason: c.id);
          }
          for (final t in tiles) {
            expect(t.toEntity().titleFor(lang), t.displayTitle, reason: t.id);
          }
          for (final b in benefits) {
            expect(b.toEntity().textFor(lang), b.displayText);
          }
          for (final p in popups) {
            final e = p.toEntity();
            expect(e.titleFor(lang), p.displayTitle, reason: p.id);
            expect(e.bodyFor(lang), p.displayBody, reason: p.id);
            expect(e.ctaFor(lang), p.displayCta, reason: p.id);
            expect(e.amountUnitFor(lang), p.displayAmountUnit, reason: p.id);
          }
        });
      }
    });

    test('store settings map both hero cards', () {
      final settings = catalog.settings.toEntity();
      expect(settings.prepTime, catalog.settings.prepTime);
      expect(settings.vip.title, catalog.settings.vip.title);
      expect(settings.mart.desc, catalog.settings.mart.desc);
    });
  });

  group('Jameia taxonomy', () {
    test('full category graph mirrors the DTO graph', () {
      for (final c in catalog.categories) {
        final e = c.toEntity();
        expect(e.subs.length, c.subs.length, reason: c.id);
        expect(e.allProducts.length, c.allProducts.length, reason: c.id);
        for (var i = 0; i < c.subs.length; i++) {
          final sub = c.subs[i];
          expect(e.subs[i].hasRanks, sub.hasRanks, reason: sub.id);
          expect(
            e.subs[i].allProducts.map((p) => p.id),
            sub.allProducts.map((p) => p.id),
            reason: sub.id,
          );
          expect(e.subs[i].ranks.length, sub.ranks.length, reason: sub.id);
        }
        for (final lang in _languages) {
          _withLocale(lang, () {
            expect(e.nameFor(lang), c.displayName, reason: c.id);
            for (var i = 0; i < c.subs.length; i++) {
              expect(e.subs[i].nameFor(lang), c.subs[i].displayName);
              for (var r = 0; r < c.subs[i].ranks.length; r++) {
                expect(
                  e.subs[i].ranks[r].nameFor(lang),
                  c.subs[i].ranks[r].displayName,
                );
              }
            }
          });
        }
      }
    });

    test('summary mapping skips the sub-category graph', () {
      final c = catalog.categories.firstWhere((c) => c.subs.isNotEmpty);
      final summary = c.toSummaryEntity();
      expect(summary.subs, isEmpty);
      expect(summary.id, c.id);
      expect(summary.name, c.name);
      expect(summary.nameAr, c.nameAr);
      expect(summary.image, c.image);
    });

    test('featured sections keep flags, slides and products', () {
      for (final s in catalog.sections) {
        final e = s.toEntity();
        expect(e.isOrderAgain, s.isOrderAgain, reason: s.id);
        expect(e.isBestSelling, s.isBestSelling, reason: s.id);
        expect(e.slides, s.slides, reason: s.id);
        expect(e.products.length, s.products.length, reason: s.id);
        for (final lang in _languages) {
          expect(
            e.nameFor(lang),
            _withLocale(lang, () => s.displayName),
            reason: s.id,
          );
        }
      }
    });
  });
}
