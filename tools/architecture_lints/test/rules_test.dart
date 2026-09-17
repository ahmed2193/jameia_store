import 'package:architecture_lints/src/rules/cubit_depends_on_usecases.dart';
import 'package:architecture_lints/src/rules/datasource_no_either.dart';
import 'package:architecture_lints/src/rules/domain_layer_purity.dart';
import 'package:architecture_lints/src/rules/feature_structure.dart';
import 'package:architecture_lints/src/rules/no_cross_feature_imports.dart';
import 'package:architecture_lints/src/rules/no_hardcoded_ui_strings.dart';
import 'package:architecture_lints/src/rules/no_imperative_navigation.dart';
import 'package:architecture_lints/src/rules/no_magic_ui_values.dart';
import 'package:architecture_lints/src/rules/no_print_statements.dart';
import 'package:architecture_lints/src/rules/no_service_locator_outside_di.dart';
import 'package:architecture_lints/src/rules/no_widget_helper_methods.dart';
import 'package:architecture_lints/src/rules/one_widget_per_file.dart';
import 'package:architecture_lints/src/rules/presentation_no_data_layer.dart';
import 'package:architecture_lints/src/rules/repository_impl_uses_base_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DomainLayerPurityTest);
    defineReflectiveTests(PresentationNoDataLayerTest);
    defineReflectiveTests(CubitDependsOnUsecasesTest);
    defineReflectiveTests(NoServiceLocatorOutsideDiTest);
    defineReflectiveTests(OneWidgetPerFileTest);
    defineReflectiveTests(NoWidgetHelperMethodsTest);
    defineReflectiveTests(NoImperativeNavigationTest);
    defineReflectiveTests(NoPrintStatementsTest);
    defineReflectiveTests(NoMagicUiValuesTest);
    defineReflectiveTests(NoHardcodedUiStringsTest);
    defineReflectiveTests(FeatureStructureTest);
    defineReflectiveTests(RepositoryImplUsesBaseMixinTest);
    defineReflectiveTests(NoCrossFeatureImportsTest);
    defineReflectiveTests(DatasourceNoEitherTest);
  });
}

@reflectiveTest
class DomainLayerPurityTest extends ArchitectureRuleTest {
  @override
  void setUp() {
    rule = DomainLayerPurity();
    super.setUp();
  }

  Future<void> test_flags_framework_and_data_imports() async {
    await expectLints(
      'lib/src/features/home/domain/entities/home_entity.dart',
      r'''
import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:flutter/foundation.dart';
import '../repositories/home_repository.dart';
import '../../data/models/home_model.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/domain/entities/money.dart';
import '../../../../core/data/keeta_repository.dart';
import 'package:test/src/core/utils/formatters.dart';
import 'package:test/src/core/domain/entities/shop.dart';
''',
      [
        "'package:flutter/foundation.dart'",
        "'../../data/models/home_model.dart'",
        "'../../../../core/error/exceptions.dart'",
        "'../../../../core/data/keeta_repository.dart'",
        "'package:test/src/core/utils/formatters.dart'",
      ],
    );
  }

  Future<void> test_ignores_non_domain_files() async {
    await expectLints(
      'lib/src/features/home/data/models/home_model.dart',
      "import 'package:flutter/foundation.dart';\n",
      [],
    );
  }
}

@reflectiveTest
class PresentationNoDataLayerTest extends ArchitectureRuleTest {
  @override
  void setUp() {
    rule = PresentationNoDataLayer();
    super.setUp();
  }

  Future<void> test_widget_imports() async {
    await expectLints(
      'lib/src/features/home/presentation/widgets/home_card.dart',
      r'''
import 'package:flutter/widgets.dart';
import '../../data/models/home_model.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/repositories/home_repository.dart';
import '../../home_injection_container.dart';
import '../../../../config/di/service_locator.dart';
import '../../domain/entities/home_entity.dart';
import '../../../../core/widgets/keeta_image.dart';
import '../cubit/home_cubit.dart';
''',
      [
        "'../../data/models/home_model.dart'",
        "'../../../../core/data/keeta_repository.dart'",
        "'../../../../core/network/api_consumer.dart'",
        "'../../../../core/storage/local_storage.dart'",
        "'../../domain/repositories/home_repository.dart'",
        "'../../home_injection_container.dart'",
        "'../../../../config/di/service_locator.dart'",
      ],
    );
  }

  Future<void> test_pages_may_import_service_locator() async {
    await expectLints(
      'lib/src/features/home/presentation/pages/home_page.dart',
      r'''
import '../../../../config/di/service_locator.dart';
import '../../../../core/data/models/shop.dart';
''',
      ["'../../../../core/data/models/shop.dart'"],
    );
  }

  Future<void> test_cubit_overlap_is_left_to_cubit_rule() async {
    await expectLints(
      'lib/src/features/home/presentation/cubit/home_cubit.dart',
      r'''
import '../../data/models/home_model.dart';
import '../../domain/repositories/home_repository.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/network/api_consumer.dart';
''',
      ["'../../../../core/network/api_consumer.dart'"],
    );
  }
}

@reflectiveTest
class CubitDependsOnUsecasesTest extends ArchitectureRuleTest {
  @override
  void setUp() {
    rule = CubitDependsOnUsecases();
    super.setUp();
  }

  Future<void> test_imports_and_build_context() async {
    await expectLints(
      'lib/src/features/home/presentation/cubit/home_cubit.dart',
      r'''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/usecases/get_home.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../../../config/di/service_locator.dart';

class HomeCubit {
  void open(BuildContext context) {}
}
''',
      [
        "'package:flutter/widgets.dart'",
        "'../../domain/repositories/home_repository.dart'",
        "'../../data/repositories/home_repository_impl.dart'",
        "'../../../../config/di/service_locator.dart'",
        'BuildContext',
      ],
    );
  }

  Future<void> test_ignores_widgets() async {
    await expectLints(
      'lib/src/features/home/presentation/widgets/home_card.dart',
      r'''
import 'package:flutter/widgets.dart';
void open(BuildContext context) {}
''',
      [],
    );
  }
}

@reflectiveTest
class NoServiceLocatorOutsideDiTest extends ArchitectureRuleTest {
  @override
  void setUp() {
    rule = NoServiceLocatorOutsideDi();
    super.setUp();
  }

  static const _cubit = r'''
import 'package:bloc/bloc.dart';
class HomeCubit extends Cubit<int> {
  HomeCubit() : super(0);
}
class HomeRepository {}
''';

  Future<void> test_di_root_is_exempt() async {
    await expectLints('lib/src/config/di/service_locator.dart', r'''
import 'package:get_it/get_it.dart';
final GetIt sl = GetIt.instance;
void setup() {
  sl.registerFactory<Object>(() => Object());
}
''', []);
  }

  Future<void> test_pages_allow_cubits_only() async {
    writeFile('lib/src/config/di/service_locator.dart', r'''
import 'package:get_it/get_it.dart';
final GetIt sl = GetIt.instance;
''');
    writeFile(
      'lib/src/features/home/presentation/cubit/home_cubit.dart',
      _cubit,
    );
    await expectLints(
      'lib/src/features/home/presentation/pages/home_page.dart',
      r'''
import 'package:get_it/get_it.dart';
import '../../../../config/di/service_locator.dart';
import '../cubit/home_cubit.dart';

void f() {
  final HomeCubit a = sl();
  final b = sl<HomeCubit>();
  final c = sl.get<HomeCubit>();
  final d = sl<HomeRepository>();
  final e = sl.isRegistered<HomeRepository>();
  final g = GetIt.I<HomeRepository>();
  final h = GetIt.instance;
}
''',
      [
        'sl<HomeRepository>()',
        'sl.isRegistered<HomeRepository>()',
        'GetIt.I<HomeRepository>()',
        'GetIt.instance',
      ],
    );
  }

  Future<void> test_cubit_lookup_outside_pages_is_flagged() async {
    writeFile('lib/src/config/di/service_locator.dart', r'''
import 'package:get_it/get_it.dart';
final GetIt sl = GetIt.instance;
''');
    writeFile(
      'lib/src/features/home/presentation/cubit/home_cubit.dart',
      _cubit,
    );
    await expectLints(
      'lib/src/features/home/presentation/widgets/home_card.dart',
      r'''
import '../../../../config/di/service_locator.dart';
import '../cubit/home_cubit.dart';
final cubit = sl<HomeCubit>();
''',
      ['sl<HomeCubit>()'],
    );
    await expectLints(
      'lib/src/features/home/home_injection_container.dart',
      r'''
import '../../config/di/service_locator.dart';
import 'presentation/cubit/home_cubit.dart';
final repo = sl<HomeRepository>();
''',
      [],
    );
  }
}

@reflectiveTest
class OneWidgetPerFileTest extends ArchitectureRuleTest {
  @override
  void setUp() {
    rule = OneWidgetPerFile();
    super.setUp();
  }

  Future<void> test_reports_every_extra_widget() async {
    await expectLints(
      'lib/src/features/home/presentation/widgets/home_card.dart',
      r'''
import 'package:flutter/widgets.dart';

class HomeCard extends StatefulWidget {
  const HomeCard({super.key});
  @override
  State<HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<HomeCard> {
  @override
  Widget build(BuildContext context) => const _Title();
}

class _Painter {}

class _Title extends StatelessWidget {
  const _Title();
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _Subtitle extends StatelessWidget {
  const _Subtitle();
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''',
      ['_Title', '_Subtitle'],
    );
  }

  Future<void> test_single_widget_with_state_is_fine() async {
    await expectLints('lib/src/core/widgets/app_button.dart', r'''
import 'package:flutter/widgets.dart';
class AppButton extends StatefulWidget {
  const AppButton({super.key});
  @override
  State<AppButton> createState() => _AppButtonState();
}
class _AppButtonState extends State<AppButton> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''', []);
  }
}

@reflectiveTest
class NoWidgetHelperMethodsTest extends ArchitectureRuleTest {
  @override
  void setUp() {
    rule = NoWidgetHelperMethods();
    super.setUp();
  }

  Future<void> test_helpers() async {
    await expectLints(
      'lib/src/features/home/presentation/widgets/home_card.dart',
      r'''
import 'package:flutter/widgets.dart';

class HomeCard extends StatelessWidget {
  const HomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile() => const SizedBox();
    final builder = () => const SizedBox();
    return _header();
  }

  Widget _header() => const SizedBox();
  List<Widget> _items() => const [];
  Iterable<SizedBox> get _boxes => const [];
  static Widget circle() => const SizedBox();
  String label() => '';
  Future<Widget> later() async => const SizedBox();
}

Widget buildSuggestionText(String text) => Text(text);

class _Scope extends InheritedWidget {
  static _Scope of(BuildContext context) => throw 0;
  static _Scope? maybeOf(BuildContext context) => null;
  _Scope wrap() => this;
}
''',
      [
        'tile',
        '_header',
        '_items',
        '_boxes',
        'circle',
        'buildSuggestionText',
        'wrap',
      ],
    );
  }

  Future<void> test_routes_are_exempt() async {
    await expectLints('lib/src/config/routes/app_router.dart', r'''
import 'package:flutter/widgets.dart';
Widget page() => const SizedBox();
''', []);
  }
}

@reflectiveTest
class NoImperativeNavigationTest extends ArchitectureRuleTest {
  @override
  void setUp() {
    rule = NoImperativeNavigation();
    super.setUp();
  }

  Future<void> test_navigator_calls() async {
    await expectLints(
      'lib/src/features/home/presentation/pages/home_page.dart',
      r'''
import 'package:flutter/widgets.dart';

void go(BuildContext context) {
  Navigator.push(context, Object());
  Navigator.pushNamed(context, '/x');
  Navigator.of(context).push(Object());
  Navigator.of(context)..popUntil((_) => true);
  Navigator.pop(context);
  Navigator.of(context).pop();
  Navigator.of(context).canPop();
}
''',
      ['push', 'pushNamed', 'push', 'popUntil'],
    );
  }

  Future<void> test_navigation_core_is_exempt() async {
    await expectLints('lib/src/core/navigation/navigation.dart', r'''
import 'package:flutter/widgets.dart';
void go(BuildContext context) => Navigator.of(context).push(Object());
''', []);
  }
}

@reflectiveTest
class NoPrintStatementsTest extends ArchitectureRuleTest {
  @override
  void setUp() {
    rule = NoPrintStatements();
    super.setUp();
  }

  Future<void> test_print_and_debug_print() async {
    await expectLints(
      'lib/main.dart',
      r'''
import 'package:flutter/foundation.dart';
void main() {
  print('a');
  debugPrint('b');
  void log(String m) {}
  log('c');
}
''',
      ['print', 'debugPrint'],
    );
  }

  Future<void> test_outside_lib_is_ignored() async {
    await expectLints('tool/script.dart', "void main() => print('a');\n", []);
  }
}

@reflectiveTest
class NoMagicUiValuesTest extends ArchitectureRuleTest {
  @override
  void setUp() {
    rule = NoMagicUiValues();
    super.setUp();
  }

  Future<void> test_ui_scope() async {
    await expectLints(
      'lib/src/features/home/presentation/widgets/home_card.dart',
      r'''
import 'package:flutter/src/animation/tween.dart';
import 'package:flutter/widgets.dart';

class HomeCard extends StatelessWidget {
  static const double gap = 12;
  static const pad = EdgeInsets.all(16);
  const HomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: 300);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      child: SizedBox(
        width: 24.5,
        height: gap,
        child: Container(color: const Color(0xFF00FF00), width: -3),
      ),
    );
  }
}

void f(void Function(Object) g, void Function(int) h, void Function({int top}) k) {
  g(const Duration(seconds: 2));
  g(const Radius.circular(4));
  g(BorderRadius.circular(0));
  g(const Color.fromARGB(255, 0, 0, 0));
  h(12);
  k(top: 5);
  g(Tween<double>(begin: 0.6, end: 1.0));
  g(double.infinity);
}
''',
      [
        '8',
        '24.5',
        'const Color(0xFF00FF00)',
        '-3',
        '2',
        '4',
        'const Color.fromARGB(255, 0, 0, 0)',
        '5',
      ],
    );
  }

  Future<void> test_color_scope_and_theme_exemption() async {
    await expectLints(
      'lib/src/core/utils/colors_util.dart',
      r'''
import 'package:flutter/widgets.dart';
void f(void Function(Object) g) {
  g(const Color(0xFF000000));
  g(const SizedBox(width: 12));
}
''',
      ['const Color(0xFF000000)'],
    );
    await expectLints('lib/src/config/theme/app_colors.dart', r'''
import 'package:flutter/widgets.dart';
void f(void Function(Object) g) => g(const Color(0xFF000000));
''', []);
  }
}

@reflectiveTest
class NoHardcodedUiStringsTest extends ArchitectureRuleTest {
  @override
  void setUp() {
    rule = NoHardcodedUiStrings();
    super.setUp();
  }

  Future<void> test_ui_strings() async {
    await expectLints(
      'lib/src/features/home/presentation/widgets/home_card.dart',
      r'''
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

void f(void Function(Object) g, int count, void Function({String? title, String? label, String? name}) k) {
  g(Text('Hello'));
  g(Text('home.title'.tr()));
  g(Text(tr('home.title')));
  g(Text('$count'));
  g(Text('$count KD'));
  g(Text('مرحبا'));
  g(Text('a' 'b'));
  g(Text('•'));
  k(title: 'Title');
  k(title: 'assets/images/a.png');
  k(label: 'https://example.com/x');
  k(label: 'map.google');
  k(label: 'Open map.google now');
  k(name: 'Bob');
}
''',
      [
        "'Hello'",
        "'\$count KD'",
        "'مرحبا'",
        "'a' 'b'",
        "'Title'",
        "'Open map.google now'",
      ],
    );
  }

  Future<void> test_outside_ui_scope() async {
    await expectLints('lib/src/core/utils/strings.dart', r'''
import 'package:flutter/widgets.dart';
final text = Text('Hello');
''', []);
  }
}

@reflectiveTest
class FeatureStructureTest extends ArchitectureRuleTest {
  @override
  void setUp() {
    rule = FeatureStructure();
    super.setUp();
  }

  Future<void> test_layout() async {
    const ok = 'class A {}\n';
    await expectLints(
      'lib/src/features/home/home_injection_container.dart',
      ok,
      [],
    );
    await expectLints(
      'lib/src/features/home/domain/usecases/get_home.dart',
      ok,
      [],
    );
    await expectLints(
      'lib/src/features/home/presentation/widgets/sub/a.dart',
      ok,
      [],
    );
    await expectLints(
      'lib/src/features/home/presentation/pages/home_page.dart',
      ok,
      [],
    );
    await expectLints('lib/src/features/home/other.dart', ok, ['class']);
    await expectLints(
      'lib/src/features/home/presentation/util/x.dart',
      "import 'dart:math';\nclass A {}\n",
      ["import 'dart:math';"],
    );
    await expectLints(
      'lib/src/features/home/presentation/pages/home_screen.dart',
      ok,
      ['class'],
    );
    await expectLints('lib/src/features/home/data/x.dart', ok, ['class']);
    await expectLints('lib/src/core/utils/x.dart', ok, []);
  }
}

@reflectiveTest
class RepositoryImplUsesBaseMixinTest extends ArchitectureRuleTest {
  @override
  void setUp() {
    rule = RepositoryImplUsesBaseMixin();
    super.setUp();
  }

  Future<void> test_impls() async {
    writeFile(
      'lib/src/core/data/repositories/base_repository_mixin.dart',
      'mixin BaseRepositoryMixin {}\n',
    );
    await expectLints(
      'lib/src/features/home/data/repositories/home_repository_impl.dart',
      r'''
import '../../../../core/data/repositories/base_repository_mixin.dart';
abstract class HomeRepository {}
class A implements HomeRepository {}
class B with BaseRepositoryMixin implements HomeRepository {}
class C {}
class D extends B implements HomeRepository {}
''',
      ['A'],
    );
  }
}

@reflectiveTest
class NoCrossFeatureImportsTest extends ArchitectureRuleTest {
  @override
  void setUp() {
    rule = NoCrossFeatureImports();
    super.setUp();
  }

  Future<void> test_cross_feature() async {
    await expectLints(
      'lib/src/features/home/presentation/widgets/home_card.dart',
      r'''
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/domain/entities/cart_item.dart';
import 'package:test/src/features/shop/presentation/widgets/shop_tile.dart';
import '../../../../core/widgets/keeta_image.dart';
import '../../domain/entities/home_entity.dart';
''',
      [
        "'../../../cart/domain/entities/cart_item.dart'",
        "'package:test/src/features/shop/presentation/widgets/shop_tile.dart'",
      ],
    );
    await expectLints(
      'lib/src/features/home/home_injection_container.dart',
      "import '../cart/data/datasources/cart_local.dart';\n",
      [],
    );
  }
}

@reflectiveTest
class DatasourceNoEitherTest extends ArchitectureRuleTest {
  @override
  void setUp() {
    rule = DatasourceNoEither();
    super.setUp();
  }

  Future<void> test_dartz() async {
    await expectLints(
      'lib/src/features/home/data/datasources/home_local_data_source.dart',
      "import 'package:dartz/dartz.dart';\n",
      ["'package:dartz/dartz.dart'"],
    );
    await expectLints(
      'lib/src/features/home/data/repositories/home_repository_impl.dart',
      "import 'package:dartz/dartz.dart';\n",
      [],
    );
  }
}
