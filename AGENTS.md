# AGENTS.md — MarkCalm

Guidance for AI agents and developers working in this repository.

Human-oriented run instructions: [`README.md`](README.md)

---

## What this is

**MarkCalm** is a native macOS app (Swift + SwiftUI) for **read-only** markdown viewing. One window per file, like Preview. Calm Technology: minimal UI, no network, optional reading progress bar (off by default).

---

## Prerequisites (verify before building)

| Requirement | How to check |
|-------------|--------------|
| macOS 14+ | `sw_vers` |
| Full Xcode 15+ (not CLT only) | `xcodebuild -version` — must say **Xcode**, not "Command Line Tools" |
| Xcode selected for CLI | `xcode-select -p` → `/Applications/Xcode.app/Contents/Developer` |
| Network (first build) | SPM must fetch MarkdownUI and Yams |

Fix wrong developer directory:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

---

## Run from scratch (developer)

All commands from the **repository root** (where `MarkCalm.xcodeproj` lives).

```bash
# 1. Clone (if needed)
git clone git@github.com:karmatosed/markcalm.git markcalm && cd markcalm

# 2. Select Xcode
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# 3. Resolve Swift packages (required before first build)
xcodebuild -resolvePackageDependencies -scheme MarkCalm -destination 'platform=macOS'

# 4. Build
xcodebuild -scheme MarkCalm -destination 'platform=macOS' build

# 5. Test
xcodebuild test -scheme MarkCalm -destination 'platform=macOS'
```

**In Xcode:** open `MarkCalm.xcodeproj` → **MarkCalm** target → **Signing & Capabilities** → pick a Team (free Apple ID OK) → **⌘R**.

### Manual smoke test after a successful run

1. **File → Open** → `Fixtures/sample.md` — headings, table, code block, footnote render
2. **MarkCalm → Settings** → toggle theme (System / Light / Dark)
3. Enable **Show reading progress** → scroll a long doc → bar fills (needs content taller than window)
4. Links open in the default browser

First launch may show an empty **Untitled** window — use **File → Open** or drag a `.md` file.

---

## Dependencies (SPM)

Declared in `MarkCalm.xcodeproj/project.pbxproj`:

| Package | URL | Min version |
|---------|-----|-------------|
| MarkdownUI | `https://github.com/gonzalezreal/swift-markdown-ui` | 2.4.1 |
| Yams | `https://github.com/jpsim/Yams` | 5.0.0 |

If packages fail: **File → Packages → Reset Package Caches** in Xcode, or re-run `-resolvePackageDependencies`.

---

## Project layout

```
MarkCalm/
  MarkCalmApp.swift       @main, DocumentGroup, Settings scene
  MarkdownDocument.swift  FileDocument (read-only in practice)
  MarkdownPipeline.swift  YAML frontmatter strip — unit tested
  ContentView.swift       Reading view + progress bar overlay
  TrackedScrollView.swift NSScrollView scroll tracking for progress
  ReadingTheme.swift      MarkdownUI theme (transparent text background)
  SettingsView.swift      Theme + reading progress settings
  DefaultAppPrompt.swift  One-time default-app sheet
  AppPreferences.swift    AppStorageKey, AppTheme, ProgressBarPosition
  Info.plist              Document types (.md) — merged with generated plist
  MarkCalm.entitlements   App sandbox
MarkCalmTests/
  MarkdownPipelineTests.swift
Fixtures/sample.md        Manual smoke-test markdown
MarkCalm.xcodeproj        Xcode project — update pbxproj when adding Swift files
```

---

## Authority

| Document | Role |
|----------|------|
| [`docs/superpowers/specs/2026-06-10-markcalm-design.md`](docs/superpowers/specs/2026-06-10-markcalm-design.md) | **Approved** product spec |
| [`docs/superpowers/plans/2026-06-10-markcalm.md`](docs/superpowers/plans/2026-06-10-markcalm.md) | Implementation plan (may lag code) |
| [`docs/spec.md`](docs/spec.md) | Docs index |

When spec and code disagree, follow the spec unless the user explicitly overrides.

---

## Product rules (do not violate)

1. **Read-only** — no editing UI.
2. **One window per file** — `DocumentGroup`, no tabs.
3. **Calm UI** — no toolbar/sidebar by default; no onboarding wizards or upsells.
4. **Offline** — no network calls.
5. **Progress bar** — optional, off by default; 3px, muted track, non-interactive.
6. **Theme** — system light/dark by default.

## Out of scope for v1 (ask before adding)

Editing, tabs, search, export, sync, plugins, font zoom, custom CSS, analytics, auto-update.

---

## Code conventions

- Small focused files; minimal comments.
- UserDefaults keys in `AppStorageKey` — **never** name types `PreferenceKey` (conflicts with SwiftUI's `PreferenceKey` protocol).
- Markdown body text: `BackgroundColor(nil)` in theme — avoid solid text block backgrounds.
- Scroll progress: use `TrackedScrollView` (`NSScrollView`), not SwiftUI `ScrollView` + GeometryReader.
- Pipeline logic in `MarkdownPipeline.swift` with tests in `MarkCalmTests/`.
- New `.swift` files: add to `MarkCalm.xcodeproj/project.pbxproj` (file reference + Sources build phase).

---

## Common build / run failures

| Symptom | Fix |
|---------|-----|
| `xcodebuild requires Xcode` | Install Xcode; run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` |
| Signing requires a development team | Target → Signing & Capabilities → Team (free Apple ID) |
| Package resolution failed | Network; reset package caches; `-resolvePackageDependencies` |
| `Inheritance from non-protocol type 'PreferenceKey'` | Do not add a type named `PreferenceKey` — use `AppStorageKey` |
| New Swift file / undefined symbol | File missing from `project.pbxproj` |
| Progress bar invisible | Enable in Settings; document must scroll (taller than window) |
| Downloaded app won't open | Unsigned build — right-click → Open, or `xattr -cr /Applications/MarkCalm.app` |
| Harmless console: `linkd.autoShortcut`, `task name port right` | Ignore if app works |

---

## Verification before claiming done

After code changes, run and confirm output:

```bash
xcodebuild -scheme MarkCalm -destination 'platform=macOS' build
```

If `MarkdownPipeline.swift` changed:

```bash
xcodebuild test -scheme MarkCalm -destination 'platform=macOS'
```

Do not claim "builds" or "tests pass" without running these commands (or equivalent in Xcode) and checking exit code 0.

---

## Distribution

### Current: unsigned preview (Apple Developer pending)

Public installs use **`build/MarkCalm.dmg`** from [GitHub Releases](https://github.com/karmatosed/markcalm/releases).

| Who | Action |
|-----|--------|
| **Build** | `./scripts/build-dmg.sh` |
| **Publish** | Push tag `v*` (unsigned CI) or `gh release create …` |
| **User install** | Right-click → Open once — [README § Install](../README.md#install-required-for-unsigned-builds) |

Release notes **must** state: unsigned preview, one-time Gatekeeper step, link to install instructions.

### After Apple Developer is Active: signed + notarized

```bash
export APPLE_TEAM_ID=… APPLE_ID=… APPLE_APP_SPECIFIC_PASSWORD=…
./scripts/build-release-dmg.sh
```

CI: push tag `v*` → **unsigned** build. Signed: **Actions → Release** with **signed** enabled + GitHub secrets. See README § Apple Developer.

---

## Agent workflow

1. Read the design spec before non-trivial changes.
2. Keep diffs minimal and scoped.
3. Build (and test if touching pipeline code).
4. Do not commit unless the user asks.
5. Do not add spec non-goals without explicit user approval.
