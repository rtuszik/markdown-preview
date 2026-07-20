#!/usr/bin/env bash
#
# Cut a release: bump Version.xcconfig, commit, tag, push.
# The release workflow (.github/workflows/release.yml) builds and publishes.
#
# Usage:
#   scripts/cut-release.sh 0.0.32
#
# Requires a CHANGELOG.md entry for the version:  ## [0.0.32], YYYY-MM-DD

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_CONFIG="$PROJECT_ROOT/Version.xcconfig"
CHANGELOG="$PROJECT_ROOT/CHANGELOG.md"

VERSION="${1:-}"
[[ -z "$VERSION" ]] && { echo "usage: $0 X.Y.Z" >&2; exit 2; }
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.]+)?$ ]] \
    || { echo "error: '$VERSION' is not a version number" >&2; exit 2; }

cd "$PROJECT_ROOT"

git update-index --refresh >/dev/null 2>&1 || true
if ! git diff-index --quiet HEAD --; then
    echo "error: working tree is dirty, commit or stash first" >&2
    git status --short
    exit 1
fi

if git rev-parse "v$VERSION" >/dev/null 2>&1; then
    echo "error: tag v$VERSION already exists" >&2
    exit 1
fi

if ! grep -q "^## \[$VERSION\]" "$CHANGELOG"; then
    echo "error: no CHANGELOG.md entry for [$VERSION]" >&2
    echo "  add a section like:  ## [$VERSION], $(date +%Y-%m-%d)" >&2
    exit 1
fi

/usr/bin/sed -i '' -E "s|^MARKETING_VERSION *=.*|MARKETING_VERSION = $VERSION|" "$VERSION_CONFIG"

if git diff --quiet -- "$VERSION_CONFIG"; then
    echo "▸ Version.xcconfig already at $VERSION"
else
    git add "$VERSION_CONFIG"
    git commit -m "Release $VERSION"
    echo "▸ committed Version.xcconfig bump"
fi

git tag -a "v$VERSION" -m "Release $VERSION"
git push origin HEAD "v$VERSION"

echo "✓ pushed v$VERSION, release workflow is building:"
echo "  https://github.com/rtuszik/markdown-preview/actions"
