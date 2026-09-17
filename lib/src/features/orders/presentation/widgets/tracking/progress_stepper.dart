import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_assets.dart';
import '../../../../../config/theme/app_spacing.dart';
import 'step_node.dart';
import 'tracking_card.dart';

// ── Status step labels (statusStep 1..5) ──────────────────────────────────────

// Step labels for the progress stepper. Values are translation keys resolved
// via `.tr()` where each label is rendered.
const List<String> _kStepLabels = <String>[
  'orders.step_confirmed',
  'orders.step_preparing',
  'orders.step_picked_up',
  'orders.step_on_the_way',
  'orders.step_delivered',
];

const List<String> _kStepNodes = <String>[
  JameiaAssets.progressNodeConfirm,
  JameiaAssets.progressNodePrepare,
  JameiaAssets.progressNodeMotor,
  JameiaAssets.progressNodeCar,
  JameiaAssets.progressNodeDelivery,
];

// ── Progress stepper ──────────────────────────────────────────────────────────
//
// Real Jameia metrics:
//   node (c33ae0): 30×30dp, border-radius=10dp (r5), bg=smallBackground
//   connector (d28766): height=4dp, radius=2dp, bg=#DEDFE4
//   active fill (hcfd3a): bg=primary #FFE41F
//   node img: 30×30 (f85843 height=30dp)
//   label margin-bottom=6dp (f11ae6)

class ProgressStepper extends StatelessWidget {
  const ProgressStepper({super.key, required this.step});

  /// Current order step, 1..5.
  final int step;

  @override
  Widget build(BuildContext context) {
    return TrackingCard(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _kStepLabels.length; i++)
            Expanded(
              child: StepNode(
                label: _kStepLabels[i],
                node: _kStepNodes[i],
                done: (i + 1) <= step,
                active: (i + 1) == step,
                leftDone: (i + 1) <= step && i > 0,
                rightDone: (i + 2) <= step,
                isFirst: i == 0,
                isLast: i == _kStepLabels.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}
