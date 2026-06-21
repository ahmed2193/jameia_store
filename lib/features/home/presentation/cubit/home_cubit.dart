import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';

/// Home-feed state. Sealed hierarchy so the screen `switch`es exhaustively.
sealed class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeError extends HomeState {
  const HomeError();
}

class HomeLoaded extends HomeState {
  final UserProfile user;
  final KeetaAddress address;
  final List<KingKongItem> kingkong;
  final List<HomeBanner> banners;
  final List<String> filters;
  final List<Shop> shops;
  final int activeFilter;

  const HomeLoaded({
    required this.user,
    required this.address,
    required this.kingkong,
    required this.banners,
    required this.filters,
    required this.shops,
    this.activeFilter = 0,
  });

  HomeLoaded copyWith({int? activeFilter, List<Shop>? shops}) => HomeLoaded(
        user: user,
        address: address,
        kingkong: kingkong,
        banners: banners,
        filters: filters,
        shops: shops ?? this.shops,
        activeFilter: activeFilter ?? this.activeFilter,
      );

  @override
  List<Object?> get props => [user, address, shops, activeFilter, banners];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repo) : super(const HomeLoading());

  final KeetaRepository _repo;

  void load() {
    try {
      emit(HomeLoaded(
        user: _repo.user,
        address: _repo.defaultAddress,
        kingkong: _repo.kingkong,
        banners: _repo.banners,
        filters: _repo.filters,
        shops: _repo.shops,
      ));
    } catch (_) {
      emit(const HomeError());
    }
  }

  void selectFilter(int index) {
    final s = state;
    if (s is! HomeLoaded) return;
    // Demo filter: "Free delivery" filters; everything else shows all.
    final label = s.filters[index];
    final shops = label == 'Free delivery'
        ? _repo.shops.where((sh) => sh.freeDelivery).toList()
        : label == 'Rating 4.5+'
            ? _repo.shops.where((sh) => sh.rating >= 4.5).toList()
            : _repo.shops;
    emit(s.copyWith(activeFilter: index, shops: shops));
  }
}
