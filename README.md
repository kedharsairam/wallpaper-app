# WallKraft

Browse, download, and favorite high-resolution wallpapers.

## Download

Download the latest APK from the [Releases](https://github.com/kedharsairam/wallpaper-app/releases) page.

Choose the right APK for your device:
- **arm64-v8a** — most modern phones (recommended)
- **armeabi-v7a** — older 32-bit devices
- **x86_64** — emulators and Chromebooks

## Build from Source

```bash
flutter pub get
flutter build apk --release --split-per-abi
```

## Tech Stack

- Flutter 3.x
- SQLite (sqflite)
- No analytics, no telemetry, no personal data collection
