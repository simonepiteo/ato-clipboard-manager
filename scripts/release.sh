#!/bin/zsh

set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
VERSION_FILE="$PROJECT_ROOT/VERSION"
CHANGELOG="$PROJECT_ROOT/CHANGELOG.md"
REPOSITORY_URL="https://github.com/simonepiteo/ato-clipboard-manager"
DRY_RUN=false
FORCED_BUMP=""

usage() {
  print "Usage: ./scripts/release.sh [--dry-run] [major|minor|patch]"
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

if [[ "$DRY_RUN" == false && -n "$(git status --porcelain)" ]]; then
  print -u2 "The working tree must be clean before creating a release."
  exit 1
fi

CURRENT_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
if [[ ! "$CURRENT_VERSION" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
  print -u2 "Invalid version in VERSION: $CURRENT_VERSION"
  exit 1
fi

LAST_TAG="$(git describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null || true)"
if [[ -n "$LAST_TAG" ]]; then
  RANGE="$LAST_TAG..HEAD"
else
  RANGE="HEAD"
fi

if [[ "$(git rev-list --count "$RANGE")" -eq 0 ]]; then
  print -u2 "There are no commits to release after ${LAST_TAG:-the repository start}."
  exit 1
fi

COMMIT_MESSAGES="$(git log --format='%s%n%b' "$RANGE")"
if [[ -n "$FORCED_BUMP" ]]; then
  BUMP="$FORCED_BUMP"
elif print -r -- "$COMMIT_MESSAGES" | grep -Eq '(^[[:alpha:]][[:alnum:]_-]*(\([^)]*\))?!:|^BREAKING[ -]CHANGE:)'; then
  BUMP="major"
elif print -r -- "$COMMIT_MESSAGES" | grep -Eq '^feat(\([^)]*\))?:'; then
  BUMP="minor"
else
  BUMP="patch"
fi

IFS=. read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
case "$BUMP" in
  major) NEXT_VERSION="$((MAJOR + 1)).0.0" ;;
  minor) NEXT_VERSION="$MAJOR.$((MINOR + 1)).0" ;;
  patch) NEXT_VERSION="$MAJOR.$MINOR.$((PATCH + 1))" ;;
esac

print "Current version: $CURRENT_VERSION"
print "Detected bump:  $BUMP"
print "Next version:   $NEXT_VERSION"
print "Commits:        $(git rev-list --count "$RANGE")"

if [[ "$DRY_RUN" == true ]]; then
  exit 0
fi

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ato-release.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT
SECTION="$TEMP_DIR/section.md"
NEW_CHANGELOG="$TEMP_DIR/CHANGELOG.md"
RELEASE_DATE="$(date +%Y-%m-%d)"
COMPARE_BASE="${LAST_TAG:-$(git rev-list --max-parents=0 HEAD)}"

{
  print ""
  print "## [$NEXT_VERSION]($REPOSITORY_URL/compare/$COMPARE_BASE...v$NEXT_VERSION) ($RELEASE_DATE)"

  for category in breaking feat fix other; do
    entries=""
    case "$category" in
      breaking)
        title="Breaking Changes"
        entries="$(git log --format='%H%x09%s' "$RANGE" | grep -E $'\t[[:alpha:]][[:alnum:]_-]*(\([^)]*\))?!:' || true)"
        ;;
      feat)
        title="Features"
        entries="$(git log --format='%H%x09%s' "$RANGE" | grep -E $'\tfeat(\([^)]*\))?:' || true)"
        ;;
      fix)
        title="Bug Fixes"
        entries="$(git log --format='%H%x09%s' "$RANGE" | grep -E $'\tfix(\([^)]*\))?:' || true)"
        ;;
      other)
        title="Other Changes"
        entries="$(git log --format='%H%x09%s' "$RANGE" | grep -Ev $'\t(feat|fix)(\([^)]*\))?!?:' || true)"
        ;;
    esac

    if [[ -n "$entries" ]]; then
      print ""
      print "### $title"
      print ""
      while IFS=$'\t' read -r hash subject; do
        short_hash="${hash[1,7]}"
        description="$(print -r -- "$subject" | sed -E 's/^[[:alpha:]][[:alnum:]_-]*(\([^)]*\))?!?:[[:space:]]*//')"
        print "* $description ([$short_hash]($REPOSITORY_URL/commit/$hash))"
      done <<< "$entries"
    fi
  done
} > "$SECTION"

{
  head -n 3 "$CHANGELOG"
  cat "$SECTION"
  tail -n +4 "$CHANGELOG"
} > "$NEW_CHANGELOG"

print "$NEXT_VERSION" > "$VERSION_FILE"
cp "$NEW_CHANGELOG" "$CHANGELOG"

git add VERSION CHANGELOG.md
git commit -m "chore(release): $NEXT_VERSION"
git tag -a "v$NEXT_VERSION" -m "Release v$NEXT_VERSION"

print ""
print "Created commit and tag v$NEXT_VERSION."
print "Push them with: git push --follow-tags origin HEAD"
