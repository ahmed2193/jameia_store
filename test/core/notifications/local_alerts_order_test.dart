// The newest call for a card wins: a post still drawing its ride picture
// when a cancel or a newer post for the same card comes in never reaches
// the shade.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/notifications/local_alerts.dart';

const int _rideId = 7;

LocalAlert _ride(String title, double progress) => LocalAlert(
  id: _rideId,
  channel: LocalAlertChannel.live,
  channelName: 'Live order tracking',
  title: title,
  body: 'Ali · 5 min',
  progress: progress,
  ongoing: true,
  track: LocalAlertTrack(progress: progress),
);

void main() {
  late _FakePlugin plugin;
  late List<Completer<Uint8List>> drawing;
  late PluginLocalAlerts alerts;

  Future<Uint8List> paint(LocalAlertTrack track) {
    final picture = Completer<Uint8List>();
    drawing.add(picture);
    return picture.future;
  }

  setUp(() {
    plugin = _FakePlugin();
    drawing = [];
    alerts = PluginLocalAlerts(plugin, paint);
  });

  test('a ride card posts once its picture is drawn', () async {
    final posting = alerts.show(_ride('On its way', 0.4));
    await pumpEventQueue();
    expect(plugin.posted, isEmpty);

    drawing.single.complete(Uint8List(1));
    await posting;

    expect(plugin.posted, ['On its way']);
  });

  test('a cancel while the picture is drawn keeps the card away', () async {
    final posting = alerts.show(_ride('On its way', 0.4));
    await pumpEventQueue();
    await alerts.cancel(_rideId);

    drawing.single.complete(Uint8List(1));
    await posting;

    expect(plugin.cancelled, [_rideId]);
    expect(plugin.posted, isEmpty);
  });

  test('only the newer of two posts in flight reaches the shade', () async {
    final older = alerts.show(_ride('Older', 0.4));
    final newer = alerts.show(_ride('Newer', 0.5));
    await pumpEventQueue();
    expect(drawing, hasLength(2));

    drawing.first.complete(Uint8List(1));
    await older;
    drawing.last.complete(Uint8List(1));
    await newer;

    expect(plugin.posted, ['Newer']);
  });

  test('a cancel for another card leaves this one alone', () async {
    final posting = alerts.show(_ride('On its way', 0.4));
    await pumpEventQueue();
    await alerts.cancel(_rideId + 1);

    drawing.single.complete(Uint8List(1));
    await posting;

    expect(plugin.posted, ['On its way']);
  });
}

/// The notification plugin on an Android phone, recording what would reach
/// the shade (no platform channel).
class _FakePlugin implements FlutterLocalNotificationsPlugin {
  final AndroidFlutterLocalNotificationsPlugin _android =
      AndroidFlutterLocalNotificationsPlugin();
  final List<String?> posted = [];
  final List<int> cancelled = [];

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() {
    final Object android = _android;
    if (android is T) return android;
    return null;
  }

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async => true;

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async => [];

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async => posted.add(title);

  @override
  Future<void> cancel({required int id, String? tag}) async =>
      cancelled.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
