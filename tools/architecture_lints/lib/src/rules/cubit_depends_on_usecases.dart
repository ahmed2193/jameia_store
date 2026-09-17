import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/file_info.dart';
import '../utils/guard.dart';
import '../utils/imports.dart';
import '../utils/types.dart';
import 'directive_rule_base.dart';

/// Rule 3 — cubits depend only on (constructor-injected) use cases.
class CubitDependsOnUsecases extends DirectiveRule {
  CubitDependsOnUsecases()
    : super(
        name: 'cubit_depends_on_usecases',
        description:
            'Cubits must not import repositories, data, DI or widget '
            'libraries, and must not use BuildContext.',
      );

  static const LintCode code = LintCode(
    'cubit_depends_on_usecases',
    "Cubits must depend only on use cases; '{0}' is not allowed here.",
    correctionMessage:
        'Inject use cases through the constructor; no repositories, '
        'datasources, sl, BuildContext or widget libraries inside cubits '
        '(CLAUDE.md §3 Layer rules). package:flutter/foundation.dart is fine.',
    severity: DiagnosticSeverity.WARNING,
  );

  static const _widgetLibraries = {
    'package:flutter/material.dart',
    'package:flutter/widgets.dart',
    'package:flutter/cupertino.dart',
  };

  @override
  LintCode get diagnosticCode => code;

  static bool isCubitFile(FileInfo file) =>
      file.isInLibSrc && file.relPath.contains('/presentation/cubit/');

  @override
  bool appliesTo(FileInfo file) => isCubitFile(file);

  @override
  List<Object>? violation(FileInfo file, DirectiveTarget target) {
    if (_widgetLibraries.contains(target.uri)) return [target.uri];
    final local = target.localPath;
    if (local == null) return null;
    if (target.localHasDir('data') ||
        local.contains('/domain/repositories/') ||
        local.startsWith('lib/src/config/di/')) {
      return [target.uri];
    }
    return null;
  }

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    super.registerNodeProcessors(registry, context);
    registry.addNamedType(this, _BuildContextVisitor(this, context));
  }
}

class _BuildContextVisitor extends SimpleAstVisitor<void> {
  _BuildContextVisitor(this.rule, this.context);

  final CubitDependsOnUsecases rule;
  final RuleContext context;

  @override
  void visitNamedType(NamedType node) => guarded(() {
    if (node.name.lexeme != 'BuildContext') return;
    if (!CubitDependsOnUsecases.isCubitFile(FileInfo.of(context))) return;
    if (!isElementNamed(node.element, 'BuildContext', isFlutterLibrary)) {
      return;
    }
    rule.reportAtNode(node, arguments: ['BuildContext']);
  });
}
