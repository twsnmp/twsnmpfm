# Project Overview: TWSNMP for Mobile (twsnmpfm)

`twsnmpfm` is a mobile SNMP manager developed using Flutter (currently targetting Flutter 3.41.6). It is the mobile version of the classic TWSNMP tool, providing features like node monitoring, SNMP resource checks (CPU, Memory, Disk), MIB browsing, traffic measurement, and automated status checks.

## Main Technologies
- **Framework:** Flutter (Dart)
- **State Management:** Riverpod (using `ChangeNotifierProvider` and `ConsumerWidget`)
- **Persistence:** `shared_preferences` for storing node data and settings.
- **SNMP/Network:** `dart_snmp`, `dart_ping`, `dart_ping_ios`, `udp`, `ntp`.
- **UI/Charts:** `fl_chart`, `google_fonts`.
- **Localization:** Flutter's standard l10n with `.arb` files (English and Japanese supported).
- **Utility/Analysis:** `basic_utils`, `statistics`, `ml_algo`.

## Directory Structure
- `lib/`: Contains all source code. The structure is relatively flat.
    - `main.dart`: Application entry point.
    - `node.dart`: Data model and provider for SNMP nodes.
    - `settings.dart`: Application settings and provider.
    - `*_page.dart`: Individual UI pages (e.g., `node_list_page.dart`, `ping_page.dart`).
    - `l10n/`: Localization files (`.arb`).
    - `assets/images/`: App icons and images.
- `assets/conf/`: Configuration files like `mib.txt`, `services.txt`, and `mac-vendors-export.csv`.
- `test/`: Unit and widget tests. Includes mocking for `shared_preferences`.
- `devtools_options.yaml`: DevTools configuration.

## Building and Running

### Prerequisites
- Flutter SDK installed (3.41.6 or compatible).
- iOS/Android/macOS development environment set up.
- [mise](https://mise.jdx.dev/) for toolchain management.

### Setup Environment
Before the first build, run the setup task to install Android SDK components and CocoaPods:
```bash
mise run setup
```
*Note: This task requires `sdkmanager` and `gem` (provided by mise tools).*

### Key Commands
- **Install dependencies:** `flutter pub get`
- **Run the app:** `flutter run`
- **Build APK (Android):** `mise run build:apk`
- **Build iOS (macOS only):** `mise run build:ios`
- **Build Web:** `flutter build web`
- **Build macOS:** `flutter build macos`

### Build Notes
- **Android SDK:** The Android SDK is managed via `mise` and installed to `~/Library/Android/sdk` by default. If `flutter doctor` fails to find it, run `flutter config --android-sdk ~/Library/Android/sdk`.
- **Xcode Components:** If the iOS build fails with "iOS SDK not installed," open Xcode > Settings > Components and download the latest iOS platform.
- **Info.plist:** `ios/Runner/Info.plist` is essential for the iOS build. Do not delete it.

## Development Conventions
- **State Management:** Use Riverpod for providing state to widgets. `ChangeNotifierProvider` is currently the primary provider type for global state.
- **Data Models:** Models should include `toMap()` and `fromMap()` methods for easy serialization to/from JSON for persistence.
- **Asynchronous Safety:** Always use `if (mounted)` or equivalent checks before calling `setState` or accessing `BuildContext` after an `await` within a `StatefulWidget`.
- **UI Styling:** Prefer using `Theme.of(context).colorScheme` for consistent color management across light and dark modes.
- **Tree Management:** Use custom `MibNode` implementations for tree structures (as seen in `search_page.dart`) instead of external treeview libraries where possible for better control.
- **Localization:** Always use `AppLocalizations.of(context)!` for user-facing strings. The application supports manual language switching (System, English, Japanese) via the settings page.
- **Testing:** Add unit tests for logic changes in `test/` and widget tests for new UI components. Ensure `SharedPreferences` is mocked for tests that involve persistence.
- **Linter:** Follow the rules defined in `analysis_options.yaml` (uses `flutter_lints`).
