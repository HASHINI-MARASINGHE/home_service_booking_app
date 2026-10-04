# Onboarding implementation report

## Files created

| File | Responsibility |
| --- | --- |
| `lib/screens/onboarding/onboarding_screen.dart` | Three-page PageView; Next, swipe, Skip, Get Started, indicators, save-in-progress/error handling, pinned footer and SafeArea. |
| `lib/screens/onboarding/onboarding_page.dart` | Shared onboarding palette/theme, image/copy layout, and the two customer/provider experience cards. |
| `lib/screens/onboarding/onboarding_gate.dart` | Reads first-launch state; shows onboarding or the existing AuthWrapper; supports loading/retry and debug reset. |
| `lib/screens/onboarding/onboarding_preferences.dart` | Reads, writes and resets only the onboarding-completed boolean. |
| `test/onboarding_test.dart` | 14 onboarding tests covering navigation, persistence logic, existing auth handoff, error recovery and responsive layouts. |
| `docs/onboarding.md` | This report and Pixel 7 testing instructions. |

## Existing files modified by this task

| File | Change |
| --- | --- |
| `lib/main.dart` | Changes only the entry import and home widget from AuthWrapper to OnboardingGate. Firebase initialization remains unchanged. |
| `pubspec.yaml` | Adds shared_preferences and registers the four supplied image paths. |
| `pubspec.lock` | Resolves shared_preferences and its transitive platform/support packages. No existing package versions were upgraded. |
| `macos/Flutter/GeneratedPluginRegistrant.swift` | Flutter-generated import and registration for shared_preferences_foundation. |

Existing provider changes and other untracked files were present before this task. They were not rewritten, committed or removed. A SHA-256 comparison against the initial files found changes only in the four existing files listed above.

## Dependency and assets

Added `shared_preferences: ^2.5.5`, resolved to 2.5.5, using its SharedPreferencesAsync API. The package documents this asynchronous local preference API in the [official package documentation](https://pub.dev/packages/shared_preferences/versions/2.5.5). Fourteen packages were added in total including transitive platform/support packages; existing direct Firebase dependencies are unchanged. The resolved Flutter SDK floor in the lockfile is now 3.44.0; this workspace uses Flutter 3.47.0.

These exact existing files are explicitly registered in pubspec.yaml and used:

- `assets/images/onboarding_home.jpg` — page 1.
- `assets/images/onboarding_connection.jpg` — page 2.
- `assets/images/onboarding_customer.jpg` — left card on page 3.
- `assets/images/onboarding_provider.jpg` — right card on page 3.

All four images are byte-for-byte unchanged. No image was downloaded, generated or replaced. Clipping and BoxFit.cover preserve aspect ratio; the connection photo uses a wider container so faces remain visible.

## Routing and persistence

Startup remains Firebase initialization → MyApp. MyApp now opens OnboardingGate:

1. Await the local `onboarding_completed` flag.
2. Missing/false → show the three onboarding pages.
3. Skip on page 1 or 2, or Get Started on page 3 → await saving true.
4. Replace the gate's content with the existing AuthWrapper.
5. On later starts, true → AuthWrapper directly.

AuthWrapper still owns login/register selection, Firebase session restoration, profile retrieval and customer/provider role routing. Completing onboarding does not push an extra route that Back could return to. If an existing authenticated user completes onboarding, AuthWrapper resumes their normal role destination.

Only the one boolean is stored by onboarding. No credentials, roles or user profiles are copied into preferences. The flag is installation-local, not account-specific. Signing out does not reset it. Read failures offer Retry; failed saves stay on onboarding with feedback instead of pretending persistence succeeded.

For development, `OnboardingPreferences.reset()` removes only this key. A debug-only `--dart-define=RESET_ONBOARDING=true` invokes that reset on startup. Run without this define afterward; otherwise each debug restart deliberately resets onboarding. Release builds ignore it.

## UI behavior

The onboarding theme is local, using the requested teal/navy/light palette. Login/Register and provider/customer styling remain unchanged. No logo or app name was added. Next advances pages, horizontal swipes work in both directions, and the active indicator follows the selected page. Page 3 has no Skip.

Bottom controls remain outside the scrollable page content. On smaller screens, landscape or large text settings, content can scroll without pushing the button out of SafeArea. The third page retains two side-by-side cards. Optional photo labels were omitted to keep the images clear.

The supplied text specification and existing photos were used; no separate onboarding Figma screenshot/file was attached in this turn, so pixel-for-pixel Figma equivalence is not claimed.

## Commands and actual results

| Executed command/check | Result |
| --- | --- |
| `flutter pub get` | Passed; dependency and assets registered. Reported eight newer incompatible package versions; unrelated packages were not upgraded. |
| `dart format lib/screens/onboarding lib/main.dart test/onboarding_test.dart` | Completed; subsequent formatting covered the final crop edit. |
| `flutter analyze` | Final run passed: no issues found. |
| `flutter test --no-pub test/onboarding_test.dart test/provider_workflow_test.dart test/provider_screens_test.dart test/provider_actions_test.dart` | Final run: **27 passed** — 14 onboarding tests plus 13 existing provider tests. |
| `flutter test --no-pub test/widget_test.dart` | **1 failed**: obsolete starter counter test expects text “0”, which no longer exists. Left unchanged. |
| `flutter devices` / `flutter emulators` | Discovered the existing Pixel_7 AVD. |
| Background Pixel_7 launch and ADB boot check | Emulator booted successfully as emulator-5554; it was shut down after testing without wiping its data. |
| `flutter run -d emulator-5554 --debug --no-pub --dart-define=RESET_ONBOARDING=true` | Android build failed downloading AGP 8.13.1 from Google Maven. Its automatic retry was stopped. No new APK was installed. |
| Temporary preview widget test outside the repository | Passed; rendered all three pages at 411×914 with the supplied assets for visual crop/layout inspection. This was not an installed-device test. |
| `git diff --check` | Passed; Git printed existing LF/CRLF notices. |
| Initial-vs-final SHA-256 comparison | Auth/customer/provider source, booking/profile models/services, Firebase options, existing tests and supplied assets were unchanged. |

The 14 onboarding tests execute Next, both swipe directions, indicator changes, Skip on both eligible pages, Get Started, save-before-routing, duplicate-tap protection, completion across preference-wrapper/gate recreation, isolated reset, preference read/write failures, existing Login/Register switching, and existing authenticated customer routing with a fake auth service.

Responsive tests cover 411×914 (Pixel 7 logical dimensions), 320×568, 740×360 landscape, and 2× text scale. No RenderFlex exceptions occurred, and footer placement inside the safe area was asserted.

Native on-disk persistence and end-to-end Firebase login on Pixel 7 were **not** executed because the APK build was blocked. Preference tests use a fake SharedPreferencesAsync; customer routing tests use the unchanged AuthWrapper with a fake auth service. Provider role-routing source was preserved and provider regression tests passed; a live provider sign-in is not claimed.

## Android build issue

Gradle failed to fetch:

`https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/8.13.1/gradle-8.13.1.jar`

The primary error was a connection timeout to dl.google.com:443 while configuring shared_preferences_android. Gradle also printed follow-on project configuration/Kotlin plugin errors after that missing artifact. Android configuration was not altered to work around this network failure. Retry with access to Google Maven restored.

The old starter counter test is a separate issue and does not describe the current app. No unrelated functionality or test was changed to make it pass.

## Exact Pixel 7 commands to run next

From the project directory, with network access to pub.dev and Google's Android Maven repository:

```powershell
flutter pub get
flutter emulators --launch Pixel_7
flutter devices
flutter run -d emulator-5554
```

Wait for the emulator to finish booting. If flutter devices lists a different device ID, substitute that ID for emulator-5554.

To deliberately replay onboarding once:

```powershell
flutter run -d emulator-5554 --dart-define=RESET_ONBOARDING=true
```

After completing/skipping, quit that debug run with `q`, then run WITHOUT the reset define:

```powershell
flutter run -d emulator-5554
```

Complete/skip onboarding in the normal run if necessary, then close and reopen the app to verify the native persisted flag. Verify Next 1→2→3, swipe/indicator changes, absence of Skip on page 3, Get Started/Skip handoff, Login/Register switching, and login with your existing customer/provider accounts. No real account creation or credentials are required by these code changes.

To rerun the passing automated checks:

```powershell
flutter analyze
flutter test --no-pub test/onboarding_test.dart test/provider_workflow_test.dart test/provider_screens_test.dart test/provider_actions_test.dart
```

The implementation remains uncommitted on `Hashini`. No branch switch, commit, push, merge, reset, deletion or renaming was performed. No next development phase was started.
