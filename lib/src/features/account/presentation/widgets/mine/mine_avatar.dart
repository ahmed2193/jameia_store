import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import 'mine_avatar_edit_badge.dart';
import 'mine_header_metrics.dart';

/// The customer's avatar in the Mine header (the API has no picture yet):
///
///   * signed in with a name — its first letter, white on the brand green;
///   * signed in, no name yet — a person glyph on the brand green;
///   * a guest — a grey person glyph on white.
///
/// A white ring frames it; a Pro member gets the Pro gradient ring instead.
/// The pencil badge (signed in only) shrinks away as the avatar docks
/// ([editBadgeScale]).
class MineAvatar extends StatelessWidget {
  const MineAvatar({
    super.key,
    required this.customer,
    this.editBadgeScale = 1,
  });

  final AuthCustomerEntity? customer;
  final double editBadgeScale;

  static const double _size = MineHeaderMetrics.avatar;
  static const double _ring = AppSize.s3;
  static const double _glyph = AppSize.s36;
  static const List<Color> _brand = [
    AppColors.brandDarkBg,
    AppColors.primaryDark,
  ];

  @override
  Widget build(BuildContext context) {
    final person = customer;
    final isPro = person?.isPro ?? false;
    final initial = person == null || person.needsName
        ? ''
        : person
              .displayNameFor(context.locale.languageCode)
              .trim()
              .characters
              .first
              .toUpperCase();
    return SizedBox.square(
      dimension: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
              gradient: isPro
                  ? const LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: AppColors.proGradient,
                    )
                  : null,
              boxShadow: AppShadows.medium,
            ),
            child: Padding(
              padding: const EdgeInsets.all(_ring),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.smallBackground,
                  gradient: person == null
                      ? null
                      : const LinearGradient(
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                          colors: _brand,
                        ),
                ),
                child: Center(
                  child: initial.isEmpty
                      ? Icon(
                          Icons.person_rounded,
                          size: _glyph,
                          color: person == null
                              ? AppColors.tertiaryText
                              : AppColors.white,
                        )
                      : Text(
                          initial,
                          maxLines: 1,
                          textScaler: TextScaler.noScaling,
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: AppSize.font30,
                            fontWeight: AppTextStyles.bold,
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
          if (person != null)
            PositionedDirectional(
              end: 0,
              bottom: 0,
              child: Transform.scale(
                scale: editBadgeScale,
                child: const MineAvatarEditBadge(),
              ),
            ),
        ],
      ),
    );
  }
}
