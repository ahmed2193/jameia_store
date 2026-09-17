import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/file_info.dart';
import '../utils/guard.dart';
import '../utils/types.dart';

/// Rule 9 — spacing, sizes, radii, durations and colors come from tokens.
class NoMagicUiValues extends AnalysisRule {
  NoMagicUiValues()
    : super(
        name: 'no_magic_ui_values',
        description:
            'Numeric literals for insets, radii, durations and size-like named '
            'arguments, and literal Color(...) values, must use design tokens.',
      );

  static const LintCode code = LintCode(
    'no_magic_ui_values',
    "Magic UI value '{0}'.",
    correctionMessage:
        'Use tokens: AppSpacing.sN (spacing), AppSize.sN / rN / fontN (sizes, '
        'radii, font sizes), AppMotion (durations), AppColors (colors), or a '
        'named static const. Only 0 and double.infinity may be inline '
        '(CLAUDE.md §4 No magic values).',
    severity: DiagnosticSeverity.WARNING,
  );

  /// Named arguments whose numeric literal is always a UI magic value.
  static const sizeLikeNames = {
    'width',
    'height',
    'size',
    'iconSize',
    'strokeWidth',
    'thickness',
    'indent',
    'endIndent',
    'spacing',
    'runSpacing',
    'mainAxisSpacing',
    'crossAxisSpacing',
    'mainAxisExtent',
    'elevation',
    'blurRadius',
    'spreadRadius',
    'radius',
    'fontSize',
    'letterSpacing',
    'maxWidth',
    'maxHeight',
    'minWidth',
    'minHeight',
    'toolbarHeight',
    'itemExtent',
    'top',
    'bottom',
    'left',
    'right',
    'start',
    'end',
    'horizontal',
    'vertical',
    'all',
  };

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addIntegerLiteral(this, visitor);
    registry.addDoubleLiteral(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final NoMagicUiValues rule;
  final RuleContext context;

  @override
  void visitIntegerLiteral(IntegerLiteral node) =>
      guarded(() => _checkNumber(node, isZero: node.value == 0));

  @override
  void visitDoubleLiteral(DoubleLiteral node) =>
      guarded(() => _checkNumber(node, isZero: node.value == 0));

  /// (e) `Color(0xFF...)`, `Color.fromARGB/fromRGBO/from(...)` with literals.
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) =>
      guarded(() {
        final cls = createdClass(node);
        if (!isElementNamed(cls, 'Color', isUiLibrary)) return;
        const constructors = {null, 'fromARGB', 'fromRGBO', 'from'};
        if (!constructors.contains(createdConstructorName(node))) return;
        final hasLiteral = node.argumentList.arguments.any(
          (argument) => _isNumericLiteral(argument.argumentExpression),
        );
        if (!hasLiteral) return;

        final file = FileInfo.of(context);
        if (!file.isInLibSrc || _isTokenHome(file)) return;
        if (_isInVariableInitializer(node)) return;
        rule.reportAtNode(node, arguments: [node.toSource()]);
      });

  void _checkNumber(Literal literal, {required bool isZero}) {
    if (isZero) return;

    Expression expression = literal;
    final literalParent = literal.parent;
    if (literalParent is PrefixExpression &&
        literalParent.operator.lexeme == '-') {
      expression = literalParent;
    }

    final argumentParent = expression.parent;
    String? argumentName;
    AstNode? argumentList;
    if (argumentParent is NamedArgument) {
      argumentName = argumentParent.name.lexeme;
      argumentList = argumentParent.parent;
    } else if (argumentParent is ArgumentList) {
      argumentList = argumentParent;
    }
    if (argumentList is! ArgumentList) return;
    final invocation = argumentList.parent;

    var matched = false;
    if (invocation is InstanceCreationExpression) {
      final cls = createdClass(invocation);
      final ctor = createdConstructorName(invocation);
      if (cls != null) {
        final name = cls.name;
        final uri = libraryUriOf(cls);
        if (name == 'Color' && isUiLibrary(uri)) {
          return; // Reported once per creation by (e).
        }
        if ((name == 'EdgeInsets' || name == 'EdgeInsetsDirectional') &&
            isFlutterLibrary(uri)) {
          matched = true; // (a)
        } else if (name == 'Radius' &&
            isUiLibrary(uri) &&
            (ctor == 'circular' || ctor == 'elliptical')) {
          matched = true; // (b)
        } else if ((name == 'BorderRadius' ||
                name == 'BorderRadiusDirectional') &&
            isFlutterLibrary(uri) &&
            ctor == 'circular') {
          matched = true; // (b)
        } else if (name == 'Duration' && uri == 'dart:core') {
          matched = true; // (c)
        } else if (isOrExtends(cls, 'Tween', isFlutterLibrary)) {
          // `Tween(begin: 0.6, end: 1.0)` — animation bounds, not UI sizes.
          return;
        }
      }
    }
    if (!matched &&
        argumentName != null &&
        NoMagicUiValues.sizeLikeNames.contains(argumentName)) {
      matched = true; // (d)
    }
    if (!matched) return;

    final file = FileInfo.of(context);
    if (!file.isUiScope || _isTokenHome(file)) return;
    if (_isInVariableInitializer(expression)) return;
    rule.reportAtNode(expression, arguments: [expression.toSource()]);
  }

  static bool _isNumericLiteral(Expression expression) {
    if (expression is IntegerLiteral || expression is DoubleLiteral) {
      return true;
    }
    return expression is PrefixExpression &&
        expression.operator.lexeme == '-' &&
        (expression.operand is IntegerLiteral ||
            expression.operand is DoubleLiteral);
  }

  /// Where tokens themselves are defined.
  static bool _isTokenHome(FileInfo file) =>
      file.isUnder('lib/src/config/theme/') ||
      file.isUnder('lib/src/core/responsive/') ||
      file.relPath == 'lib/src/core/motion/motion.dart';

  /// Literals that initialize a variable/field (`static const gap = 12;`)
  /// are named values, not magic ones.
  static bool _isInVariableInitializer(AstNode node) {
    for (
      AstNode? current = node.parent;
      current != null;
      current = current.parent
    ) {
      if (current is VariableDeclaration) return true;
      if (current is MethodDeclaration ||
          current is FunctionDeclaration ||
          current is ConstructorDeclaration ||
          current is CompilationUnit) {
        return false;
      }
    }
    return false;
  }
}
