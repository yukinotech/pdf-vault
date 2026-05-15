# Release Workflow

This project separates continuous integration from release publishing.

- CI proves that a commit is healthy.
- A git tag freezes a version, for example `v1.1.0`.
- A GitHub Release publishes assets built from that exact tag.

The app version is maintained in `pubspec.yaml`:

```yaml
version: 1.1.0+2
```

The part before `+` is the product version and must match the git tag without
the leading `v`. The part after `+` is the Flutter build number.

## Standard AI Release Flow

When asked to release the current `main`, the agent should use `git` and `gh`
instead of creating releases by hand in the browser.

1. Make sure the intended feature PRs are merged into `main`.
2. Choose the release version. If the user does not specify one, use the
   current version from `pubspec.yaml`.
3. Run:

```bash
scripts/release_main.sh v1.1.0
```

The script will:

- switch to `main`
- fast-forward from `origin/main`
- update `pubspec.yaml` when needed
- commit and push the version bump when needed
- wait for the `CI` workflow on `main`
- create and push an annotated tag
- wait for the `Release` workflow
- print the GitHub Release URL

If the shell still contains a stale `GITHUB_TOKEN`, the script ignores it by
default and uses the local `gh` keyring login. Set
`PDF_VAULT_USE_ENV_GH_TOKEN=1` only when intentionally releasing with an
environment token.

## Release Assets

The `Release` workflow builds these assets from the tagged source:

- split Android release APKs
- Android release app bundle
- unsigned iOS release app zip

The Android release assets currently follow the repository's local release
signing setup. The iOS zip is unsigned and is meant for verification only until
App Store signing is configured.
