import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../config/theme/app_colors.dart';
import 'local_alert_track_picture.dart';

/// Which shelf of the notification shade an alert goes on.
enum LocalAlertChannel {
  /// A quiet, ongoing card that follows a live task (no sound, no pop-up;
  /// updates in place).
  live('live_tracking'),

  /// A moment that matters (sound + heads-up pop-up).
  updates('order_updates'),

  /// A message from a person (sound + heads-up pop-up, filed as a message).
  messages('rider_messages');

  const LocalAlertChannel(this.id);

  /// The Android channel id (the customer tunes each in system settings).
  final String id;
}

/// A trip drawn on a live card: from its start to its end, [progress]
/// (0 → 1) of the way along ([LocalAlertTrackPicture]).
@immutable
class LocalAlertTrack {
  const LocalAlertTrack({required this.progress, this.rightToLeft = false});

  final double progress;

  /// The reader reads right to left: the trip runs that way too.
  final bool rightToLeft;
}

/// One notification the app posts itself (no server push), with the texts
/// already in the customer's language.
@immutable
class LocalAlert {
  const LocalAlert({
    required this.id,
    required this.channel,
    required this.channelName,
    required this.title,
    required this.body,
    this.subText,
    this.progress,
    this.dueAt,
    this.ongoing = false,
    this.track,
  });

  /// Posting the same id again updates the card in place.
  final int id;
  final LocalAlertChannel channel;

  /// The channel's name, shown in the phone's notification settings.
  final String channelName;
  final String title;
  final String body;

  /// A short line in the card's header (an order number).
  final String? subText;

  /// How far along (0 → 1), drawn as a bar; `null` = no bar.
  final double? progress;

  /// When the task is due: the card counts down to it by itself, between
  /// updates (Android).
  final DateTime? dueAt;

  /// Cannot be swiped away while the task lasts.
  final bool ongoing;

  /// The trip, drawn when the card is expanded (Android); `null` = none.
  final LocalAlertTrack? track;
}

/// The phone's notification shade, for the app's own alerts. Used only from
/// a datasource (like `SessionStore`). Best effort: a failure is logged and
/// the app goes on — a notification is never worth an error on screen.
abstract class LocalAlerts {
  /// Whether the customer lets the app post notifications.
  Future<bool> allowed();

  /// Asks for that (Android 13+, iOS); `true` when granted.
  Future<bool> ask();

  /// Posts [alert], or updates the card with its id.
  Future<void> show(LocalAlert alert);

  /// Takes the card [id] away.
  Future<void> cancel(int id);
}

/// Draws a live card's trip as a PNG ([LocalAlertTrackPicture.render]).
typedef LocalAlertTrackPainter = Future<Uint8List> Function(LocalAlertTrack);

class PluginLocalAlerts implements LocalAlerts {
  PluginLocalAlerts([
    FlutterLocalNotificationsPlugin? plugin,
    this._paint = LocalAlertTrackPicture.render,
  ]) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final LocalAlertTrackPainter _paint;
  Future<bool>? _ready;

  /// The latest post or cancel per card id. A post still drawing its
  /// picture when a newer post or a cancel for its id comes in is dropped:
  /// the newest call always wins, so a card that was taken away never
  /// comes back.
  final Map<int, int> _turns = {};

  int _nextTurn(int id) => _turns[id] = (_turns[id] ?? 0) + 1;

  /// The monochrome Hero mark (`res/drawable/ic_stat_hero.xml`).
  static const String smallIcon = 'ic_stat_hero';
  static const int _progressSteps = 100;

  /// How long an ongoing card outlives its due time (or its last update):
  /// if the app is killed before it takes the card away (Android kills an
  /// app in the background when memory runs short), the phone does — soon,
  /// as a card that cannot be swiped away must not outstay the ride. A live
  /// app posts the card again on every fix, which pushes this back.
  static const Duration ongoingGrace = Duration(minutes: 2);
  static const String _logName = 'alerts';

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  /// Initialises once; permissions are asked in context, never here.
  Future<bool> _init() => _ready ??= _guard(() async {
    final ready = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(smallIcon),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (ready ?? false) await _clearLeftovers();
    return ready ?? false;
  }, false);

  /// Live cards an earlier, killed run of the app left up (Android): their
  /// task ended with that run, so they go on the first use in this one.
  Future<void> _clearLeftovers() async {
    if (_android == null) return;
    for (final card in await _plugin.getActiveNotifications()) {
      final id = card.id;
      if (id != null && card.channelId == LocalAlertChannel.live.id) {
        await _plugin.cancel(id: id);
      }
    }
  }

  @override
  Future<bool> allowed() => _guard(() async {
    if (!await _init()) return false;
    final android = _android;
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return (await _ios?.checkPermissions())?.isEnabled ?? false;
  }, false);

  @override
  Future<bool> ask() => _guard(() async {
    if (!await _init()) return false;
    final android = _android;
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return await _ios?.requestPermissions(alert: true, sound: true) ?? false;
  }, false);

  @override
  Future<void> show(LocalAlert alert) => _guard(() async {
    // Taken before the first await, so turns follow the call order.
    final turn = _nextTurn(alert.id);
    if (!await _init()) return;
    final live = alert.channel == LocalAlertChannel.live;
    final track = alert.track;
    final picture = track == null || _android == null
        ? null
        : await _pictureOf(track);
    final progress = alert.progress;
    final dueAt = alert.dueAt;
    final left = dueAt?.difference(DateTime.now()) ?? Duration.zero;
    final timeout = alert.ongoing
        ? (left.isNegative ? Duration.zero : left) + ongoingGrace
        : null;
    // A newer post or a cancel came in while the picture was drawn.
    if (_turns[alert.id] != turn) return;
    await _plugin.show(
      id: alert.id,
      title: alert.title,
      body: alert.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          alert.channel.id,
          alert.channelName,
          icon: smallIcon,
          color: AppColors.primary,
          importance: live ? Importance.low : Importance.high,
          priority: live ? Priority.low : Priority.high,
          category: switch (alert.channel) {
            LocalAlertChannel.live => AndroidNotificationCategory.progress,
            LocalAlertChannel.updates => AndroidNotificationCategory.status,
            LocalAlertChannel.messages => AndroidNotificationCategory.message,
          },
          styleInformation: picture == null
              ? BigTextStyleInformation(alert.body)
              : BigPictureStyleInformation(
                  ByteArrayAndroidBitmap(picture),
                  contentTitle: alert.title,
                  summaryText: alert.body,
                  hideExpandedLargeIcon: true,
                ),
          ongoing: alert.ongoing,
          autoCancel: !alert.ongoing,
          timeoutAfter: timeout?.inMilliseconds,
          onlyAlertOnce: live,
          silent: live,
          subText: alert.subText,
          showProgress: progress != null,
          maxProgress: _progressSteps,
          progress: ((progress ?? 0).clamp(0, 1) * _progressSteps).round(),
          when: dueAt?.millisecondsSinceEpoch,
          showWhen: dueAt != null,
          usesChronometer: dueAt != null,
          chronometerCountDown: dueAt != null,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: !live,
          presentBanner: !live,
          presentList: true,
          presentSound: !live,
          subtitle: alert.subText,
          interruptionLevel: live
              ? InterruptionLevel.passive
              : InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }, null);

  /// [track] drawn, or `null` when it cannot be (the card goes without).
  Future<Uint8List?> _pictureOf(LocalAlertTrack track) async {
    try {
      return await _paint(track);
    } catch (error) {
      log('ride picture failed: $error', name: _logName);
      return null;
    }
  }

  @override
  Future<void> cancel(int id) => _guard(() async {
    // Drops any post for [id] still drawing its picture.
    _nextTurn(id);
    if (!await _init()) return;
    await _plugin.cancel(id: id);
  }, null);

  static Future<T> _guard<T>(Future<T> Function() run, T fallback) async {
    try {
      return await run();
    } catch (error) {
      log('notification failed: $error', name: _logName);
      return fallback;
    }
  }
}
