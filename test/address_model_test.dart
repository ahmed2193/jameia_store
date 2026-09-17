// Smoke test: JameiaAddress JSON round-trip.
//
// Verifies toJson()/fromJson() preserve every field — including the
// schema-driven Jameia fields (structType / labelType / dropOff) and the KW
// addressing parts (block / street / lat / lng) — so user-added addresses
// survive serialization to shared_preferences and back.

import 'package:flutter_test/flutter_test.dart';

import 'package:jameia_mart/src/core/data/models/address.dart';
import 'package:jameia_mart/src/core/utils/jameia_geocode.dart';

void main() {
  test('JameiaAddress.toJson()/fromJson() round-trip preserves all fields', () {
    const original = JameiaAddress(
      id: 'addr_test_1',
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
      altLocation: 'Reception desk, ground floor',
      poiName: 'Tower One',
      brief: 'Salmiya, Block 7, Street 22, Tower One',
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

    final restored = JameiaAddress.fromJson(original.toJson());

    // Core / legacy flat fields.
    expect(restored.id, original.id);
    expect(restored.label, original.label);
    expect(restored.line, original.line);
    expect(restored.area, original.area);
    expect(restored.recipient, original.recipient);
    expect(restored.phone, original.phone);
    expect(restored.isDefault, original.isDefault);
    expect(restored.lat, original.lat);
    expect(restored.lng, original.lng);

    // Schema-driven enums.
    expect(restored.structType, StructType.office);
    expect(restored.labelType, LabelType.work);
    expect(restored.dropOff, DropOff.leaveAtSpot);

    // KW addressing parts + the rest.
    expect(restored.dropSpot, original.dropSpot);
    expect(restored.altLocation, original.altLocation);
    expect(restored.poiName, original.poiName);
    expect(restored.brief, original.brief);
    expect(restored.detail, original.detail);
    expect(restored.buildingName, original.buildingName);
    expect(restored.aptNumber, original.aptNumber);
    expect(restored.unitOrFloor, original.unitOrFloor);
    expect(restored.companyName, original.companyName);
    expect(restored.street, original.street);
    expect(restored.block, original.block);
    expect(restored.avenue, original.avenue);
    expect(restored.additionalDirection, original.additionalDirection);
    expect(restored.note, original.note);
  });

  test('round-trip defaults handToMe drop-off + apartment/home enums', () {
    const a = JameiaAddress(
      id: 'addr_test_2',
      label: 'Home',
      line: '',
      area: 'Hawally',
      recipient: '',
      phone: '',
      isDefault: false,
      lat: 29.3328,
      lng: 48.0289,
    );

    final r = JameiaAddress.fromJson(a.toJson());
    expect(r.structType, StructType.apartment);
    expect(r.labelType, LabelType.home);
    expect(r.dropOff, DropOff.handToMe);
    expect(r.lat, 29.3328);
    expect(r.lng, 48.0289);
  });
}
