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

/// Rule 4 — GetIt (`sl`) is read only by the DI composition root.
class NoServiceLocatorOutsideDi extends AnalysisRule {
  NoServiceLocatorOutsideDi()
    : super(
        name: 'no_service_locator_outside_di',
        description:
            'sl / GetIt may only be used in config/di, injection containers '
            'and (for cubits) pages.',
      );

  static const LintCode code = LintCode(
    'no_service_locator_outside_di',
    "Service locator access '{0}' outside the DI layer.",
    correctionMessage:
        'Use constructor injection. sl is read only in config/di and '
        '<feature>_injection_container.dart; pages may only do '
        'BlocProvider(create: (_) => sl<XCubit>()) (CLAUDE.md §2 DI, §4 Pages).',
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
    registry.addFunctionExpressionInvocation(this, visitor);
    registry.addMethodInvocation(this, visitor);
    registry.addPrefixedIdentifier(this, visitor);
    registry.addPropertyAccess(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final NoServiceLocatorOutsideDi rule;
  final RuleContext context;

  /// `null` when the file is exempt, else whether cubit lookups are allowed.
  ({bool allowCubits})? _scope() {
    final file = FileInfo.of(context);
    if (!file.isInLibSrc) return null; // lib/main.dart and non-lib are exempt
    if (file.isUnder('lib/src/config/di/')) return null;
    if (file.isInjectionContainer) return null;
    final pages =
        file.featureRelPath?.startsWith('presentation/pages/') ?? false;
    return (allowCubits: pages);
  }

  /// `sl<T>()`, `sl()`, `GetIt.instance<T>()`.
  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      guarded(() {
        if (!isGetItType(node.function.staticType)) return;
        final scope = _scope();
        if (scope == null) return;
        if (scope.allowCubits && isBlocBaseType(node.staticType)) return;
        rule.reportAtNode(node, arguments: [_describe(node)]);
      });

  /// `sl.get<T>()`, `sl.isRegistered<T>()`, `GetIt.I.registerFactory(...)`.
  @override
  void visitMethodInvocation(MethodInvocation node) => guarded(() {
    final target = node.realTarget;
    if (target == null || !isGetItType(target.staticType)) return;
    final scope = _scope();
    if (scope == null) return;
    final name = node.methodName.name;
    if (scope.allowCubits &&
        (name == 'get' || name == 'call') &&
        isBlocBaseType(node.staticType)) {
      return;
    }
    rule.reportAtNode(node, arguments: [_describe(node)]);
  });

  /// Bare `GetIt.instance` / `GetIt.I` not already reported as an invocation.
  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) => guarded(() {
    _checkStaticAccess(node, node.identifier);
  });

  @override
  void visitPropertyAccess(PropertyAccess node) => guarded(() {
    _checkStaticAccess(node, node.propertyName);
  });

  void _checkStaticAccess(Expression node, SimpleIdentifier property) {
    final name = property.name;
    if (name != 'instance' && name != 'I') return;
    final element = property.element;
    if (element is! GetterElement || !element.isStatic) return;
    if (!isElementNamed(
      element.enclosingElement,
      'GetIt',
      (uri) => uri != null && uri.startsWith('package:get_it/'),
    )) {
      return;
    }
    final parent = node.parent;
    if (parent is FunctionExpressionInvocation && parent.function == node) {
      return; // reported by visitFunctionExpressionInvocation
    }
    if (parent is MethodInvocation && parent.realTarget == node) {
      return; // reported by visitMethodInvocation
    }
    // Anything else (`final locator = GetIt.I;`, `GetIt.I.allowReassignment`)
    // is still a locator read and is reported here.
    if (_scope() == null) return;
    rule.reportAtNode(node, arguments: [node.toSource()]);
  }

  static String _describe(AstNode node) {
    final source = node.toSource();
    final paren = source.indexOf('(');
    return paren < 0 ? source : '${source.substring(0, paren)}(...)';
  }
}
