import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

import 'file_info.dart';

/// The resolved target of an `import` / `export` directive.
final class DirectiveTarget {
  const DirectiveTarget(this.uri, this.localPath);

  /// The URI exactly as written.
  final String uri;

  /// The package-relative posix path of the target when it lives inside the
  /// analyzed package (relative import or `package:<self>/`), else `null`.
  final String? localPath;

  bool get isDart => uri.startsWith('dart:');

  bool get isLocal => localPath != null;

  /// Whether this is a `package:` URI of another package named [name].
  bool isPackage(String name) => uri.startsWith('package:$name/');

  /// Whether [localPath] has a directory segment named [name].
  bool localHasDir(String name) {
    final path = localPath;
    if (path == null) return false;
    final segments = path.split('/');
    return segments.sublist(0, segments.length - 1).contains(name);
  }

  bool localContains(String fragment) => localPath?.contains(fragment) ?? false;

  bool localStartsWith(String prefix) => localPath?.startsWith(prefix) ?? false;
}

/// Resolves [directive] (an import or export) relative to [file].
DirectiveTarget? resolveDirective(NamespaceDirective directive, FileInfo file) {
  final uri = directive.uri.stringValue;
  if (uri == null || uri.isEmpty) return null;

  if (uri.startsWith('dart:')) return DirectiveTarget(uri, null);

  if (uri.startsWith('package:')) {
    final LibraryElement? library = switch (directive) {
      ImportDirective() => directive.libraryImport?.importedLibrary,
      ExportDirective() => directive.libraryExport?.exportedLibrary,
    };
    final resolvedPath = library?.firstFragment.source.fullName;
    if (resolvedPath != null) {
      final rel = file.relativize(resolvedPath);
      if (rel != null) return DirectiveTarget(uri, rel);
    }
    final self = file.packageName;
    if (self != null && uri.startsWith('package:$self/')) {
      return DirectiveTarget(
        uri,
        'lib/${uri.substring('package:$self/'.length)}',
      );
    }
    return DirectiveTarget(uri, null);
  }

  // Any other scheme (e.g. `dart-ext:`) is external.
  if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(uri)) {
    return DirectiveTarget(uri, null);
  }

  return DirectiveTarget(uri, file.resolveRelative(uri));
}
