import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../domain/entities/faq_item.dart';
import '../../cubit/customer_service_question_cubit.dart';
import 'support_faq_results.dart';
import 'support_topics_search_field.dart';

/// The help topics: a search field over the FAQ accordion. Owns the search
/// text and which topic is open (view state), and opens [initialQuestion]
/// once the list has loaded.
class SupportTopicsBody extends StatefulWidget {
  const SupportTopicsBody({super.key, this.initialQuestion});

  /// The topic (question key, or its text) the hub was opened with.
  final String? initialQuestion;

  @override
  State<SupportTopicsBody> createState() => _SupportTopicsBodyState();
}

class _SupportTopicsBodyState extends State<SupportTopicsBody> {
  final TextEditingController _controller = TextEditingController();
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  /// Index of the open FAQ within the FULL list (-1 == none).
  final ValueNotifier<int> _expanded = ValueNotifier<int>(-1);

  @override
  void dispose() {
    _controller.dispose();
    _query.dispose();
    _expanded.dispose();
    super.dispose();
  }

  void _maybePreExpand(List<FaqItem> faqs) {
    if (_expanded.value != -1) return;
    final wanted = widget.initialQuestion;
    if (wanted == null || wanted.isEmpty) return;
    final index = faqs.indexWhere(
      (faq) => faq.questionKey == wanted || faq.questionKey.tr() == wanted,
    );
    if (index != -1) _expanded.value = index;
  }

  void _onChanged(String value) => _query.value = value.trim().toLowerCase();

  void _clear() {
    _controller.clear();
    _query.value = '';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ContentClamp(
        child: Column(
          children: [
            // Hero `customer-search` → `faqSearchKey`.
            SupportTopicsSearchField(
              controller: _controller,
              onChanged: _onChanged,
              onClear: _clear,
              query: _query,
            ),
            Expanded(
              child:
                  BlocConsumer<
                    CustomerServiceQuestionCubit,
                    CustomerServiceQuestionState
                  >(
                    listenWhen: (previous, current) =>
                        previous.faqs != current.faqs,
                    listener: (context, state) => _maybePreExpand(state.faqs),
                    // The dots while the topics load (never the "no
                    // results" plate over a list that is still coming), a
                    // Retry when they did not; the list fades through in.
                    builder: (context, state) => FadeThroughSwitcher(
                      stateKey:
                          state.status == CustomerServiceQuestionStatus.initial
                          ? CustomerServiceQuestionStatus.loading
                          : state.status,
                      child: switch (state.status) {
                        CustomerServiceQuestionStatus.loaded =>
                          SupportFaqResults(
                            faqs: state.faqs,
                            query: _query,
                            expanded: _expanded,
                          ),
                        CustomerServiceQuestionStatus.error =>
                          HeroStateView.error(
                            onRetry: context
                                .read<CustomerServiceQuestionCubit>()
                                .load,
                          ),
                        _ => const AppLoader(),
                      },
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
