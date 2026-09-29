// BX-11: the add-to-cart flight's destination stack, on its own.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/fly_to_cart.dart';

void main() {
  group('FlyToCartTargets', () {
    test('empty: nowhere to land', () {
      final targets = FlyToCartTargets();

      expect(targets.top, isNull);
      expect(targets.length, 0);
    });

    test('the base target is where flights land', () {
      final targets = FlyToCartTargets();
      final shell = GlobalKey();

      targets.register(shell);

      expect(targets.top, shell);
    });

    test('registering again replaces the base, keeping pushed targets', () {
      final targets = FlyToCartTargets();
      final oldShell = GlobalKey();
      final newShell = GlobalKey();
      final page = GlobalKey();

      targets
        ..register(oldShell)
        ..push(page)
        ..register(newShell);

      expect(targets.top, page);
      expect(targets.length, 2);
      targets.pop(page);
      expect(targets.top, newShell);
    });

    test('a pushed target rules until popped; the one below comes back', () {
      final targets = FlyToCartTargets();
      final shell = GlobalKey();
      final pdp = GlobalKey();
      final sheet = GlobalKey();

      targets
        ..register(shell)
        ..push(pdp)
        ..push(sheet);
      expect(targets.top, sheet);

      targets.pop(sheet);
      expect(targets.top, pdp);
      targets.pop(pdp);
      expect(targets.top, shell);
    });

    test('popping out of order or an unknown key leaves the rest alone', () {
      final targets = FlyToCartTargets();
      final shell = GlobalKey();
      final a = GlobalKey();
      final b = GlobalKey();

      targets
        ..register(shell)
        ..push(a)
        ..push(b)
        ..pop(a)
        ..pop(GlobalKey());

      expect(targets.top, b);
      expect(targets.length, 2);
    });
  });

  test('FlyToCart keeps its static front door onto one registry', () {
    final shell = GlobalKey();
    final page = GlobalKey();

    FlyToCart.registerTarget(shell);
    FlyToCart.pushTarget(page);
    expect(FlyToCart.debugTarget, page);
    FlyToCart.popTarget(page);
    expect(FlyToCart.debugTarget, shell);
    expect(FlyToCart.defaultThumbSize, 56);
  });
}
