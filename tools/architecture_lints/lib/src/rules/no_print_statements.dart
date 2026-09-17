import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../utils/file_info.dart';
import '../utils/guard.dart';
import '../utils/types.dart';

/// Rule 8 — log with `dart:developer` `log()`, never `print` / `debugPrint`.
class NoPrintStatements extends AnalysisRule {
  NoPrintStatements()
    : super(
        name: 'no_print_statements',
        description: 'print() and debugPrint() are not allowed in lib/.',
      );

  static const LintCode code = LintCode(
    'no_print_statements',
    "Don't use '{0}' in app code.",
    correctionMessage:
        "Use log() from 'dart:developer' (CLAUDE.md §5 Logging).",
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
    registry.addMethodInvocation(this, visitor);
    registry.addFunctionExpressionInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final NoPrintStatements rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) => guarded(() {
    final name = node.methodName.name;
    if (name != 'print' && name != 'debugPrint') return;
    if (!_isBanned(node.methodName.element)) return;
    _report(node.methodName, name);
  });

  /// `debugPrint` is a top-level *variable* of function type, so its calls
  /// resolve to a [FunctionExpressionInvocation].
  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      guarded(() {
        final function = node.function;
        final Element? element = switch (function) {
          SimpleIdentifier() => function.element,
          PrefixedIdentifier() => function.element,
          _ => null,
        };
        final name = element?.name;
        if (name != 'print' && name != 'debugPrint') return;
        if (!_isBanned(element)) return;
        _report(function, name!);
      });

  static bool _isBanned(Element? element) {
    if (element == null) return false;
    final uri = libraryUriOf(element);
    if (element.name == 'print') {
      return element is TopLevelFunctionElement && uri == 'dart:core';
    }
    if (element.name == 'debugPrint') {
      return (element is GetterElement || element is TopLevelVariableElement) &&
          isFlutterLibrary(uri);
    }
    return false;
  }

  void _report(AstNode node, String name) {
    if (!FileInfo.of(context).isInLib) return;
    rule.reportAtNode(node, arguments: ['$name()']);
  }
}
