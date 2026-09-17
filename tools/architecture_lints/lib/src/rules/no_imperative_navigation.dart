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

/// Rule 7 — navigation goes through GoRouter, never `Navigator.push*`.
class NoImperativeNavigation extends AnalysisRule {
  NoImperativeNavigation()
    : super(
        name: 'no_imperative_navigation',
        description:
            'Navigator / NavigatorState push*, popUntil and restorablePush* '
            'calls are not allowed outside config/routes and core/navigation.',
      );

  static const LintCode code = LintCode(
    'no_imperative_navigation',
    "Imperative navigation '{0}.{1}' bypasses GoRouter.",
    correctionMessage:
        'Use context.push/go/pop with Routes.* paths and extra: arguments; '
        'dialogs/sheets use showJameiaDialog/showJameiaBottomSheet '
        '(CLAUDE.md §2 Navigation).',
    severity: DiagnosticSeverity.WARNING,
  );

  static const bannedMethods = {
    'push',
    'pushNamed',
    'pushReplacement',
    'pushReplacementNamed',
    'pushNamedAndRemoveUntil',
    'pushAndRemoveUntil',
    'popUntil',
    'popAndPushNamed',
    'restorablePush',
    'restorablePushNamed',
    'restorablePushReplacement',
    'restorablePushReplacementNamed',
    'restorablePushAndRemoveUntil',
    'restorablePushNamedAndRemoveUntil',
    'restorablePopAndPushNamed',
  };

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final NoImperativeNavigation rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) => guarded(() {
    final name = node.methodName.name;
    if (!NoImperativeNavigation.bannedMethods.contains(name)) return;
    final element = node.methodName.element;
    if (element is! MethodElement) return;
    final owner = element.enclosingElement;
    if (owner is! InterfaceElement) return;
    final isNavigator =
        isOrExtends(owner, 'Navigator', isFlutterLibrary) ||
        isOrExtends(owner, 'NavigatorState', isFlutterLibrary);
    if (!isNavigator) return;

    final file = FileInfo.of(context);
    if (!file.isInLibSrc) return;
    if (file.isUnder('lib/src/config/routes/') ||
        file.isUnder('lib/src/core/navigation/')) {
      return;
    }
    rule.reportAtNode(node.methodName, arguments: [owner.name ?? '', name]);
  });
}
