// `ErrorSeverity`/`ErrorReporter` are the types custom_lint's base `run` still
// exposes on analyzer 8 (their `Diagnostic*` renames are not yet what the base
// class uses), so keep using them and silence the rename deprecation.
// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// custom_lint entry point. Discovered automatically by the `custom_lint`
/// runner via the top-level `createPlugin` function.
PluginBase createPlugin() => _PresentationLintsPlugin();

class _PresentationLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const PresentationNoCoreRepo(),
      ];
}

/// Bans presentation-layer code from reaching into the core
/// `KeetaRepository` — either by importing
/// `core/data/keeta_repository.dart` or by resolving `sl<KeetaRepository>()`.
/// Presentation must flow through a cubit → feature repository instead.
class PresentationNoCoreRepo extends DartLintRule {
  const PresentationNoCoreRepo() : super(code: _code);

  static const _code = LintCode(
    name: 'presentation_no_core_repo',
    problemMessage:
        'Presentation must not read the core KeetaRepository directly. '
        'Route through a cubit → feature repository (see clean-arch boundary).',
    errorSeverity: ErrorSeverity.WARNING,
  );

  /// True for files under `lib/features/<f>/presentation/**`.
  static bool _isPresentation(String path) {
    final p = path.replaceAll(r'\', '/');
    return p.contains('/features/') && p.contains('/presentation/');
  }

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isPresentation(resolver.path)) return;

    // (a) import of the core repository from presentation.
    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue ?? '';
      if (uri.contains('core/data/keeta_repository.dart')) {
        reporter.atNode(node, _code);
      }
    });

    // (b) `sl<KeetaRepository>()` resolved anywhere in a presentation file.
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'sl') return;
      final targs = node.typeArguments?.arguments ?? const [];
      if (targs.any((t) => t.toSource() == 'KeetaRepository')) {
        reporter.atNode(node, _code);
      }
    });
    context.registry.addFunctionExpressionInvocation((node) {
      final targs = node.typeArguments?.arguments ?? const [];
      if (targs.any((t) => t.toSource() == 'KeetaRepository') &&
          node.function.toSource() == 'sl') {
        reporter.atNode(node, _code);
      }
    });
  }
}
