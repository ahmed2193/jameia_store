// Tails the Dart VM service `Logging` stream to stdout.
//
// `dart:developer` `log()` — the only logger this project allows — never shows
// in a plain `flutter run` terminal or in logcat. This prints it, so an agent
// without an IDE Debug Console can still read the `api` / `auth` / `sse` trace.
//
//   dart run vm_log_tail.dart <vm-service-ws-uri> [seconds] [name-filter]
//
//   <vm-service-ws-uri>  from the `flutter run` output line
//                        "A Dart VM Service ... is available at: http://127.0.0.1:PORT/TOKEN=/"
//                        → ws://127.0.0.1:PORT/TOKEN=/ws
//   [seconds]            how long to listen (default 60)
//   [name-filter]        comma-separated log names to keep, e.g. api,auth,sse
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: dart run vm_log_tail.dart <ws-uri> [seconds] [name,name]',
    );
    exit(64);
  }
  final seconds = args.length > 1 ? int.parse(args[1]) : 60;
  final names = args.length > 2 ? args[2].split(',').toSet() : const <String>{};

  final socket = await WebSocket.connect(_toWebSocketUri(args[0]));
  var id = 0;
  void send(String method, Map<String, Object?> params) => socket.add(
    jsonEncode({
      'jsonrpc': '2.0',
      'id': '${++id}',
      'method': method,
      'params': params,
    }),
  );

  send('streamListen', {'streamId': 'Logging'});
  socket.listen((raw) {
    final message = jsonDecode(raw as String) as Map<String, dynamic>;
    final event = (message['params'] as Map?)?['event'] as Map?;
    final record = event?['logRecord'] as Map?;
    if (record == null) return;
    final name = (record['loggerName'] as Map?)?['valueAsString'] ?? '';
    if (names.isNotEmpty && !names.contains(name)) return;
    final text = (record['message'] as Map?)?['valueAsString'] ?? '';
    stdout.writeln('[$name] $text');
  });

  await Future<void>.delayed(Duration(seconds: seconds));
  await socket.close();
}

/// Accepts the `http://…/TOKEN=/` form `flutter run` prints as well as `ws://`.
String _toWebSocketUri(String input) {
  var uri = input.trim();
  if (uri.startsWith('http://')) uri = 'ws://${uri.substring(7)}';
  if (uri.startsWith('https://')) uri = 'wss://${uri.substring(8)}';
  if (!uri.endsWith('/ws')) uri = uri.endsWith('/') ? '${uri}ws' : '$uri/ws';
  return uri;
}
