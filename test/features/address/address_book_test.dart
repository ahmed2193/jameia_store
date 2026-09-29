import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/features/address/domain/entities/address_book.dart';

import 'address_test_fakes.dart';

void main() {
  test('of() moves the default address first, keeps the server order', () {
    final book = AddressBook.of([
      address(n: 1),
      address(n: 2),
      address(n: 3, isDefault: true),
    ]);
    expect(book.addresses.map((a) => a.id), [
      addressId(3),
      addressId(1),
      addressId(2),
    ]);
    expect(book.defaultAddress?.id, addressId(3));
  });

  test('defaultAddress falls back to the first address, null when empty', () {
    expect(
      AddressBook.of([address(n: 1), address(n: 2)]).defaultAddress?.id,
      addressId(1),
    );
    expect(AddressBook.empty.defaultAddress, isNull);
    expect(AddressBook.empty.isEmpty, isTrue);
  });

  test('upsert appends a new address and replaces a known one', () {
    final book = AddressBook.of([address(n: 1)]);
    final added = book.upsert(address(n: 2));
    expect(added.addresses.map((a) => a.id), [addressId(1), addressId(2)]);

    final edited = added.upsert(address(n: 1, city: 'Hawally'));
    expect(edited.byId(addressId(1))?.city, 'Hawally');
    expect(edited.addresses, hasLength(2));
  });

  test('a new default clears the flag on the others and moves first', () {
    final book = AddressBook.of([
      address(n: 1, isDefault: true),
      address(n: 2),
    ]);
    final next = book.upsert(address(n: 2, isDefault: true));
    expect(next.addresses.first.id, addressId(2));
    expect(next.byId(addressId(1))?.isDefault, isFalse);
    expect(next.addresses.where((a) => a.isDefault), hasLength(1));
  });

  test('remove drops the id; an unknown id returns the same book', () {
    final book = AddressBook.of([address(n: 1), address(n: 2)]);
    expect(book.remove(addressId(1)).addresses.map((a) => a.id), [
      addressId(2),
    ]);
    expect(identical(book.remove(addressId(9)), book), isTrue);
  });

  test('restore puts an address back where it was (B1-17)', () {
    final book = AddressBook.of([address(n: 1), address(n: 2), address(n: 3)]);
    final without = book.remove(addressId(2));

    expect(without.restore(address(n: 2), 1), book);
    expect(
      without.restore(address(n: 2), 9).addresses.last.id,
      addressId(2),
      reason: 'clamped to the end',
    );
    expect(identical(book.restore(address(n: 2), 0), book), isTrue);
  });

  test('a restored default gives way to a newer default', () {
    final book = AddressBook.of([
      address(n: 1, isDefault: true),
      address(n: 2),
    ]);
    final moved = book.remove(addressId(1)).withDefault(addressId(2));

    final restored = moved.restore(address(n: 1, isDefault: true), 0);
    expect(restored.addresses.where((a) => a.isDefault), hasLength(1));
    expect(restored.flaggedDefault?.id, addressId(2));
    expect(
      book.remove(addressId(1)).restore(address(n: 1, isDefault: true), 0),
      book,
      reason: 'no other default: it keeps its flag',
    );
  });

  test('books compare by value', () {
    expect(AddressBook.of([address(n: 1)]), AddressBook.of([address(n: 1)]));
  });
}
