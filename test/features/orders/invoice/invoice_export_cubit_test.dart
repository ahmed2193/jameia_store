// The invoice PDF sheet's cubit: the file made in the app's language first,
// a language switch that reuses a file already made, a later opening that
// keeps the last pick, a build overtaken by a newer choice, failures and
// retry, the system screens one at a time.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_language.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_share_origin.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/invoice_export_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/invoice_export_state.dart';

import 'fake_invoice_repository.dart';
import 'invoice_test_fixtures.dart';

void main() {
  late FakeInvoiceRepository repository;
  final order = fullInvoiceOrder();
  final english = fakeInvoiceDocument();
  final arabic = fakeInvoiceDocument(language: InvoiceLanguage.arabic);

  setUp(() => repository = FakeInvoiceRepository());

  InvoiceExportCubit build() => invoiceExportCubit(repository);

  /// A cubit whose English file is ready.
  Future<void> ready(InvoiceExportCubit cubit) =>
      cubit.prepare(order, InvoiceLanguage.english);

  blocTest<InvoiceExportCubit, InvoiceExportState>(
    'opens on the app language: building, then the ready file',
    build: build,
    act: (cubit) => cubit.prepare(order, InvoiceLanguage.arabic),
    expect: () => [
      const InvoiceExportState(
        language: InvoiceLanguage.arabic,
        status: InvoiceExportStatus.building,
      ),
      InvoiceExportState(
        language: InvoiceLanguage.arabic,
        status: InvoiceExportStatus.ready,
        document: arabic,
      ),
    ],
    verify: (cubit) {
      expect(cubit.state.canAct, isTrue);
      expect(repository.calls, ['build:ar']);
    },
  );

  blocTest<InvoiceExportCubit, InvoiceExportState>(
    'a language made before is shown at once, never built twice',
    build: build,
    act: (cubit) async {
      await ready(cubit);
      await cubit.chooseLanguage(InvoiceLanguage.arabic);
      await cubit.chooseLanguage(InvoiceLanguage.english);
      await cubit.chooseLanguage(InvoiceLanguage.english);
    },
    verify: (cubit) {
      expect(repository.calls, ['build:en', 'build:ar']);
      expect(
        cubit.state,
        InvoiceExportState(
          status: InvoiceExportStatus.ready,
          document: english,
        ),
      );
    },
  );

  blocTest<InvoiceExportCubit, InvoiceExportState>(
    'a later opening keeps the last pick; a refreshed order is rebuilt',
    build: build,
    act: (cubit) async {
      await ready(cubit);
      await cubit.chooseLanguage(InvoiceLanguage.arabic);
      await cubit.prepare(order, InvoiceLanguage.english);
      expect(cubit.state.language, InvoiceLanguage.arabic);
      expect(repository.calls, ['build:en', 'build:ar']);

      await cubit.prepare(
        fullInvoiceOrder(status: OrderStatus.cancelled),
        InvoiceLanguage.english,
      );
    },
    verify: (cubit) {
      expect(repository.calls, ['build:en', 'build:ar', 'build:ar']);
      expect(repository.lastOrder?.status, OrderStatus.cancelled);
      expect(cubit.state.document, arabic);
    },
  );

  blocTest<InvoiceExportCubit, InvoiceExportState>(
    'an overtaken file stays off screen, but a switch back shows it at once',
    build: build,
    act: (cubit) async {
      final slowEnglish = Completer<void>();
      repository.buildGates[InvoiceLanguage.english] = slowEnglish;
      final first = ready(cubit);
      await cubit.chooseLanguage(InvoiceLanguage.arabic);
      slowEnglish.complete();
      await first;
      expect(
        cubit.state,
        InvoiceExportState(
          language: InvoiceLanguage.arabic,
          status: InvoiceExportStatus.ready,
          document: arabic,
        ),
      );
      await cubit.chooseLanguage(InvoiceLanguage.english);
    },
    verify: (cubit) {
      expect(repository.calls, ['build:en', 'build:ar']);
      expect(cubit.state.document, english);
    },
  );

  blocTest<InvoiceExportCubit, InvoiceExportState>(
    'asked again while it builds (switch back, sheet reopened): one build',
    build: build,
    act: (cubit) async {
      final slowEnglish = Completer<void>();
      repository.buildGates[InvoiceLanguage.english] = slowEnglish;
      final first = ready(cubit);
      final reopened = cubit.prepare(order, InvoiceLanguage.english);
      await cubit.chooseLanguage(InvoiceLanguage.arabic);
      final back = cubit.chooseLanguage(InvoiceLanguage.english);
      slowEnglish.complete();
      await Future.wait([first, reopened, back]);
    },
    verify: (cubit) {
      expect(repository.calls, ['build:en', 'build:ar']);
      expect(
        cubit.state,
        InvoiceExportState(
          status: InvoiceExportStatus.ready,
          document: english,
        ),
      );
    },
  );

  blocTest<InvoiceExportCubit, InvoiceExportState>(
    "a refreshed order mid-build: the old copy's file is not used",
    build: build,
    act: (cubit) async {
      final slowEnglish = Completer<void>();
      repository.buildGates[InvoiceLanguage.english] = slowEnglish;
      final first = ready(cubit);
      final refreshed = fullInvoiceOrder(status: OrderStatus.cancelled);
      await cubit.prepare(refreshed, InvoiceLanguage.english);
      slowEnglish.complete();
      await first;
      // The refreshed copy's file stays; nothing of the old copy is kept.
      await cubit.chooseLanguage(InvoiceLanguage.arabic);
      await cubit.chooseLanguage(InvoiceLanguage.english);
    },
    verify: (cubit) {
      expect(repository.calls, ['build:en', 'build:en', 'build:ar']);
      expect(repository.lastOrder?.status, OrderStatus.cancelled);
      expect(cubit.state.document, english);
    },
  );

  blocTest<InvoiceExportCubit, InvoiceExportState>(
    'a failed build says why; retry builds again',
    build: build,
    act: (cubit) async {
      repository.buildFailure = const CacheFailure('fonts');
      await ready(cubit);
      await cubit.retry();
    },
    expect: () => [
      const InvoiceExportState(status: InvoiceExportStatus.building),
      const InvoiceExportState(
        status: InvoiceExportStatus.failed,
        failure: CacheFailure('fonts'),
      ),
      const InvoiceExportState(status: InvoiceExportStatus.building),
      InvoiceExportState(status: InvoiceExportStatus.ready, document: english),
    ],
    verify: (_) => expect(repository.calls, ['build:en', 'build:en']),
  );

  blocTest<InvoiceExportCubit, InvoiceExportState>(
    'a save that went through is told once',
    build: build,
    act: (cubit) async {
      await ready(cubit);
      await cubit.save();
    },
    skip: 2,
    expect: () => [
      InvoiceExportState(
        status: InvoiceExportStatus.ready,
        document: english,
        running: InvoiceExportAction.save,
      ),
      InvoiceExportState(
        status: InvoiceExportStatus.ready,
        document: english,
        completed: InvoiceExportAction.save,
      ),
    ],
    verify: (_) => expect(repository.calls, ['build:en', 'save']),
  );

  blocTest<InvoiceExportCubit, InvoiceExportState>(
    'backing out of the dialog completes nothing',
    build: build,
    act: (cubit) async {
      await ready(cubit);
      repository.actionDone = false;
      await cubit.save();
    },
    verify: (cubit) => expect(
      cubit.state,
      InvoiceExportState(status: InvoiceExportStatus.ready, document: english),
    ),
  );

  blocTest<InvoiceExportCubit, InvoiceExportState>(
    'a failed action keeps the file and says why',
    build: build,
    act: (cubit) async {
      await ready(cubit);
      repository.actionFailure = const CacheFailure('no app');
      await cubit.printDocument();
    },
    verify: (cubit) {
      expect(cubit.state.failure, const CacheFailure('no app'));
      expect(cubit.state.canAct, isTrue);
      expect(repository.calls, ['build:en', 'print']);
    },
  );

  blocTest<InvoiceExportCubit, InvoiceExportState>(
    'one system screen at a time; the language is locked meanwhile',
    build: build,
    act: (cubit) async {
      await ready(cubit);
      final shareSheet = Completer<void>();
      repository.actionGate = shareSheet;
      final share = cubit.share(
        origin: const InvoiceShareOrigin(left: 1, top: 2, width: 3, height: 4),
      );
      await cubit.save();
      await cubit.printDocument();
      await cubit.chooseLanguage(InvoiceLanguage.arabic);
      expect(cubit.state.running, InvoiceExportAction.share);
      expect(cubit.state.language, InvoiceLanguage.english);
      shareSheet.complete();
      await share;
    },
    verify: (cubit) {
      expect(repository.calls, ['build:en', 'share']);
      expect(
        repository.lastOrigin,
        const InvoiceShareOrigin(left: 1, top: 2, width: 3, height: 4),
      );
      expect(cubit.state.completed, InvoiceExportAction.share);
    },
  );

  blocTest<InvoiceExportCubit, InvoiceExportState>(
    'no file yet: the actions and the switch do nothing',
    build: build,
    act: (cubit) async {
      await cubit.save();
      await cubit.chooseLanguage(InvoiceLanguage.arabic);
    },
    expect: () => <InvoiceExportState>[],
    verify: (_) => expect(repository.calls, isEmpty),
  );
}
