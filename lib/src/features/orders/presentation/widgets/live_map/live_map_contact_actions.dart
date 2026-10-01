import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/widgets/hero_sheet_header.dart';
import '../../../domain/entities/courier_trip.dart';
import '../../cubit/rider_chat_cubit.dart';
import '../rider_chat/rider_chat_sheet.dart';
import 'live_map_call_sheet.dart';
import 'live_map_contact_button.dart';

/// Message and call, on the rider card from the moment the rider heads to
/// the customer — the chat opens (and the rider says hello) then, its
/// unread count on the message button; call only when the ride has a line
/// that reaches the rider.
class LiveMapContactActions extends StatefulWidget {
  const LiveMapContactActions({super.key, required this.trip});

  final CourierTrip trip;

  @override
  State<LiveMapContactActions> createState() => _LiveMapContactActionsState();
}

class _LiveMapContactActionsState extends State<LiveMapContactActions> {
  @override
  void initState() {
    super.initState();
    context.read<RiderChatCubit>().start(widget.trip.orderId);
  }

  String get _rider => widget.trip.riderName.isEmpty
      ? 'orders.live_rider_default'.tr()
      : widget.trip.riderName;

  void _openChat() {
    final chat = context.read<RiderChatCubit>();
    showHeroBottomSheet<void>(
      context,
      large: true,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: HeroSheetHeader.shape,
      builder: (_) => BlocProvider.value(
        value: chat,
        child: RiderChatSheet(riderName: _rider),
      ),
    );
  }

  Future<void> _openCall() async {
    final messageInstead = await showHeroBottomSheet<bool>(
      context,
      backgroundColor: AppColors.white,
      shape: HeroSheetHeader.shape,
      builder: (_) => LiveMapCallSheet(trip: widget.trip, rider: _rider),
    );
    if (messageInstead == true && mounted) _openChat();
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.select<RiderChatCubit, int>(
      (cubit) => cubit.state.unread,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiveMapContactButton(
          icon: HeroIcons.chat,
          label: 'orders.live_message_rider'.tr(),
          semanticLabel: unread == 0
              ? 'orders.live_message_rider'.tr()
              : 'orders.live_message_rider_unread'.plural(unread),
          unread: unread,
          onPressed: _openChat,
        ),
        if (widget.trip.canCall) ...[
          const SizedBox(width: AppSpacing.s8),
          LiveMapContactButton(
            icon: HeroIcons.phone,
            label: 'orders.live_call_rider'.tr(),
            onPressed: () => unawaited(_openCall()),
          ),
        ],
      ],
    );
  }
}
