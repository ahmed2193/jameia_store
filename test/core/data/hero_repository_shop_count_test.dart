// BX-05 / PB-14: the 2.2 MB catalogue is not read before the first frame just
// to count favourites. `load()` (awaited before runApp) reads only the small
// account asset; the shop count is read on the first `shopCount()` call —
// once — and matches what the full parse would have counted.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/data/hero/hero_loader.dart';
import 'package:hero_mart/src/core/data/hero_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _catalogAsset = 'assets/data/hero/hero_catalog.json';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Every asset key the app asks the engine for.
  final requested = <String>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    requested.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = Uri.decodeFull(
            utf8.decode(message!.buffer.asUint8List()),
          );
          requested.add(key);
          final bytes = File(key).readAsBytesSync();
          return ByteData.sublistView(bytes);
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null),
  );

  test('load() never touches the catalogue', () async {
    await HeroRepository().load();

    expect(requested, isNot(contains(_catalogAsset)));
  });

  test('the shop count is read once, on first use, and matches the full '
      'parse', () async {
    final repository = HeroRepository();
    await repository.load();
    final raw = File(_catalogAsset).readAsStringSync();
    final expected = parseHeroCatalog(raw).shops.length;

    final first = await repository.shopCount();
    final second = await repository.shopCount();

    expect(expected, greaterThan(0));
    expect(first, expected);
    expect(second, expected);
    expect(requested.where((key) => key == _catalogAsset), hasLength(1));
  });

  test('countHeroShops counts one shop per top category', () {
    final raw = File(_catalogAsset).readAsStringSync();

    expect(countHeroShops(raw), parseHeroCatalog(raw).categories.length);
    expect(countHeroShops('[]'), 0);
    expect(countHeroShops('{"categories": 3}'), 0);
  });
}
