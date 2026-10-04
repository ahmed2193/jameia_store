import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/design/hero_assets.dart';
import '../../../../core/error/exceptions.dart';
import '../models/invoice_pdf_assets_model.dart';
import 'invoice_pdf/invoice_pdf_style.dart';

/// The invoice PDF's words and the files it embeds, read from the app's
/// bundle.
abstract class InvoiceAssetsDataSource {
  /// The `orders.*` strings of `assets/i18n/<languageCode>.json`, keyed in
  /// full (`orders.subtotal`): the words the invoice page shows, in the
  /// language the PDF is written in — which need not be the app's. Plural
  /// and nested entries are left out. Throws [CacheException].
  Future<Map<String, String>> labels(String languageCode);

  /// The fonts for both scripts and the logo. Throws [CacheException].
  Future<InvoicePdfAssetsModel> pdfAssets();
}

class InvoiceAssetsDataSourceImpl implements InvoiceAssetsDataSource {
  InvoiceAssetsDataSourceImpl(
    this._bundle, {
    this._keepAssets = const Duration(minutes: 2),
  });

  final AssetBundle _bundle;

  /// How long the fonts stay after the last build asked for them (a test
  /// shortens it).
  final Duration _keepAssets;

  static const String _section = 'orders';
  static const String latinRegularFont = 'assets/fonts/NotoSans-Regular.ttf';
  static const String latinBoldFont = 'assets/fonts/NotoSans-Bold.ttf';
  static const String arabicRegularFont =
      'assets/fonts/NotoSansArabicUI-Regular.ttf';
  static const String arabicBoldFont = 'assets/fonts/NotoSansArabicUI-Bold.ttf';

  /// The logo is decoded at three pixels a point of the size the header
  /// prints it at: sharp on paper — the 512 px app icon would add ~100 KB
  /// per file.
  static const double _logoPixelsPerPoint = 3;

  /// Each language's words, read once: the section is small and never
  /// changes while the app runs. The read itself is kept, so builds asking
  /// at the same time share it; a failed one is let go for a Retry.
  final Map<String, Future<Map<String, String>>> _labels =
      <String, Future<Map<String, String>>>{};

  /// The fonts and logo while builds keep coming (a language switch, a
  /// Retry, another invoice); [_keepAssets] after the last one they go —
  /// 1.5 MB not worth holding all day. Builds at the same time share one
  /// read.
  Future<InvoicePdfAssetsModel>? _assets;
  Timer? _releaseAssets;
  Uint8List? _logo;

  @override
  Future<Map<String, String>> labels(String languageCode) async {
    final read = _labels[languageCode] ??= _readLabels(languageCode);
    try {
      return await read;
    } on Object {
      if (identical(_labels[languageCode], read)) _labels.remove(languageCode);
      rethrow;
    }
  }

  @override
  Future<InvoicePdfAssetsModel> pdfAssets() async {
    _releaseAssets?.cancel();
    _releaseAssets = Timer(_keepAssets, () => _assets = null);
    final read = _assets ??= _readAssets();
    try {
      return await read;
    } on Object {
      if (identical(_assets, read)) _assets = null;
      rethrow;
    }
  }

  Future<Map<String, String>> _readLabels(String languageCode) async {
    final ByteData file;
    try {
      file = await _bundle.load(
        '${AppConstants.translationsDir}/$languageCode.json',
      );
    } on FlutterError catch (error) {
      throw CacheException('invoice labels ($languageCode): $error');
    }
    return _decodeLabels(file, languageCode);
  }

  /// Off the UI isolate: the whole file (~100 KB) is decoded for its one
  /// section, while the sheet that asked is opening.
  static Future<Map<String, String>> _decodeLabels(
    ByteData file,
    String languageCode,
  ) => Isolate.run(
    () => _ordersSection(file, languageCode),
    debugName: 'invoice-labels',
  );

  /// The `orders` section of a language file as `orders.<key>` → text.
  static Map<String, String> _ordersSection(
    ByteData file,
    String languageCode,
  ) {
    final Object? content;
    try {
      content = utf8.decoder
          .fuse(json.decoder)
          .convert(
            file.buffer.asUint8List(file.offsetInBytes, file.lengthInBytes),
          );
    } on FormatException catch (error) {
      throw CacheException('invoice labels ($languageCode): $error');
    }
    final section = content is Map<String, dynamic> ? content[_section] : null;
    if (section is! Map<String, dynamic>) {
      throw CacheException('invoice labels ($languageCode): no "$_section"');
    }
    return Map.unmodifiable(<String, String>{
      for (final MapEntry(:key, :value) in section.entries)
        if (value is String) '$_section.$key': value,
    });
  }

  Future<InvoicePdfAssetsModel> _readAssets() async {
    try {
      final fonts = await Future.wait([
        _bundle.load(latinRegularFont),
        _bundle.load(latinBoldFont),
        _bundle.load(arabicRegularFont),
        _bundle.load(arabicBoldFont),
      ]);
      return InvoicePdfAssetsModel(
        latinRegular: fonts[0],
        latinBold: fonts[1],
        arabicRegular: fonts[2],
        arabicBold: fonts[3],
        logoPng: _logo ??= await _smallLogo(),
      );
    } on FlutterError catch (error) {
      throw CacheException('invoice assets: $error');
    } on Exception catch (error) {
      // A logo the engine cannot decode.
      throw CacheException('invoice assets: $error');
    }
  }

  Future<Uint8List> _smallLogo() async {
    final data = await _bundle.load(HeroAssets.appLogo);
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    final codec = await ui.instantiateImageCodecFromBuffer(
      buffer,
      targetWidth: (InvoicePdfStyle.logo * _logoPixelsPerPoint).round(),
    );
    final frame = await codec.getNextFrame();
    try {
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) throw const CacheException('invoice logo: no PNG');
      return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
    } finally {
      frame.image.dispose();
      codec.dispose();
    }
  }
}
