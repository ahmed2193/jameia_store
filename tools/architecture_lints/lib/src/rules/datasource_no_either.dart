import 'package:analyzer/error/error.dart';

import '../utils/file_info.dart';
import '../utils/imports.dart';
import 'directive_rule_base.dart';

/// Rule 14 — datasources throw `AppException`; only repositories return Either.
class DatasourceNoEither extends DirectiveRule {
  DatasourceNoEither()
    : super(
        name: 'datasource_no_either',
        description: 'Files under data/datasources must not import dartz.',
      );

  static const LintCode code = LintCode(
    'datasource_no_either',
    "Datasources must not import '{0}'.",
    correctionMessage:
        'Datasources THROW AppException subclasses; repositories wrap calls '
        'in BaseRepositoryMixin.execute and return Either '
        '(CLAUDE.md §1 data/datasources, §2 Exceptions).',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  bool appliesTo(FileInfo file) =>
      file.isInLibSrc && file.relPath.contains('/data/datasources/');

  @override
  List<Object>? violation(FileInfo file, DirectiveTarget target) =>
      target.isPackage('dartz') ? [target.uri] : null;
}
