import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/utils/jameia_geocode.dart';
import '../../cubit/address_edit_cubit.dart';
import 'address_choice_chip.dart';
import 'address_form_labels.dart';
import 'photo_upload_box.dart';
import 'schema_field.dart';
import 'section_header.dart';

/// Address details — struct-type tabs + schema-driven inputs + photo box.
class AddressDetailsSection extends StatelessWidget {
  const AddressDetailsSection({
    super.key,
    required this.errors,
    required this.onClearError,
  });

  final Map<AddrField, String> errors;
  final ValueChanged<AddrField> onClearError;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      margin: const EdgeInsets.only(top: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'addr.address_details'.tr(), required: true),
          // Struct-type tabs (Apartment / House / Office) — drives the field set.
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s12,
            ),
            child: BlocSelector<AddressEditCubit, AddressEditState, StructType>(
              selector: (s) => s.structType,
              builder: (context, active) {
                final cubit = context.read<AddressEditCubit>();
                return Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    for (final t in StructType.values)
                      AddressChoiceChip(
                        label: structLabel(t),
                        selected: t == active,
                        onTap: () => cubit.setStructType(t),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          // Schema-driven fields for the active struct type.
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s12,
            ),
            child: BlocSelector<AddressEditCubit, AddressEditState, StructType>(
              selector: (s) => s.structType,
              builder: (context, structType) {
                final specs = JameiaGeocode.kwSchema.fieldsFor(structType);
                return Column(
                  children: [
                    for (final spec in specs) ...[
                      SchemaField(
                        spec: spec,
                        errorKey: errors[spec.field],
                        onClearError: () => onClearError(spec.field),
                      ),
                      const SizedBox(height: AppSpacing.s10),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          // Photo-upload box (stub).
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.s12,
              end: AppSpacing.s12,
              bottom: AppSpacing.s14,
            ),
            child: const PhotoUploadBox(),
          ),
        ],
      ),
    );
  }
}
