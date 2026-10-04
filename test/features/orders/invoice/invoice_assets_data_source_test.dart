// The invoice PDF's words and files from the bundle: the chosen language's
// `orders` words (decoded off the UI isolate), read once and shared by
// builds asking at the same time, a failed read let go for a Retry; the
// fonts kept while builds keep coming and let go after a quiet while.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/features/orders/data/datasources/invoice_assets_data_source.dart';

import 'invoice_test_fixtures.dart';

/// The repo's files, every read counted; a [broken] path reads as its text.
class _CountingBundle extends DiskAssetBundle {
  final List<String> reads = <String>[];
  final Map<String, String> broken = <String, String>{};

  int readsOf(String key) => reads.where((read) => read == key).length;

  @override
  Future<ByteData> load(String key) async {
    reads.add(key);
    final text = broken[key];
    if (text != null) return ByteData.sublistView(utf8.encode(text));
    return super.load(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const englishFile = 'assets/i18n/en.json';
  late _CountingBundle bundle;

  setUp(() => bundle = _CountingBundle());

  group('labels', () {
    test("the language's orders words in full keys, nothing nested", () async {
      final labels = await InvoiceAssetsDataSourceImpl(bundle).labels('ar');

      expect(labels['orders.invoice_title'], 'الفاتورة');
      expect(labels.keys, everyElement(startsWith('orders.')));
      expect(labels, isNot(contains('orders.invoice_pdf_pages')));
    });

    test('read once; builds asking together share the read', () async {
      final source = InvoiceAssetsDataSourceImpl(bundle);

      await Future.wait([source.labels('en'), source.labels('en')]);
      await source.labels('en');

      expect(bundle.readsOf(englishFile), 1);
    });

    test(
      'a missing or broken file fails, and is read again next time',
      () async {
        final source = InvoiceAssetsDataSourceImpl(bundle);
        bundle.broken[englishFile] = '{"orders": ';

        await expectLater(source.labels('xx'), throwsA(isA<CacheException>()));
        await expectLater(source.labels('en'), throwsA(isA<CacheException>()));

        bundle.broken[englishFile] = '{"core": {}}';
        await expectLater(source.labels('en'), throwsA(isA<CacheException>()));

        bundle.broken.remove(englishFile);
        expect((await source.labels('en'))['orders.invoice_title'], 'Invoice');
        expect(bundle.readsOf(englishFile), 3);
      },
    );
  });

  group('pdfAssets', () {
    test(
      'fonts read once while builds keep coming, again after a quiet while',
      () async {
        const quiet = Duration(milliseconds: 40);
        final source = InvoiceAssetsDataSourceImpl(bundle, keepAssets: quiet);
        const font = InvoiceAssetsDataSourceImpl.arabicBoldFont;

        final first = await source.pdfAssets();
        final second = await source.pdfAssets();
        expect(identical(first, second), isTrue);
        expect(bundle.readsOf(font), 1);
        expect(first.logoPng, isNotEmpty);

        await Future<void>.delayed(quiet * 3);
        final later = await source.pdfAssets();

        expect(identical(later, first), isFalse);
        expect(bundle.readsOf(font), 2);
        expect(later.logoPng, same(first.logoPng));
      },
    );

    test(
      'a font that cannot be read fails, and is read again next time',
      () async {
        final source = InvoiceAssetsDataSourceImpl(_MissingFontBundle(bundle));

        await expectLater(source.pdfAssets(), throwsA(isA<CacheException>()));
        final assets = await source.pdfAssets();

        expect(assets.arabicBold.lengthInBytes, greaterThan(0));
      },
    );
  });
}

/// [inner], except that the Arabic bold font is missing on the first read.
class _MissingFontBundle extends CachingAssetBundle {
  _MissingFontBundle(this.inner);

  final AssetBundle inner;
  bool _failed = false;

  @override
  Future<ByteData> load(String key) async {
    if (key == InvoiceAssetsDataSourceImpl.arabicBoldFont && !_failed) {
      _failed = true;
      throw FlutterError('Unable to load asset: $key');
    }
    return inner.load(key);
  }
}
