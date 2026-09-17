import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// The library URI of [element], e.g. `package:flutter/src/widgets/framework.dart`.
String? libraryUriOf(Element? element) => element?.library?.uri.toString();

bool isFlutterLibrary(String? uri) =>
    uri != null && uri.startsWith('package:flutter/');

/// `dart:ui` in the real SDK; the analyzer_testing mocks expose it as
/// `package:ui/` or through flutter's painting library.
bool isUiLibrary(String? uri) =>
    uri != null &&
    (uri == 'dart:ui' ||
        uri.startsWith('package:ui/') ||
        uri.startsWith('package:flutter/'));

/// Whether [element] is the class [name] declared in a library accepted by
/// [libraryTest].
bool isElementNamed(
  Element? element,
  String name,
  bool Function(String? uri) libraryTest,
) =>
    element != null &&
    element.name == name &&
    libraryTest(libraryUriOf(element));

/// Whether [element] is, or has as a supertype, the class [name] from a
/// library accepted by [libraryTest].
bool isOrExtends(
  InterfaceElement element,
  String name,
  bool Function(String? uri) libraryTest,
) {
  if (isElementNamed(element, name, libraryTest)) return true;
  for (final supertype in element.allSupertypes) {
    if (isElementNamed(supertype.element, name, libraryTest)) return true;
  }
  return false;
}

/// `package:flutter/src/widgets/framework.dart` `Widget` (or a subclass).
bool isWidgetElement(InterfaceElement element) =>
    isOrExtends(element, 'Widget', isFlutterLibrary);

/// A type that denotes a widget: `Widget`, any subclass, or
/// `PreferredSizeWidget` (an interface that is not itself a `Widget`).
bool isWidgetLikeType(DartType? type) {
  if (type is! InterfaceType) return false;
  final element = type.element;
  return isWidgetElement(element) ||
      isOrExtends(element, 'PreferredSizeWidget', isFlutterLibrary);
}

/// `Widget`-like, or `List`/`Iterable` of `Widget`-like.
bool isWidgetOrWidgetCollectionType(DartType? type) {
  if (isWidgetLikeType(type)) return true;
  if (type is! InterfaceType) return false;
  final element = type.element;
  final isCollection =
      (element.name == 'List' || element.name == 'Iterable') &&
      libraryUriOf(element) == 'dart:core';
  if (!isCollection || type.typeArguments.length != 1) return false;
  return isWidgetLikeType(type.typeArguments.single);
}

/// `package:bloc` `BlocBase` subtype (every `Cubit` / `Bloc`).
bool isBlocBaseType(DartType? type) {
  if (type is! InterfaceType) return false;
  return isOrExtends(
    type.element,
    'BlocBase',
    (uri) => uri != null && uri.startsWith('package:bloc/'),
  );
}

/// `package:get_it` `GetIt` interface type.
bool isGetItType(DartType? type) {
  if (type is! InterfaceType) return false;
  return isOrExtends(
    type.element,
    'GetIt',
    (uri) => uri != null && uri.startsWith('package:get_it/'),
  );
}

/// The class element of an instance creation (`Foo(...)`, `Foo.named(...)`).
InterfaceElement? createdClass(InstanceCreationExpression node) {
  final element = node.constructorName.type.element;
  return element is InterfaceElement ? element : null;
}

/// The name of the constructor used, `null` for the unnamed constructor.
String? createdConstructorName(InstanceCreationExpression node) =>
    node.constructorName.name?.name;

/// Whether [node] carries an `@override` annotation.
bool hasOverrideAnnotation(AnnotatedNode node) =>
    node.metadata.any((annotation) => annotation.name.name == 'override');
