// A field's text reads in its own direction, from the layout's start side.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/utils/typed_text_direction.dart';

void main() {
  test('follows what is typed; no letter keeps the layout\'s', () {
    final direction = TypedTextDirection('5 St. 6 Lane');
    addTearDown(direction.dispose);
    expect(direction.directionIn(TextDirection.rtl), TextDirection.ltr);

    direction.follow('شارع ٥');
    expect(direction.directionIn(TextDirection.ltr), TextDirection.rtl);

    direction.follow('12');
    expect(direction.directionIn(TextDirection.rtl), TextDirection.rtl);
    expect(direction.directionIn(TextDirection.ltr), TextDirection.ltr);
  });

  test('aligned to the layout\'s start side', () {
    expect(TypedTextDirection.startOf(TextDirection.rtl), TextAlign.right);
    expect(TypedTextDirection.startOf(TextDirection.ltr), TextAlign.left);
  });
}
