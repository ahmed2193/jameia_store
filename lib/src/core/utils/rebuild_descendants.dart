import 'package:flutter/widgets.dart';

/// Rebuilds everything below [context] in the next frame, in place: every
/// element is marked dirty, so every `build` runs again — const widgets and
/// offstage routes included — while every `State`, scroll position,
/// controller and page cubit stays as it is.
///
/// Made for a language switch: easy_localization's `.tr()` reads a global,
/// not the context, so a widget that does not depend on the locale (a const
/// one, or one under a parent that did not rebuild) would keep its
/// old-language text. One full rebuild re-resolves every string; re-creating
/// the subtrees instead would throw their state away (scroll, loaded data,
/// cubits) and start every request again.
///
/// Call it outside a build — from a listener or a callback.
void rebuildDescendants(BuildContext context) {
  void mark(Element element) {
    element.markNeedsBuild();
    element.visitChildren(mark);
  }

  context.visitChildElements(mark);
}
