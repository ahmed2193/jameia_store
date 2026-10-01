# Live delivery tracking — research and recommendation (2026)

Scope: how Hero should show a rider driving from the store to the customer — the
map, the rider's movement, the camera, ETA, stage feedback (haptics, sound, live
notifications), and talking to the rider (chat, call). Research done 2026-09-30 from
public sources (listed at the end). Where a claim comes from a secondary write-up and
not the company itself, it says so.

What exists in the app today (`features/orders`, `Routes.orderLiveMap`): a live map
fed by a **simulated** rider (`DemoCourierTrackingDataSource` — the one swap point),
projection onto the route, glide between fixes, steady ETA, stale state, feed stopped
when hidden, camera following, brand markers. The backend has **no rider-location
route** today (`/v1/*` spec checked), so everything below separates what the client
can do now from what needs the backend.

---

## 1. How real-time rider tracking works (end to end)

The pipeline every large delivery / mobility app converges on:

```
rider phone GNSS ──▶ on-device filter + adaptive sampling ──▶ batched upload
   ──▶ server: map matching ──▶ progress along the planned route ──▶ ETA
   ──▶ fan-out per order ──▶ customer app: project, interpolate, render
```

| Stage | Current practice | Numbers seen |
|---|---|---|
| Sampling | Fused location, **adaptive** cadence: fast while moving on a trip, slow when idle, paused when stationary | 1–2 s moving fast → 15–30 s idle (industry write-up) |
| Filtering | Kalman-type filter **on the rider's device** (predict from speed/heading, weigh the fix by its accuracy) | — |
| Upload | Batch 3–5 fixes per request, binary payloads (protobuf over gRPC / MQTT) | ≈67 % fewer calls; 40–60 B per fix (write-up) |
| Map matching | HMM-style matching of the trace to the road graph: Google Roads API *snapToRoads*, OSRM `/match`, Valhalla *Meili*; **incremental** (only the newest fix, with history) for real time | Roads API: 100 points per request, optional path interpolation |
| Progress | Distance travelled **along the planned route**, off-route detection → reroute | — |
| Fan-out | One push stream per customer session | Uber RAMEN: moved SSE → gRPC bidirectional streaming (QUIC/HTTP3) for ACKs + RTT; +1–2 % push success |
| Client | Snap to the route, drop out-of-order fixes, **interpolate along the route** between fixes, bounded extrapolation when a fix is late, "locating…" when stale | fixes ≈ every 2–4 s, render every frame |

Key takeaways for the client:
- Never draw raw GPS. Project each fix onto the route polyline, **forward only**, and
  move the marker along the road geometry, not in a straight line between fixes.
- Heading comes from the **route tangent**, not the GPS bearing (noisy at low speed).
- Decouple network cadence from render cadence: fixes every few seconds, glide every frame.
- A fix older than the last one is dropped; a gap longer than ~15 s is shown as "locating".

## 2. ETA

- **Routing ETA + learned correction.** Uber's DeepETA predicts the *residual* on top of
  the routing engine's segment-sum ETA (linear-transformer model, all 4-wheel ETAs in
  production). DoorDash moved from trees to deep multi-task models with **probabilistic**
  forecasts (a distribution, not a point).
- Customer-facing rule: an ETA that jumps erodes trust more than one that is a little off.
  Show a **range** before pickup, a **point** ("7 min") once the rider is driving, and
  smooth it: drop at once, rise slowly (Hero already does: `SteadyEta` — +1 min needs 3
  fixes, +2 at once).
- The client should display the server's ETA; the demo computes it from its own timetable.

## 3. Camera, zoom, route rendering, interpolation

Camera ("smart zoom") rules that the best trackers share:
1. **Frame what matters now**, inside the part of the map that is visible (padding for the
   top bar and the bottom sheet): the rider + where they are heading (store, then door) +
   a **look-ahead** point along the route (speed × ~30 s, at least ~150 m).
2. **Close in near the goal**: under ~300 m, frame rider + door tighter; at the door, a
   close-up (zoom ≈ 17). Clamp zoom (never closer than ≈ 17.5).
3. **Dead zone / hysteresis**: do not move the camera on every fix. Re-aim only when the
   rider leaves the inner part of the view or the framing would change zoom noticeably.
   Long, eased camera moves (≈ 1 s), never a jump except under reduced motion.
4. **The customer owns the camera after a gesture**: pause following, show a *recenter*
   button (Google's Navigation SDK uses the same "re-center" pattern); arrival takes the
   camera back.
5. **North-up, no tilt** for a customer (bearing-up is for the person driving).

Route rendering: an encoded polyline from the server; a white casing under a brand line
for contrast on any map; the part behind the rider removed ("eaten"); dashed while only
planned; optionally coloured by traffic (Routes API `TRAFFIC_ON_POLYLINE` +
`speedReadingIntervals`: NORMAL / SLOW / TRAFFIC_JAM per polyline interval).

## 4. UI / UX patterns (leading apps)

- **Map first, bottom sheet second.** Sheet = ETA headline, stage line, a segmented
  progress bar, rider card (name, photo, vehicle, rating) with **Call** and **Message**.
  Uber Eats uses a five-section tracking bar with animated illustrations per stage.
- **Show the status, don't tell it**: a moving marker, a progress bar that fills, a live
  dot, rather than paragraphs of text (UX write-up, 2026).
- **Stage moments**, not a stream of noise: rider assigned → picked up → on the way →
  nearby (~2 min / ~300 m) → arrived. Glovo pushes at *collected*, *courier nearby* and
  *delivered*.
- **Contact the rider** from the moment they are driving to you (Uber Eats lets customers
  contact the courier directly). Chat has quick replies ("Leave it at the door", "Call me
  when you arrive") because customers type little while waiting.
- **Stale honesty**: "Locating your rider…" instead of a frozen marker that looks live.
- **Arrival moment**: the camera lands on the door, a success mark, one haptic.

## 5. Motion, haptics, sound, live notifications

**Motion** — continuous (glide along the road, no teleports), short state transitions,
reduced-motion = step/jump, decorative loops only a few laps (Hero: `AmbientLoop`,
`MotionGuard`, `AppMotion.ambientBudget`).

**Haptics** (Android haptics principles): prefer *rich and clear* over buzzy, stay
consistent with the system, and be mindful of frequency and importance — one haptic per
stage moment, none per fix. Respect the user's vibration setting (Hero: `Haptics.*`).

**Sound** — a short earcon only for the few moments that matter (nearby, arrived), only
in the foreground; in the background the notification channel's sound speaks. Sound must
never be the only cue (phones are often silent).

**Live notifications**
- **Android 16 Live Updates**: `Notification.ProgressStyle` (segments with colours for
  stages / traffic, points for milestones, a tracker icon for the vehicle, start / end
  icons) and *promoted ongoing* notifications: `POST_PROMOTED_NOTIFICATIONS` permission,
  `setRequestPromotedOngoing(true)`, must be ongoing, have a title, not colourised, no
  custom `RemoteViews`, channel not `IMPORTANCE_MIN`; a status-bar chip via
  `setShortCriticalText("3 min")` or a count-down chronometer. Food-delivery tracking is
  an explicitly allowed use case; ads, chat messages and parcel tracking are not.
  Just Eat Takeaway reported +22 % post-order screen views from progress notifications,
  kept for ~38 min on average — about one order.
- **iOS Live Activities** (lock screen + Dynamic Island): ActivityKit, a **WidgetKit
  extension target** is mandatory, updates from the app or via **APNs ActivityKit push**
  (≤ 4 KB per update), push-to-start from iOS 17.2. Uber Eats shows status, ETA, the
  courier's name and photo and the store image.
- Flutter today: `flutter_local_notifications` (released) covers ongoing progress
  notifications on every Android version and iOS notifications, but **not** Android 16
  promotion / `ProgressStyle` yet (PR #2810 is open; it needs compileSdk 37 + AGP 9.1).
  iOS Live Activities: `live_activities` (2.6.0, verified publisher, 656 likes) needs a
  Swift widget extension + App Group; `live_activity_kit` (1.1.1, unverified, 6 likes)
  is too young to bet on.

## 6. Performance (60 fps, battery, network)

- **Map widget rebuilds are platform messages.** With `google_maps_flutter`, every rebuild
  of the map diff-sends markers, polylines, circles… and a changed marker resends its
  bitmap, decoded natively. So: rebuild only the map (not the screen), only when something
  moved **visibly** (≥ 0.5 dp at the current zoom, or ≥ 2° turn), at most every ~30 ms.
- Rasterise marker art once, at the device pixel ratio, handed over with
  `imagePixelRatio` (no native rescale per update).
- Recut the eaten route every few metres, not every frame; keep static markers identical
  objects so they are never re-sent.
- Create the native map **after** the page transition; debounce padding changes (a
  padding change re-lays out the native map).
- Stop the feed when the screen is hidden or the app is in the background; re-read a
  snapshot on return (battery + data). One shared connection per order.
- Android: TLHC is the default platform-view mode and the fastest today; HCPP is opt-in.
  Advanced Markers need a cloud **Map ID** (and replace JSON styling) — a later option,
  not needed for performance.
- Server-to-app transport: **SSE is enough** for one-way location fan-out (auto-reconnect,
  works through proxies) and Hero already has `EventStreamClient`; WebSocket for chat;
  gRPC bidi / MQTT are for rider devices and Uber-scale fan-out.

## 7. What the leading apps do (public facts only)

| App | Public facts |
|---|---|
| Uber / Uber Eats | Live Activities: status, ETA, courier name + photo, store image; five-section tracking bar with animated illustrations; customers can contact couriers directly; DeepETA; RAMEN push over gRPC |
| DoorDash | Deep multi-task ETA models, probabilistic forecasts |
| Just Eat Takeaway | Android 16 Live Updates with ProgressStyle; +22 % post-order views, ~38 min kept |
| Glovo | Live map in order details; pushes at collected / nearby / delivered |
| Talabat | Live order tracking; chat with the rider |
| Keeta (Meituan) | Real-time order tracking and a rider app with route navigation; its internals are not public |

## 8. APIs, SDKs, architecture options

| Need | Options (2026) | Note |
|---|---|---|
| Road route | **Google Routes API** `computeRoutes` (encoded polyline, traffic on polyline); OSRM / Valhalla self-hosted; Mapbox Directions | Routes API pricing: Essentials $5 / 1 000 (10 000 free per month), Pro $10 / 1 000 with `TRAFFIC_AWARE` (5 000 free), Enterprise $15 / 1 000 e.g. two-wheeler routing (1 000 free). Call it **from the backend** (key safety, cost control) |
| Map matching | Roads API snapToRoads, OSRM `/match`, Valhalla Meili | server side |
| Managed stack | Google **Fleet Engine + Consumer SDK** (journey sharing) | native Android / iOS / JS SDKs, no Flutter plugin |
| Push stream | SSE (have it), WebSocket, gRPC | one connection per order |
| Background stages | FCM / APNs | Hero has no push-token source yet (CLAUDE.md §12) |
| Masked calls | Twilio Programmable Voice / Conversations (Twilio *Proxy* is closed to new customers), other CPaaS number masking, or in-app VoIP | the customer never sees the rider's real number |
| Chat | Hero backend (WebSocket or SSE + POST), or a chat SDK | quick replies, auto-translate (riders and customers often do not share a language) |
| Demo routing | OSRM public demo server | fair use only, ≤ 1 request/s, **not for production**, attribution — acceptable for the simulated feed, never for real customers |

## 9. Recommendation for Hero

**Production target (needs the backend):**
1. Rider app streams filtered fixes (adaptive 1–5 s); the backend map-matches, tracks
   progress on the planned route, computes ETA (routing ETA + correction), and reroutes.
2. New routes (proposal): `GET /v1/orders/{id}/tracking` → rider (name, photo, vehicle,
   masked-call capability), store + door points, route (encoded polyline, distance,
   duration), stage, ETA; `GET /v1/orders/{id}/tracking/stream` (SSE) → fixes
   `{at, lat, lng, heading, speed, accuracy, state, etaSeconds, routeVersion}` and
   `route` frames on reroute; chat `/v1/orders/{id}/rider/messages` (+ SSE); call
   `POST /v1/orders/{id}/rider/call` → a masked number or a VoIP session.
3. FCM / APNs for stage changes in the background, driving an Android Live Update and an
   iOS Live Activity (updates ≤ every 15–30 s, stage changes at once).

**Client now (this pass):** keep the swap point and make the demo as real as the data
allows —
- **Real store**: the order's branch (`order.branch.id`) located through
  `GET /v1/delivery/branches` (lat / lng / phone).
- **Real door**: the order's address (lat / lng).
- **Real roads**: the rider's way to the store and the delivery leg routed on the road
  network (OSRM demo in the demo feed only; the grid generator stays as the offline
  fallback). Speeds and turns come from the real geometry.
- **Smart camera**: look-ahead framing, dead zone, speed-aware, close-in near the goal.
- **Stage feedback**: haptic + short earcon (foreground) + an ongoing live notification
  with progress (Android; plain notifications on iOS), updated at stage moments and every
  ~15 s while tracking.
- **Talk to the rider** once they are driving to the customer: chat sheet with quick
  replies (demo replies until the backend has chat) and call (the rider's masked number
  when the backend gives one; until then the branch phone).
- iOS Live Activity and Android 16 promotion wait for the backend push path and a Mac
  build for the widget extension.

## Sources

- Google — Roads API snap to roads: https://developers.google.com/maps/documentation/roads/snap
- Google — Routes API traffic on polylines: https://developers.google.com/maps/documentation/routes/traffic_on_polylines
- Google — Routes API usage and billing: https://developers.google.com/maps/documentation/routes/usage-and-billing
- Pricing summary (secondary): https://lazige.agency/articles/understanding-google-maps-apis-a-comprehensive-guide-to-uses-and-costs
- Google — Mobility consumer experience (journey sharing): https://developers.google.com/maps/documentation/mobility/journey-sharing
- Google — Navigation SDK camera: https://developers.google.com/maps/documentation/navigation/android-sdk/camera
- Android — Progress-centric notifications: https://developer.android.com/about/versions/16/features/progress-centric-notifications
- Android — Live Updates: https://developer.android.com/develop/ui/views/notifications/live-update
- Just Eat Takeaway — Live Updates at JET: https://medium.com/justeattakeaway-tech/live-updates-and-progress-notifications-for-android-16-at-jet-b0c87eab17b4
- flutter_local_notifications PR #2810 (Android 16 live updates, open): https://github.com/MaikuB/flutter_local_notifications/pull/2810
- Apple — ActivityKit push updates: https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications
- live_activities: https://pub.dev/packages/live_activities · live_activity_kit: https://pub.dev/packages/live_activity_kit
- Uber — DeepETA: https://www.uber.com/blog/deepeta-how-uber-predicts-arrival-times/
- Uber — Next-gen push platform on gRPC: https://www.uber.com/blog/ubers-next-gen-push-platform-on-grpc/
- DoorDash — multi-task / probabilistic ETAs: https://careersatdoordash.com/blog/improving-etas-with-multi-task-models-deep-learning-and-probabilistic-forecasts/
- Location ingestion at scale (secondary): https://dev.to/vesviet/system-design-gps-location-ingestion-at-scale-grpc-streaming-mqtt-kalman-filter-in-3pm
- PubNub — smoothing driver location: https://www.pubnub.com/how-to/smooth-driver-location/
- Uber Eats Live Activities (MacRumors): https://www.macrumors.com/2023/05/02/uber-eats-live-activities/
- Uber Eats tracking bar: https://www.marketingdive.com/news/uber-eats-boosts-delivery-tracker-transparency-with-colorful-animations/552543/
- Baymard — order tracking UX: https://baymard.com/blog/integrate-tracking-info
- Status shown, not told (2026): https://medium.com/@uxpeak.com/ui-design-tip-dont-tell-users-the-status-show-it-95116b2ac24c
- Android — haptics principles: https://developer.android.com/develop/ui/views/haptics/haptics-principles
- google_maps_flutter advanced markers: https://github.com/flutter/flutter/issues/183892
- Flutter platform views (TLHC / HCPP): https://docs.flutter.dev/platform-integration/android/platform-views
- Twilio Proxy status: https://www.twilio.com/docs/proxy
- OSRM demo server policy: https://github.com/Project-OSRM/osrm-backend/wiki/Api-usage-policy
- Keeta (Meituan) overview: https://techbuzzchina.substack.com/p/keeta-meituans-overseas-expansion
- Glovo tracking stages (secondary): https://www.accio.com/plp/glovo_order_tracking
