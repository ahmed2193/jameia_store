import '../../../../core/data/models/customer_model.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/end_points.dart';

/// Mirrors the device language onto the customer account so backend
/// notifications / emails arrive in the language the app shows.
///
/// Reference: https://docs.jm3eia.store/developers/account.html
/// (`PATCH /v1/account/profile { language: 'en' | 'ar' }`).
abstract class LangRemoteDataSource {
  Future<void> syncLanguage(String langCode);
}

class LangRemoteDataSourceImpl implements LangRemoteDataSource {
  const LangRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  @override
  Future<void> syncLanguage(String langCode) => _api.patch(
    EndPoints.accountProfile,
    body: <String, Object?>{CustomerModel.languageKey: langCode},
  );
}
