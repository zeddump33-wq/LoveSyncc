# LoveSync 💕

A modern couple app built with Flutter, featuring a completely free backend with offline-first design.

## Features

- **Couple Profiles** - Partner linking with invite codes
- **Private Chat** - Local chat with images, voice notes, and emojis
- **Shared Calendar** - Events, anniversaries, reminders
- **Love Counter** - Days together counter
- **Memories** - Photo albums with local storage
- **Couple Goals** - Savings and travel goals
- **Couple Games** - Truth or Dare, Love Quiz, Daily Challenges, Would You Rather
- **Wishlist** - Shared gift ideas
- **Love Notes** - Private notes and future messages
- **Daily Check-In** - Mood tracking with streak system
- **Statistics Dashboard** - Track your relationship stats
- **Security** - PIN lock, biometric authentication, local encryption

## Tech Stack

- **Flutter** - Cross-platform framework (mobile + web)
- **SQLite** (sqflite / sqflite_common_ffi_web) - Local database
- **Hive** - Caching
- **SharedPreferences** - Settings storage
- **Provider** - State management
- **Local Auth** - Biometric authentication
- **Encrypt** - AES-256 local data encryption
- **Firebase** - Optional real-time sync (Firestore + Auth)
- **PWA** - Progressive Web App for Android support
- **sql.js** (WebAssembly) - SQLite for web browsers

## Project Structure

```
lovesync/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   ├── utils/
│   │   ├── services/
│   │   └── widgets/
│   ├── models/
│   ├── providers/
│   └── screens/
│       ├── splash/
│       ├── onboarding/
│       ├── auth/
│       ├── home/
│       ├── chat/
│       ├── calendar/
│       ├── memories/
│       ├── goals/
│       ├── games/
│       ├── wishlist/
│       ├── love_notes/
│       ├── checkin/
│       ├── profile/
│       └── statistics/
├── database/
├── assets/
└── android/ & ios/ config
```

## Database Schema

### Tables
- `users` - User profiles
- `couples` - Couple relationships
- `messages` - Chat messages
- `memories` - Photo memories
- `memory_albums` - Memory album organization
- `events` - Calendar events
- `goals` - Couple goals
- `goal_steps` - Goal sub-tasks
- `wishlist` - Gift ideas
- `love_notes` - Love notes and future messages
- `moods` - Daily mood tracking
- `check_ins` - Daily check-in answers
- `games` - Game history
- `milestones` - Relationship milestones
- `notifications` - Notification history

## Deployment Guide

### Android (APK)

```bash
# Build APK
flutter build apk --release

# APK location: build/app/outputs/flutter-apk/app-release.apk

# Build app bundle (for Play Store)
flutter build appbundle --release
```

### iOS (IPA)

```bash
# Build IPA
flutter build ios --release

# Open in Xcode for archiving
open ios/Runner.xcworkspace
# Product -> Archive -> Export IPA
```

### Web (PWA + Android)

LoveSync runs as a Progressive Web App (PWA) on both desktop and mobile browsers, including Android.

```bash
# Development
flutter run -d chrome

# Build for production
flutter build web --release

# Build with PWA service worker
flutter build web --release --pwa

# Output: build/web/
# Deploy the entire build/web/ directory to any static host
```

**Firebase Hosting (recommended):**
```bash
npm install -g firebase-tools
firebase init hosting
# Set public directory to 'build/web'
firebase deploy --only hosting
```

**Android PWA Support:**
- Open the deployed URL in Chrome on Android
- Chrome will prompt "Add LoveSync to Home screen"
- The app runs fullscreen with offline support via service worker
- Push notifications are supported via the Web Push API

### Setup Requirements

1. **Flutter SDK** (3.0+):
   ```bash
   # Install from: https://flutter.dev/docs/get-started/install
   flutter doctor
   ```

2. **Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Firebase Setup** (optional - for email/Google auth):
   - Create project at console.firebase.google.com
   - For web: Add a Web app in Firebase Console, copy config to `lib/firebase_options.dart`
   - For Android: Add Android app with package `com.lovesync.app`
   - For iOS: Add iOS app with bundle ID from Xcode
   - Download `google-services.json` -> `android/app/`
   - Download `GoogleService-Info.plist` -> `ios/Runner/`

4. **Android Permissions** are configured in `AndroidManifest.xml`

5. **iOS Permissions** are configured in `Info.plist`

### Running

```bash
# Development
flutter run                   # Auto-detect device
flutter run -d chrome         # Web
flutter run -d android        # Android

# Build
flutter build apk --release   # Android
flutter build ios --release   # iOS
flutter build web --release   # Web (PWA)
```

## Architecture

- **Offline-First**: All data stored locally in SQLite
- **No Cloud Storage**: Images stored on device only
- **No Backend Required**: Works completely offline
- **Partner Linking**: Via invite codes over local network
- **Local Auth**: Email/password simulated locally, or local accounts
- **Encryption**: AES-256 for sensitive local data

## State Management

Uses `Provider` pattern. Each feature has its own provider:
- `AuthProvider` - Authentication state
- `CoupleProvider` - Couple relationship data
- `ChatProvider` - Message handling
- `CalendarProvider` - Event management
- `MemoriesProvider` - Photo albums
- `GoalsProvider` - Goal tracking
- `GamesProvider` - Game logic
- `WishlistProvider` - Gift ideas
- `LoveNotesProvider` - Love notes
- `CheckInProvider` - Mood and check-in
- `StatisticsProvider` - Relationship stats
- `ThemeProvider` - Dark/Light mode

## License

MIT
