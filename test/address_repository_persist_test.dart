// Smoke test: JameiaRepository address-book persistence (shared_preferences).
//
// A user-added address must survive a fresh repository instance (it is written
// to shared_preferences on upsert and restored on the next load()). Deleting it
// removes it from the restored book.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jameia_mart/src/core/data/jameia_repository.dart';
import 'package:jameia_mart/src/core/data/models/address.dart';
import 'package:jameia_mart/src/core/utils/jameia_geocode.dart';

void main() {
  // load() reads bundled assets via rootBundle + persists via shared_preferences.
  TestWidgetsFlutterBinding.ensureInitialized();

  const newAddr = JameiaAddress(
    id: 'addr_persist_test',
    label: 'Hangout',
    line: 'Block 3, Street 9, Beach Tower',
    area: 'Mahboula',
    recipient: 'Sara',
    phone: '+96599887766',
    isDefault: false,
    lat: 29.1456,
    lng: 48.1278,
    structType: StructType.apartment,
    labelType: LabelType.hangout,
    brief: 'Mahboula, Block 3, Street 9, Beach Tower',
    buildingName: 'Beach Tower',
    aptNumber: '8',
    unitOrFloor: 'Floor 4',
    street: '9',
    block: '3',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'upserted address survives a fresh JameiaRepository, delete removes it',
    () async {
      // First repo: load the seed book, then add a new address (persisted).
      final repo1 = JameiaRepository();
      await repo1.load();
      expect(repo1.addresses.any((a) => a.id == newAddr.id), isFalse);

      repo1.upsertAddress(newAddr);
      expect(repo1.addresses.any((a) => a.id == newAddr.id), isTrue);

      // Give the best-effort async persistence a chance to flush.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Second repo: a fresh instance must restore the persisted book.
      final repo2 = JameiaRepository();
      await repo2.load();
      final restored = repo2.addresses.where((a) => a.id == newAddr.id);
      expect(restored, hasLength(1));
      expect(restored.first.area, 'Mahboula');
      expect(restored.first.block, '3');
      expect(restored.first.labelType, LabelType.hangout);

      // Delete it on repo2, persist, and confirm a 3rd repo no longer has it.
      repo2.deleteAddress(newAddr.id);
      expect(repo2.addresses.any((a) => a.id == newAddr.id), isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final repo3 = JameiaRepository();
      await repo3.load();
      expect(repo3.addresses.any((a) => a.id == newAddr.id), isFalse);
    },
  );

  test('defaultAddress/activeAddress never throw on an empty address book', () {
    // A fresh (un-loaded) repository has no addresses yet — the getters must
    // return the benign empty placeholder instead of throwing StateError.
    final repo = JameiaRepository();
    expect(repo.addresses, isEmpty);
    expect(() => repo.defaultAddress, returnsNormally);
    expect(repo.defaultAddress, same(JameiaAddress.empty));
    expect(() => repo.activeAddress, returnsNormally);
    expect(repo.activeAddress, same(JameiaAddress.empty));
  });

  test(
    'deleteAddress keeps the last remaining address (book never emptied)',
    () async {
      final repo = JameiaRepository();
      await repo.load();
      for (final a in [...repo.addresses]) {
        repo.deleteAddress(a.id);
      }
      expect(repo.addresses, hasLength(1));
      expect(() => repo.defaultAddress, returnsNormally);
    },
  );
}
