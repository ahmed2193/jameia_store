import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/file_info.dart';
import '../utils/guard.dart';
import '../utils/types.dart';

/// Rule 10 — user-facing text comes from easy_localization keys.
class NoHardcodedUiStrings extends AnalysisRule {
  NoHardcodedUiStrings()
    : super(
        name: 'no_hardcoded_ui_strings',
        description:
            'String literals with letters passed to Text/SelectableText or to '
            'user-facing named arguments must be localized.',
      );

  static const LintCode code = LintCode(
    'no_hardcoded_ui_strings',
    'Hardcoded user-facing string {0}.',
    correctionMessage:
        "Use a translation key: 'feature.key'.tr(), with the key added to both "
        'assets/i18n/en.json and ar.json (CLAUDE.md §4 No hardcoded '
        'user-facing strings).',
    severity: DiagnosticSeverity.WARNING,
  );

  static const userFacingNames = {
    'text',
    'title',
    'label',
    'hintText',
    'labelText',
    'helperText',
    'errorText',
    'semanticsLabel',
    'semanticLabel',
    'tooltip',
    'message',
    'barrierLabel',
    'counterText',
    'prefixText',
    'suffixText',
  };

  /// Latin letters or any Arabic-script letter block.
  static bool hasLetter(String text) {
    for (final rune in text.runes) {
      if ((rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A)) {
        return true;
      }
      if ((rune >= 0x0600 && rune <= 0x06FF) || // Arabic
          (rune >= 0x0750 && rune <= 0x077F) || // Arabic Supplement
          (rune >= 0x08A0 && rune <= 0x08FF) || // Arabic Extended-A
          (rune >= 0xFB50 && rune <= 0xFDFF) || // Presentation Forms-A
          (rune >= 0xFE70 && rune <= 0xFEFC)) {
        // Presentation Forms-B
        return true;
      }
    }
    return false;
  }

  static final _assetOrUrl = RegExp(
    r'(\.(png|svg|json|gif|webp|jpe?g)$)|(^[a-z][a-z0-9+.-]*://)',
    caseSensitive: false,
  );

  /// `feature.key` / `map.google` — an easy_localization key that the
  /// receiving widget translates with `.tr()` itself.
  static final _translationKey = RegExp(
    r'^[a-z][a-zA-Z0-9_]*(\.[a-zA-Z0-9_]+)+$',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addSimpleStringLiteral(this, visitor);
    registry.addAdjacentStrings(this, visitor);
    registry.addStringInterpolation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final NoHardcodedUiStrings rule;
  final RuleContext context;

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) =>
      guarded(() => _check(node));

  @override
  void visitAdjacentStrings(AdjacentStrings node) =>
      guarded(() => _check(node));

  @override
  void visitStringInterpolation(StringInterpolation node) =>
      guarded(() => _check(node));

  void _check(StringLiteral node) {
    final parent = node.parent;
    if (parent is AdjacentStrings) return; // the whole literal is checked

    if (!_isUserFacingSlot(node, parent)) return;

    final text = _literalText(node);
    if (!NoHardcodedUiStrings.hasLetter(text)) return;
    final trimmed = text.trim();
    if (NoHardcodedUiStrings._assetOrUrl.hasMatch(trimmed)) return;
    if (node is SimpleStringLiteral &&
        NoHardcodedUiStrings._translationKey.hasMatch(trimmed)) {
      return;
    }

    if (!FileInfo.of(context).isUiScope) return;
    rule.reportAtNode(node, arguments: [_preview(node)]);
  }

  /// `Text('x')`, `SelectableText('x')`, or `title: 'x'` style arguments.
  /// A literal wrapped as `'key'.tr()` / `tr('key')` is never *directly* the
  /// argument, so it is not matched.
  static bool _isUserFacingSlot(StringLiteral node, AstNode? parent) {
    if (parent is NamedArgument) {
      return NoHardcodedUiStrings.userFacingNames.contains(parent.name.lexeme);
    }
    if (parent is! ArgumentList) return false;
    final invocation = parent.parent;
    if (invocation is! InstanceCreationExpression) return false;
    if (createdConstructorName(invocation) != null) return false;
    final cls = createdClass(invocation);
    final isTextWidget =
        isElementNamed(cls, 'Text', isFlutterLibrary) ||
        isElementNamed(cls, 'SelectableText', isFlutterLibrary);
    if (!isTextWidget) return false;
    final firstPositional = parent.arguments
        .where((argument) => argument is! NamedArgument)
        .firstOrNull;
    return identical(firstPositional, node);
  }

  static String _literalText(StringLiteral node) {
    return switch (node) {
      SimpleStringLiteral() => node.value,
      StringInterpolation() =>
        node.elements
            .whereType<InterpolationString>()
            .map((e) => e.value)
            .join(),
      AdjacentStrings() => node.strings.map(_literalText).join(),
    };
  }

  static String _preview(StringLiteral node) {
    final source = node.toSource().replaceAll(RegExp(r'\s+'), ' ');
    return source.length <= 40 ? source : '${source.substring(0, 37)}...';
  }
}
