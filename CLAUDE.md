# Markdown Preview, agent guide

A macOS app for previewing Markdown files. AppKit, sandboxed, ships with a Quick Look extension. Distributed as a DMG via GitHub Releases; no auto-updater.

## Project facts

| Thing | Value |
|---|---|
| Bundle id | `io.tuszik.md-preview` |
| Product name | `Markdown Preview` |
| Scheme | `md-preview` |
| Quick Look target | `quick-look` (embedded extension, `io.tuszik.md-preview.quick-look`) |
| Min macOS | 15.0 |
| Sandboxed | yes |
| Auto-updater | none, users download new DMGs from GitHub Releases |
| Distribution | GitHub Releases (built by `.github/workflows/release.yml`) |

Version is managed centrally in `Version.xcconfig`. `MARKETING_VERSION` is the source of truth and is bumped per release; `CURRENT_PROJECT_VERSION` only matters for local builds, the release workflow overrides it with `git rev-list --count HEAD`. Both the app and the quick-look extension inherit from it.

## Release pipeline

Releases are cut directly from `main`, no release branches or PRs. CI is the gate: the workflow refuses to publish if the tag, `Version.xcconfig`, and `CHANGELOG.md` disagree.

1. **Add a `CHANGELOG.md` entry** for the version being shipped. **Always invoke the `changelog-maintenance` skill** (`.claude/skills/changelog-maintenance`) via the Skill tool whenever the user asks you to write, generate, or update a changelog entry, do not draft freeform. The skill enforces the house format, the Keep-a-Changelog category split (Added / Changed / Fixed / Security), and contributor crediting.

   Entry shape (heading is `## [X.Y.Z], YYYY-MM-DD` with a comma before the date, not the Keep-a-Changelog en-dash: a repo formatter hook rewrites en/em dashes to commas, even inside code spans, so using an en-dash just causes churn):

   ```md
   ## [0.0.32], 2026-07-20

   Short narrative summary.

   - **Bullet for each change.**
   - Bug fix bullet.
   ```

2. **Cut the release:**

   ```bash
   ./scripts/cut-release.sh 0.0.32
   ```

   The script validates (clean tree, changelog entry exists, tag doesn't already exist), bumps `MARKETING_VERSION`, commits `Release 0.0.32`, tags `v0.0.32`, and pushes commit + tag.

3. The tag push triggers `.github/workflows/release.yml`:
   - runs the Swift test suite
   - re-validates tag ↔ `Version.xcconfig` ↔ `CHANGELOG.md`
   - archives the `md-preview` scheme (ad-hoc signed), build number = commit count
   - packages `Markdown-Preview-X.Y.Z.dmg` via `hdiutil`
   - creates the GitHub release with notes extracted from `CHANGELOG.md`

To dry-run the build without publishing, trigger the workflow manually (`gh workflow run release.yml`), it uploads the DMG as a build artifact instead of creating a release.

Builds are currently ad-hoc signed (no Developer ID, no notarization), downloaders must right-click → Open on first launch. Proper signing + notarization is a planned follow-up (Developer ID cert + notarytool via repo secrets).

## Rolling back a release

```bash
gh release delete v0.0.32 --yes
git push --delete origin v0.0.32
git tag -d v0.0.32
```

There is no update feed to unpublish, deleting the GitHub release fully retracts it.

## Common Xcode tasks

```bash
xcodebuild -project md-preview.xcodeproj -scheme md-preview -configuration Debug build
xcodebuild -resolvePackageDependencies -project md-preview.xcodeproj
swift test --package-path tests/swift-tests
```
