# PDF Vault

`PDF Vault` is a Flutter app for Android and iOS that removes password protection from a PDF when the user already knows the password.

## App Icon

![PDF 解密 App Icon](assets/branding/app-icon.png)

## What This Project Does

- Input: an encrypted PDF file and its known password
- Output: a new unlocked PDF file without password protection

This repository currently focuses on a single-file unlock flow. It does not yet handle batch jobs or re-encryption.

## Tech Stack

- Flutter
- Dart
- `decrypt_pdf` for PDF unlocking
- `file_picker` for selecting input files
- `flutter_file_dialog` for exporting the unlocked file

## Project Structure

```text
lib/
├── app/                  # App shell and theme
├── core/pdf/             # Core PDF unlock interface and implementation
└── features/pdf_unlock/  # UI for the unlock flow

test/
└── core/pdf/             # Core-layer tests
```

## Install Dependencies

Assumption: Flutter/Dart is already installed and available in PATH.

```bash
cd <repo-root>
flutter pub get
```

Optional environment verification:

```bash
flutter doctor -v
```

## Android SDK Setup (Official CLI Path)

You can install the official Android SDK components without Android Studio. This uses Google's Android SDK Command-line Tools (`sdkmanager`) distributed through Homebrew.

```bash
brew install openjdk@17 android-commandlinetools android-platform-tools
```

Add environment variables to `~/.zshrc`:

```bash
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export ANDROID_SDK_ROOT=/opt/homebrew/share/android-commandlinetools
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin"
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
```

Install required SDK packages and accept licenses:

```bash
yes | sdkmanager --licenses
sdkmanager \
  "platform-tools" \
  "platforms;android-36" \
  "build-tools;35.0.0" \
  "cmdline-tools;latest"
flutter config --android-sdk /opt/homebrew/share/android-commandlinetools
flutter doctor -v
```

## Development Workflow

Start development (choose one target):

```bash
cd <repo-root>
flutter run -d ios
flutter run -d android
```

Code quality checks:

Run these after code changes:

```bash
dart format lib test
flutter analyze
flutter test
```

`flutter test` is currently lightweight and mainly covers core error mapping. `format` and `analyze` are the baseline quality gate for every change.

## Build Outputs

### iOS build

Debug build:

```bash
cd <repo-root>
flutter build ios --debug
```

Release build (no codesign):

```bash
cd <repo-root>
flutter build ios --release --no-codesign
```

Package sideload IPA (AltStore/SideStore/Sideloadly):

```bash
cd <repo-root>
TAG="v1.0.1"
flutter build ios --release --no-codesign
rm -rf Payload
mkdir Payload
cp -R build/ios/iphoneos/Runner.app Payload/
zip -qry "pdf-vault-ios-${TAG}.ipa" Payload
rm -rf Payload
```

Open Xcode project for archive/signing/export:

```bash
open ios/Runner.xcworkspace
```

### Android build

Debug APK:

```bash
cd <repo-root>
flutter build apk --debug
```

Release APK:

```bash
cd <repo-root>
flutter build apk --release
```

Smaller release APKs by CPU ABI (recommended for local distribution/testing):

```bash
cd <repo-root>
flutter build apk --release --split-per-abi
```

Notes:

- Current Android `release` build uses the debug signing key in `android/app/build.gradle.kts` for local testing/distribution, not production signing.
- For most modern Android phones, install `app-arm64-v8a-release.apk`.
- If R8 fails with missing `com.gemalto.jp2.*` classes, add `-dontwarn` rules in `android/app/proguard-rules.pro`.

Release App Bundle (Play Store):

```bash
cd <repo-root>
flutter build appbundle --release
```

## CI and Release

GitHub Actions are split into two lanes:

- `CI` runs on pull requests, pushes to `main`, and manual dispatch. It checks formatting, analysis, tests, Android debug build, and iOS debug build.
- `Release` runs from version tags like `v1.1.0`. It rebuilds release assets from the tagged source and publishes a GitHub Release.

The app version lives in `pubspec.yaml`:

```yaml
version: 1.1.0+2
```

Use the release helper when publishing the current `main`:

```bash
scripts/release_main.sh v1.1.0
```

For tagged releases, GitHub Actions now publishes both iOS assets:

- `pdf-vault-ios-vX.Y.Z.ipa` for sideload users
- `pdf-vault-ios-unsigned-vX.Y.Z.zip` for developers

See [Release Workflow](docs/release.md) for the full `git`/`gh` flow.

## iOS Install (GitHub Release Sideload)

The iOS build is distributed as an `.ipa` in GitHub Releases.

Because of iOS platform restrictions, the `.ipa` is not directly installable from Safari. Use a sideload tool such as AltStore, SideStore, or Sideloadly.

Manual IPA install:

1. Download latest `pdf-vault-ios-vX.Y.Z.ipa` from Releases.
2. Open AltStore / SideStore / Sideloadly on your computer or device.
3. Select the `.ipa` file.
4. Sign with your own Apple ID and install.

Optional AltStore source mode:

- Host an AltStore source JSON and add it in AltStore.
- Template: `docs/AltStore.source.example.json`

Sideload limitations:

- Not App Store distribution.
- Not one-tap Safari install.
- Requires user-side signing with Apple ID.
- Free Apple ID usually requires periodic refresh.
- Sideloaded app count is limited by Apple policy.

## Manual Validation

Suggested flow:

1. Launch the app.
2. Select any password-protected PDF on your device/simulator.
3. Enter the known password.
4. Unlock the file and export the decrypted PDF.

## Git Workflow

Typical local development flow:

```bash
git status
git checkout -b feature/some-change
git add .
git commit -m "feat: describe your change"
git push -u origin feature/some-change
```

## GitHub CLI Workflow

This repository is intended to work well with `gh`:

```bash
gh auth status
gh repo view
gh issue list
gh pr status
gh pr create
gh pr view --web
```

Common examples:

- Check login: `gh auth status`
- See current repo info: `gh repo view`
- Open a PR after pushing a branch: `gh pr create`
- Inspect CI or PR state: `gh pr status`

## Notes

- This app is designed as `UI + Core`.
- UI should not directly own PDF decryption logic.
- Core should remain replaceable if the underlying PDF library changes later.
