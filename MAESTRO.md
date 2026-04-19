# Maestro E2E Testing for TWSNMP FM

This project uses [Maestro](https://maestro.mobile.dev/) for End-to-End (E2E) testing.

## Prerequisites

1.  **Install Maestro CLI:**
    Follow the [official installation guide](https://docs.maestro.mobile.dev/getting-started/installing-maestro).
2.  **Flutter 3.19+:**
    This project uses the `identifier` property in the `Semantics` widget for stable element targeting.

## Setup for Flutter

Maestro interacts with the accessibility layer of the application. Key UI elements are wrapped in `Semantics` widgets with unique identifiers.

### Example targeting in Dart:
```dart
Semantics(
  identifier: 'add_node_fab',
  child: FloatingActionButton(...),
)
```

### Example usage in Maestro Flow (.yaml):
```yaml
- tapOn:
    id: "add_node_fab"
```

## Running Tests

### 1. Start an Emulator or Simulator
Ensure an Android Emulator or iOS Simulator is running.

### 2. Build and Run the App
Maestro works with the installed app. Run the app in debug or profile mode:
```bash
flutter run
```

### 3. Run Maestro Flow
Run the smoke test flow:
```bash
maestro test .maestro/smoke_test.yaml
```

To run all flows in the directory:
```bash
maestro test .maestro/
```

## Best Practices for TWSNMP FM
- **Avoid hardcoded strings:** Use `id` (Semantics identifier) whenever possible to make tests resistant to localization (i10n) changes.
- **Wait for elements:** Maestro commands like `- tapOn:` and `- assertVisible:` implicitly wait for elements to appear (up to a default timeout). Use `- assertVisible:` with an `id` to ensure an element is ready, or `- waitForAnimationToEnd` if the app performs asynchronous UI transitions.
