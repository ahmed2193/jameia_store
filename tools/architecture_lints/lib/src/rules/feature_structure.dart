import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/file_info.dart';
import '../utils/guard.dart';

/// Rule 11 — the canonical feature folder layout.
class FeatureStructure extends AnalysisRule {
  FeatureStructure()
    : super(
        name: 'feature_structure',
        description:
            'Feature files live only in data/(datasources|models|mappers|'
            'repositories), domain/(entities|repositories|usecases), '
            'presentation/(cubit|pages|widgets) or '
            '<feature>_injection_container.dart; pages are *_page.dart.',
      );

  static const LintCode code = LintCode(
    'feature_structure',
    "Feature file '{0}' {1}.",
    correctionMessage:
        'Allowed: <feature>_injection_container.dart, '
        'data/{datasources,models,mappers,repositories}/, '
        'domain/{entities,repositories,usecases}/, '
        'presentation/{cubit,pages,widgets}/ — no screens/, util/, popups/, '
        'helpers/ (CLAUDE.md §1 Project structure).',
    severity: DiagnosticSeverity.WARNING,
  );

  static const allowedFolders = {
    'data': {'datasources', 'models', 'mappers', 'repositories'},
    'domain': {'entities', 'repositories', 'usecases'},
    'presentation': {'cubit', 'pages', 'widgets'},
  };

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _Visitor(this, context));
  }

  /// The reason [featureRelPath] (inside feature [feature]) is misplaced, or
  /// `null` when the location is valid.
  static String? problemFor(String feature, String featureRelPath) {
    final segments = featureRelPath.split('/');
    if (segments.length == 1) {
      return segments.single == '${feature}_injection_container.dart'
          ? null
          : 'is not an allowed file at the feature root '
                '(only ${feature}_injection_container.dart)';
    }
    final layer = segments[0];
    final folder = segments[1];
    final allowed = allowedFolders[layer];
    if (allowed == null) {
      return "is in '$layer/', which is not a feature layer";
    }
    if (segments.length < 3 || !allowed.contains(folder)) {
      return "is in '$layer/${segments.length < 3 ? '' : '$folder/'}', "
          'which is not an allowed $layer folder';
    }
    if (layer == 'presentation' &&
        folder == 'pages' &&
        !segments.last.endsWith('_page.dart')) {
      return 'is in presentation/pages but is not named *_page.dart';
    }
    return null;
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final FeatureStructure rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) => guarded(() {
    final file = FileInfo.of(context);
    final feature = file.featureName;
    final featurePath = file.featureRelPath;
    if (feature == null || featurePath == null) return;
    final problem = FeatureStructure.problemFor(feature, featurePath);
    if (problem == null) return;

    final arguments = [file.relPath, problem];
    if (node.directives.isNotEmpty) {
      rule.reportAtNode(node.directives.first, arguments: arguments);
    } else if (node.declarations.isNotEmpty) {
      rule.reportAtToken(
        node.declarations.first.firstTokenAfterCommentAndMetadata,
        arguments: arguments,
      );
    } else {
      rule.reportAtOffset(0, 0, arguments: arguments);
    }
  });
}
