# Maharaja Solutions – Insurance Reminder App (Flutter)

Offline app to manage Insurance, Fitness and PUC expiries with local notifications, calendar view, and Google Drive backup/restore.

## Features
- Add customers/vehicles with three expiry dates
- Auto reminders at **20 days**, **10 days**, **2 days**, **on the day**, and **after expiry**
- Calendar view of expiries
- Offline SQLite storage
- Google Drive backup & restore (manual from menu)

## Getting Started

### 1) Prerequisites
- Flutter SDK (3.22+)
- Android Studio or VS Code
- Android device/emulator

### 2) Setup
```bash
flutter pub get
```

### 3) Android notification/timezone setup
No extra steps needed; the app uses `flutter_local_notifications` with timezone init.

### 4) Google Drive Backup
Create an **OAuth 2.0 Client ID (Android)** in Google Cloud Console and configure the SHA-1 of your debug/release keystores.
This sample uses **google_sign_in** directly. On the first backup/restore, you'll be prompted to sign in.

### 5) Build APK
```bash
flutter build apk --release
```
The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

### 6) Branding
- App name: *Maharaja Solutions – Insurance Reminder*
- Logo placed at `assets/images/ms_logo.jpg` and referenced in `pubspec.yaml`.
You can later replace launcher icon via `flutter_launcher_icons` if desired.
