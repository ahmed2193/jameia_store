import 'dart:convert';
import 'dart:io';

import 'package:hero_mart/src/core/network/event_stream_client.dart';

/// Readers for the saved assistant payloads:
/// - `fixtures/live_2026_09_24/` — real captures from api.jm3eia.store
///   (SSE turns as `[{ms, event, data, comment}]`, full envelopes);
/// - `fixtures/mock_blocks.json` — one block of every kind (spec-shaped).
abstract final class AssistantFixtures {
  static const String _root = 'test/features/assistant/fixtures';
  static const String _live = '$_root/live_2026_09_24';

  static Object? _read(String path) =>
      jsonDecode(File(path).readAsStringSync());

  /// A saved envelope (`conversation_detail_en.json` …).
  static Map<String, dynamic> liveEnvelope(String name) =>
      (_read('$_live/$name') as Map).cast<String, dynamic>();

  /// The `results` of a saved envelope.
  static Map<String, dynamic> liveResults(String name) =>
      (liveEnvelope(name)['results'] as Map).cast<String, dynamic>();

  /// The frames of a saved SSE turn as the client yields them: the
  /// `: connected` comment is dropped (the real parser never emits it).
  static List<ServerSentEvent> liveFrames(String name) => [
    for (final raw in _read('$_live/$name') as List)
      if ((raw as Map)['comment'] == null)
        ServerSentEvent(
          event: raw['event'] as String,
          data: raw['data'] as String,
        ),
  ];

  /// The same frames as raw `text/event-stream` bytes, comment included.
  static String liveWire(String name) {
    final buffer = StringBuffer();
    for (final raw in _read('$_live/$name') as List) {
      final frame = raw as Map;
      final comment = frame['comment'];
      if (comment != null) {
        buffer.write('$comment\n\n');
        continue;
      }
      buffer.write('event: ${frame['event']}\ndata: ${frame['data']}\n\n');
    }
    return buffer.toString();
  }

  static const List<String> liveTurns = [
    'sse_text_actions_en.json',
    'sse_products_en.json',
    'sse_cart_action_persist_error_en.json',
    'sse_cart_action_persist_error_ar.json',
    'sse_delivery_info_empty_en.json',
    'sse_recipe_offers_en.json',
  ];

  /// Every block of `mock_blocks.json`, raw.
  static List<Object?> mockBlocks() =>
      ((_read('$_root/mock_blocks.json') as Map)['blocks'] as List)
          .cast<Object?>();
}
