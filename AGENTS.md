# AGENTS.md

This file gives repository-specific guidance to AI coding agents and human collaborators working in this project.

## Project Intent

Build a Flutter mobile app that unlocks password-protected PDF files on Android and iOS.

Current v1 scope:

- User selects one encrypted PDF
- User enters a known password
- App generates and exports an unlocked PDF

Out of scope for now:

- Batch processing
- Re-encryption
- Desktop targets
- Cloud sync or backend services

## Architecture Rules

- Keep the project split as `UI + Core`.
- UI lives under `lib/features/pdf_unlock/`.
- App shell and theme live under `lib/app/`.
- PDF logic lives under `lib/core/pdf/`.
- UI may call the Core interface, but should not directly depend on low-level PDF package details.
- If the PDF library changes later, preserve the Core interface shape whenever possible.

## Core Contract

The main unlock entry point should stay centered around:

```dart
decryptPdf({
  required String inputPath,
  required String password,
  required String outputPath,
})
```

The result object should continue to carry:

- success or failure
- output path when available
- typed error classification
- user-facing message

Current error categories:

- invalid password
- unreadable input
- unsupported document
- output write failed
- cancelled
- unknown

## Development Expectations

- Prefer small, clear changes over broad refactors.
- Preserve the mobile-first scope.
- Do not add state-management frameworks unless they are clearly needed.
- Keep UI branded and intentional, but avoid turning the app into a multi-screen flow unless requested.
- Do not move PDF logic into widgets.

## Validation After Changes

Run these commands after implementation work:

```bash
dart format lib test
flutter analyze
flutter test
```

If a change affects platform file handling or export behavior, also do a manual verification on Android or iOS when possible.

## Repository Conventions

- Main workspace path: `/Users/zyf/workspace/pdf-vault`
- Git remote uses SSH
- Prefer `gh` for GitHub workflow and `git` for commits/history
- App versions live in `pubspec.yaml` as `MAJOR.MINOR.PATCH+BUILD`.
- Release tags use `vMAJOR.MINOR.PATCH` and must match the `pubspec.yaml` product version.

Useful commands:

```bash
git status
git add .
git commit -m "feat: message"
git push
gh repo view
gh pr status
gh pr create
```

## Release Expectations

When the user asks to release the current `main`, use the repository release helper:

```bash
scripts/release_main.sh v1.1.0
```

If the user does not specify a version, inspect `pubspec.yaml` and existing tags before deciding whether to reuse the current version or ask for a version bump. The helper switches to `main`, fast-forwards from `origin/main`, updates `pubspec.yaml` when needed, waits for CI, creates an annotated tag, pushes it, and waits for the Release workflow.

Do not publish a GitHub Release directly from a random CI artifact. The release workflow should rebuild assets from the tagged source and attach those assets to the GitHub Release.

## Test Data

- `data/` is ignored by git in this repository.
- For manual validation, use local sample PDFs/passwords that are not committed.
