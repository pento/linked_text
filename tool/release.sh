#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <version>"
  echo "  version: semver version (e.g. 1.1.0)"
  exit 1
}

if [[ $# -ne 1 ]]; then
  usage
fi

version="$1"

# Validate semver format.
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: '$version' is not a valid semver version (expected X.Y.Z)."
  exit 1
fi

# Check working tree is clean.
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: working tree is not clean. Commit or stash changes first."
  exit 1
fi

# Warn if not on main branch.
current_branch=$(git branch --show-current)
if [[ "$current_branch" != "main" ]]; then
  echo "Warning: you are on branch '$current_branch', not 'main'."
  read -rp "Continue anyway? [y/N] " confirm
  if [[ "$confirm" != [yY] ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# Verify CHANGELOG.md has an entry for this version.
if ! grep -q "^## $version" CHANGELOG.md; then
  echo "Error: CHANGELOG.md has no '## $version' heading."
  echo "Add a changelog entry before releasing."
  exit 1
fi

# Check that the tag doesn't already exist.
if git rev-parse "v$version" >/dev/null 2>&1; then
  echo "Error: tag 'v$version' already exists."
  exit 1
fi

# Check that pubspec.yaml actually needs updating.
current_version=$(grep '^version:' pubspec.yaml | awk '{print $2}')
if [[ "$current_version" == "$version" ]]; then
  echo "Warning: pubspec.yaml already has version $version."
else
  # Update version in pubspec.yaml.
  sed -i.bak "s/^version: .*/version: $version/" pubspec.yaml && rm -f pubspec.yaml.bak
  echo "Updated pubspec.yaml to version $version."
fi

# Run analysis and tests as a gate.
# If either fails, restore pubspec.yaml so the working tree stays clean.
cleanup_on_failure() {
  echo ""
  echo "Restoring pubspec.yaml to its previous state."
  git checkout pubspec.yaml
  exit 1
}

echo "Running flutter analyze..."
flutter analyze || cleanup_on_failure

echo "Running flutter test..."
flutter test || cleanup_on_failure

# Commit and tag.
if [[ "$current_version" != "$version" ]]; then
  git add pubspec.yaml
  git commit -m "Bump version to $version"
fi
git tag -a "v$version" -m "v$version"

echo ""
echo "Done! Version $version is committed and tagged."
echo "To publish, run:"
echo ""
echo "  git push origin main --tags"
echo ""
