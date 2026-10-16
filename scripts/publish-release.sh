#!/bin/zsh

set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
REPOSITORY="simonepiteo/ato-clipboard-manager"
DRY_RUN=false
FORCED_BUMP=""

usage() {
  print "Usage: ./scripts/publish-release.sh [--dry-run] [major|minor|patch]"
}

for argument in "$@"; do
  case "$argument" in
    --dry-run) DRY_RUN=true ;;
    major|minor|patch)
      if [[ -n "$FORCED_BUMP" ]]; then
        print -u2 "Specify only one version bump."
        exit 1
      fi
      FORCED_BUMP="$argument"
      ;;
    -h|--help) usage; exit 0 ;;
    *) print -u2 "Unknown argument: $argument"; usage; exit 1 ;;
  esac
done

cd "$PROJECT_ROOT"

if ! command -v gh >/dev/null; then
  print -u2 "GitHub CLI is required. Install it with: brew install gh"
  exit 1
fi

if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  print -u2 "GitHub CLI is not authenticated with github.com."
  print -u2 "Run: gh auth login --hostname github.com --git-protocol https --web"
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  print -u2 "The working tree must be clean before publishing a release."
  exit 1
fi

if [[ "$(git branch --show-current)" != "develop" ]]; then
  print -u2 "Releases must be published from the develop branch."
  exit 1
fi

if [[ "$DRY_RUN" == false ]]; then
  source "$PROJECT_ROOT/scripts/code-signing.sh"
  ato_resolve_signing_identity
  git fetch origin develop main --tags

  if ! git merge-base --is-ancestor origin/develop HEAD; then
    print -u2 "Local develop is behind or has diverged from origin/develop. Pull or rebase before releasing."
    exit 1
  fi

  if ! git merge-base --is-ancestor origin/main HEAD; then
    print -u2 "origin/main has commits that are not in develop. Merge main into develop first."
    exit 1
  fi
fi

CURRENT_VERSION="$(tr -d '[:space:]' < "$PROJECT_ROOT/VERSION")"
CURRENT_TAG="v$CURRENT_VERSION"
PREPARED_RELEASE=false

if git tag --points-at HEAD --list "$CURRENT_TAG" | grep -qx "$CURRENT_TAG" && \
   [[ "$(git log -1 --format=%s)" == "chore(release): $CURRENT_VERSION" ]]; then
  PREPARED_RELEASE=true
fi

if [[ "$DRY_RUN" == true ]]; then
  if [[ "$PREPARED_RELEASE" == true ]]; then
    print "Release $CURRENT_TAG is already prepared at HEAD."
  else
    "$PROJECT_ROOT/scripts/release.sh" --dry-run ${FORCED_BUMP:+$FORCED_BUMP}
  fi
  print "The real command will build the DMG, fast-forward develop and main, push the tag, and create the GitHub Release."
  exit 0
fi

if [[ "$PREPARED_RELEASE" == true ]]; then
  print "Using the release already prepared at HEAD: $CURRENT_TAG"
else
  "$PROJECT_ROOT/scripts/release.sh" ${FORCED_BUMP:+$FORCED_BUMP}
  CURRENT_VERSION="$(tr -d '[:space:]' < "$PROJECT_ROOT/VERSION")"
  CURRENT_TAG="v$CURRENT_VERSION"
fi

DMG_PATH="$PROJECT_ROOT/dist/ATO-Clipboard-Manager-$CURRENT_VERSION.dmg"

"$PROJECT_ROOT/scripts/build-dmg.sh"

if [[ ! -f "$DMG_PATH" ]]; then
  print -u2 "Expected DMG was not created: $DMG_PATH"
  exit 1
fi

git push --atomic origin \
  HEAD:develop \
  HEAD:main \
  "$CURRENT_TAG"

if gh release view "$CURRENT_TAG" --repo "$REPOSITORY" >/dev/null 2>&1; then
  print "GitHub Release $CURRENT_TAG already exists; updating its DMG."
  gh release upload "$CURRENT_TAG" "$DMG_PATH" --clobber --repo "$REPOSITORY"
else
  gh release create "$CURRENT_TAG" "$DMG_PATH" \
    --repo "$REPOSITORY" \
    --verify-tag \
    --generate-notes \
    --title "ATO Clipboard Manager $CURRENT_TAG"
fi

print "Published $CURRENT_TAG with $(basename "$DMG_PATH"); develop and main now point to the release commit."
