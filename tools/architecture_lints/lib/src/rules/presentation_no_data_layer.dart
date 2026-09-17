import 'package:analyzer/error/error.dart';

import '../utils/file_info.dart';
import '../utils/imports.dart';
import 'directive_rule_base.dart';

/// Rule 2 — feature presentation never reaches into data / infrastructure.
///
/// Also replaces the legacy custom_lint `presentation_no_core_repo` rule:
/// `core/data/jameia_repository.dart` is a `data/` import here, and
/// `sl<JameiaRepository>()` is caught by `no_service_locator_outside_di`.
class PresentationNoDataLayer extends DirectiveRule {
  PresentationNoDataLayer()
    : super(
        name: 'presentation_no_data_layer',
        description:
            'Feature presentation must not import data/, core/data, '
            'core/network, core/storage, domain repositories or injection '
            'containers.',
      );

  static const LintCode code = LintCode(
    'presentation_no_data_layer',
    "The presentation layer must not import '{0}'.",
    correctionMessage:
        'Presentation depends on domain entities/use cases and core UI only '
        '(CLAUDE.md §3 Layer rules). Go through a cubit + use case; '
        'config/di/service_locator.dart is allowed only in presentation/pages.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  bool appliesTo(FileInfo file) => file.isFeaturePresentation;

  @override
  List<Object>? violation(FileInfo file, DirectiveTarget target) {
    final local = target.localPath;
    if (local == null) return null;
    final featurePath = file.featureRelPath ?? '';
    // Cubit files get data / repository / DI imports reported by
    // `cubit_depends_on_usecases` instead, so one bad import = one diagnostic.
    final inCubit = featurePath.startsWith('presentation/cubit/');
    final inPages = featurePath.startsWith('presentation/pages/');
    final flagged = [target.uri];

    if (target.localHasDir('data')) return inCubit ? null : flagged;
    if (local.contains('/domain/repositories/')) {
      return inCubit ? null : flagged;
    }
    if (local.startsWith('lib/src/config/di/')) {
      return (inCubit || inPages) ? null : flagged;
    }
    if (local.startsWith('lib/src/core/network/') ||
        local.startsWith('lib/src/core/storage/')) {
      return flagged;
    }
    if (local.endsWith('_injection_container.dart')) return flagged;
    return null;
  }
}
