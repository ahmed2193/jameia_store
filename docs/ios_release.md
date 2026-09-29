# Hero on iOS — app, configuration and App Store release (Codemagic)

The one reference for shipping the Hero app (`hero_mart`) to the App Store through
Codemagic. It covers what the app does (for the store listing and App Review), every
iOS setting in `ios/`, the Codemagic pipeline in `codemagic.yaml`, the App Store Connect
checklist, and the known review risks.

Last checked: 2026-09-29, Flutter 3.47.4 / Dart 3.13.3, `version: 1.0.0+1`.

---

## 1. What the app is

**Hero** (Arabic: **هيرو**) is a grocery and household delivery app for Kuwait. Customers
browse the store catalogue, fill a basket, choose a delivery time and address, and pay
cash on delivery or from their Hero wallet. Orders are tracked in the app. The app is
fully bilingual (Arabic RTL / English) and talks to the Hero backend
(`https://api.jm3eia.store`, routes under `/v1`).

### Features (what App Review will see)

| Area | What the customer can do | Feature folder |
|---|---|---|
| Splash + shell | Branded launch animation, bottom tabs (Home, Categories, Search, Cart, Account) | `splash`, `shell` |
| Sign-in | Phone number (8 digits, Kuwait) + one-time SMS code. **"Continue as guest"** is allowed: browse and fill a cart without an account | `auth` |
| Home | Banners, categories, offers, product rails, recipes, Hero Pro banner | `home`, `marketing` |
| Catalogue | Category tree, brand pages, product listings, filters, product details page | `shop`, `product_details` |
| Search | Live product search, recent searches | `search` |
| Recipes | Recipe pages that add their ingredients to the cart | `recipes` |
| Cart | Add / remove / change quantity (works offline, syncs when back online), coupon code, loyalty points, express delivery | `cart` |
| Checkout | Pick branch, address and delivery slot (ASAP / express / scheduled), pay **cash on delivery** or **wallet**, place order | `checkout` |
| Orders | Order list, live status, cancel, reorder, rate the order, "get help with this order" (support ticket) | `orders`, `support` |
| Addresses | Saved addresses; new address pinned on a **Google map**, optional "use my current location" | `address` |
| Account | Profile (name, email, date of birth, gender, household size), wallet, loyalty points, language, notification settings, coupons, sign out | `account`, `coupons`, `language` |
| Hero Pro | Paid delivery-benefits membership (free / cheaper delivery). Subscribe / cancel through the backend | `store_mode` |
| Notifications | In-app inbox + unread badge (no push notifications yet) | `notifications` |
| Shopping assistant | Chat with an AI shopping assistant (streamed replies); it can propose cart changes that the customer confirms. **Voice messages** are converted to text **on the device** (Apple Speech) — no audio leaves the phone | `assistant` |
| Offline | Offline banner, cached screens with "Updated … ago", automatic refresh when back online | `connectivity` |

### Store listing text (starting point)

- **Name:** Hero
- **Subtitle (≤30):** Groceries delivered fast
- **Category:** Shopping (secondary: Food & Drink)
- **Short description:** Order groceries and household essentials in Kuwait and get them
  delivered to your door. Browse offers, fill your basket, pick a delivery time, pay cash
  on delivery or with your Hero wallet, and track your order live. Ask the Hero shopping
  assistant for ideas and recipes, by text or by voice. Available in Arabic and English.

---

## 2. Identity and versions

| Setting | Value | Where |
|---|---|---|
| Bundle ID | `com.herodelivery.app` (same as the Android `applicationId`; changed from `com.jameiamart.app` on 2026-09-29 — **do not change after the first upload**, it is the App Store identity) | `ios/Runner.xcodeproj/project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER` |
| Tests bundle ID | `com.herodelivery.app.RunnerTests` | same |
| Home-screen name | `Hero` (both languages, same as Android) | `Info.plist` → `CFBundleDisplayName` |
| Version (marketing) | from `pubspec.yaml` `version: X.Y.Z+N` → `X.Y.Z` | `CFBundleShortVersionString = $(FLUTTER_BUILD_NAME)` |
| Build number | Codemagic sets it: latest TestFlight build + 1 | `CFBundleVersion = $(FLUTTER_BUILD_NUMBER)` |
| Minimum iOS | **15.0** (Flutter 3.47 floor) | `IPHONEOS_DEPLOYMENT_TARGET`, `ios/Podfile` |
| Devices | iPhone **and iPad** (`TARGETED_DEVICE_FAMILY = "1,2"`) → App Store needs iPad screenshots too | pbxproj |
| Orientations | iPhone: portrait + landscape L/R. iPad: all four | `Info.plist` |
| Signing | Automatic in Xcode; Codemagic replaces it with the App Store profile (`xcode-project use-profiles`) | pbxproj `CODE_SIGN_STYLE = Automatic` |
| Swift | 5.0, bitcode off | pbxproj |

**Releasing a new version:** bump `version:` in `pubspec.yaml` (e.g. `1.0.1+1`). The `+N`
part is ignored by the CI build number; only `X.Y.Z` matters. App Store Connect needs a
new `X.Y.Z` for every version that goes to review; several TestFlight builds can share one.

---

## 3. The `ios/` folder, file by file

| File | What it does |
|---|---|
| `Runner/Info.plist` | App metadata, permissions strings, scenes, orientations, export compliance (table below) |
| `Runner/en.lproj/InfoPlist.strings`, `Runner/ar.lproj/InfoPlist.strings` | English / Arabic text of the iOS permission prompts (an Arabic iPhone shows Arabic prompts) |
| `Runner/AppDelegate.swift` | Starts Flutter (implicit engine + `GeneratedPluginRegistrant`) and gives the **Google Maps SDK** its iOS API key (`GMSServices.provideAPIKey`) |
| `Runner/SceneDelegate.swift` | `FlutterSceneDelegate` — the app uses the UIScene life cycle (required by recent Flutter) |
| `Runner/Assets.xcassets/AppIcon.appiconset` | App icon: light (1024 px, **no alpha** — App Store requirement), iOS 18 dark and tinted variants. Generated by `dart run flutter_launcher_icons` from `assets/app_icon/` |
| `Runner/Assets.xcassets/LaunchImage*`, `LaunchBackground*` + `Base.lproj/LaunchScreen.storyboard` | Native launch screen: brand green `#22C55E` + the caped-bag mark, identical to the first Flutter splash frame. Generated by `dart run flutter_native_splash:create` |
| `Runner/Base.lproj/Main.storyboard` | Flutter's host view controller |
| `Podfile` | CocoaPods side of the hybrid build (§4): iOS 15 platform, deployment target on every pod, `permission_handler` macros for a CocoaPods-only build |
| `Flutter/Debug.xcconfig`, `Flutter/Release.xcconfig` | Include the CocoaPods settings (`#include? Pods/...`) + Flutter's `Generated.xcconfig` |
| `Flutter/AppFrameworkInfo.plist` | Flutter framework metadata (template, untouched) |
| `Runner.xcodeproj/project.pbxproj` | Targets, build settings, bundle ID, regions (`en`, `ar`, `Base`) |
| `RunnerTests/` | Empty native test target from the Flutter template |

Generated, never committed: `Flutter/Generated.xcconfig`, `Flutter/ephemeral/`, `Pods/`,
`Podfile.lock` (CI deletes and re-resolves it), `Runner/GeneratedPluginRegistrant.*`.

### `Info.plist` keys

| Key | Value | Why |
|---|---|---|
| `CFBundleDisplayName` / `CFBundleName` | `Hero` | Name under the icon |
| `CFBundleLocalizations` | `en`, `ar` | Tells iOS / the App Store the app is Arabic + English (the language list on the store page, Arabic permission prompts) |
| `ITSAppUsesNonExemptEncryption` | `false` | Export compliance: the app only uses standard HTTPS/TLS. With this key TestFlight never stops on "Missing Compliance" |
| `NSLocationWhenInUseUsageDescription` | "Hero uses your location to pin your delivery address on the map." | `geolocator` — "use my location" on the address map. **Without it iOS crashes / Apple rejects the build** |
| `NSMicrophoneUsageDescription` | "Hero uses the microphone so you can talk to the shopping assistant by voice." | Assistant voice messages (`speech_to_text` + `permission_handler`) |
| `NSSpeechRecognitionUsageDescription` | "Hero turns your voice into text on your device so you can send voice messages to the shopping assistant." | Apple Speech framework (on-device recognition) |
| `UIApplicationSceneManifest` | one scene, `SceneDelegate` | UIScene life cycle |
| `UILaunchStoryboardName` | `LaunchScreen` | Native launch screen |
| `UIStatusBarStyle` / `UIStatusBarHidden` | light content / visible | Flutter changes the style per screen at run time |
| `CADisableMinimumFrameDurationOnPhone` | `true` | Allows 120 Hz on ProMotion iPhones |
| `LSRequiresIPhoneOS` | `true` | iOS app |

If you add a feature that needs a new permission (camera, photos, contacts, location
"always"…) add **both** the `NS…UsageDescription` key to `Info.plist` and its text to
both `InfoPlist.strings` files. `permission_handler_apple` (Swift Package Manager) enables a
permission **only** when its key is in `Info.plist`; with no key the permission always
answers "denied".

### Capabilities / entitlements

None. The app has **no** `Runner.entitlements`: no push notifications, no Apple Pay, no Sign
in with Apple, no associated domains, no background modes. Add the capability in the
Apple Developer portal **and** the entitlement file when one of these is built (the App
Store profile Codemagic fetches must include it).

### Networking

All requests go over HTTPS to `AppEnv.apiBaseUrl`. Flutter's `dart:io` HTTP stack does not
use App Transport Security, so no `NSAppTransportSecurity` exceptions are needed. Maps and
map tiles are loaded by the Google Maps SDK over HTTPS.

---

## 4. Native dependencies (plugins)

Flutter 3.47 builds iOS plugins with **Swift Package Manager (SPM)** by default. One plugin
here has no SPM support, so the build is **hybrid**: SPM for most plugins, CocoaPods for
Google Maps.

| Plugin (iOS package) | Built by | Used for | Permission |
|---|---|---|---|
| `google_maps_flutter_ios` 2.18.x (Google Maps SDK 8.4–10.x) | **CocoaPods** | Address map, order / shop maps | — |
| `geolocator_apple` | SPM | Current location for the address pin | Location when in use |
| `geocoding_darwin` | SPM | Coordinates → street / area names (Apple geocoder) | — |
| `speech_to_text` | SPM | On-device speech-to-text for assistant voice messages | Microphone, Speech recognition |
| `permission_handler_apple` 9.6.x | SPM | Asks for the microphone + speech permissions | reads `Info.plist` keys |
| `flutter_secure_storage_darwin` | SPM | Keychain: auth tokens, guest cart / assistant ids | — |
| `shared_preferences_foundation` | SPM | Settings, cart mirror | — |
| `sqflite_darwin` | SPM | Image cache index (`flutter_cache_manager`) | — |
| `path_provider_foundation` | Dart FFI (no native build) | Cache / documents folders | — |
| `package_info_plus` | SPM | App version | — |

**Google Maps API key (iOS):** in `AppDelegate.swift`. It is a different key from Android's
(`AndroidManifest.xml`). In Google Cloud Console, restrict it to **iOS apps → bundle ID
`com.herodelivery.app`** and to the **Maps SDK for iOS** API.

To move Google Maps to SPM later (and drop CocoaPods), replace the default implementation
with `google_maps_flutter_ios_sdk9` (iOS 15+) or `google_maps_flutter_ios_sdk10` (iOS 16+)
— a `pubspec.yaml` change that needs its own test pass.

---

## 5. Build configuration (`--dart-define`)

Defined in `lib/src/core/constants/app_env.dart`:

| Define | Default | Release value (Codemagic) |
|---|---|---|
| `API_BASE_URL` | `https://api.jm3eia.store` | `https://api.jm3eia.store` (`codemagic.yaml` → `vars`) |
| `API_LOG_SECRETS` | `false` | not set (debug-only trace anyway) |
| `LIVE_NOTIFICATIONS` | `false` | not set (live stream off; inbox loads on open) |

Release builds print no API trace (`NetworkLogInterceptor` is debug-only).

---

## 6. Codemagic

### One-time setup

1. **Apple side**
   - Apple Developer → Identifiers: App ID `com.herodelivery.app` (no extra capabilities).
   - App Store Connect → My Apps → **+ New App**: platform iOS, name **Hero**, primary
     language (English or Arabic), bundle ID `com.herodelivery.app`, SKU e.g. `hero-ios`.
     Copy its **Apple ID** (a number, App Information page).
   - App Store Connect → Users and Access → Integrations → **App Store Connect API**: a key
     with **App Manager** access (the `jameia` key used by jm3eia_mobile works if it is on
     the same Apple team).
2. **Codemagic side**
   - Add the GitHub repo `ahmed2193/jameia_store`; Codemagic reads `codemagic.yaml` from
     the repo root.
   - Team settings → Integrations → App Store Connect: the API key, named **`jameia`**
     (or change `integrations.app_store_connect` in `codemagic.yaml`).
   - Team settings → Code signing identities → iOS certificates: an **Apple Distribution**
     certificate (`.p12` + password) — the same one as jm3eia_mobile if same team. The App
     Store provisioning profile for `com.herodelivery.app` is fetched (or created) through
     the integration.
   - `codemagic.yaml` → `APP_STORE_APP_ID: "6817324787"` (Hero's Apple ID, set 2026-09-29; change it only if the app is re-created).

### What `codemagic.yaml` → `ios-release` does

| Step | What / why |
|---|---|
| Environment | `mac_mini_m2`, Flutter **3.47.4** (pinned to the dev SDK), latest Xcode, default CocoaPods; `ios_signing` = App Store distribution for `com.herodelivery.app` |
| Get Flutter packages | `flutter clean` + `flutter pub get` |
| Install iOS dependencies | Deletes `Pods` / `Podfile.lock`, `flutter build ios --config-only` (writes `Generated.xcconfig`, wires SPM packages + CocoaPods into the Xcode project), `pod install --repo-update` |
| Verify Info.plist usage strings | Fails the build if a usage string or `ITSAppUsesNonExemptEncryption` was lost |
| Set up code signing | `xcode-project use-profiles` applies the fetched App Store profile |
| Build IPA | build number = latest TestFlight build + 1 (1 on the very first upload), `flutter build ipa --release --dart-define=API_BASE_URL=…` |
| Artifacts | the `.ipa`, `build_output.log`, Xcode logs |
| Publishing | e-mail on success / failure; upload to **TestFlight** (`submit_to_app_store: false` — the App Store submission stays a manual click) |

The workflow has **no trigger**: start it from Codemagic → the app → **Start new build**
→ workflow *Hero - iOS App Store Release* → branch `main`. The comment in the file shows how
to build on every push to `main` instead.

### Release routine

1. Bump `version:` in `pubspec.yaml`, commit, push to `main`.
2. Codemagic → Start new build → `ios-release`. (~20–30 min.)
3. TestFlight: the build appears after Apple's processing (5–30 min). Test it on a phone.
4. App Store Connect → the app → the version → **Build** → choose it → **Add for Review**.

---

## 7. App Store Connect checklist (first submission)

**App information**
- Name *Hero*, subtitle, category Shopping / Food & Drink.
- Localizations: English + Arabic (name, subtitle, description, keywords, screenshots).
- Privacy Policy URL (required) and Support URL — from the Hero website.
- Age rating questionnaire: no objectionable content → 4+. The AI assistant produces text:
  answer the "unrestricted web access / user-generated content" questions honestly (the
  assistant is limited to shopping topics by the backend).
- Availability: Kuwait (the app only delivers there; phone numbers are 8-digit Kuwaiti).

**Screenshots** — 6.9" iPhone (1320×2868 or 1290×2796) **and 13" iPad (2064×2752)**
because the app supports iPad. Arabic and English sets.

**App Privacy ("nutrition label")** — the app has **no analytics, ads or tracking SDKs**.
Declare as *linked to the user, not used for tracking*:

| Data type | Collected because |
|---|---|
| Contact info → Phone number | Sign-in (OTP) |
| Contact info → Name, Email address | Profile (optional fields) |
| Contact info → Physical address | Delivery addresses |
| Location → Precise location | Only when the customer taps "use my location" on the address map; the chosen pin is saved as the address |
| Purchases → Purchase history | Orders |
| User content → Customer support | Order-help tickets |
| User content → Other user content | Messages sent to the shopping assistant (voice is converted to text on the device; audio is not sent) |
| Identifiers → User ID | Customer account id |
| Other data → date of birth, gender, household size | Optional profile fields |

**App Review information**
- **Demo account:** App Review cannot receive an SMS. Ask the backend team for a test phone
  number with a **fixed OTP** and put both in *Sign-in required → username / password*
  plus the notes. Guest mode lets them browse, but checkout needs the account.
- **Notes** (example): "Hero is a grocery delivery app for Kuwait. Sign in with phone
  XXXXXXXX and code XXXX. Payment is cash on delivery or Hero wallet balance; no card
  payment in the app. Hero Pro is a delivery-benefits membership used for physical
  delivery services. Location is used only to pin the delivery address. The microphone is
  used only for voice messages to the shopping assistant."

**Export compliance** — answered automatically by `ITSAppUsesNonExemptEncryption = false`.

---

## 8. App Review risks (read before the first submission)

| Risk | Guideline | Status / action |
|---|---|---|
| **No in-app account deletion** | 5.1.1(v): an app that lets users create an account must let them delete it from inside the app | **Blocker.** The backend has no delete-account route (`/v1/account/*` has none, checked 2026-09-29). Needs a backend route (e.g. `DELETE /v1/account`) + an Account → "Delete account" flow before submission |
| Demo login with SMS OTP | 2.1 | Provide a test number with a fixed code (§7) |
| Hero Pro paid outside In-App Purchase | 3.1.1 / 3.1.3(e) | Allowed for physical goods/services consumed outside the app (delivery benefits, like other delivery memberships). Say so in the review notes; never sell digital content through it |
| iPad support | 2.4.1 | The app runs on iPad and rotates; check the layouts in the iPad simulator. If iPad is not wanted, set `TARGETED_DEVICE_FAMILY = 1` (iPhone only) before the first upload — it cannot be removed after release |
| Permission texts | 5.1.1 | Specific texts in EN + AR are in place (§3) |
| Push notifications | — | Not implemented; no push capability, nothing to declare |

---

## 9. Building on a Mac by hand

```sh
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter build ipa --release --dart-define=API_BASE_URL=https://api.jm3eia.store
# → build/ios/ipa/*.ipa, upload with Transporter or Xcode Organizer
open ios/Runner.xcworkspace   # always the .xcworkspace, not the .xcodeproj
```

Building from Xcode.app (not the CLI): `permission_handler_apple` cannot find `Info.plist`
from Xcode's working directory; run once
`launchctl setenv PERMISSION_HANDLER_INFO_PLIST "$PWD/ios/Runner/Info.plist"`, restart
Xcode and clear `~/Library/Developer/Xcode/DerivedData`.

---

## 10. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Voice or location permission always "denied" on device | Usage key missing from `Info.plist`, or a stale SPM manifest cache → add the key, delete DerivedData, rebuild |
| `ITMS-90683: Missing purpose string` | A plugin references a permission API with no usage key → add the key + both `InfoPlist.strings` lines |
| `ITMS-90717: Invalid App Store icon` | 1024 px icon has alpha → regenerate icons (`remove_alpha_ios: true` is set) |
| `pod install` fails on `GoogleMaps` | Run with `--repo-update`; check the `platform :ios, '15.0'` line |
| "No matching profiles found" in *Set up code signing* | Integration key lacks access, or no Apple Distribution certificate in Codemagic, or `APP_STORE_APP_ID` / bundle ID mismatch |
| Upload rejected: build number already used | Build numbers come from TestFlight + 1; a manual upload with a higher number can collide — rerun the build |
| Map is blank / grey | iOS Google Maps key restricted to the wrong bundle ID or Maps SDK for iOS not enabled |
| TestFlight "Missing Compliance" | `ITSAppUsesNonExemptEncryption` removed from `Info.plist` |

---

## 11. Change log (iOS)

**2026-09-29 — iOS release preparation**
- `Info.plist`: added `NSLocationWhenInUseUsageDescription` (was missing — the address map's
  "use my location" would crash / be rejected), rewrote the microphone + speech texts for
  the assistant (they still described the removed voice search), added
  `CFBundleLocalizations` (en, ar) and `ITSAppUsesNonExemptEncryption = false`.
- New `en.lproj` / `ar.lproj` `InfoPlist.strings` (Arabic permission prompts), registered in
  the Xcode project; `ar` added to the project's known regions.
- New `ios/Podfile` (hybrid SPM + CocoaPods, iOS 15, permission macros) and the Pods
  includes in `Flutter/Debug.xcconfig` / `Release.xcconfig`.
- New `codemagic.yaml` (`ios-release` → TestFlight).
- Not built on a Mac yet: the first Codemagic run is the first real iOS build.
