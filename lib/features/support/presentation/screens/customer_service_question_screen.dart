import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
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
import '../../domain/entities/faq_item.dart';
import '../cubit/customer_service_question_cubit.dart';

/// KeeTa FAQ list / question-detail page — `mach_pro_sailor_c_customer_service_question`.
///
/// Faithful 1:1 clone of KeeTa's self-serve help page (analysis 2.13). The live
/// page hits `/api/faq/faqList?faqSearchKey=` (a search-filtered FAQ list) with a
/// `QUEUE` chat hand-off (`handleJumpToSearch`); the offline clone serves the same
/// fixed help topics from [KeetaRepository] via a page-scoped cubit, filters them
/// locally as the user types, and renders each topic as an expandable
/// question→answer accordion. A "Still need help?" footer drops into the support
/// chat (the page's contact CTA).
///
/// [arg] (router positional argument) optionally carries the originating FAQ
/// question or order id from the help-center hub; when it matches a topic, that
/// item starts expanded.
class CustomerServiceQuestionScreen extends StatelessWidget {
  const CustomerServiceQuestionScreen({super.key, this.arg});

  /// Optional originating question (or order id) passed from the help hub.
  final String? arg;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CustomerServiceQuestionCubit>(),
      child: _QuestionView(initialQuestion: arg),
    );
  }
}

class _QuestionView extends StatefulWidget {
  const _QuestionView({this.initialQuestion});
  final String? initialQuestion;

  @override
  State<_QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<_QuestionView> {
  late final TextEditingController _controller;
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  /// Index of the currently-expanded FAQ within the FULL list (-1 == none).
  final ValueNotifier<int> _expanded = ValueNotifier<int>(-1);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  /// Pre-expand the topic the user tapped on the hub, once the FAQ list has
  /// loaded (the cubit resolves it asynchronously through the use case).
  void _maybePreExpand(List<FaqItem> faqs) {
    if (_expanded.value != -1) return;
    final q = widget.initialQuestion;
    if (q == null || q.isEmpty) return;
    final idx = faqs.indexWhere((f) => f.question == q);
    if (idx != -1) _expanded.value = idx;
  }

  @override
  void dispose() {
    _controller.dispose();
    _query.dispose();
    _expanded.dispose();
    super.dispose();
  }

  void _onChanged(String value) => _query.value = value.trim().toLowerCase();

  void _clear() {
    _controller.clear();
    _query.value = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            KeetaIcons.back,
            size: 20,
            color: AppColors.primaryText,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'support.title_help_topics'.tr(),
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ContentClamp(
          child: Column(
            children: [
              // Search field (KeeTa `customer-search` → `faqSearchKey`).
              _SearchField(
                controller: _controller,
                onChanged: _onChanged,
                onClear: _clear,
                query: _query,
              ),
              Expanded(
                child: BlocConsumer<CustomerServiceQuestionCubit,
                    CustomerServiceQuestionState>(
                  listenWhen: (p, c) => p.faqs != c.faqs,
                  listener: (context, state) => _maybePreExpand(state.faqs),
                  builder: (context, state) => _FaqResults(
                    faqs: state.faqs,
                    query: _query,
                    expanded: _expanded,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Search field ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.query,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueNotifier<String> query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Container(
        height: 44,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            const Icon(
              KeetaIcons.search,
              size: 18,
              color: AppColors.tertiaryText,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: AppTextStyles.bodyLarge,
                cursorColor: AppColors.primaryText,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'support.search_help_topics'.tr(),
                  hintStyle: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<String>(
              valueListenable: query,
              builder: (_, value, _) {
                if (value.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: onClear,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsetsDirectional.only(start: AppSpacing.s8),
                    child: Icon(
                      KeetaIcons.searchClear,
                      size: 16,
                      color: AppColors.tertiaryText,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAQ results (filtered list + expandable items + footer) ───────────────────

class _FaqResults extends StatelessWidget {
  const _FaqResults({
    required this.faqs,
    required this.query,
    required this.expanded,
  });

  final List<FaqItem> faqs;
  final ValueNotifier<String> query;
  final ValueNotifier<int> expanded;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: query,
      builder: (context, q, _) {
        // Filter on question OR answer; keep original indices so the expand
        // notifier (full-list index) stays valid across filtering.
        final matches = <int>[
          for (var i = 0; i < faqs.length; i++)
            if (q.isEmpty ||
                faqs[i].question.toLowerCase().contains(q) ||
                faqs[i].answer.toLowerCase().contains(q))
              i,
        ];

        if (matches.isEmpty) {
          return const _NoResults();
        }

        // +1 trailing row for the "Still need help?" footer card.
        return ListView.builder(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.s24,
            start: AppSpacing.s12,
            end: AppSpacing.s12,
          ),
          itemCount: matches.length + 1,
          itemBuilder: (context, row) {
            if (row == matches.length) return const _StillNeedHelpCard();
            final fullIndex = matches[row];
            return RepaintBoundary(
              // Key by topic so a freshly built (filtered) list cascades in once
              // per item without replaying on expand/collapse rebuilds.
              key: ValueKey<String>(faqs[fullIndex].question),
              child: StaggerEntrance(
                index: row,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppSpacing.s8,
                  ),
                  child: _FaqTile(
                    index: fullIndex,
                    faq: faqs[fullIndex],
                    expanded: expanded,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: KeetaIcons.help,
      message: 'support.no_results_message'.tr(),
      actionLabel: 'support.chat_with_support'.tr(),
      onAction: () => Navigator.pushNamed(context, Routes.imChat),
    );
  }
}

// ── Expandable FAQ tile (question header + answer body) ────────────────────────

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.index,
    required this.faq,
    required this.expanded,
  });

  final int index;
  final FaqItem faq;
  final ValueNotifier<int> expanded;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: expanded,
      builder: (context, current, _) {
        final isOpen = current == index;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            children: [
              PressScale(
                // Decorate the question header tap with KeeTa's press feel; the
                // InkWell still owns the gesture/ripple and the expand toggle.
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  onTap: () => expanded.value = isOpen ? -1 : index,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          KeetaIcons.help,
                          size: 18,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: AppSpacing.s10),
                        Expanded(
                          child: Text(
                            faq.question,
                            style: AppTextStyles.headingSmall.copyWith(
                              fontWeight: AppTextStyles.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        _Chevron(open: isOpen),
                      ],
                    ),
                  ),
                ),
              ),
              // Answer body — KeeTa's FAQ accordion (height + cross-fade),
              // lazily built when open.
              AnimatedAccordion(
                expanded: isOpen,
                alignment: AlignmentDirectional.topStart.resolve(
                  Directionality.of(context),
                ),
                child: _AnswerBody(answer: faq.answer),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.open});
  final bool open;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: AppMotion.standard,
      turns: open ? 0.5 : 0,
      child: const Icon(
        KeetaIcons.arrowDownSmall,
        size: 16,
        color: AppColors.tertiaryText,
      ),
    );
  }
}

class _AnswerBody extends StatelessWidget {
  const _AnswerBody({required this.answer});
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s14,
        0,
        AppSpacing.s14,
        AppSpacing.s14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ThinDivider(),
          const SizedBox(height: AppSpacing.s12),
          Text(
            answer,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Still-need-help footer card (contact button) ──────────────────────────────

class _StillNeedHelpCard extends StatelessWidget {
  const _StillNeedHelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.brandLightBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              KeetaIcons.customerService,
              size: 24,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'support.still_need_help'.tr(),
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'support.still_need_help_body'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          AppButton(
            label: 'support.contact_support'.tr(),
            radius: AppRadius.r2,
            trailing: const Icon(
              KeetaIcons.chat,
              size: 18,
              color: AppColors.brandForeground,
            ),
            onPressed: () => Navigator.pushNamed(context, Routes.imChat),
          ),
        ],
      ),
    );
  }
}
