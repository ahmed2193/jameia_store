import 'package:flutter/material.dart';

/// Shared SnackBar helper for the tracking screen stubs.
void trackingToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
