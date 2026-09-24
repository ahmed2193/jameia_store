import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/content_page_entity.dart';
import '../../domain/usecases/get_content_page_usecase.dart';
import 'content_page_state.dart';

/// One CMS page of the backend (`GET /v1/pages/:slug`): about, contact, FAQ,
/// privacy, terms.
class ContentPageCubit extends Cubit<ContentPageState>
    with SafeCubitMixin<ContentPageState> {
  ContentPageCubit(this._getContentPage, {required this._kind})
    : super(const ContentPageState());

  final GetContentPageUseCase _getContentPage;
  final ContentPageKind _kind;
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    if (!state.isLoaded) {
      safeEmit(state.copyWith(status: ContentPageStatus.loading));
    }
    final result = await _getContentPage(GetContentPageParams(_kind));
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.isLoaded
              ? ContentPageStatus.loaded
              : ContentPageStatus.error,
          failure: failure,
        ),
      ),
      (page) => safeEmit(
        state.copyWith(status: ContentPageStatus.loaded, page: page),
      ),
    );
  }
}
