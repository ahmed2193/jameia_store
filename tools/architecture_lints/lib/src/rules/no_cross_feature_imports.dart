import 'package:analyzer/error/error.dart';

import '../utils/file_info.dart';
import '../utils/imports.dart';
import 'directive_rule_base.dart';

/// Rule 13 — features are isolated; only app-global cubits cross over.
class NoCrossFeatureImports extends DirectiveRule {
  NoCrossFeatureImports()
    : super(
        name: 'no_cross_feature_imports',
        description:
            "A feature may import another feature's presentation/cubit only.",
      );

  static const LintCode code = LintCode(
    'no_cross_feature_imports',
    "Feature '{0}' must not import '{1}' from feature '{2}'.",
    correctionMessage:
        "Only another feature's presentation/cubit/ (app-global cubits) may be "
        'imported; move anything else that is shared into core/ '
        '(CLAUDE.md §3 Cross-feature).',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  bool appliesTo(FileInfo file) =>
      file.featureName != null && !file.isInjectionContainer;

  @override
  List<Object>? violation(FileInfo file, DirectiveTarget target) {
    final local = target.localPath;
    if (local == null) return null;
    final targetFeature = FileInfo.featureOf(local);
    final ownFeature = file.featureName;
    if (targetFeature == null || ownFeature == null) return null;
    if (targetFeature == ownFeature) return null;
    final targetRel = FileInfo.featureRelPathOf(local) ?? '';
    if (targetRel.startsWith('presentation/cubit/')) return null;
    return [ownFeature, target.uri, targetFeature];
  }
}
