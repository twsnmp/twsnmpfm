# Project Overview: TWSNMP for Mobile (twsnmpfm)

`twsnmpfm` is a mobile SNMP manager developed using Flutter. It is the mobile version of the classic TWSNMP tool, providing features like node monitoring, SNMP resource checks (CPU, Memory, Disk), MIB browsing, and traffic measurement.

## Main Technologies
- **Framework:** Flutter (Dart)
- **State Management:** Riverpod (using `ChangeNotifierProvider` and `ConsumerWidget`)
- **Persistence:** `shared_preferences` for storing node data and settings.
- **SNMP/Network:** `dart_snmp`, `dart_ping`, `udp`, `ntp`.
- **UI/Charts:** `fl_chart`, `flutter_simple_treeview`.
- **Localization:** Flutter's standard l10n with `.arb` files (English and Japanese supported).

## Directory Structure
- `lib/`: Contains all source code. The structure is relatively flat.
    - `main.dart`: Application entry point.
    - `node.dart`: Data model and provider for SNMP nodes.
    - `settings.dart`: Application settings and provider.
    - `*_page.dart`: Individual UI pages (e.g., `node_list_page.dart`, `ping_page.dart`).
    - `l10n/`: Localization files (`.arb`).
    - `assets/images/`: App icons and images.
- `assets/conf/`: Configuration files like `mib.txt`, `services.txt`, and `mac-vendors-export.csv`.
- `test/`: Unit and widget tests.

## Building and Running

### Prerequisites
- Flutter SDK installed.
- iOS/Android/macOS development environment set up.

### Key Commands
- **Install dependencies:** `flutter pub get`
- **Run the app:** `flutter run`
- **Build APK (Android):** `flutter build apk`
- **Build iOS (macOS only):** `flutter build ios`
- **Build Web:** `flutter build web`
- **Build macOS:** `flutter build macos`
- **Run tests:** `flutter test`
- **Update Localization:** `flutter gen-l10n` (if `l10n.yaml` is present and `generate: true` is set in `pubspec.yaml`).

## Development Conventions
- **State Management:** Use Riverpod for providing state to widgets.
- **Data Models:** Models should include `toMap()` and `fromMap()` methods for easy serialization to/from JSON for persistence.
- **Localization:** Always use `AppLocalizations.of(context)!` for user-facing strings.
- **Testing:** Add unit tests for logic changes in `test/` and widget tests for new UI components.
- **Linter:** Follow the rules defined in `analysis_options.yaml` (uses `flutter_lints`).
