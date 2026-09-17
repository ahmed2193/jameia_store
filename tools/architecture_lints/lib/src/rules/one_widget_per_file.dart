import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/file_info.dart';
import '../utils/guard.dart';
import '../utils/types.dart';

/// Rule 5 — one `Widget` subclass per file (State/painters/delegates excluded:
/// they are not `Widget`s).
class OneWidgetPerFile extends AnalysisRule {
  OneWidgetPerFile()
    : super(
        name: 'one_widget_per_file',
        description: 'A file may declare at most one Widget subclass.',
      );

  static const LintCode code = LintCode(
    'one_widget_per_file',
    "'{0}' is a second widget class in this file (first: '{1}').",
    correctionMessage:
        'Move it to its own file — one widget class per file, including '
        'private _Foo widgets; a StatefulWidget and its State may share a '
        'file (CLAUDE.md §4 UI rules).',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final OneWidgetPerFile rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) => guarded(() {
    if (!FileInfo.of(context).isInLibSrc) return;
    String? firstWidget;
    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;
      final element = declaration.declaredFragment?.element;
      if (element == null || !isWidgetElement(element)) continue;
      final nameToken = declaration.namePart.typeName;
      if (firstWidget == null) {
        firstWidget = nameToken.lexeme;
        continue;
      }
      rule.reportAtToken(nameToken, arguments: [nameToken.lexeme, firstWidget]);
    }
  });
}
