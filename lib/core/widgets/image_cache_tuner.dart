import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Adaptive image-cache sizer.
///
/// Picks an initial `PaintingBinding.imageCache` budget from total RAM, then
/// narrows it under memory pressure. Three signals drive it:
///   1. MemTotal              → baseline tier (low / mid / high)
///   2. MemAvailable at start → step the baseline down if already short on RAM
///   3. Memory-pressure cb    → soft-shrink to 50% for a window; permanent
///                              tier-down only if pressure repeats.
///
/// NEVER calls `imageCache.clear()` — trimming the budget evicts only the
/// least-recently-used *cached* bitmaps; on-screen images (with a live
/// ImageStream) are untouched and re-decode instantly from the 365-day disk
/// cache with no network round-trip.
class ImageCacheTuner {
  ImageCacheTuner._();

  static bool _installed = false;
  static _CacheTier _activeTier = _CacheTier.mid;
  static bool _shrunk = false;
  static DateTime? _lastPressureAt;
  static Timer? _restoreTimer;

  static const double _shrinkFactor = 0.5;
  static const Duration _pressureWindow = Duration(seconds: 90);
  static const Duration _restoreAfter = Duration(seconds: 90);

  static Future<void> install() async {
    if (_installed) return;
    _installed = true;

    _activeTier = await _pickTier();
    _applyTier(_activeTier);

    if (kDebugMode) {
      debugPrint('[ImageCacheTuner] tier=${_activeTier.name} '
          'maxBytes=${(_activeTier.bytes / 1024 / 1024).toStringAsFixed(0)}MB '
          'maxCount=${_activeTier.count}');
    }

    WidgetsBinding.instance.addObserver(_MemoryPressureObserver());
  }

  static void _applyTier(_CacheTier tier, {double factor = 1.0}) {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSizeBytes = (tier.bytes * factor).round();
    cache.maximumSize = (tier.count * factor).round();
  }

  static Future<_CacheTier> _pickTier() async {
    final ram = await _readMeminfo();
    if (ram.totalGb <= 0) return _CacheTier.mid;

    _CacheTier baseline;
    if (ram.totalGb <= 2) {
      baseline = _CacheTier.low;
    } else if (ram.totalGb <= 4) {
      baseline = _CacheTier.mid;
    } else {
      baseline = _CacheTier.high;
    }

    if (ram.availableGb > 0 && ram.availableGb < ram.totalGb * 0.25) {
      final stepped = baseline == _CacheTier.high
          ? _CacheTier.mid
          : baseline == _CacheTier.mid
              ? _CacheTier.low
              : baseline;
      if (kDebugMode && stepped != baseline) {
        debugPrint(
            '[ImageCacheTuner] low headroom → stepping down to ${stepped.name}');
      }
      return stepped;
    }
    return baseline;
  }

  static Future<_MemInfo> _readMeminfo() async {
    try {
      if (Platform.isAndroid) {
        final f = File('/proc/meminfo');
        if (await f.exists()) {
          final lines = await f.readAsLines();
          double total = -1, available = -1;
          for (final l in lines) {
            if (l.startsWith('MemTotal:')) {
              total = _parseLineGb(l);
            } else if (l.startsWith('MemAvailable:')) {
              available = _parseLineGb(l);
            }
            if (total >= 0 && available >= 0) break;
          }
          return _MemInfo(total, available);
        }
      }
    } on PlatformException catch (_) {
    } catch (_) {}
    return const _MemInfo(-1, -1);
  }

  static double _parseLineGb(String line) {
    final m = RegExp(r'(\d+)').firstMatch(line);
    if (m == null) return -1;
    final kb = int.parse(m.group(1)!);
    return kb / 1024 / 1024;
  }

  static void _onMemoryPressure() {
    final now = DateTime.now();
    final isRepeat = _lastPressureAt != null &&
        now.difference(_lastPressureAt!) < _pressureWindow;
    _lastPressureAt = now;

    if (isRepeat && _activeTier != _CacheTier.low) {
      _activeTier =
          _activeTier == _CacheTier.high ? _CacheTier.mid : _CacheTier.low;
      _shrunk = false;
      _restoreTimer?.cancel();
      _applyTier(_activeTier);
      if (kDebugMode) {
        debugPrint('[ImageCacheTuner] repeat pressure → '
            'permanent tier-down to ${_activeTier.name}');
      }
    } else {
      _shrunk = true;
      _applyTier(_activeTier, factor: _shrinkFactor);
      _restoreTimer?.cancel();
      _restoreTimer = Timer(_restoreAfter, () {
        _shrunk = false;
        _applyTier(_activeTier);
        if (kDebugMode) {
          debugPrint('[ImageCacheTuner] budget restored to ${_activeTier.name}');
        }
      });
    }
  }

  static void _onLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _shrunk) {
      _shrunk = false;
      _restoreTimer?.cancel();
      _applyTier(_activeTier);
      if (kDebugMode) debugPrint('[ImageCacheTuner] resumed → budget restored');
    }
  }
}

class _MemInfo {
  final double totalGb;
  final double availableGb;
  const _MemInfo(this.totalGb, this.availableGb);
}

class _CacheTier {
  final String name;
  final int bytes;
  final int count;
  const _CacheTier(this.name, this.bytes, this.count);

  static const low = _CacheTier('low', 80 << 20, 800);
  static const mid = _CacheTier('mid', 160 << 20, 1500);
  static const high = _CacheTier('high', 256 << 20, 2400);
}

class _MemoryPressureObserver with WidgetsBindingObserver {
  @override
  void didHaveMemoryPressure() => ImageCacheTuner._onMemoryPressure();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      ImageCacheTuner._onLifecycle(state);
}
