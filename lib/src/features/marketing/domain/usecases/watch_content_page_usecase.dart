import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/content_page_entity.dart';
import '../repositories/promotions_repository.dart';

class WatchContentPageParams extends Equatable {
  const WatchContentPageParams(this.kind, {this.forceRefresh = false});

  final ContentPageKind kind;

  /// The page asks the server again (reconnect): skip the saved copy.
  final bool forceRefresh;

  @override
  List<Object?> get props => [kind, forceRefresh];
}

/// A CMS page (`GET /v1/pages/:slug`): the copy saved on the device first,
/// then the server's; failures on the error channel.
class WatchContentPageUseCase
    implements
        StreamUseCase<DataSnapshot<ContentPageEntity>, WatchContentPageParams> {
  const WatchContentPageUseCase(this._repository);

  final PromotionsRepository _repository;

  @override
  Stream<DataSnapshot<ContentPageEntity>> call(WatchContentPageParams params) =>
      _repository.watchContentPage(
        params.kind,
        forceRefresh: params.forceRefresh,
      );
}
