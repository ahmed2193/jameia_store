import 'package:analyzer/error/error.dart';

import '../utils/file_info.dart';
import '../utils/imports.dart';
import 'directive_rule_base.dart';

/// Rule 1 — `lib/src/**/domain/**` stays framework- and infrastructure-free.
class DomainLayerPurity extends DirectiveRule {
  DomainLayerPurity()
    : super(
        name: 'domain_layer_purity',
        description:
            'Domain files may only import dart:*, dartz, equatable, meta, '
            'collection, other domain files, core/error/failures.dart and '
            'core/usecase.',
      );

  static const LintCode code = LintCode(
    'domain_layer_purity',
    "The domain layer must not import '{0}'.",
    correctionMessage:
        'Domain imports only dart:*, dartz, equatable, meta, collection, '
        'domain/ files, core/error/failures.dart and core/usecase '
        '(CLAUDE.md §3 Layer rules). Move framework/data concerns out of the '
        'domain.',
    severity: DiagnosticSeverity.WARNING,
  );

  static const _allowedPackages = ['dartz', 'equatable', 'meta', 'collection'];

  @override
  LintCode get diagnosticCode => code;

  @override
  bool appliesTo(FileInfo file) => file.isInLibSrc && file.hasDir('domain');

  @override
  List<Object>? violation(FileInfo file, DirectiveTarget target) {
    if (target.isDart) return null;
    if (_allowedPackages.any(target.isPackage)) return null;
    final local = target.localPath;
    if (local != null && local.startsWith('lib/src/')) {
      if (target.localHasDir('domain')) return null;
      if (local == 'lib/src/core/error/failures.dart') return null;
      if (local.startsWith('lib/src/core/usecase/')) return null;
    }
    return [target.uri];
  }
}
