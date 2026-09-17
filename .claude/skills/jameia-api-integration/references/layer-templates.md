# Layer templates (copy these shapes)

Worked example: the wallet ledger, `GET /v1/account/wallet?page&limit` (customer route).
It is **not in the repo yet** — it is here because it shows the common case: a paginated
list, money in fils, an enum, and a header value next to the list.

```
results: {
  balance: { wallet: integer },                       // fils
  data: [{ _id, customerId, type: "refund"|"checkout"|"cashback"|"admin_adjustment"|"promo",
           amount: integer, referenceId: ObjectId|null, note?: string, createdAt: date-time }],
  pagination: { total, page, limit, hasMore }
}
```

Real, shipped equivalents to read next to these templates:
`features/notifications/**` (list + mutations + stream) and `features/account/**` (object + PATCH).

`lib/` uses relative imports; `test/` uses `package:jameia_mart/...`.

---

## 1. Entity — `features/account/domain/entities/wallet_entry_entity.dart`

```dart
import 'package:equatable/equatable.dart';

enum WalletEntryKind { refund, checkout, cashback, adminAdjustment, promo, other }

/// One wallet ledger line. [amountFils] is signed: credits > 0, debits < 0.
class WalletEntryEntity extends Equatable {
  const WalletEntryEntity({
    required this.id,
    required this.kind,
    required this.amountFils,
    required this.createdAt,
    this.note = '',
  });

  static const int filsPerDinar = 1000;

  final String id;
  final WalletEntryKind kind;
  final int amountFils;
  final DateTime createdAt;
  final String note;

  bool get isCredit => amountFils > 0;
  double get amountKd => amountFils / filsPerDinar;

  @override
  List<Object?> get props => [id, kind, amountFils, createdAt, note];
}
```

Page aggregate (feature view entity) — list arithmetic lives HERE, not in the cubit:

```dart
// features/account/domain/entities/wallet_ledger.dart
class WalletLedger extends Equatable {
  const WalletLedger({
    required this.balanceFils,
    required this.entries,
    required this.page,
    required this.hasMore,
  });

  static const WalletLedger empty =
      WalletLedger(balanceFils: 0, entries: [], page: 0, hasMore: false);

  final int balanceFils;
  final List<WalletEntryEntity> entries;
  final int page;
  final bool hasMore;

  bool get isEmpty => entries.isEmpty;

  /// Appends [next] (a later page), dropping ids already shown.
  WalletLedger merge(WalletLedger next) {
    final known = {for (final entry in entries) entry.id};
    return WalletLedger(
      balanceFils: next.balanceFils,
      entries: [...entries, ...next.entries.where((e) => !known.contains(e.id))],
      page: next.page,
      hasMore: next.hasMore,
    );
  }

  @override
  List<Object?> get props => [balanceFils, entries, page, hasMore];
}
```

Domain imports allowed: `dart:*`, `dartz`, `equatable`, `meta`, `collection`, domain files,
`core/domain/**`, `core/error/failures.dart`, `core/usecase/**`. No Flutter, no `intl`.

## 2. DTO — `features/account/data/models/wallet_entry_model.dart`

```dart
import '../../../../core/error/exceptions.dart';

class WalletEntryModel {
  const WalletEntryModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.note = '',
  });

  static const String idKey = '_id';
  static const String typeKey = 'type';
  static const String amountKey = 'amount';
  static const String noteKey = 'note';
  static const String createdAtKey = 'createdAt';

  factory WalletEntryModel.fromJson(Map<String, dynamic> json) {
    final id = json[idKey];
    if (id is! String || id.isEmpty) {
      throw const ParsingException('wallet entry: missing id');
    }
    final createdAtRaw = json[createdAtKey];
    final createdAt =
        createdAtRaw is String ? DateTime.tryParse(createdAtRaw) : null;
    if (createdAt == null) {
      throw const ParsingException('wallet entry: bad createdAt');
    }
    final amount = json[amountKey];
    final type = json[typeKey];
    final note = json[noteKey];
    return WalletEntryModel(
      id: id,
      type: type is String ? type : '',
      amount: amount is num ? amount.toInt() : 0,
      createdAt: createdAt,
      note: note is String ? note : '',
    );
  }

  final String id;
  final String type; // wire value, mapped to the enum by the mapper
  final int amount; // fils
  final DateTime createdAt;
  final String note;
}
```

Rules: named key constants (no string literals scattered in `fromJson`); `is` checks, never
`as`; identity fields missing → `ParsingException`; everything else gets a safe default;
unknown enum wire values map to an `other` case, never throw; never import Flutter or `dartz`.

Page DTO — skip a bad row, keep the page (copy of `NotificationsPageModel`):

```dart
// features/account/data/models/wallet_ledger_model.dart
factory WalletLedgerModel.fromJson(Map<String, dynamic> json, {int requestedPage = 1}) {
  final data = json[dataKey];
  if (data is! List) throw const ParsingException('wallet: data missing');
  final items = <WalletEntryModel>[for (final raw in data) ...?_tryParse(raw)];
  final paginationRaw = json[paginationKey];
  final pagination = paginationRaw is Map
      ? paginationRaw.cast<String, dynamic>()
      : const <String, dynamic>{};
  final balance = json[balanceKey];
  return WalletLedgerModel(
    items: items,
    balance: _int(balance is Map ? balance[walletKey] : null) ?? 0,
    page: _int(pagination[pageKey]) ?? requestedPage,
    hasMore: pagination[hasMoreKey] == true,
  );
}

/// Numbers may arrive as int, double or a numeric string.
static int? _int(Object? value) => switch (value) {
  int() => value,
  num() => value.toInt(),
  String() => int.tryParse(value),
  _ => null,
};

static List<WalletEntryModel>? _tryParse(Object? raw) {
  if (raw is! Map) return null;
  try {
    return [WalletEntryModel.fromJson(raw.cast<String, dynamic>())];
  } on AppException catch (error) {
    log('dropped wallet row: $error', name: 'WalletLedgerModel');
    return null;
  }
}
```

## 3. Mapper — `features/account/data/mappers/wallet_mapper.dart`

```dart
extension WalletEntryMapper on WalletEntryModel {
  WalletEntryEntity toEntity() => WalletEntryEntity(
    id: id,
    kind: _kindOf(type),
    amountFils: amount,
    createdAt: createdAt,
    note: note,
  );

  static WalletEntryKind _kindOf(String wire) => switch (wire) {
    'refund' => WalletEntryKind.refund,
    'checkout' => WalletEntryKind.checkout,
    'cashback' => WalletEntryKind.cashback,
    'admin_adjustment' => WalletEntryKind.adminAdjustment,
    'promo' => WalletEntryKind.promo,
    _ => WalletEntryKind.other,
  };
}

extension WalletEntryListMapper on List<WalletEntryModel> {
  List<WalletEntryEntity> toEntities() =>
      map((model) => model.toEntity()).toList(growable: false);
}

extension WalletLedgerMapper on WalletLedgerModel {
  WalletLedger toEntity() => WalletLedger(
    balanceFils: balance,
    entries: items.toEntities(),
    page: page,
    hasMore: hasMore,
  );
}
```

Write path: the mapper is on the **domain input** and produces the JSON body —
see `features/account/data/mappers/profile_update_mapper.dart` (`ProfileUpdate.toBody()`).

## 4. Remote datasource — `features/account/data/datasources/wallet_remote_data_source.dart`

```dart
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/wallet_ledger_model.dart';

/// Receives the envelope's `results` (unwrapped by `DioConsumer`); throws
/// `AppException` only.
abstract class WalletRemoteDataSource {
  /// `GET /v1/account/wallet?page&limit` (Bearer).
  Future<WalletLedgerModel> getLedger({required int page, required int limit});
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  const WalletRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  static const String pageField = 'page';
  static const String limitField = 'limit';

  @override
  Future<WalletLedgerModel> getLedger({
    required int page,
    required int limit,
  }) async {
    final results = await _api.get(
      EndPoints.accountWallet,
      queryParameters: <String, dynamic>{pageField: page, limitField: limit},
    );
    return WalletLedgerModel.fromJson(
      ApiPayload.asMap(results, EndPoints.accountWallet),
      requestedPage: page,
    );
  }
}
```

`ApiConsumer` surface: `get / post / put / patch / delete(path, {body, queryParameters, headers})`
→ `Future<dynamic>` = the decoded **`results`**. A mutation that returns nothing useful:
`Future<void> x() => _api.post(EndPoints.y, body: {...});`.

## 5. Repository

```dart
// domain/repositories/wallet_repository.dart
abstract class WalletRepository {
  /// `GET /v1/account/wallet` — signed-in only; a guest gets `Left(UnauthorizedFailure)`.
  Future<Either<Failure, WalletLedger>> getLedger({required int page, required int limit});
}

// data/repositories/wallet_repository_impl.dart
class WalletRepositoryImpl with BaseRepositoryMixin implements WalletRepository {
  const WalletRepositoryImpl(this._remote);

  final WalletRemoteDataSource _remote;

  @override
  Future<Either<Failure, WalletLedger>> getLedger({
    required int page,
    required int limit,
  }) => execute(
    () async => (await _remote.getLedger(page: page, limit: limit)).toEntity(),
  );
}
```

`Future<Either<Failure, Unit>>` for "no result" mutations: `execute(() async { await _remote.x(); return unit; })`.
Streams: `guardStream(_remote.watch().map((m) => m.toEntity()))`.

## 6. Use case — `domain/usecases/get_wallet_ledger_usecase.dart`

```dart
class GetWalletLedgerParams extends Equatable {
  const GetWalletLedgerParams({required this.page, required this.limit});

  final int page; // 1-based
  final int limit; // backend cap 100

  @override
  List<Object?> get props => [page, limit];
}

class GetWalletLedgerUseCase implements UseCase<WalletLedger, GetWalletLedgerParams> {
  const GetWalletLedgerUseCase(this._repository);

  final WalletRepository _repository;

  @override
  Future<Either<Failure, WalletLedger>> call(GetWalletLedgerParams params) =>
      _repository.getLedger(page: params.page, limit: params.limit);
}
```

Input that can be invalid is rejected here, before the network:
`if (!params.isValid) return const Left(UnexpectedFailure('…'));`
(see `RegisterPushTokenUseCase`).

## 7. State + cubit

```dart
// presentation/cubit/wallet_state.dart
enum WalletStatus { initial, loading, loaded, error }

class WalletState extends Equatable {
  const WalletState({
    this.status = WalletStatus.initial,
    this.ledger = WalletLedger.empty,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.failure,
  });

  final WalletStatus status;
  final WalletLedger ledger;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  bool get isLoaded => status == WalletStatus.loaded;
  bool get isEmpty => isLoaded && ledger.isEmpty;

  /// Customer route answered 401: show the sign-in prompt, not an error.
  bool get isSignedOut =>
      status == WalletStatus.error && failure is UnauthorizedFailure;

  WalletState copyWith({
    WalletStatus? status,
    WalletLedger? ledger,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    Failure? failure,
  }) => WalletState(
    status: status ?? this.status,
    ledger: ledger ?? this.ledger,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, ledger, isLoadingMore, loadMoreFailed, failure];
}
```

```dart
// presentation/cubit/wallet_cubit.dart
class WalletCubit extends Cubit<WalletState> with SafeCubitMixin<WalletState> {
  WalletCubit(this._getLedger) : super(const WalletState());

  static const int pageSize = 20;
  static const int _firstPage = 1;

  final GetWalletLedgerUseCase _getLedger;

  /// Bumped by every first-page load; a reply from an older generation is stale.
  int _generation = 0;

  Future<void> load() async {
    safeEmit(state.copyWith(status: WalletStatus.loading));
    await refresh();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    final result = await _getLedger(
      const GetWalletLedgerParams(page: _firstPage, limit: pageSize),
    );
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.isLoaded ? WalletStatus.loaded : WalletStatus.error,
          failure: failure,
        ),
      ),
      (ledger) => safeEmit(
        state.copyWith(
          status: WalletStatus.loaded,
          ledger: ledger,
          isLoadingMore: false,
          loadMoreFailed: false,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    if (!state.isLoaded || !state.ledger.hasMore || state.isLoadingMore) return;
    final generation = _generation;
    safeEmit(state.copyWith(isLoadingMore: true, loadMoreFailed: false));
    final result = await _getLedger(
      GetWalletLedgerParams(page: state.ledger.page + 1, limit: pageSize),
    );
    if (generation != _generation) {
      safeEmit(state.copyWith(isLoadingMore: false));
      return;
    }
    result.fold(
      (failure) => safeEmit(
        state.copyWith(isLoadingMore: false, loadMoreFailed: true, failure: failure),
      ),
      (next) => safeEmit(
        state.copyWith(isLoadingMore: false, ledger: state.ledger.merge(next)),
      ),
    );
  }
}
```

Cubit imports: use cases, entities, `core/error/failures.dart`, `core/usecase/usecase.dart`,
`SafeCubitMixin`, `flutter_bloc`. Never a repository, datasource, `sl`, `BuildContext`, widget.

## 8. DI — `features/account/account_injection_container.dart`

```dart
void initAccountFeature() {
  if (sl.isRegistered<AccountRepository>()) return; // idempotent
  sl
    ..registerLazySingleton<WalletRemoteDataSource>(() => WalletRemoteDataSourceImpl(sl()))
    ..registerLazySingleton<WalletRepository>(() => WalletRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetWalletLedgerUseCase(sl()))
    ..registerFactory(() => WalletCubit(sl()));
}
```

`ApiConsumer`, `EventStreamClient`, `SessionStore`, `LocalStorage` are registered by
`setupServiceLocator()` before any feature init. A cubit that needs a runtime argument uses
`registerFactoryParam` (see `ProfileCubit`) and the page passes `param1:` inside `create:`.

## 9. Page + error UI

```dart
class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<WalletCubit>()..load(),
    child: const Scaffold(appBar: WalletAppBar(), body: WalletBody()),
  );
}
```

- Body switches on state: loading → loader; `isSignedOut` → sign-in prompt (button →
  `context.push(Routes.login)`); error → `state.failure?.localizedMessage` + retry;
  `isEmpty` → empty view; loaded → list.
- One-shot failures (refresh, load-more, a mutation) → `BlocListener` with `listenWhen` on
  `failure != null` → snack bar with `failure.localizedMessage`.
- Lists: `ListView.builder`, rows keyed by id + `findChildIndexCallback`, load-more footer that
  shows a loader unless `loadMoreFailed` (then a retry), pull-to-refresh → `cubit.refresh()`.
- Money text: `Formatters.price(entity.amountKd)` (`core/utils/formatters.dart`), never string
  maths in a widget.
