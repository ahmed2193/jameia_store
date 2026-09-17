import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/file_info.dart';
import '../utils/guard.dart';
import '../utils/types.dart';

/// Rule 6 — no `Widget _buildX()` helpers; extract widget classes instead.
class NoWidgetHelperMethods extends AnalysisRule {
  NoWidgetHelperMethods()
    : super(
        name: 'no_widget_helper_methods',
        description:
            'Methods/functions must not return Widget (or List/Iterable of '
            'Widget), except build and @override framework hooks.',
      );

  static const LintCode code = LintCode(
    'no_widget_helper_methods',
    "'{0}' is a widget-returning helper.",
    correctionMessage:
        'Extract a widget class with constructor params instead of a '
        'Widget-returning method/function (CLAUDE.md §4 UI rules).',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final NoWidgetHelperMethods rule;
  final RuleContext context;

  bool _inScope() {
    final file = FileInfo.of(context);
    return file.isInLibSrc && !file.isUnder('lib/src/config/routes/');
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) => guarded(() {
    if (node.isSetter || node.isOperator) return;
    final name = node.name.lexeme;
    if (name == 'build') return;
    // `static _Scope of(BuildContext)` — InheritedWidget lookup, not a builder.
    if (node.isStatic && (name == 'of' || name == 'maybeOf')) return;
    if (hasOverrideAnnotation(node)) return;
    final returnType = node.returnType;
    if (returnType == null) return;
    if (!isWidgetOrWidgetCollectionType(returnType.type)) return;
    if (!_inScope()) return;
    rule.reportAtToken(node.name, arguments: [node.name.lexeme]);
  });

  /// Top-level and local function declarations (closures are
  /// `FunctionExpression`s and never reach here).
  @override
  void visitFunctionDeclaration(FunctionDeclaration node) => guarded(() {
    if (node.isSetter) return;
    if (hasOverrideAnnotation(node)) return;
    final returnType = node.returnType;
    if (returnType == null) return;
    if (!isWidgetOrWidgetCollectionType(returnType.type)) return;
    if (!_inScope()) return;
    rule.reportAtToken(node.name, arguments: [node.name.lexeme]);
  });
}
