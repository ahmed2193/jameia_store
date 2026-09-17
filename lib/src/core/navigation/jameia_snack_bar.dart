import 'package:flutter/material.dart';

/// The one way to show a transient message: replaces any snack bar still on
/// screen so rapid taps never queue a backlog.
void showJameiaSnackBar(
  BuildContext context,
  String message, {
  SnackBarBehavior? behavior,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(behavior: behavior, content: Text(message)));
}
