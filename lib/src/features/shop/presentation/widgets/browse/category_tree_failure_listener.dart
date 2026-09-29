import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/navigation/hero_snack_bar.dart';
import '../../cubit/category_browse_cubit.dart';
import '../../cubit/category_browse_state.dart';

/// Tells a failed read of a category page's tree. The products never wait
/// for the tree, so its failure is a background one even on the first read
/// (the page shows no full-screen error for it): it goes through
/// [showFailureSnackBar] — a lost connection says nothing of its own (the
/// connection check and the banner speak, and the tree is read again when
/// it returns); anything else says why the sub-category rows are missing.
class CategoryTreeFailureListener extends StatelessWidget {
  const CategoryTreeFailureListener({super.key, required this.child});

  final Widget child;

  /// The failure to tell: the first read's (nothing on screen) or a failed
  /// refresh over the saved tree.
  static Failure? _failureOf(CategoryBrowseState state) =>
      state.load.hasFailed ? state.failure : state.load.toldFailure;

  static bool _shouldTell(
    CategoryBrowseState previous,
    CategoryBrowseState current,
  ) {
    final failure = _failureOf(current);
    return failure != null && failure != _failureOf(previous);
  }

  static void _tell(BuildContext context, CategoryBrowseState state) {
    final failure = _failureOf(state);
    if (failure != null) showFailureSnackBar(context, failure);
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<CategoryBrowseCubit, CategoryBrowseState>(
        listenWhen: _shouldTell,
        listener: _tell,
        child: child,
      );
}
