import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_block_reason.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_ui_controller.dart';

void main() {
  test('signalBlocked bumps the serial, even for the same reason', () {
    final ui = CheckoutUiController();
    addTearDown(ui.dispose);

    expect(ui.blocked.value, isNull);
    ui.signalBlocked(CheckoutBlockReason.destination);
    final first = ui.blocked.value;
    ui.signalBlocked(CheckoutBlockReason.destination);

    expect(first?.$1, CheckoutBlockReason.destination);
    expect(ui.blocked.value?.$1, CheckoutBlockReason.destination);
    expect(ui.blocked.value?.$2, (first?.$2 ?? 0) + 1);
  });

  test('requestItems and bumpPayment notify', () {
    final ui = CheckoutUiController();
    addTearDown(ui.dispose);
    var items = 0;
    var payment = 0;
    ui.itemsRequests.addListener(() => items++);
    ui.paymentBumps.addListener(() => payment++);

    ui
      ..requestItems()
      ..requestItems()
      ..bumpPayment();

    expect(items, 2);
    expect(payment, 1);
  });

  test('the clock is injectable', () {
    final at = DateTime(2026, 9, 26, 10, 3);
    expect(CheckoutUiController(clock: () => at).clock(), at);
  });

  test('dispose disposes every notifier', () {
    final ui = CheckoutUiController()..dispose();

    void listener() {}
    expect(() => ui.hintDismissed.addListener(listener), throwsFlutterError);
    expect(() => ui.blocked.addListener(listener), throwsFlutterError);
    expect(() => ui.itemsRequests.addListener(listener), throwsFlutterError);
    expect(() => ui.paymentBumps.addListener(listener), throwsFlutterError);
  });
}
