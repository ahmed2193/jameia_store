import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:path/path.dart' as p;

/// Location facts about the compilation unit currently being analyzed.
///
/// Every rule scopes itself by the unit's path relative to its package root,
/// always in posix form (`lib/src/features/home/presentation/pages/x.dart`),
/// so Windows `\` separators and drive-letter casing never matter.
final class FileInfo {
  FileInfo._(this.absolutePath, this.relPath, this._rootPath, this.packageName);

  /// The absolute path, posix separators.
  final String absolutePath;

  /// The path relative to the package root, posix separators.
  final String relPath;

  /// The package root, posix separators, or `null` when unknown.
  final String? _rootPath;

  /// The `name:` from the package's pubspec, when readable.
  final String? packageName;

  static final Map<String, FileInfo> _cache = {};
  static final Map<String, String?> _packageNames = {};

  /// Resolves the [FileInfo] for the unit currently visited in [context].
  static FileInfo of(RuleContext context) {
    final unit = context.currentUnit ?? context.definingUnit;
    final rawPath = unit.file.path;
    final cached = _cache[rawPath];
    if (cached != null) return cached;

    final absolute = toPosix(rawPath);
    final package = context.package;
    String? root = package == null ? null : toPosix(package.root.path);
    String rel;
    if (root != null && _startsWithPath(absolute, root)) {
      rel = absolute.substring(root.length + 1);
    } else {
      // Fallback: anchor on the `lib/` folder of the containing package.
      var index = absolute.indexOf('/lib/src/');
      if (index < 0) index = absolute.lastIndexOf('/lib/');
      if (index >= 0) {
        root = absolute.substring(0, index);
        rel = absolute.substring(index + 1);
      } else {
        root = null;
        rel = absolute;
      }
    }

    String? packageName;
    if (package != null) {
      final rootKey = package.root.path;
      packageName = _packageNames.putIfAbsent(rootKey, () {
        try {
          final pubspec = package.root.getFile('pubspec.yaml');
          if (!pubspec.exists) return null;
          final match = RegExp(
            r'^name:\s*([A-Za-z0-9_]+)',
            multiLine: true,
          ).firstMatch(pubspec.readAsStringSync());
          return match?.group(1);
        } on Exception {
          return null;
        }
      });
    }

    final info = FileInfo._(absolute, rel, root, packageName);
    _cache[rawPath] = info;
    return info;
  }

  /// Converts any path to posix separators.
  static String toPosix(String path) => path.replaceAll(r'\', '/');

  static bool _startsWithPath(String path, String root) {
    if (path.length <= root.length) return false;
    if (path[root.length] != '/') return false;
    final head = path.substring(0, root.length);
    // Windows paths are case-insensitive (drive letters especially).
    return head == root || head.toLowerCase() == root.toLowerCase();
  }

  late final List<String> segments = relPath.split('/');

  /// The file name, e.g. `home_page.dart`.
  String get fileName => segments.last;

  /// The directory segments (everything but the file name).
  List<String> get dirSegments => segments.sublist(0, segments.length - 1);

  bool get isInLib => relPath.startsWith('lib/');

  bool get isInLibSrc => relPath.startsWith('lib/src/');

  bool isUnder(String prefix) => relPath.startsWith(prefix);

  /// Whether one of the *directories* of this file is named [name].
  bool hasDir(String name) => dirSegments.contains(name);

  /// `home` for `lib/src/features/home/...`, else `null`.
  String? get featureName => featureOf(relPath);

  /// The part after `lib/src/features/<f>/`, else `null`.
  String? get featureRelPath => featureRelPathOf(relPath);

  /// `lib/src/features/<f>/presentation/**`.
  bool get isFeaturePresentation =>
      featureRelPath?.startsWith('presentation/') ?? false;

  /// Presentation code checked by the UI rules: feature presentation layers
  /// plus the shared `core/widgets` kit.
  bool get isUiScope =>
      isFeaturePresentation || relPath.startsWith('lib/src/core/widgets/');

  bool get isInjectionContainer =>
      fileName.endsWith('_injection_container.dart');

  /// Converts an absolute path to a package-relative posix path, or `null`
  /// when it lies outside this package.
  String? relativize(String absolutePath) {
    final root = _rootPath;
    if (root == null) return null;
    final posix = toPosix(absolutePath);
    if (!_startsWithPath(posix, root)) return null;
    return posix.substring(root.length + 1);
  }

  /// Resolves a relative URI against this file, returning a package-relative
  /// posix path (or `null` when it escapes the package root).
  String? resolveRelative(String uri) {
    final joined = p.posix.normalize(
      p.posix.join(p.posix.dirname(relPath), Uri.decodeFull(uri)),
    );
    if (joined.startsWith('../') || joined == '..') return null;
    return joined;
  }

  static String? featureOf(String relPath) {
    const prefix = 'lib/src/features/';
    if (!relPath.startsWith(prefix)) return null;
    final rest = relPath.substring(prefix.length);
    final slash = rest.indexOf('/');
    if (slash <= 0) return null;
    return rest.substring(0, slash);
  }

  static String? featureRelPathOf(String relPath) {
    final feature = featureOf(relPath);
    if (feature == null) return null;
    return relPath.substring('lib/src/features/$feature/'.length);
  }
}
