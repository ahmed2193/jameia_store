import 'dart:io';

/// Errors swallowed by [guarded], newest last (capped). Tests assert this
/// stays empty; in the analysis server nothing reads it.
final List<Object> guardedErrors = [];

/// When the analysis server is started with this environment variable set to
/// a file path, swallowed rule errors are appended there (plugins cannot
/// `print`). Example: `ARCHITECTURE_LINTS_ERROR_LOG=C:\tmp\arch.log dart analyze`.
const _errorLogVariable = 'ARCHITECTURE_LINTS_ERROR_LOG';

/// Runs a rule's visit body without ever crashing the analysis isolate.
///
/// The plugin server propagates visitor exceptions, which would abort every
/// architecture_lints rule for the rest of that library. An unexpected error
/// therefore only drops the one diagnostic being computed; it is recorded in
/// [guardedErrors] (and the optional error log) so it can still be found.
void guarded(void Function() body) {
  try {
    body();
  } catch (error, stackTrace) {
    if (guardedErrors.length >= 50) guardedErrors.removeAt(0);
    guardedErrors.add(error);
    _log(error, stackTrace);
  }
}

void _log(Object error, StackTrace stackTrace) {
  try {
    final path = Platform.environment[_errorLogVariable];
    if (path == null || path.isEmpty) return;
    File(path).writeAsStringSync(
      '${DateTime.now().toIso8601String()} $error\n$stackTrace\n',
      mode: FileMode.append,
      flush: true,
    );
  } on Object {
    // Logging must never throw inside the analysis server.
  }
}
