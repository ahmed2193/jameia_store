import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'assistant_scroll_anchor.dart';

/// Wraps one chat row; the newest row ([isNewest]) reports its height to
/// [anchor] after every layout so the list can keep the reader's place
/// (see [AssistantScrollAnchor]). Other rows are plain pass-throughs.
class AssistantAnchoredItem extends SingleChildRenderObjectWidget {
  const AssistantAnchoredItem({
    super.key,
    required this.anchor,
    required this.rowKey,
    required this.isNewest,
    required super.child,
  });

  final AssistantScrollAnchor anchor;
  final String rowKey;
  final bool isNewest;

  @override
  RenderAssistantAnchoredItem createRenderObject(BuildContext context) =>
      RenderAssistantAnchoredItem(
        anchor: anchor,
        rowKey: rowKey,
        isNewest: isNewest,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderAssistantAnchoredItem renderObject,
  ) {
    renderObject
      ..anchor = anchor
      ..rowKey = rowKey
      ..isNewest = isNewest;
  }
}

/// The render side of [AssistantAnchoredItem]: sizes like its child and,
/// when it is the newest row, reports the new height with the old one.
class RenderAssistantAnchoredItem extends RenderProxyBox {
  RenderAssistantAnchoredItem({
    required this.anchor,
    required this.rowKey,
    required this.isNewest,
  });

  AssistantScrollAnchor anchor;
  String rowKey;
  bool isNewest;

  @override
  void performLayout() {
    final previous = hasSize ? size.height : null;
    super.performLayout();
    if (isNewest) anchor.report(rowKey, size.height, previous);
  }
}
