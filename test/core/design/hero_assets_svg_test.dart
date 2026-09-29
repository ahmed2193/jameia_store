// Every drawn SVG of the bundle (assets/svg/) has a HeroAssets constant, is
// drawn somewhere in lib/, ships in the bundle and parses
// (docs/motion/asset_manifest.md, BX-13).
import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const String _heroAssets = 'lib/src/core/design/hero_assets.dart';

/// `static const String name = 'assets/svg/x.svg';` (the formatter may break
/// the line after `=`).
final RegExp _declaration = RegExp(
  r"static const String (\w+) =\s*'(assets/svg/[a-z0-9_]+\.svg)'",
);

Map<String, String> _declared() => {
  for (final match in _declaration.allMatches(
    File(_heroAssets).readAsStringSync(),
  ))
    match.group(1)!: match.group(2)!,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every file in assets/svg/ has one HeroAssets constant', () {
    final files = Directory('assets/svg')
        .listSync()
        .whereType<File>()
        .map((file) => 'assets/svg/${file.uri.pathSegments.last}')
        .where((path) => path.endsWith('.svg'))
        .toSet();
    final declared = _declared().values.toList();
    expect(declared.toSet(), files);
    expect(declared.length, declared.toSet().length, reason: 'duplicates');
  });

  test('every HeroAssets SVG constant is drawn somewhere in lib/', () {
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.uri.path.endsWith(_heroAssets))
        .map((file) => file.readAsStringSync())
        .join('\n');
    final unused = [
      for (final name in _declared().keys)
        if (!RegExp('HeroAssets\\.$name\\b').hasMatch(sources)) name,
    ];
    expect(unused, isEmpty);
  });

  testWidgets('every HeroAssets SVG ships in the bundle and parses', (
    tester,
  ) async {
    final assets = _declared().values;
    expect(assets, isNotEmpty);
    for (final asset in assets) {
      // Reads the bundled file and compiles it like SvgPicture does; a
      // missing asset or broken markup throws.
      final bytes = await tester.runAsync(
        () => SvgAssetLoader(asset).loadBytes(null),
      );
      expect(bytes!.lengthInBytes, greaterThan(0), reason: asset);
    }
  });
}
