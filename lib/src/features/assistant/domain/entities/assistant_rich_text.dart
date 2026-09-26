import 'package:equatable/equatable.dart';

import 'assistant_text_direction.dart';

/// A run of characters with one style.
class AssistantTextRun extends Equatable {
  const AssistantTextRun(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  List<Object?> get props => [text, bold];
}

enum AssistantRichBlockKind { paragraph, heading, bullet, numbered }

/// One paragraph, heading or list item of an assistant reply.
class AssistantRichBlock extends Equatable {
  const AssistantRichBlock({
    required this.kind,
    required this.runs,
    this.marker = '',
    this.isRtl,
  });

  final AssistantRichBlockKind kind;
  final List<AssistantTextRun> runs;

  /// `3.` for a numbered item (the number as the model wrote it); `''`
  /// otherwise.
  final String marker;

  /// The block's own reading direction (`AssistantTextDirection`); `null`
  /// when it has none — follow the surrounding direction.
  final bool? isRtl;

  bool get isListItem =>
      kind == AssistantRichBlockKind.bullet ||
      kind == AssistantRichBlockKind.numbered;

  String get text => runs.map((run) => run.text).join();

  /// What a list item is drawn after: `•` or the number as written.
  String get displayMarker => kind == AssistantRichBlockKind.bullet
      ? AssistantRichText.bulletGlyph
      : marker;

  @override
  List<Object?> get props => [kind, runs, marker, isRtl];
}

/// The light markdown the assistant writes (`text` blocks, ≤ 8000 chars),
/// parsed ONCE per text change — in the cubit's flush, never in `build`.
///
/// Supported: paragraphs (blank-line separated; single line breaks kept),
/// `#` headings, `-` / `*` / `•` bullets, `1.` / `1)` numbered items,
/// `**bold**`. Links `[label](url)` keep their label only (the app opens no
/// external URLs), inline code and `*emphasis*` markers are dropped.
///
/// Streaming-safe: an unclosed `**` makes the rest of its block bold instead
/// of printing the asterisks, so the text does not flicker between the half
/// and the closed marker, and a dangling `-` / `1.` is hidden until its
/// text arrives.
class AssistantRichText extends Equatable {
  const AssistantRichText._(this.blocks);

  static const AssistantRichText empty = AssistantRichText._([]);

  final List<AssistantRichBlock> blocks;

  bool get isEmpty => blocks.isEmpty;

  /// The reply's reading direction: its first block that has one.
  bool? get isRtl {
    for (final block in blocks) {
      if (block.isRtl != null) return block.isRtl;
    }
    return null;
  }

  factory AssistantRichText.parse(String source) {
    final builder = _BlockBuilder();
    for (final line in source.replaceAll('\r\n', '\n').split('\n')) {
      builder.addLine(line);
    }
    return AssistantRichText._(List.unmodifiable(builder.finish()));
  }

  /// The visible text without markdown markers — what "Copy" puts on the
  /// clipboard. List items keep a `•` / `1.` prefix.
  String get plainText {
    final buffer = StringBuffer();
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (i > 0) {
        final tight = block.isListItem && blocks[i - 1].isListItem;
        buffer.write(tight ? '\n' : '\n\n');
      }
      switch (block.kind) {
        case AssistantRichBlockKind.bullet:
          buffer.write('$bulletGlyph ');
        case AssistantRichBlockKind.numbered:
          buffer.write('${block.marker} ');
        case AssistantRichBlockKind.paragraph:
        case AssistantRichBlockKind.heading:
          break;
      }
      buffer.write(block.text);
    }
    return buffer.toString();
  }

  static const String bulletGlyph = '•';

  @override
  List<Object?> get props => [blocks];
}

class _BlockBuilder {
  static final RegExp _heading = RegExp(r'^\s{0,3}#{1,6}\s+(.*)$');
  static final RegExp _bullet = RegExp(r'^\s*[-*•](?:\s+(.*))?$');
  static final RegExp _numbered = RegExp(r'^\s*(\d{1,3})[.)]\s+(.*)$');
  static final RegExp _rule = RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$');
  static final RegExp _indented = RegExp(r'^\s{2,}\S');

  final List<AssistantRichBlock> _done = [];
  AssistantRichBlockKind? _kind;
  String _marker = '';
  final List<String> _lines = [];

  void addLine(String line) {
    if (line.trim().isEmpty) {
      _close();
      return;
    }
    if (_rule.hasMatch(line)) {
      _close();
      return;
    }
    final heading = _heading.firstMatch(line);
    if (heading != null) {
      _close();
      _open(AssistantRichBlockKind.heading, heading.group(1)!);
      _close();
      return;
    }
    final numbered = _numbered.firstMatch(line);
    if (numbered != null) {
      _close();
      _open(
        AssistantRichBlockKind.numbered,
        numbered.group(2)!,
        marker: '${numbered.group(1)}.',
      );
      return;
    }
    final bullet = _bullet.firstMatch(line);
    if (bullet != null && !line.trimLeft().startsWith('**')) {
      _close();
      _open(AssistantRichBlockKind.bullet, bullet.group(1) ?? '');
      return;
    }
    final continuesItem =
        (_kind == AssistantRichBlockKind.bullet ||
            _kind == AssistantRichBlockKind.numbered) &&
        _indented.hasMatch(line);
    if (_kind == AssistantRichBlockKind.paragraph || continuesItem) {
      _lines.add(continuesItem ? line.trim() : line.trimRight());
      return;
    }
    _close();
    _open(AssistantRichBlockKind.paragraph, line.trimRight());
  }

  List<AssistantRichBlock> finish() {
    _close();
    return _done;
  }

  void _open(
    AssistantRichBlockKind kind,
    String firstLine, {
    String marker = '',
  }) {
    _kind = kind;
    _marker = marker;
    _lines
      ..clear()
      ..add(firstLine);
  }

  void _close() {
    final kind = _kind;
    if (kind == null) return;
    final joiner = kind == AssistantRichBlockKind.paragraph ? '\n' : ' ';
    final runs = _InlineParser.parse(_lines.join(joiner).trim());
    // An empty block — a dangling `-` / `1.` mid-stream — is not drawn until
    // its text arrives (no empty bullet flashing in).
    if (runs.isNotEmpty) {
      _done.add(
        AssistantRichBlock(
          kind: kind,
          runs: runs,
          marker: _marker,
          isRtl: AssistantTextDirection.isRtl(runs.map((r) => r.text).join()),
        ),
      );
    }
    _kind = null;
    _marker = '';
    _lines.clear();
  }
}

abstract final class _InlineParser {
  static const String _boldMarker = '**';
  static final RegExp _link = RegExp(r'\[([^\]\n]+)\]\([^)\s]*\)');
  static final RegExp _code = RegExp('`([^`\n]*)`');
  static final RegExp _emphasis = RegExp(
    r'(?<![*\w])\*(?![\s*])([^*\n]+?)(?<!\s)\*(?![*\w])',
  );

  static List<AssistantTextRun> parse(String text) {
    final cleaned = text
        .replaceAllMapped(_link, (m) => m.group(1)!)
        .replaceAllMapped(_code, (m) => m.group(1)!)
        .replaceAllMapped(_emphasis, (m) => m.group(1)!);
    final parts = cleaned.split(_boldMarker);
    final runs = <AssistantTextRun>[];
    for (var i = 0; i < parts.length; i++) {
      // Odd parts sit between two markers — or after an unclosed one, which
      // stays bold to the end of the block (streaming-safe).
      _append(runs, parts[i], bold: i.isOdd);
    }
    return runs;
  }

  static void _append(
    List<AssistantTextRun> runs,
    String text, {
    required bool bold,
  }) {
    if (text.isEmpty) return;
    if (runs.isNotEmpty && runs.last.bold == bold) {
      runs[runs.length - 1] = AssistantTextRun(
        runs.last.text + text,
        bold: bold,
      );
      return;
    }
    runs.add(AssistantTextRun(text, bold: bold));
  }
}
