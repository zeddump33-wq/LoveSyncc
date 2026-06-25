# LoveSync — Complete Setup Guide

## Firebase Console Setup

### 1. Create Firebase Project
Go to https://console.firebase.google.com → **Create project** → name it `LoveSync` → disable Analytics → **Create**

### 2. Add Android App
- **Add app** → **Android**
- Package name: `com.lovesync.app` → **Register app**
- **Download `google-services.json`** → save to `android/app/google-services.json`
- **Add SHA-1 fingerprint** (required for Google Sign-In):
  ```powershell
  cd android
  .\gradlew signingReport
  ```
  Copy the SHA-1 from `debug` variant → Firebase Console → **Project Settings** → **General** → **Add fingerprint** → paste SHA-1 → **Save**
- Click **Next** (skip remaining steps)

### 3. Add iOS App
- **Add app** → **iOS**
- Bundle ID: `com.lovesync.app` → **Register app**
- **Download `GoogleService-Info.plist`** → save to `ios/Runner/GoogleService-Info.plist`
- Click **Next** (skip remaining steps)

### 4. Enable Firestore Database
- **Firestore Database** → **Create database**
- Choose **Start in test mode** → pick a location → **Enable**
- Go to **Rules** tab → paste contents of `firestore.rules` from project → **Publish**

### 5. Enable Google Sign-In (Authentication)
- **Authentication** → **Sign-in method**
- Click **Google** → **Enable**
- Public-facing name: `LoveSync`
- Support email: your email
- Click **Save**

---

## Windows — Build Android APK

```powershell
flutter build apk --release
```

APK at `build/app/outputs/flutter-apk/app-release.apk` (55MB). Install on both phones.

---

## GitHub — Push Code

```powershell
git add -A
git commit -m "Full Firebase setup + Google Sign-In"
git remote add origin https://github.com/YOUR_USERNAME/LoveSync.git
git branch -M main
git push -u origin main
```

> **Important**: the files `google-services.json` and `GoogleService-Info.plist` contain API keys but are **required** in the repo for builds. The repo is private, so this is safe.

---

## Codemagic — Build iOS

1. Go to https://codemagic.io → login with GitHub
2. **Add your repository** → select `LoveSync`
3. **Set environment variables** (from App Store Connect):
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_KEY_IDENTIFIER`
   - `APP_STORE_CONNECT_PRIVATE_KEY`
   - `CERTIFICATE_PRIVATE_KEY`
4. **Push to `main`** → Codemagic auto-detects `codemagic.yaml` → builds Android + iOS

---

## Verify Everything Works

1. Install APK on both phones
2. Phone 1: tap **Continue with Google** → sign in → should see "Create Invite Code"
3. Phone 2: tap **Continue with Google** → sign in → tap **Connect** → enter Phone 1's code
4. Both phones should now show "Connected!" with days together
5. Chat should work in real-time between both phones
