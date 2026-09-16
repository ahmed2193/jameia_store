import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/design/keeta_assets.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/marketing_moments.dart';
import '../../domain/entities/punctual_landing.dart';
import '../cubit/punctual_cubit.dart';

/// KeeTa on-time guarantee landing (`mach_pro_sailor_c_punctual`).
///
/// Faithful 1:1 clone of the punctual / on-time promise page: a brand hero with
/// the promise logo + headline over the `punctual-background` artwork, a coupon
/// explainer banner (the make-up coupon you get when an order runs late), a
/// numbered "how it works" list, an FAQ accordion, and a sticky "View rules"
/// button that pushes [Routes.punctualRule].
///
/// The promise headline/body, coupon explainer, how-it-works steps and FAQ are
/// fetched through [PunctualCubit] from the marketing repository (dummy
/// stand-in for the live `v1/order/late/compensation/landing` call), so the page
/// shows a loading skeleton then data/error with retry.
class PunctualScreen extends StatelessWidget {
  const PunctualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PunctualCubit>(),
      child: const _PunctualView(),
    );
  }
}

class _PunctualView extends StatelessWidget {
  const _PunctualView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      body: BlocBuilder<PunctualCubit, PunctualState>(
        // Only swap between the top-level loading/error/loaded variants here;
        // FAQ-expansion rebuilds are scoped to the FAQ list below.
        buildWhen: (a, b) => a.status != b.status,
        builder: (context, state) {
          return switch (state.status) {
            PunctualStatus.loaded => _LoadedBody(landing: state.landing!),
            PunctualStatus.error => ErrorView(
              message: 'marketing.error_load'.tr(),
              onRetry: () => context.read<PunctualCubit>().load(),
            ),
            _ => const _PunctualSkeleton(),
          };
        },
      ),
      bottomNavigationBar: const _ViewRulesBar(),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.landing});
  final PunctualLanding landing;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Hero(landing: landing)),
        SliverToBoxAdapter(
          child: ContentClamp(
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.s16),
                _CouponExplainer(landing: landing),
                const SizedBox(height: AppSpacing.s24),
                _HowItWorks(steps: landing.steps),
                const SizedBox(height: AppSpacing.s24),
                _FaqSection(faqs: landing.faqs),
                const SizedBox(height: AppSpacing.s24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.landing});
  final PunctualLanding landing;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 300 + topPad,
      child: Stack(
        children: [
          // Brand-yellow promise backdrop (KeeTa `punctual-background`).
          const Positioned.fill(child: _HeroBackdrop()),
          // Floating circular back button.
          PositionedDirectional(
            top: topPad + AppSpacing.s8,
            start: AppSpacing.s12,
            child: const _CircleBack(),
          ),
          // Promise logo + headline, centred over the backdrop.
          Positioned.fill(
            top: topPad,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    KeetaAssets.punctualLogo,
                    height: 56,
                    errorBuilder: (_, _, _) => const Icon(
                      KeetaIcons.deliveryTime,
                      size: 52,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    landing.promiseTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayLarge.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    landing.promiseBody,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.accent4Foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.punctualGradientTop, AppColors.accent2],
            ),
          ),
        ),
        // Real KeeTa punctual hero background (`punctual-background`); falls
        // back to the brand-green gradient when unavailable.
        Image.asset(
          KeetaAssets.punctualBackground,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _CircleBack extends StatelessWidget {
  const _CircleBack();

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => Navigator.maybePop(context),
      behavior: HitTestBehavior.opaque,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.overlayDivider,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.s8),
          child: Icon(KeetaIcons.back, size: 20, color: AppColors.primaryText),
        ),
      ),
    );
  }
}

// ── White card shell shared by the body sections ──────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: child,
    );
  }
}

// ── Coupon-on-late explainer ──────────────────────────────────────────────────

class _CouponExplainer extends StatelessWidget {
  const _CouponExplainer({required this.landing});
  final PunctualLanding landing;

  @override
  Widget build(BuildContext context) {
    // Reward/promo banner (the make-up coupon) — pop it in on first build and
    // sweep the brand shine across it, matching the invite reward card grammar
    // (PopScale + ShineSweep).
    return PopScale.onMount(
      child: ShineSweep(
        child: _Card(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.brandLightBg,
                  borderRadius: BorderRadius.circular(AppRadius.r4),
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  // Real KeeTa make-up-coupon graphic shipped with the punctual
                  // bundle (`promise_rule_coupon`).
                  KeetaAssets.punctualCoupon,
                  width: 30,
                  height: 30,
                  errorBuilder: (_, _, _) => const Icon(
                    KeetaIcons.deliveryTime,
                    size: 26,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      landing.couponTitle,
                      style: AppTextStyles.headingMedium.copyWith(
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      landing.couponBody,
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── How it works ──────────────────────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.steps});
  final List<PunctualStep> steps;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'marketing.how_it_works'.tr(),
            style: AppTextStyles.headingLarge.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          for (var i = 0; i < steps.length; i++) ...[
            RepaintBoundary(
              child: StaggerEntrance(
                index: i,
                child: _StepRow(
                  index: i + 1,
                  step: steps[i],
                  isLast: i == steps.length - 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.step,
    required this.isLast,
  });

  final int index;
  final PunctualStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.black,
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
              if (!isLast)
                const Expanded(
                  child: VerticalDivider(
                    width: 28,
                    thickness: 2,
                    color: AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                bottom: isLast ? 0 : AppSpacing.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    step.body,
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── FAQ accordion ─────────────────────────────────────────────────────────────

class _FaqSection extends StatelessWidget {
  const _FaqSection({required this.faqs});
  final List<PunctualFaq> faqs;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                KeetaAssets.punctualFaqsIcon,
                width: 20,
                height: 20,
                errorBuilder: (_, _, _) => const Icon(
                  KeetaIcons.help,
                  size: 20,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'marketing.frequently_asked'.tr(),
                style: AppTextStyles.headingLarge.copyWith(
                  fontWeight: AppTextStyles.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          // Only the FAQ list rebuilds when a row expands.
          BlocBuilder<PunctualCubit, PunctualState>(
            buildWhen: (a, b) => a.expandedFaq != b.expandedFaq,
            builder: (context, state) {
              final expanded = state.expandedFaq;
              return Column(
                children: [
                  for (var i = 0; i < faqs.length; i++) ...[
                    if (i > 0) const ThinDivider(),
                    _FaqRow(
                      faq: faqs[i],
                      expanded: expanded == i,
                      onTap: () => context.read<PunctualCubit>().toggleFaq(i),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FaqRow extends StatelessWidget {
  const _FaqRow({
    required this.faq,
    required this.expanded,
    required this.onTap,
  });

  final PunctualFaq faq;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    faq.question,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  // Match the accordion body (AppMotion.medium + signature) so
                  // the chevron flips in lockstep with the panel opening.
                  duration: MotionGuard.duration(context, AppMotion.medium),
                  curve: AppMotion.signature,
                  child: const Icon(
                    KeetaIcons.arrowDown,
                    size: 22,
                    color: AppColors.tertiaryText,
                  ),
                ),
              ],
            ),
            AnimatedAccordion(
              expanded: expanded,
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.s8),
                child: Text(
                  faq.answer,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

/// Placeholder shown while [PunctualCubit] resolves the landing payload: a
/// brand-yellow hero block plus three shimmer-free grey cards mirroring the
/// coupon / how-it-works / FAQ sections.
class _PunctualSkeleton extends StatelessWidget {
  const _PunctualSkeleton();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: 300 + topPad, child: const _HeroBackdrop()),
        ),
        const SliverToBoxAdapter(
          child: ContentClamp(
            child: Column(
              children: [
                SizedBox(height: AppSpacing.s16),
                _SkeletonCard(lines: 2),
                SizedBox(height: AppSpacing.s24),
                _SkeletonCard(lines: 4),
                SizedBox(height: AppSpacing.s24),
                _SkeletonCard(lines: 4),
                SizedBox(height: AppSpacing.s24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.lines});
  final int lines;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBar(widthFactor: 0.5, height: 16),
          const SizedBox(height: AppSpacing.s12),
          for (var i = 0; i < lines; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s8),
            _SkeletonBar(widthFactor: i.isEven ? 0.9 : 0.7, height: 10),
          ],
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.widthFactor, required this.height});
  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(AppRadius.r4),
          ),
        ),
      ),
    );
  }
}

// ── Sticky "View rules" button ────────────────────────────────────────────────

class _ViewRulesBar extends StatelessWidget {
  const _ViewRulesBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: AppButton(
          label: 'marketing.view_rules'.tr(),
          onPressed: () => Navigator.pushNamed(context, Routes.punctualRule),
        ),
      ),
    );
  }
}
