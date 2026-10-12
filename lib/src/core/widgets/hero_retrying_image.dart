import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import '../media/hero_image_cache_manager.dart';
import '../media/image_load_policy.dart';
import '../media/image_request.dart';
import '../media/image_retry_machine.dart';
import '../motion/motion.dart';
import 'hero_image_attempt_key.dart';
import 'hero_image_load_session.dart';
import 'hero_image_loading_placeholder.dart';
import 'hero_image_shape.dart';

/// `HeroImage`'s network load: `CachedNetworkImage` under ONE load decision
/// per (cacheKey, decode size) ([HeroImageLoadSession], whose plan picks the
/// loading look: RAM → none, disk → the still box, variant → a cached other
/// size, network → the still box then the shimmer after 300 ms) and an
/// unconditional retry loop ([ImageRetryMachine]). Its parent keys it by the
/// ASSET: a size or URL change of the same image updates this state (a new
/// file resets the retry machine) and octo_image's gapless path keeps the
/// old pixels until the new size decodes. Ported from the reference's
/// `_RetryingNetworkImage` (jm3eia_mobile `app_image.dart`).
class HeroRetryingImage extends StatefulWidget {
  const HeroRetryingImage({
    super.key,
    required this.request,
    required this.fit,
    required this.shape,
    this.width,
    this.height,
  });

  final ImageRequest request;
  final BoxFit fit;

  /// The tile's box and corners, for every loading look.
  final HeroImageShape shape;

  /// The explicit size handed to the image (null = from the layout).
  final double? width;
  final double? height;

  /// Past this many attempts the retry shimmer freezes (~2 min of fast
  /// retries: the tile is almost certainly broken and nobody watches it
  /// load); the retries go on.
  static const int freezeShimmerAtAttempt = 8;

  /// Every pending backoff retries now (the reconnect hook).
  static void retryAllNow() => ImageRetryMachine.retryAllNow();

  @override
  State<HeroRetryingImage> createState() => _HeroRetryingImageState();
}

class _HeroRetryingImageState extends State<HeroRetryingImage>
    implements ImageRetryHost, HeroImageLoadTile {
  late final ImageRetryMachine _retry = ImageRetryMachine(this);
  late final HeroImageLoadSession _load = HeroImageLoadSession(this);

  @override
  ImageRequest get request => widget.request;

  @override
  int get attempt => _retry.attempt;

  @override
  bool get alive => mounted;

  @override
  String get retryKey => request.cacheKey;

  @override
  String get activeUrl => _retry.onFallback && request.fallbackUrl != null
      ? request.fallbackUrl!
      : request.imageUrl;

  @override
  void retryStep(void Function() step) => setState(step);

  @override
  void redecided(void Function() apply) => setState(apply);

  @override
  void didUpdateWidget(HeroRetryingImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_load.requestChanged(oldWidget.request)) _retry.reset();
  }

  @override
  void dispose() {
    _retry.dispose();
    _load.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int attempt = _retry.attempt;
    final bool animate = attempt < HeroRetryingImage.freezeShimmerAtAttempt;
    final Duration networkFade = MotionGuard.duration(context, AppMotion.fast);
    final ImageLoadDecision decision = _load.decision(networkFade);
    final Duration fadeIn = attempt > 0 ? networkFade : decision.fadeIn;
    final bool sized = widget.width != null || widget.height != null;
    final int? decodeW = request.memCacheWidth;
    final int? decodeH = request.memCacheHeight;
    final double? boxW = sized ? widget.width : decodeW?.toDouble();
    final double? boxH = sized ? widget.height : decodeH?.toDouble();
    _load.traceBuild(context, decision);
    return CachedNetworkImage(
      key: HeroImageAttemptKey(
        epoch: _load.epoch,
        attempt: attempt,
        raw: _retry.onFallback,
      ),
      cacheKey: request.cacheKey,
      imageUrl: activeUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      memCacheWidth: decodeW,
      memCacheHeight: decodeH,
      fadeInDuration: fadeIn,
      fadeOutDuration: attempt > 0 ? networkFade : decision.fadeOut,
      cacheManager: HeroImageCacheManager.loader,
      useOldImageOnUrlChange: true,
      // The bitmap is already decoded at the painted size.
      filterQuality: FilterQuality.low,
      // `decision` is this build's: a handler octo keeps from an earlier
      // build measures ITS decision's delay.
      placeholder: (BuildContext context, String _) {
        _load.tracePlaceholder(decision, fadeIn);
        return HeroImageLoadingPlaceholder(
          plan: _load.placeholderPlan(decision, animate: animate),
          shape: widget.shape,
          fit: widget.fit,
          variantWidth: boxW,
          variantHeight: boxH,
        );
      },
      // EVERY failure retries behind the placeholder. A failure of a URL
      // this tile no longer shows (octo's gapless path holding the previous
      // one, the primary URL after the raw hop) schedules nothing.
      errorWidget: (BuildContext context, String failedUrl, Object error) {
        if (failedUrl == activeUrl) {
          _load.traceFail(error);
          _retry.loadFailed(error, request);
        }
        return HeroImageLoadingPlaceholder(
          plan: _load.retryPlan(decision, animate: animate),
          shape: widget.shape,
          fit: widget.fit,
          variantWidth: boxW,
          variantHeight: boxH,
        );
      },
    );
  }
}
