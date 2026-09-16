import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/meal_for_one_view.dart';
import '../repositories/discovery_repository.dart';

/// Load the "Meal for One" channel: seed the curated view from the full shop set
/// and the real filter chips (the chip-driven curation lives on
/// [MealForOneView.curatedFor], invoked synchronously as the user taps a chip).
class GetMealForOneUseCase implements UseCase<MealForOneView, NoParams> {
  final DiscoveryRepository repository;
  const GetMealForOneUseCase(this.repository);

  @override
  Future<Either<Failure, MealForOneView>> call(NoParams params) async {
    final result = await repository.catalogue();
    return result.fold(
      (failure) => Left(failure),
      (c) => Right(MealForOneView(filters: c.filters, shops: c.shops)),
    );
  }
}
