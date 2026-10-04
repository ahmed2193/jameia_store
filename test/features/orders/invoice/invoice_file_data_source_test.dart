// The system screens a ready invoice goes to, through the plugins' own
// channels (faked here): save answers with the place or nothing, share hands
// the file over with the button's box, print names the job without the
// ".pdf" the queue adds, the preview's pages come out as PNGs in order, and
// a platform error or a missing plugin becomes a CacheException.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/features/orders/data/datasources/invoice_file_data_source.dart';
import 'package:printing/printing.dart';

const MethodChannel _dialog = MethodChannel('flutter_file_dialog');
const MethodChannel _printing = MethodChannel('net.nfet.printing');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const source = InvoiceFileDataSourceImpl();
  final bytes = Uint8List.fromList(const [37, 80, 68, 70]);
  const name = 'Hero-Invoice-HM-10234-EN.pdf';
  final calls = <MethodCall>[];

  void answer(MethodChannel channel, Object? Function(MethodCall call) reply) =>
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return reply(call);
      });

  Map<Object?, Object?> argumentsOf(MethodCall call) =>
      call.arguments as Map<Object?, Object?>;

  setUp(calls.clear);
  tearDown(() {
    messenger.setMockMethodCallHandler(_dialog, null);
    messenger.setMockMethodCallHandler(_printing, null);
  });

  group('save', () {
    test('written → true, the customer backed out → false', () async {
      answer(_dialog, (_) => 'content://downloads/12');
      expect(await source.save(bytes, name), isTrue);

      final call = calls.single;
      expect(call.method, 'saveFile');
      expect(argumentsOf(call)['fileName'], name);
      expect(argumentsOf(call)['data'], bytes);
      expect(argumentsOf(call)['mimeTypesFilter'], ['application/pdf']);

      answer(_dialog, (_) => null);
      expect(await source.save(bytes, name), isFalse);
    });

    test('a platform error or no plugin → CacheException', () async {
      answer(_dialog, (_) => throw PlatformException(code: 'denied'));
      await expectLater(
        source.save(bytes, name),
        throwsA(isA<CacheException>()),
      );

      messenger.setMockMethodCallHandler(_dialog, null);
      await expectLater(
        source.save(bytes, name),
        throwsA(isA<CacheException>()),
      );
    });
  });

  test("share hands the file over with the button's box", () async {
    answer(_printing, (_) => 1);

    final shared = await source.share(
      bytes,
      name,
      origin: const Rect.fromLTWH(10, 20, 100, 44),
    );

    expect(shared, isTrue);
    final call = calls.single;
    expect(call.method, 'sharePdf');
    expect(argumentsOf(call)['name'], name);
    expect(
      [
        for (final key in ['x', 'y', 'w', 'h']) argumentsOf(call)[key],
      ],
      [10, 20, 100, 44],
    );
  });

  group('print', () {
    test(
      'the job is named without ".pdf"; done once the dialog says so',
      () async {
        answer(_printing, (call) {
          if (call.method == 'printPdf') {
            final job = argumentsOf(call)['job'];
            // The platform reports back once its dialog closes.
            unawaited(
              Future<void>(
                () => messenger.handlePlatformMessage(
                  _printing.name,
                  _printing.codec.encodeMethodCall(
                    MethodCall('onCompleted', <String, Object?>{
                      'job': job,
                      'completed': true,
                    }),
                  ),
                  (_) {},
                ),
              ),
            );
          }
          return 1;
        });

        expect(await source.printDocument(bytes, name), isTrue);
        expect(argumentsOf(calls.single)['name'], 'Hero-Invoice-HM-10234-EN');
      },
    );

    test('a platform error → CacheException', () async {
      answer(_printing, (_) => throw PlatformException(code: 'no-printer'));

      await expectLater(
        source.printDocument(bytes, name),
        throwsA(isA<CacheException>()),
      );
    });
  });

  group('renderPages', () {
    PdfRaster page(int width, int height) =>
        PdfRaster(width, height, Uint8List(width * height * 4));

    test('every page as a PNG, first page first, at the dpi', () async {
      double? askedDpi;
      final drawing = InvoiceFileDataSourceImpl(
        rasterize: (document, {pages, dpi = 72}) {
          askedDpi = dpi;
          return Stream<PdfRaster>.fromIterable([page(2, 3), page(4, 5)]);
        },
      );

      final pages = await drawing.renderPages(bytes, 200).toList();

      expect(askedDpi, 200);
      expect(pages.map((page) => page.index), [0, 1]);
      expect(pages.map((page) => (page.width, page.height)), [(2, 3), (4, 5)]);
      // A PNG: the signature's "PNG" after its first byte.
      expect(pages.first.png.sublist(1, 4), [0x50, 0x4E, 0x47]);
    });

    test('a renderer error → CacheException', () async {
      final drawing = InvoiceFileDataSourceImpl(
        rasterize: (document, {pages, dpi = 72}) =>
            Stream<PdfRaster>.error(PlatformException(code: 'corrupt')),
      );

      await expectLater(
        drawing.renderPages(bytes, 200),
        emitsError(isA<CacheException>()),
      );
    });
  });
}
