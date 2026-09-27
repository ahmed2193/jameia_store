# Prompt — 2026 Motion Research, Full-App UI Audit & Motion Design System

---

### FEATURE NAME

Hero 2026 Motion & Interaction System: research, whole-app UI/motion audit, performance + clean-code review, icons / images / GIFs for every screen, and a motion design system.

---

### CONTEXT

Hero (`hero_mart`, Flutter 3.47 / Dart 3.13, Cubit, GoRouter, easy_localization AR/EN + RTL) is a
grocery / quick-commerce app in the Talabat / Keeta / Glovo family. It already has a motion layer:

- `lib/src/core/motion/` — `AppMotion` tokens (durations + curves, grounded in Material 3 tokens and
  a decompiled reference app, tagged `[FACT]` / `[INFERENCE]`), `MotionGuard` (reduced-motion gate),
  `haptics.dart`, and ~35 primitives: `press_scale`, `pop_scale`, `pop_switcher`, `change_bump`,
  `flip_value`, `rolling_number`, `rolling_glyph`, `count_up_text`, `entrance_cascade`,
  `stagger_entrance`, `scroll_reveal`, `list_item_transition`, `fade_through_switcher`,
  `size_fade_switcher`, `collapse_reveal`, `shake_x`, `blocked_tap_shake`, `tint_flash`,
  `glow_pulse`, `float_loop`, `idle_loop`, `fly_to_cart`, `confetti_*`, `locale_swap_veil*`,
  `spring_curve`, `second_clock*`, `rotating_line`.
- `lib/src/core/navigation/` — `HeroTransitionPage`, `HeroSlideUpTransitionPage`,
  `hero_shared_axis_*`, `hero_fade_through_page`, `hero_slide_fade_transition`,
  `showHeroDialog` / `showHeroBottomSheet`, `hero_snack_bar`.
- Loaders / states in `lib/src/core/widgets/` — `AppLoader` (two-dot branded loader),
  `BusyOverlay`, `skeletonizer` skeletons, `FailureView`, `HeroStateView`, `EmptyStateView`,
  `BrandedRefresh`, `StaleDataNotice`, connectivity banner.
- An AI assistant (`features/assistant`): streamed SSE chat, cart proposals, a painted mascot
  "buddy" launcher with thought bubbles and a tour, WhatsApp-style hold/lock/cancel voice input.
- Packages today: `skeletonizer`, `cached_network_image`. **No Lottie, no Rive** (the brand loader
  is a GIF in `assets/animations/`).
- Only ~5 files call `HapticFeedback` directly — haptics are not yet a system.

The goal is NOT to add more animation. The goal is to understand, with current evidence, what
motion is worth having in a 2026 consumer commerce app, audit every screen of Hero against that,
and deliver one consistent, fast, calm motion system the whole app can follow.

---

### FIGMA

None. The running app and the code are the source of truth for the current UI.

---

### API SPEC

None (UI / motion work). Where motion depends on data states, read the existing cubit states:
loading / loaded / empty / error / signed-out / offline / stale (`DataFreshness`) and the
assistant's SSE stream states (thinking, streaming tokens, tool / cart proposal, done, error).

---

### EXECUTION MODE — READ-ONLY CODE, ASSETS ALLOWED

This is research + audit + design + asset creation. **Do not edit Dart code under `lib/` or
`test/`, or anything in `android/` / `ios/`.** Do not add packages. Do not commit. Wiring an asset
into a widget (`HeroAssets` constant, widget change) is implementation. It goes in the backlog,
not in this task.

You MAY write:
- the deliverables listed under OUTPUT (`docs/motion/**`);
- **new icons, images and GIFs** for any screen of the app (Phase 5), in the asset folders
  listed there;
- `pubspec.yaml`, **only** its `flutter: assets:` list, and only when a new asset folder is
  really needed. Nothing else in that file.
- temporary render scripts / preview tests needed to produce GIFs (Phase 5). Delete them when
  done, or keep them under the scratchpad directory.

---

### PHASE 0 — Read before anything (mandatory)

1. `CLAUDE.md` (the whole contract; §3 core building blocks, §7 UI rules — motion through
   `AppMotion` + `MotionGuard`, no magic values, one widget per file, RTL, performance).
2. `docs/hero_motion_reference.md` and `docs/design_system.md`.
3. Every file in `lib/src/core/motion/` and `lib/src/core/navigation/`; the loader / state
   widgets in `lib/src/core/widgets/`; `lib/src/config/theme/`.
4. The two review contracts you will apply in Phases 3 and 4:
   - `F:\_jam3eia_apps\workflow\workflow\agents\flutter-performance-reviewer.md`
   - `F:\_jam3eia_apps\workflow\workflow\agents\flutter-clean-code-reviewer.md`
   Note: the clean-code reviewer names `AppLocalizations` / `AppStrings`; in this repo strings are
   easy_localization `'key'.tr()`. When a reviewer file and `CLAUDE.md` disagree, `CLAUDE.md` wins.
5. Load the `flutter-performance` skill (frame budget, rebuilds, raster cost, Impeller rules).

Write down, before researching, a one-page summary of what the motion layer already does, so the
research is compared against reality and not against an imagined blank app.

---

### PHASE 1 — Web research first (evidence, not memory)

Use `WebSearch` and `WebFetch`. Do this phase **before** any recommendation. Do not rely on prior
knowledge: every trend claim needs a source.

**Sources to cover (at minimum)**
- Platform motion systems as shipped in 2025–2026: Material 3 Expressive (motion physics /
  springs, shape morph), Apple HIG motion + iOS 26 "Liquid Glass", Android predictive back,
  Flutter's own guidance (Impeller, `flutter/animations`, spring simulations, performance docs).
- Leading consumer apps — Glovo, Talabat, Keeta, Uber / Uber Eats, Deliveroo, DoorDash,
  Instacart, Careem, Noon: release notes, design-team blog posts, case studies, conference talks,
  screen recordings reviewed by credible design writers. Say plainly when an app's motion is
  only observable (video / teardown), not documented.
- AI assistants in 2026 — ChatGPT, Gemini, Claude, Copilot, Siri / Apple Intelligence, and
  in-commerce assistants (Instacart / Amazon Rufus / Talabat or Careem AI if present): thinking /
  typing states, streaming text reveal, suggested-action chips, tool / action cards, voice
  recording states, feedback, handoff to a human.
- Motion + accessibility: reduced motion (WCAG 2.2 "Animation from Interactions",
  `prefers-reduced-motion`, iOS/Android settings), vestibular safety, haptics guidelines
  (Apple Core Haptics HIG, Android haptics design principles).
- Performance research on animation cost on mobile (60 / 90 / 120 Hz budgets, Impeller specifics,
  `saveLayer` / blur / clip cost, Lottie vs Rive vs code-driven runtime cost).

**Topics to research (each one)**
Micro-interactions · page and screen transitions · interactive buttons and cards · loading and
skeletons · bottom sheets and modals · gesture interactions (swipe, drag-to-dismiss, predictive
back) · scroll-linked motion (collapsing headers, parallax, sticky rails) · empty states ·
success / error feedback · AI assistant interactions · chat bubbles · floating elements (FABs,
cart bars, mascots) · Lottie / Rive-style illustration motion · motion that communicates a state
change (price, count, status, freshness) · haptics paired with motion.

**For every finding record:** the pattern · who uses it (app + screen) · the UX problem it solves
(orientation, feedback, continuity, perceived speed, attention, delight) · evidence URL + publish
date · confidence (documented / observed / inferred) · cost (performance, cognitive load,
accessibility).

Keep a research log: `docs/motion/research_log_2026.md` (source list with URLs + dates, one line
of what each source supports). Discard sources older than 2024 unless they are the canonical
spec. No source → the claim does not go in the report, or it is marked `[INFERENCE]`.

---

### PHASE 2 — Analyse ALL UI in the app (full inventory, no sampling)

Audit every page, and the shared surfaces they use. Pages (44):

- **account**: loyalty, loyalty_rewards, mine_about, mine_delivery_code, mine, mine_settings,
  profile_edit, wallet
- **address**: address_edit (map), address_list
- **assistant**: assistant_buddy_layer, assistant_chat, assistant_history
- **auth**: login, otp_verify
- **cart**: cart_preview, cart_tab
- **checkout**: checkout, checkout_vouchers
- **coupons**: history_coupons, my_coupons
- **home**: home
- **marketing**: content, offers
- **notifications**: notifications
- **orders**: order_invoice, order_review, order_tracking, orders
- **product_details**: pdp_image_viewer, product_detail
- **recipes**: recipe_detail, recipes
- **search**: search
- **shell**: main_shell (tab bar, cart bar)
- **shop**: brands, categories, category, product_listing
- **splash**: splash
- **store_mode**: pro_membership
- **support**: customer_service, customer_service_question, im_chat

Plus shared surfaces: every bottom sheet and dialog (`showHeroBottomSheet` / `showHeroDialog`
call sites), snack bars, the connectivity banner, stale notices, skeletons, `AppLoader` /
`BusyOverlay`, empty / error / offline views, product cards / shelves / steppers, the add-to-cart
path (`fly_to_cart`, cart badge), the locale switch veil, the tab bar.

Work method: split the inventory by feature group across read-only `Explore` subagents if useful
(one message, parallel), each returning the table below; you merge and verify. If a debug build
is running, you may also use the `flutter-mcp-toolkit` (`fmt_*`) tools / DevTools to look at
real screens and frame timings — the user tests on a real phone by hand; do not drive `adb input`.
If nothing is running, the audit is static and must say so.

**Per screen, one row / block:**
| Field | Content |
|---|---|
| Screen + file | page path |
| Entry / exit transition | which page type, duration, curve |
| Motion present | every animated element: what, trigger, token used, `MotionGuard`-gated? |
| State-change motion | loading → loaded, empty, error, offline, stale, success, signed-out |
| Gestures | swipe, drag, pull-to-refresh, long-press, back |
| Haptics | where, which type |
| Problems | missing feedback, jarring change, flashy / looping for no reason, inconsistent with the rest of the app, blocked input during animation, no reduced-motion fallback, RTL direction wrong |
| Perf risk | rebuild scope, raster cost (opacity / blur / clip / shadows / `saveLayer`), always-running tickers, offscreen animation |
| Opportunity | what 2026 evidence (Phase 1) says this screen should do — or "leave as is" |
| Assets | icons / illustrations / GIFs the screen lacks or has weak (empty, error, offline, success, onboarding, tour, rewards, placeholders, directional glyphs): what, why, where it shows. Feeds Phase 5 |

Also answer across the app: Is there one motion language, or several? Where does the same
interaction animate differently on two screens? Which loops run when nobody looks at them?
Which animations make the user wait?

---

### PHASE 3 — Performance review of motion (apply `flutter-performance-reviewer`)

Run the full checklist of that agent (rebuilds and `const`, large `build`s, lists and
`.builder` / pagination, Cubit emission overhead and whole-screen rebuilds, deep trees / overdraw,
images and decode size, repeated network calls / debounce / blocked UI) **focused on motion**, and
add these animation-specific checks with `file:line` evidence:

- `AnimationController` created in `initState`, disposed in `dispose`; `vsync` from the right
  ticker mixin; tickers paused offscreen (`TickerMode`, route not current, tab not visible,
  app backgrounded) — especially `float_loop`, `idle_loop`, `glow_pulse`, shine / sheen sweeps,
  carousels, `second_clock`, the assistant buddy, the loader.
- Animations rebuild the smallest subtree: `AnimatedBuilder` / `*Transition` with a `child:`,
  no `setState` per tick on a big widget, no `BlocBuilder` that rebuilds during a tween.
- Raster cost: `Opacity` widget vs `FadeTransition` / `AnimatedOpacity`; animated `BackdropFilter`
  / blur; `ClipRRect` / `ClipPath` on moving content; animated shadows; `saveLayer` triggers;
  `RepaintBoundary` around animated list items and independent loops (and not sprinkled
  everywhere).
- Lists: item entrance animations only on first appearance, not on every scroll-back;
  stagger capped; no animation work for items off screen.
- Images during transitions: `cacheWidth` / `cacheHeight`, placeholder → fade, no decode on the
  UI thread mid-transition, hero image continuity (PDP, image viewer).
- Frame budget at 60 Hz (16.6 ms) and 120 Hz (8.3 ms); first-frame / splash cost; jank on the
  first run of a transition.
- Cost of adding Lottie or Rive vs the current code-driven approach (runtime, APK size, raster).

Output exactly the agent's format: `## 🔴 Issues Found` · `## 🟡 Severity` (High / Medium / Low)
· `## 🟢 Recommendations` · `## 🚀 Optimized Version` (structure only, when needed).

---

### PHASE 4 — Clean code & architecture review of motion (apply `flutter-clean-code-reviewer` + CLAUDE.md §10)

Scope: `lib/src/core/motion/`, `lib/src/core/navigation/`, the loader / state widgets, and every
feature-local animation found in Phase 2. Check:

- **Duplication / overlap** between primitives (e.g. `pop_scale` vs `pop_switcher` vs
  `change_bump` vs `flip_value`; `entrance_cascade` vs `stagger_entrance` vs `scroll_reveal` vs
  `list_item_transition`; `float_loop` vs `idle_loop`; `shake_x` vs `blocked_tap_shake`) — which
  to keep, merge or retire, with every call site counted.
- Feature-local animation code that belongs in `core/motion`; motion logic in cubits or pages.
- Magic values: raw `Duration(...)` / `Curves.*` / `Cubic(...)` outside `AppMotion`; token sprawl
  (tokens used once, tokens that duplicate each other).
- `MotionGuard` coverage: every implicit animation passes duration / curve through it; every
  controller early-returns on `MotionGuard.reduced(context)`.
- Haptics: scattered `HapticFeedback` calls vs one `haptics.dart` policy.
- CLAUDE.md §7: one widget per file, no widget-returning helpers, RTL (`*Directional`), naming,
  SOLID (no god animation widgets), consistency across features.

Output exactly the agent's format: `## 🔴 Issues Found` (Severity Critical / Major / Minor ·
Location `file:line` · Problem + broken rule · Fix) · `## ✨ Refactored Example` (only when it adds
clarity, no full implementations) · `## ✅ Summary`.

---

### PHASE 5 — Generate the icons, images and GIFs every screen needs (all 44 pages)

Go through **every screen** in the Phase 2 audit, using its "Assets" field, plus the shared
surfaces. For each screen, create what it needs. Leave it alone when the current asset is
already right, and say so in the manifest. No screen is skipped. Each gets a "created", "kept"
or "not needed" line.

**What to create**
- **Icons**: missing or inconsistent glyphs (state icons, feature icons, directional arrows,
  haptic-paired action icons). Read first: `lib/src/core/design/hero_icons.dart` (HeroIcon font),
  `hero_glyphs.dart`, `grocery_doodles.dart`, `hero_mark*.dart` and `assets/svg/*.svg`, so the
  new ones match their stroke weight, corner radius, grid and colour use.
- **Illustrations / images**: empty, error, offline, success, first-run / tour, rewards / Pro,
  order-status art, and so on, as vector SVG by default.
- **GIFs**, two kinds:
  1. **Preview GIFs** (docs only): each proposed motion pattern from section 9, and a
     before / after for the top backlog items, so the user can see a pattern before approving it.
  2. **In-app animated art**: only where code-driven motion (CustomPainter / existing
     primitives) is not practical. A GIF can't follow reduced motion, can't be paused offscreen,
     and decodes every frame on the CPU. So for in-app motion, prefer a painter spec or an
     animated SVG built from paths, and say why a GIF was still chosen.

**Where they go**
- In-app SVGs → `assets/svg/` (already bundled, no pubspec change). File names are
  `<screen_or_area>_<what>.svg`, snake_case.
- In-app GIF / animated art → `assets/animations/` (already bundled).
- In-app rasters (only when vector cannot work) → an existing `assets/images/**` folder with
  `2.0x/` and `3.0x/` variants. A new folder is the one allowed `pubspec.yaml` assets edit.
- Preview GIFs and mockup frames → `docs/motion/previews/<screen>/` (never bundled).
- New sub-folders under `assets/svg/` or `assets/animations/` are NOT bundled by the parent
  entry. Keep files flat, or add the folder to the pubspec assets list.

**How to make them (tools on this machine)**
- `node` and `ffmpeg` are installed. `python` is NOT (it's only the Store alias). No
  image-generation model is available. Every asset is drawn: hand-authored SVG paths, or a
  Flutter `CustomPainter` rendered to frames.
- Rendering frames from Flutter: a temporary widget test that pumps the widget / painter with a
  fake clock, captures each frame via `RepaintBoundary.toImage`, and writes PNGs to the
  scratchpad. Load the real fonts first (`FontLoader`), otherwise test text shows up as Ahem
  boxes. Delete the test afterwards. A device recording also works: the user drives the phone by
  hand while you run `adb shell screenrecord`. Never use `adb input`.
- SVG → PNG frames: rasterize with a node tool fetched into the scratchpad (e.g. `npx`
  resvg / sharp). Don't add anything to the project.
- Frames → GIF (two-pass palette, small file):
  `ffmpeg -framerate 30 -i f_%04d.png -vf "fps=30,scale=360:-1:flags=lanczos,palettegen=stats_mode=diff" pal.png`
  then `ffmpeg -framerate 30 -i f_%04d.png -i pal.png -lavfi "fps=30,scale=360:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5" out.gif`.

**Asset rules**
- Brand: colours are the exact values in `lib/src/config/theme/app_colors.dart`, no new hues.
  Keep the Hero look: reference apps inspire the idea, never the artwork.
- **Original work only.** Never copy, trace or re-export icons, illustrations or GIFs from
  Talabat, Glovo, Keeta, Uber or any other app or site. Never use another brand's logo.
- RTL: mark directional art (arrows, progress, "go" motion) and state that it needs
  `matchTextDirection: true` or a mirrored variant. Arabic text is never baked into an image.
  Text belongs in i18n keys, drawn by the widget.
- Contrast: art stays legible on the app background and meets WCAG non-text contrast (3:1) for
  meaningful shapes.
- Size budgets: SVG clean and minimal (a `viewBox`, no embedded rasters, no editor metadata,
  under 10 KB each where possible); preview GIF ≤ 2 MB; in-app GIF ≤ 300 KB, ≤ 30 fps, loops only
  when the state really is ongoing, and a static first frame usable as the reduced-motion
  fallback.
- Every asset has a manifest row: file · screen(s) · purpose (which UX problem) · light-bg check ·
  RTL rule · reduced-motion fallback · size · how it was made · the backlog item that wires it in.

---

### BEHAVIOR (what good motion must do in Hero)

Every animation in the final system must answer "which user problem does this solve?" — one of:
**feedback** (my tap worked), **continuity** (where did that come from / go to), **orientation**
(where am I, what changed), **perceived speed** (something is happening, content is coming),
**state change** (price, count, freshness, status, error), **attention** (only for something the
user must act on), **delight** (rare, earned moments only: first add, order placed, reward).

The app must feel smooth, natural, responsive, modern, premium, calm and fast. Motion never
delays input, never blocks a tap, never hides content the user already asked for, and never
loops on screen without a reason.

---

### REQUIREMENTS FOR THE RECOMMENDATIONS

- Build on the existing `AppMotion` / `MotionGuard` / `core/motion` layer. Extend, merge or
  retire — do not propose a parallel system. Say which existing token or primitive each
  recommendation uses or replaces.
- Keep the Hero brand: app colours, cart button, existing brand loader and splash. Reference apps
  inspire behaviour, not a copy of their look.
- Respect decisions already made in this app (no basket bar on home when the cart has items;
  category shelf wash + auto-glide; the assistant buddy exists) unless evidence shows a real UX
  problem — then say so as a finding, not as a silent change.
- Every pattern ships with a reduced-motion fallback, an RTL rule and a haptic rule (or "none").
- Offline / stale / error states: motion must make the state clear without alarming
  (CLAUDE.md §3.2 offline contract — no full-screen error over data).
- New packages (Lottie, Rive, springs libs …) only with a cost / benefit case from Phase 1 + 3;
  default answer is "code-driven with existing primitives".
- i18n: any text in a recommendation refers to keys in `assets/i18n/{en,ar}.json`, not literals.

---

### AI ASSISTANT — dedicated section

Research-backed design for `features/assistant`, covering: idle / buddy presence, thinking
state, streaming text reveal (token vs word vs chunk reveal, caret, auto-scroll anchoring),
chat bubble entrance and grouping, suggested-action chips, cart-proposal cards (confirm / reject
feedback, fly-to-cart link), tool-running indicators, errors and retry mid-stream, voice
recording (hold, lock, cancel, live level, transcript reveal), feedback (thumbs), handoff to a
human. For each: what 2026 assistants do (with sources), what Hero does today (file refs), the
gap, the recommendation, timing, haptics, reduced-motion fallback. The assistant must feel
alive and responsive, **not childish and not distracting**: define exactly when the buddy may
move, how often, and when it must stay still (while the user types, reads a streaming answer,
records, or is on checkout / payment).

---

### UI GUIDELINES (constraints on every proposed pattern)

- Durations and curves come from tokens; propose token names and values, mapped to existing
  `AppMotion` names wherever one exists.
- Prefer transform + opacity; avoid animating layout, blur, clips and shadows.
- Motion is interruptible and reversible (a second tap mid-animation behaves correctly).
- Directional motion mirrors in RTL.
- One primary motion per moment; stagger short and capped; loops only for real "in progress"
  states or rare ambient hero art, and they stop offscreen.

---

### ARCHITECTURE GUIDELINES

- Motion primitives live in `core/motion` (one widget per file); transitions in
  `core/navigation`; features compose primitives and never own raw tweens.
- No motion decisions in cubits beyond exposing state (e.g. a `justAdded` / changed flag); no
  `BuildContext` in cubits.
- Haptics go through one policy in `core/motion/haptics.dart`.
- The design system is enforceable: note which rules `architecture_lints` could check
  (e.g. raw `Duration` / `Curves.*` in features) — as proposals, not edits.

---

### OUTPUT

Write these (and nothing else, apart from the Phase 5 assets):

1. `docs/motion/research_log_2026.md`: the Phase 1 source log.
2. `docs/motion/asset_manifest.md`: the Phase 5 manifest. Every one of the 44 screens is listed,
   and each asset has its row. It links the previews in `docs/motion/previews/`.
3. `docs/motion/motion_design_system_2026.md`, with these sections, in order:
   1. The most important animation / UI trends in 2026 (each with sources).
   2. Examples — which apps / products use each pattern (screen + source).
   3. Patterns worth adopting, and why (UX problem solved, evidence, cost).
   4. Patterns to avoid, and why (cognitive load, a11y, performance, brand).
   5. The recommended motion direction for Hero (one page, plain words).
   6. Specific ideas for Hero's existing UI — per screen, from the Phase 2 audit.
   7. Durations, easing curves (cubic-bezier or spring params) and interaction behaviour
      per pattern.
   8. Performance considerations for Flutter at 60 / 120 FPS (Phase 3 report included).
   9. **The Hero 2026 Motion & Interaction System**:
      - Principles (5–7, each one sentence).
      - Token table: name · value · curve · use for · replaces (existing `AppMotion` token).
      - Primitive catalogue: keep / merge / retire / new, with call-site counts.
      - Pattern specs: trigger · purpose · motion · duration · curve · haptic · reduced-motion ·
        RTL · perf budget.
      - Haptics map.
      - AI assistant motion spec.
      - Do / Don't list.
      - Review checklist a PR can be checked against.
   Appendices: A. full per-screen audit (all 44 pages + shared surfaces). B. Performance review
   (Phase 3 format). C. Clean-code review (Phase 4 format). D. **Implementation backlog** — ranked
   by user impact ÷ effort, each item: files, primitives / tokens used, risk, test needed,
   and whether it changes behaviour (flag those for user approval).

Then reply with the §0.9 report shape: Summary · Files written (docs + every asset path) ·
Verification (source count, pages audited N/44, screens covered by Phase 5 N/44, asset sizes,
each GIF opened and checked frame by frame; if `pubspec.yaml` assets changed, `flutter pub get`
and `dart analyze` results) · Behavior changes proposed (need approval) · Risks / open
questions.

---

### ACCEPTANCE CRITERIA

- [ ] Phase 1 ran before any recommendation; every trend claim has a dated source or is
      marked `[INFERENCE]`; sources from 2025–2026 dominate.
- [ ] All 44 pages and the shared surfaces appear in the audit; nothing sampled.
- [ ] Every recommendation names the UX problem it solves and the existing token / primitive it
      uses; no generic "add a nice animation".
- [ ] Performance and clean-code reviews use the reviewer agents' exact output formats, with
      `file:line` evidence.
- [ ] Every pattern has duration, curve, haptic, reduced-motion and RTL behaviour.
- [ ] The assistant section defines when the buddy moves and when it stays still.
- [ ] Phase 5 covered all 44 screens + shared surfaces: each has created / kept / not-needed,
      and each asset has a manifest row.
- [ ] Assets are original, use brand colours only, meet the size budgets, have RTL and
      reduced-motion rules, and have no baked-in text. Preview GIFs exist for the section 9
      patterns and the top backlog items.
- [ ] Only `docs/motion/**`, new files in the asset folders, and (if needed) the pubspec
      assets list were changed. No Dart code in `lib/` / `test/` was changed, no package was
      added, temporary render scripts are gone, and nothing was committed.
