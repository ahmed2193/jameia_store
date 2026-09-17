import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:architecture_lints/src/utils/guard.dart';
import 'package:test/test.dart';

/// Shared harness: writes files at package-relative paths (the rules scope
/// themselves by `lib/src/...` location) and compares the *text* each
/// diagnostic of the rule under test covers, ignoring unrelated diagnostics
/// (unused imports etc.).
abstract class ArchitectureRuleTest extends AnalysisRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  bool get addMetaPackageDep => true;

  @override
  void setUp() {
    newPackage('get_it').addFile('lib/get_it.dart', r'''
abstract class GetIt {
  static GetIt get instance => throw 0;
  static GetIt get I => throw 0;
  T call<T extends Object>({String? instanceName}) => throw 0;
  T get<T extends Object>({String? instanceName}) => throw 0;
  bool isRegistered<T extends Object>() => true;
  void registerFactory<T extends Object>(T Function() factory) {}
}
''');
    newPackage('bloc').addFile('lib/bloc.dart', r'''
abstract class BlocBase<State> {
  BlocBase(this.state);
  State state;
}
abstract class Cubit<State> extends BlocBase<State> {
  Cubit(super.initialState);
}
''');
    newPackage('dartz').addFile('lib/dartz.dart', r'''
abstract class Either<L, R> {}
''');
    newPackage('equatable').addFile('lib/equatable.dart', r'''
abstract class Equatable {
  const Equatable();
  List<Object?> get props;
}
''');
    newPackage('easy_localization').addFile('lib/easy_localization.dart', r'''
extension StringTr on String {
  String tr() => this;
}
String tr(String key) => key;
''');
    super.setUp();
    // The analyzer_testing flutter mock has no push*/popUntil on Navigator.
    newFile('/packages/flutter/lib/src/widgets/navigator.dart', r'''
import 'framework.dart';

class Navigator extends StatefulWidget {
  static NavigatorState of(BuildContext context) => throw 0;
  static Future<T?> push<T extends Object?>(BuildContext context, Object route) => throw 0;
  static Future<T?> pushNamed<T extends Object?>(BuildContext context, String routeName) => throw 0;
  static void pop<T extends Object?>(BuildContext context, [T? result]) {}
}

class NavigatorState extends State<Navigator> {
  Future<T?> push<T extends Object?>(Object route) => throw 0;
  void popUntil(bool Function(Object) predicate) {}
  void pop<T extends Object?>([T? result]) {}
  bool canPop() => true;
}
''');
    newFile('/packages/flutter/lib/src/animation/tween.dart', r'''
class Animatable<T> {}
class Tween<T extends Object?> extends Animatable<T> {
  Tween({this.begin, this.end});
  T? begin;
  T? end;
}
''');
    guardedErrors.clear();
  }

  /// Writes [content] at [relPath] (e.g. `lib/src/features/home/x.dart`) and
  /// expects exactly the diagnostics of this rule whose highlighted source
  /// text equals the entries of [expected] (order-insensitive).
  Future<void> expectLints(
    String relPath,
    String content,
    List<String> expected,
  ) async {
    final path = convertPath('$testPackageRootPath/$relPath');
    newFile(path, content);
    final result = await resolveFile(path);
    final actual = [
      for (final diagnostic in result.diagnostics)
        if (diagnostic.diagnosticCode.lowerCaseName == rule.name)
          content.substring(
            diagnostic.offset,
            diagnostic.offset + diagnostic.length,
          ),
    ];
    expect(actual, unorderedEquals(expected), reason: 'in $relPath');
    expect(guardedErrors, isEmpty, reason: 'rule threw while visiting');
  }

  /// Writes a supporting file without asserting anything about it.
  void writeFile(String relPath, String content) {
    newFile(convertPath('$testPackageRootPath/$relPath'), content);
  }
}
