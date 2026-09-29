import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/support_category_model.dart';
import '../models/support_ticket_receipt_model.dart';

/// The Hero support routes the app uses. `results` only (the envelope is
/// unwrapped by `DioConsumer`); throws `AppException`.
///
/// Reference: https://docs.jm3eia.store/developers/support.html
abstract class SupportRemoteDataSource {
  /// `GET /v1/support/categories` (public).
  Future<SupportCategoriesModel> getCategories();

  /// `POST /v1/support/tickets { subject, category, subcategory?, orderId?,
  /// productIds?, body }` (customer).
  Future<SupportTicketReceiptModel> createTicket(Map<String, dynamic> body);
}

class SupportRemoteDataSourceImpl implements SupportRemoteDataSource {
  const SupportRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  static const String _categoriesRoute = 'support/categories';
  static const String _ticketsRoute = 'support/tickets';

  @override
  Future<SupportCategoriesModel> getCategories() async =>
      SupportCategoriesModel.fromJson(
        ApiPayload.asMap(
          await _api.get(EndPoints.supportCategories),
          _categoriesRoute,
        ),
      );

  @override
  Future<SupportTicketReceiptModel> createTicket(
    Map<String, dynamic> body,
  ) async => SupportTicketReceiptModel.fromJson(
    ApiPayload.asMap(
      await _api.post(EndPoints.supportTickets, body: body),
      _ticketsRoute,
    ),
  );
}
