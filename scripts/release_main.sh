#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/release_main.sh [vMAJOR.MINOR.PATCH] [--build-number N] [--skip-ci-check]

Examples:
  scripts/release_main.sh
  scripts/release_main.sh v1.1.0
  scripts/release_main.sh 1.1.0 --build-number 4

This script prepares a release from the current main branch:
  1. Switches to main and fast-forwards from origin/main.
  2. Updates pubspec.yaml when the requested version differs.
  3. Commits and pushes the version bump when needed.
  4. Waits for the CI workflow on main to pass.
  5. Creates and pushes an annotated release tag.
  6. Waits for the Release workflow triggered by that tag.

By default, GitHub CLI commands ignore GH_TOKEN/GITHUB_TOKEN from the
environment and use the local gh keyring login. Set PDF_VAULT_USE_ENV_GH_TOKEN=1
to use environment tokens intentionally.
USAGE
}

gh_cmd() {
  if [ "${PDF_VAULT_USE_ENV_GH_TOKEN:-}" = "1" ]; then
    gh "$@"
  else
    env -u GH_TOKEN -u GITHUB_TOKEN gh "$@"
  fi
}

die() {
  echo "error: $*" >&2
  exit 1
}

release_arg=""
build_number=""
skip_ci_check="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --build-number)
      shift
      [ "$#" -gt 0 ] || die "--build-number requires a value"
      build_number="$1"
      ;;
    --skip-ci-check)
      skip_ci_check="true"
      ;;
    v*|[0-9]*)
      [ -z "$release_arg" ] || die "release version was provided more than once"
      release_arg="$1"
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
  shift
done

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

[ -f pubspec.yaml ] || die "pubspec.yaml not found"
[ -f .github/workflows/ci.yml ] || die "CI workflow not found"
[ -f .github/workflows/release.yml ] || die "Release workflow not found"

if [ -n "$(git status --porcelain)" ]; then
  die "working tree is not clean; commit or stash changes before releasing"
fi

gh_cmd auth status >/dev/null

git fetch origin main --tags
git switch main
git pull --ff-only origin main

current_pubspec_version="$(awk '/^version:/ { print $2; exit }' pubspec.yaml)"
[ -n "$current_pubspec_version" ] || die "could not read version from pubspec.yaml"

current_app_version="${current_pubspec_version%%+*}"
current_build_number="${current_pubspec_version#*+}"
if [ "$current_build_number" = "$current_pubspec_version" ]; then
  current_build_number="0"
fi

case "$current_build_number" in
  ''|*[!0-9]*) die "pubspec build number must be numeric; got ${current_pubspec_version}" ;;
esac

if [ -z "$release_arg" ]; then
  release_version="$current_app_version"
else
  release_version="${release_arg#v}"
fi

if ! [[ "$release_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  die "release version must look like 1.2.3 or v1.2.3"
fi

if [ -z "$build_number" ]; then
  if [ "$release_version" = "$current_app_version" ]; then
    build_number="$current_build_number"
  else
    build_number="$((current_build_number + 1))"
  fi
fi

case "$build_number" in
  ''|*[!0-9]*) die "build number must be numeric" ;;
esac

release_tag="v${release_version}"
new_pubspec_version="${release_version}+${build_number}"

if git rev-parse -q --verify "refs/tags/${release_tag}" >/dev/null; then
  die "local tag ${release_tag} already exists"
fi

if git ls-remote --exit-code --tags origin "refs/tags/${release_tag}" >/dev/null 2>&1; then
  die "remote tag ${release_tag} already exists"
fi

if [ "$new_pubspec_version" != "$current_pubspec_version" ]; then
  perl -0pi -e "s/^version:\\s*\\S+/version: ${new_pubspec_version}/m" pubspec.yaml
  git add pubspec.yaml
  git commit -m "chore: release ${release_tag}"
  git push origin main
fi

release_sha="$(git rev-parse HEAD)"

if [ "$skip_ci_check" != "true" ]; then
  echo "Waiting for CI on main at ${release_sha}..."

  run_id=""
  for _ in $(seq 1 36); do
    run_id="$(
      gh_cmd run list \
        --workflow CI \
        --branch main \
        --limit 20 \
        --json databaseId,headSha,status,conclusion \
        --jq "map(select(.headSha == \"${release_sha}\"))[0].databaseId // \"\""
    )"

    [ -n "$run_id" ] && break
    sleep 5
  done

  if [ -z "$run_id" ]; then
    echo "No CI run found for ${release_sha}; triggering CI manually."
    gh_cmd workflow run CI --ref main
    sleep 10
    run_id="$(
      gh_cmd run list \
        --workflow CI \
        --branch main \
        --limit 20 \
        --json databaseId,headSha,status,conclusion \
        --jq "map(select(.headSha == \"${release_sha}\"))[0].databaseId // \"\""
    )"
  fi

  [ -n "$run_id" ] || die "could not find or trigger a CI run for ${release_sha}"
  gh_cmd run watch "$run_id" --exit-status
fi

git tag -a "$release_tag" "$release_sha" -m "$release_tag"
git push origin "$release_tag"

echo "Waiting for Release workflow for ${release_tag}..."
sleep 10

release_run_id=""
for _ in $(seq 1 36); do
  release_run_id="$(
    gh_cmd run list \
      --workflow Release \
      --limit 20 \
      --json databaseId,headBranch,headSha,event \
      --jq "map(select(.headBranch == \"${release_tag}\" or (.headSha == \"${release_sha}\" and .event == \"push\")))[0].databaseId // \"\""
  )"

  [ -n "$release_run_id" ] && break
  sleep 5
done

[ -n "$release_run_id" ] || die "could not find Release workflow run for ${release_tag}"
gh_cmd run watch "$release_run_id" --exit-status

echo "Release created:"
gh_cmd release view "$release_tag" --json url --jq .url
