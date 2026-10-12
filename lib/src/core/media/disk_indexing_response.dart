import 'dart:async';
import 'dart:io' show HttpStatus;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'image_body_stalled_exception.dart';
import 'image_disk_index.dart';
import 'image_net_activity.dart';

/// Tells [ImageDiskIndex] that [_url]'s file is on disk once that is certain:
/// a 304 keeps the file already there; a 200/202 body counts when its stream
/// completes without error (WebHelper writes it as it streams and records the
/// metadata right after: flutter_cache_manager 3.4.3 web_helper.dart:146-163).
/// Anything else marks nothing.
///
/// Also ends the GET's [ImageGetLease] (at the headers for a status with no
/// body to save; else when the body is done, failed or cancelled), and fails
/// a body silent for [bodyIdle]: dart:io has no read timeout, so a stalled
/// socket would pin a WebHelper slot (and a prefetch worker) forever. That is
/// an [ImageBodyStalledException]. Everything else is delegated untouched;
/// WebHelper reads [content] once.
class DiskIndexingResponse implements FileServiceResponse {
  DiskIndexingResponse(this._inner, this._url, this._lease) {
    final int code = _inner.statusCode;
    if (code == HttpStatus.notModified) {
      ImageDiskIndex.instance.markDownloaded(_url);
    }
    if (code != HttpStatus.ok && code != HttpStatus.accepted) _lease?.end();
  }

  /// Longest silence a 200/202 body may keep before it fails.
  static const Duration bodyIdle = Duration(seconds: 15);

  final FileServiceResponse _inner;
  final String _url;
  final ImageGetLease? _lease;

  @override
  Stream<List<int>> get content {
    final int code = _inner.statusCode;
    if (code != HttpStatus.ok && code != HttpStatus.accepted) {
      return _inner.content;
    }
    // Not `Stream.timeout`: its onCancel future (and that of an onCancel
    // forwarding a finished subscription's cancel) delays `done`.
    bool failed = false, ended = false;
    StreamSubscription<List<int>>? sub;
    Timer? idle;
    late final StreamController<List<int>> out;
    void end() {
      ended = true;
      idle?.cancel();
      _lease?.end();
    }

    void arm() {
      idle?.cancel();
      if (ended) return;
      idle = Timer(bodyIdle, () {
        failed = true;
        end();
        out.addError(
          ImageBodyStalledException(
            'Image body stalled for ${bodyIdle.inSeconds}s',
            Uri.parse(_url),
          ),
        );
        unawaited(sub?.cancel());
        out.close();
      });
    }

    out = StreamController<List<int>>(
      sync: true,
      onListen: () {
        arm();
        sub = _inner.content.listen(
          (List<int> chunk) {
            arm();
            out.add(chunk);
          },
          onError: (Object e, StackTrace st) {
            failed = true;
            arm();
            out.addError(e, st);
          },
          onDone: () {
            if (!failed) ImageDiskIndex.instance.markDownloaded(_url);
            end();
            out.close();
          },
        );
      },
      onPause: () {
        idle?.cancel(); // our consumer's back-pressure is not a stall
        sub?.pause();
      },
      onResume: () {
        sub?.resume();
        arm();
      },
      onCancel: () {
        if (ended) return null;
        end();
        return sub?.cancel();
      },
    );
    return out.stream;
  }

  @override
  int? get contentLength => _inner.contentLength;

  @override
  int get statusCode => _inner.statusCode;

  @override
  DateTime get validTill => _inner.validTill;

  @override
  String? get eTag => _inner.eTag;

  @override
  String get fileExtension => _inner.fileExtension;
}
