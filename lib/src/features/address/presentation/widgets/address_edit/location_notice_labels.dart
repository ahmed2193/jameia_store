import 'package:easy_localization/easy_localization.dart';

import '../../cubit/address_picker_state.dart';

/// Why "find me" could not move the map, as the customer reads it, and the
/// label of the way to the setting that fixes it (`null`: no setting can).
({String message, String? action}) locationNoticeText(LocationNotice notice) =>
    switch (notice) {
      LocationNotice.serviceOff => (
        message: 'addr.location.service_off'.tr(),
        action: 'addr.location.turn_on'.tr(),
      ),
      LocationNotice.blocked => (
        message: 'addr.location.blocked'.tr(),
        action: 'addr.location.settings'.tr(),
      ),
      LocationNotice.denied => (
        message: 'addr.location.denied'.tr(),
        action: null,
      ),
      LocationNotice.unavailable => (
        message: 'addr.location.unavailable'.tr(),
        action: null,
      ),
    };
