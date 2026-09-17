import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../utils/file_info.dart';
import '../utils/guard.dart';
import '../utils/imports.dart';

/// Base for rules that only inspect `import` / `export` directives.
abstract class DirectiveRule extends AnalysisRule {
  DirectiveRule({required super.name, required super.description});

  /// Whether the importing [file] is in this rule's scope at all.
  bool appliesTo(FileInfo file);

  /// Returns the message arguments (usually just the offending URI) when
  /// [target] violates the rule for [file], else `null`.
  List<Object>? violation(FileInfo file, DirectiveTarget target);

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _DirectiveVisitor(this, context);
    registry.addImportDirective(this, visitor);
    registry.addExportDirective(this, visitor);
  }
}

class _DirectiveVisitor extends SimpleAstVisitor<void> {
  _DirectiveVisitor(this.rule, this.context);

  final DirectiveRule rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) => _check(node);

  @override
  void visitExportDirective(ExportDirective node) => _check(node);

  void _check(NamespaceDirective node) => guarded(() {
    final file = FileInfo.of(context);
    if (!rule.appliesTo(file)) return;
    final target = resolveDirective(node, file);
    if (target == null) return;
    final arguments = rule.violation(file, target);
    if (arguments != null) {
      rule.reportAtNode(node.uri, arguments: arguments);
    }
  });
}
