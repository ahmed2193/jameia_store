import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';

/// Offline source for the login screen. The live KeeTa page hits the passport
/// auth endpoints; here there is no real auth backend, so [login] is a no-op that
/// returns the seeded demo profile from the in-memory [KeetaRepository] (the
/// "logged-in" user), ignoring the typed phone.
abstract class AuthLocalDataSource {
  UserProfile login(String phone);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this.catalog);

  final KeetaRepository catalog;

  @override
  UserProfile login(String phone) => catalog.user;
}
