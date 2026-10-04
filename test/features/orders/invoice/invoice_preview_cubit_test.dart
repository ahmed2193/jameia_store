// The invoice PDF preview's cubit: a file's pages drawn one after the
// other, another file replacing them, no file clearing them, the same file
// never drawn twice, a failed drawing and its retry, and the drawing
// stopped when the page closes.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_language.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/invoice_preview_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/invoice_preview_state.dart';

import 'fake_invoice_repository.dart';
import 'invoice_test_fixtures.dart';

void main() {
  late FakeInvoiceRepository repository;
  final english = fakeInvoiceDocument(pageCount: 2);
  final arabic = fakeInvoiceDocument(language: InvoiceLanguage.arabic);

  setUp(() => repository = FakeInvoiceRepository());

  InvoicePreviewCubit build() => invoicePreviewCubit(repository);

  blocTest<InvoicePreviewCubit, InvoicePreviewState>(
    'the pages one after the other, then ready',
    build: build,
    act: (cubit) => cubit.show(english),
    expect: () => [
      InvoicePreviewState(
        status: InvoicePreviewStatus.drawing,
        document: english,
      ),
      InvoicePreviewState(
        status: InvoicePreviewStatus.drawing,
        document: english,
        pages: [fakePageImage(0)],
      ),
      InvoicePreviewState(
        status: InvoicePreviewStatus.drawing,
        document: english,
        pages: [fakePageImage(0), fakePageImage(1)],
      ),
      InvoicePreviewState(
        status: InvoicePreviewStatus.ready,
        document: english,
        pages: [fakePageImage(0), fakePageImage(1)],
      ),
    ],
    verify: (cubit) {
      expect(cubit.state.pageCount, 2);
      expect(repository.calls, ['render:en']);
    },
  );

  blocTest<InvoicePreviewCubit, InvoicePreviewState>(
    'the same file is not drawn twice; another replaces it; none clears',
    build: build,
    act: (cubit) async {
      cubit.show(english);
      await Future<void>.delayed(Duration.zero);
      cubit.show(english);
      cubit.show(arabic);
      await Future<void>.delayed(Duration.zero);
      cubit.show(null);
    },
    skip: 4,
    expect: () => [
      InvoicePreviewState(
        status: InvoicePreviewStatus.drawing,
        document: arabic,
      ),
      InvoicePreviewState(
        status: InvoicePreviewStatus.drawing,
        document: arabic,
        pages: [fakePageImage(0)],
      ),
      InvoicePreviewState(
        status: InvoicePreviewStatus.ready,
        document: arabic,
        pages: [fakePageImage(0)],
      ),
      const InvoicePreviewState(),
    ],
    verify: (_) => expect(repository.calls, ['render:en', 'render:ar']),
  );

  blocTest<InvoicePreviewCubit, InvoicePreviewState>(
    'a failed drawing says why; retry draws the file again',
    build: build,
    setUp: () => repository.renderFailure = const CacheFailure('renderer'),
    act: (cubit) async {
      cubit.show(english);
      await Future<void>.delayed(Duration.zero);
      cubit.retry();
    },
    expect: () => [
      InvoicePreviewState(
        status: InvoicePreviewStatus.drawing,
        document: english,
      ),
      InvoicePreviewState(
        status: InvoicePreviewStatus.drawing,
        document: english,
        pages: [fakePageImage(0)],
      ),
      InvoicePreviewState(
        status: InvoicePreviewStatus.failed,
        document: english,
        pages: [fakePageImage(0)],
        failure: const CacheFailure('renderer'),
      ),
      InvoicePreviewState(
        status: InvoicePreviewStatus.drawing,
        document: english,
      ),
      InvoicePreviewState(
        status: InvoicePreviewStatus.drawing,
        document: english,
        pages: [fakePageImage(0)],
      ),
      InvoicePreviewState(
        status: InvoicePreviewStatus.drawing,
        document: english,
        pages: [fakePageImage(0), fakePageImage(1)],
      ),
      InvoicePreviewState(
        status: InvoicePreviewStatus.ready,
        document: english,
        pages: [fakePageImage(0), fakePageImage(1)],
      ),
    ],
    verify: (_) => expect(repository.calls, ['render:en', 'render:en']),
  );

  test('closing stops the drawing', () async {
    final cubit = build()..show(english);
    await cubit.close();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.pages, isEmpty);
  });
}
