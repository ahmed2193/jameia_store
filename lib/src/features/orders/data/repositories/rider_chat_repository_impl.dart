import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/rider_chat.dart';
import '../../domain/entities/rider_quick_reply.dart';
import '../../domain/repositories/rider_chat_repository.dart';
import '../datasources/rider_chat_data_source.dart';
import '../mappers/rider_chat_mapper.dart';

class RiderChatRepositoryImpl
    with BaseRepositoryMixin
    implements RiderChatRepository {
  const RiderChatRepositoryImpl(this._source);

  final RiderChatDataSource _source;

  @override
  Stream<RiderChat> watch(String orderId) =>
      guardStream(_source.watch(orderId).map((chat) => chat.toEntity()));

  @override
  Future<Either<Failure, Unit>> send(
    String orderId,
    String text, {
    RiderQuickReply? quick,
  }) => execute(() async {
    await _source.send(orderId, text, quick: quick);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> markRead(String orderId, DateTime at) =>
      execute(() async {
        await _source.markRead(orderId, at);
        return unit;
      });
}
