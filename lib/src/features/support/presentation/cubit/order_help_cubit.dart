import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/order_help_issue.dart';
import '../../domain/usecases/create_support_ticket_usecase.dart';
import '../../domain/usecases/get_support_categories_usecase.dart';
import 'order_help_state.dart';

/// "Get help with this order": reads the support taxonomy
/// (`GET /v1/support/categories`), keeps what the customer picks and
/// writes, and opens one ticket about the order (`POST /v1/support/tickets`).
/// A send runs once at a time and never twice after it went through; a
/// failed send keeps everything the customer chose and wrote.
class OrderHelpCubit extends Cubit<OrderHelpState>
    with SafeCubitMixin<OrderHelpState> {
  OrderHelpCubit({
    required this._getCategories,
    required this._createTicket,
    this._clock = DateTime.now,
  }) : super(const OrderHelpState());

  final GetSupportCategoriesUseCase _getCategories;
  final CreateSupportTicketUseCase _createTicket;
  final DateTime Function() _clock;
  int _generation = 0;

  /// The options: the skeleton while nothing is on screen, a retry reads
  /// again. A reply older than the last request is dropped.
  Future<void> load() async {
    final generation = ++_generation;
    final started = state.load.started();
    if (started != state.load) safeEmit(state.withLoad(started));
    final result = await _getCategories(const NoParams());
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(state.withLoad(state.load.failedWith(failure))),
      (categories) => safeEmit(
        state.copyWith(
          groups: OrderHelpIssueGroup.listOf(categories),
          load: state.load.arrived(
            DataSnapshot<Object?>(
              data: categories,
              fetchedAt: _clock(),
              origin: SnapshotOrigin.network,
            ),
          ),
        ),
      ),
    );
  }

  /// The connection came back over a page that could not load.
  Future<void> onReconnected() async {
    if (state.load.needsRefresh) await load();
  }

  void selectIssue(OrderHelpIssue issue) {
    if (state.sent || state.request.issue == issue) return;
    safeEmit(state.copyWith(request: state.request.withIssue(issue)));
  }

  void toggleProduct(String productId) {
    if (state.sent) return;
    safeEmit(state.copyWith(request: state.request.toggleProduct(productId)));
  }

  void setNote(String note) {
    if (state.sent || state.request.note == note) return;
    safeEmit(state.copyWith(request: state.request.withNote(note)));
  }

  /// Opens the ticket for [orderId]. The page words the [subject] and the
  /// [fallbackBody] used when the customer wrote nothing (it knows the
  /// language). Returns whether the ticket is open.
  Future<bool> send({
    required String orderId,
    required String subject,
    required String fallbackBody,
  }) async {
    if (!state.canSend) return false;
    final draft = state.request.toDraft(
      orderId: orderId,
      subject: subject,
      fallbackBody: fallbackBody,
    );
    if (draft == null) return false;
    safeEmit(state.copyWith(isSending: true));
    final result = await _createTicket(CreateSupportTicketParams(draft));
    return result.fold(
      (failure) {
        safeEmit(
          state.copyWith(isSending: false, load: state.load.noted(failure)),
        );
        return false;
      },
      (receipt) {
        safeEmit(state.copyWith(isSending: false, receipt: receipt));
        return true;
      },
    );
  }
}
