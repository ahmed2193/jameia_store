// An English address in the Arabic app: every saved part keeps its own
// direction ("5 St. 6 Lane" must not read "St. 6 Lane 5"), and an address
// field reads like what is typed in it, from the layout's start side.
import 'dart:convert';

import 'package:dartz/dartz.dart' show Right;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/features/address/domain/entities/address_field.dart';
import 'package:hero_mart/src/features/address/domain/entities/pinned_place.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_edit_cubit.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_edit/address_text_field.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_edit/pinned_place_text.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_list/address_row_details.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'address_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const start = '\u2068';
  const end = '\u2069';
  const pin = GeoPointEntity(lat: 29.33, lng: 48.07);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  group('the pin line', () {
    const place = PinnedPlace(
      location: pin,
      street: '5 St. 6 Lane',
      building: '7',
    );

    test('right-to-left: each part isolated', () {
      expect(
        pinTitle(place, rtl: true),
        '${start}5 St. 6 Lane$end, Building ${start}7$end',
      );
    });

    test('left-to-right: the words as they are', () {
      expect(pinTitle(place), '5 St. 6 Lane, Building 7');
    });
  });

  Widget inDirection(TextDirection direction, Widget child) => MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Material(child: child),
    ),
  );

  testWidgets('a list row isolates its parts in a right-to-left line', (
    tester,
  ) async {
    await tester.pumpWidget(
      inDirection(
        TextDirection.rtl,
        AddressRowDetails(address: address(street: '5 St. 6 Lane')),
      ),
    );

    // A named street as it is; a bare number with its name.
    expect(
      find.textContaining(
        '${start}Salmiya$end, Block ${start}7$end, '
        '${start}5 St. 6 Lane$end, Building ${start}5$end',
      ),
      findsOneWidget,
    );
  });

  testWidgets('an address field reads in its text\'s direction, from the '
      'layout\'s start side', (tester) async {
    final cubit = AddressEditCubit(
      addAddress: FakeAddAddressUseCase(Right(address())),
      updateAddress: FakeUpdateAddressUseCase(Right(address())),
      original: address(street: '5 St. 6 Lane'),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      inDirection(
        TextDirection.rtl,
        BlocProvider.value(
          value: cubit,
          child: const AddressTextField(
            field: AddressField.street,
            label: 'Street',
          ),
        ),
      ),
    );
    TextField field() => tester.widget<TextField>(find.byType(TextField));

    expect(field().textDirection, TextDirection.ltr);
    expect(field().textAlign, TextAlign.right);

    await tester.enterText(find.byType(TextField), 'شارع ٥');
    await tester.pump();
    expect(field().textDirection, TextDirection.rtl);

    await tester.enterText(find.byType(TextField), '12');
    await tester.pump();
    // No letter: the layout's direction.
    expect(field().textDirection, TextDirection.rtl);
  });
}
