import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/hero_assets.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/motion/fade_through_switcher.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/cubit_busy_overlay.dart';
import '../../../../core/widgets/hero_state_view.dart';
import '../../../address/presentation/cubit/address_book_cubit.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_offers_cubit.dart';
import '../cubit/checkout_rail_cubit.dart';
import '../cubit/checkout_state.dart';
import '../widgets/checkout/checkout_body.dart';
import '../widgets/checkout/checkout_page_listeners.dart';
import '../widgets/checkout/checkout_title_bar.dart';
import '../widgets/checkout/checkout_ui_controller.dart';

/// What the page shows; the switch between them fades through.
enum _CheckoutBucket { loading, error, signedOut, empty, content }

/// Checkout (`Routes.checkout`), Hero style: destination and timing, the
/// deals rail, the order and its savings, payment and notes over the
/// app-global cart, then `POST /v1/orders`.
///
/// The page provides its own cubits — the checkout, the deals rail (in-cart
/// products taken once, at open) and the store's offers — plus the
/// [CheckoutUiController] its sections signal each other through, and
/// switches between loading, error, sign-in, empty and content. Its content
/// waits for the rail to settle, so nothing is inserted above the fold
/// after the first paint. What it does on the customer's behalf (payment
/// fallbacks, dropped coupon / express / window, placing) lives in
/// [CheckoutPageListeners].
///
/// A customer call that answers 401 turns the page into the sign-in prompt
/// ([CheckoutState.requiresSignIn]); an emptied basket into "start
/// shopping". Cart failures are not repeated here: the cart tab under this
/// page (kept mounted by the shell) already reports them.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  @override
  void initState() {
    super.initState();
    // The wallet and points the payment rows and savings read are the
    // customer's latest, not the ones cached at sign-in.
    final session = context.read<AuthSessionCubit>();
    if (session.state.isSignedIn) unawaited(session.restore());
  }

  String? _defaultAddressId(BuildContext context) =>
      context.read<AddressBookCubit>().state.book.defaultAddress?.id;

  /// The cart owns the express flag on the server, so the draft has to open
  /// on whatever the cart already selected.
  bool _expressSelected(BuildContext context) =>
      context.read<CartCubit>().state.cart.expressSelected;

  /// The basket's products when the page opened: the rail never offers
  /// what is already in it.
  Set<String> _basketProductIds(BuildContext context) => <String>{
    for (final line in context.read<CartCubit>().state.cart.lines)
      line.product.id,
  };

  _CheckoutBucket _bucketOf({
    required CheckoutStatus status,
    required bool requiresSignIn,
    required bool railSettled,
    required bool cartEmpty,
  }) {
    if (requiresSignIn) return _CheckoutBucket.signedOut;
    return switch (status) {
      CheckoutStatus.error => _CheckoutBucket.error,
      CheckoutStatus.initial ||
      CheckoutStatus.loading => _CheckoutBucket.loading,
      CheckoutStatus.ready when !railSettled => _CheckoutBucket.loading,
      CheckoutStatus.ready when cartEmpty => _CheckoutBucket.empty,
      // `ready` and `placed` share one bucket, so placing never re-mounts
      // the content (the cart empties under a placed order on purpose).
      CheckoutStatus.ready || CheckoutStatus.placed => _CheckoutBucket.content,
    };
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<CheckoutUiController>(
      create: (_) => CheckoutUiController(),
      dispose: (ui) => ui.dispose(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CheckoutCubit>(
            lazy: false,
            create: (context) => sl<CheckoutCubit>()
              ..start(
                defaultAddressId: _defaultAddressId(context),
                expressSelected: _expressSelected(context),
              ),
          ),
          BlocProvider<CheckoutRailCubit>(
            lazy: false,
            create: (context) =>
                sl<CheckoutRailCubit>()
                  ..load(excludeProductIds: _basketProductIds(context)),
          ),
          BlocProvider<CheckoutOffersCubit>(
            lazy: false,
            create: (_) => sl<CheckoutOffersCubit>()..load(),
          ),
        ],
        child: CheckoutPageListeners(
          // Placing holds the whole screen; the check shows as tracking
          // takes over.
          child: CubitBusyOverlay<CheckoutCubit, CheckoutState>(
            busyOf: (state) => state.isPlacing,
            doneOf: (state) => state.status == CheckoutStatus.placed,
            failOf: (state) =>
                state.failedAction == CheckoutAction.place &&
                state.failure != null &&
                !state.requiresSignIn,
            label: 'checkout.placing'.tr(),
            doneLabel: 'checkout.order_placed'.tr(),
            child: Scaffold(
              backgroundColor: AppColors.smallBackground,
              appBar: const CheckoutTitleBar(),
              body: Builder(
                builder: (context) {
                  final (status, loadFailure, requiresSignIn) = context
                      .select<CheckoutCubit, (CheckoutStatus, Failure?, bool)>(
                        (cubit) => (
                          cubit.state.status,
                          cubit.state.loadFailure,
                          cubit.state.requiresSignIn,
                        ),
                      );
                  final railSettled = context.select<CheckoutRailCubit, bool>(
                    (cubit) => cubit.state.isSettled,
                  );
                  final cartEmpty = context.select<CartCubit, bool>(
                    (cubit) => cubit.state.isEmpty,
                  );
                  final bucket = _bucketOf(
                    status: status,
                    requiresSignIn: requiresSignIn,
                    railSettled: railSettled,
                    cartEmpty: cartEmpty,
                  );
                  return FadeThroughSwitcher(
                    stateKey: bucket,
                    alignment: AlignmentDirectional.topCenter,
                    child: switch (bucket) {
                      _CheckoutBucket.loading => const AppLoader(),
                      _CheckoutBucket.signedOut => HeroStateView.signedOut(
                        message: 'checkout.sign_in_required'.tr(),
                      ),
                      _CheckoutBucket.error => HeroStateView.error(
                        message: loadFailure?.localizedMessage,
                        onRetry: () => context.read<CheckoutCubit>().retry(
                          defaultAddressId: _defaultAddressId(context),
                          expressSelected: _expressSelected(context),
                        ),
                      ),
                      _CheckoutBucket.empty => HeroStateView(
                        art: HeroAssets.emptyBasket,
                        message: 'checkout.cart_empty'.tr(),
                        actionLabel: 'cart.start_shopping'.tr(),
                        onAction: () => context.pop(),
                      ),
                      _CheckoutBucket.content => const CheckoutBody(),
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
