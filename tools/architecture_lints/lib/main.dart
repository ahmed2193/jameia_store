/// Entry point loaded by the Dart Analysis Server (analysis_server_plugin).
///
/// Enabled from the app's `analysis_options.yaml`:
///
/// ```yaml
/// plugins:
///   architecture_lints:
///     path: tools/architecture_lints
/// ```
///
/// Every rule is registered as a *warning* rule, so it is on by default and
/// shows up in `flutter analyze` / `dart analyze` and the IDE. Suppress a
/// single site with `// ignore: architecture_lints/<rule_name>`.
library;

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';

import 'src/rules/cubit_depends_on_usecases.dart';
import 'src/rules/datasource_no_either.dart';
import 'src/rules/domain_layer_purity.dart';
import 'src/rules/feature_structure.dart';
import 'src/rules/no_cross_feature_imports.dart';
import 'src/rules/no_hardcoded_ui_strings.dart';
import 'src/rules/no_imperative_navigation.dart';
import 'src/rules/no_magic_ui_values.dart';
import 'src/rules/no_print_statements.dart';
import 'src/rules/no_service_locator_outside_di.dart';
import 'src/rules/no_widget_helper_methods.dart';
import 'src/rules/one_widget_per_file.dart';
import 'src/rules/presentation_no_data_layer.dart';
import 'src/rules/repository_impl_uses_base_mixin.dart';

final plugin = ArchitectureLintsPlugin();

class ArchitectureLintsPlugin extends Plugin {
  @override
  String get name => 'architecture_lints';

  @override
  void register(PluginRegistry registry) {
    for (final rule in allRules()) {
      registry.registerWarningRule(rule);
    }
  }
}

/// All rules, in CLAUDE.md order. Exposed for tests.
List<AnalysisRule> allRules() => [
  DomainLayerPurity(),
  PresentationNoDataLayer(),
  CubitDependsOnUsecases(),
  NoServiceLocatorOutsideDi(),
  OneWidgetPerFile(),
  NoWidgetHelperMethods(),
  NoImperativeNavigation(),
  NoPrintStatements(),
  NoMagicUiValues(),
  NoHardcodedUiStrings(),
  FeatureStructure(),
  RepositoryImplUsesBaseMixin(),
  NoCrossFeatureImports(),
  DatasourceNoEither(),
];
