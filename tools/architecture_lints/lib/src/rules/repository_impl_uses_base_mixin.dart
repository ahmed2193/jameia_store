import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/file_info.dart';
import '../utils/guard.dart';

/// Rule 12 — repository implementations share `BaseRepositoryMixin`.
class RepositoryImplUsesBaseMixin extends AnalysisRule {
  RepositoryImplUsesBaseMixin()
    : super(
        name: 'repository_impl_uses_base_mixin',
        description:
            'Classes in data/repositories that implement a contract must mix '
            'in BaseRepositoryMixin.',
      );

  static const LintCode code = LintCode(
    'repository_impl_uses_base_mixin',
    "Repository implementation '{0}' does not use BaseRepositoryMixin.",
    correctionMessage:
        'Declare `class XRepositoryImpl with BaseRepositoryMixin implements '
        'XRepository` and wrap each call in execute(() => ...) / '
        'executeSync(() => ...) instead of hand-written try/catch '
        '(CLAUDE.md §2 BaseRepositoryMixin).',
    severity: DiagnosticSeverity.WARNING,
  );

  static const mixinName = 'BaseRepositoryMixin';

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final RepositoryImplUsesBaseMixin rule;
  final RuleContext context;

  @override
  void visitClassDeclaration(ClassDeclaration node) => guarded(() {
    if (node.implementsClause == null) return;
    if (node.abstractKeyword != null) return;
    final file = FileInfo.of(context);
    if (!file.isInLibSrc || !file.relPath.contains('/data/repositories/')) {
      return;
    }
    if (file.fileName == 'base_repository_mixin.dart') return;

    const mixinName = RepositoryImplUsesBaseMixin.mixinName;
    final withClause = node.withClause;
    if (withClause != null &&
        withClause.mixinTypes.any((type) => type.name.lexeme == mixinName)) {
      return;
    }
    // Inherited through a superclass that already mixes it in.
    final element = node.declaredFragment?.element;
    if (element != null &&
        element.allSupertypes.any((type) => type.element.name == mixinName)) {
      return;
    }
    final name = node.namePart.typeName;
    rule.reportAtToken(name, arguments: [name.lexeme]);
  });
}
