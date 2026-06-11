# MarkCalm

A calm, native macOS app for reading markdown files — one window per file, no IDE chrome.

## Download MarkCalm

**Current release:** [v0.1.6 — signed & notarized](https://github.com/karmatosed/markcalm/releases/latest) (Developer ID). No Xcode needed to install.

Download **`MarkCalm.dmg`** from **[GitHub Releases](https://github.com/karmatosed/markcalm/releases)**.

### Install

1. Open the `.dmg` and drag **MarkCalm** to **Applications**
2. Double-click **MarkCalm** to open
3. Use **File → Open** (⌘O) to read a `.md` file

Signed releases pass macOS Gatekeeper — no right-click → Open step.

### Settings

**MarkCalm → Settings** (⌘,)

| Setting | Default | Notes |
|---------|---------|-------|
| Theme | System | System / Light / Dark |
| Show reading progress | **Off** | Turn **on** to see the scroll progress bar |
| Progress bar position | Top | Top or Bottom (when progress is enabled) |

The reading progress bar only moves when the document is **taller than the window**.

### Set as default for `.md` files

1. Right-click any `.md` file in Finder
2. **Get Info → Open with → MarkCalm**
3. Click **Change All…**

Or accept the in-app prompt the first time you open a markdown file.

---

## Who this README is for

| Audience | What you need |
|----------|----------------|
| **Try the app** | [Download the latest `.dmg`](https://github.com/karmatosed/markcalm/releases/latest) — drag to Applications, double-click |
| **Developers** (build from source) | macOS 14+, Xcode 15+ — [Quick start](#quick-start) |
| **Maintainers** (ship releases) | [Publishing](#publishing-releases) |

---

## Requirements

- **macOS 14+** (Sonoma or later)
- **Xcode 15+** from the [App Store](https://apps.apple.com/app/xcode/id497799835) — Command Line Tools alone are **not** enough
- **Apple ID** (free) for code signing when running locally
- **Network** on first build (Swift Package Manager downloads MarkdownUI and Yams)

---

## Quick start

### 1. Get the code

```bash
git clone git@github.com:karmatosed/markcalm.git markcalm
cd markcalm
```

### 2. Install and configure Xcode

1. Install **Xcode** from the App Store.
2. Open Xcode once and accept the license / install additional components if prompted.
3. Point command-line tools at Xcode:

   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   xcodebuild -version   # should print Xcode 15+ — not "Command Line Tools"
   ```

### 3. Open the project

Open **`MarkCalm.xcodeproj`** in Xcode (double-click or `open MarkCalm.xcodeproj`).

Swift Package dependencies are pinned in `MarkCalm.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (required for Xcode Cloud and CI). After changing dependencies in Xcode, commit the updated lockfile.

Packages:

- [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui) (≥ 2.4.1)
- [Yams](https://github.com/jpsim/Yams) (≥ 5.0.0)

### 4. Configure signing

1. In the project navigator, select the **MarkCalm** project → **MarkCalm** target.
2. Open **Signing & Capabilities**.
3. Enable **Automatically manage signing**.
4. Choose your **Team** (Developer Program team `K2967B5G85` for distribution; personal Apple ID is fine for local development).

### 5. Build and run

1. Scheme: **MarkCalm**
2. Destination: **My Mac**
3. Press **⌘R**

### 6. Open a markdown file

On first launch you may see an empty **Untitled** window — that's normal.

- **File → Open** (⌘O) → choose `Fixtures/sample.md`, or
- Drag any `.md` file onto the MarkCalm icon / window

---

## Build from the command line

From the repository root:

```bash
# One-time: ensure Xcode is selected
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Resolve Swift packages (first run or after dependency changes)
xcodebuild -resolvePackageDependencies -scheme MarkCalm -destination 'platform=macOS'

# Build
xcodebuild -scheme MarkCalm -destination 'platform=macOS' build

# Run tests
xcodebuild test -scheme MarkCalm -destination 'platform=macOS'
```

A successful build produces `MarkCalm.app` under Xcode's DerivedData. Running from Xcode (⌘R) is the easiest way to launch during development.

---

## Publishing releases

Public releases are **signed and notarized** Developer ID builds uploaded to [GitHub Releases](https://github.com/karmatosed/markcalm/releases).

### Signed + notarized (recommended)

**Prerequisites:** Apple Developer Program membership (Active), **Developer ID Application** certificate in Keychain, app-specific password from [appleid.apple.com](https://appleid.apple.com).

```bash
export APPLE_TEAM_ID="K2967B5G85"
export APPLE_ID="you@example.com"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"

./scripts/build-release-dmg.sh
# → build/MarkCalm.dmg (signed + notarized)
```

Publish:

```bash
git tag v0.1.7 && git push origin v0.1.7

gh release create v0.1.7 build/MarkCalm.dmg \
  --title "v0.1.7 — signed & notarized" \
  --notes "Signed and notarized build. Drag to Applications and double-click to open."
```

Or upload to an existing tag:

```bash
gh release upload v0.1.7 build/MarkCalm.dmg --clobber -R karmatosed/markcalm
```

### Configure Xcode signing (one time)

1. **Xcode → Settings → Accounts** → add your Apple ID → select team **K2967B5G85**
2. **Manage Certificates → + → Developer ID Application**
3. **MarkCalm** target → **Signing & Capabilities** → **Automatically manage signing** → same team

### Release from Xcode (alternative)

1. Scheme **MarkCalm**, destination **Any Mac (arm64, x86_64)**
2. **Product → Archive**
3. Organizer → **Distribute App** → **Custom** → **Developer ID** → notarize → export `.dmg`
4. Upload to [GitHub Releases](https://github.com/karmatosed/markcalm/releases)

### Unsigned builds (CI / local testing)

Tag pushes (`git push origin v*`) trigger GitHub Actions, which builds an **unsigned** `.dmg` by default:

```bash
./scripts/build-dmg.sh
# → build/MarkCalm.dmg (unsigned — for local testing only)
```

Unsigned builds require a one-time Gatekeeper bypass — see [Troubleshooting](#unsigned-builds-gatekeeper).

### Automated signed releases (GitHub Actions, optional)

Add [repository secrets](https://github.com/karmatosed/markcalm/settings/secrets/actions):

| Secret | Value |
|--------|-------|
| `APPLE_TEAM_ID` | `K2967B5G85` |
| `APPLE_ID` | Apple ID email |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password |
| `APPLE_CERTIFICATE_BASE64` | `base64 -i DeveloperID.p12 \| pbcopy` |
| `APPLE_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` |

Then **Actions → Release → Run workflow** with **signed** checked.

> **Note:** Tag pushes build **unsigned** DMGs in CI. Signed public releases are built locally with `./scripts/build-release-dmg.sh` and uploaded with `gh release upload`.

---

## Troubleshooting

### “MarkCalm can't be opened” / “unidentified developer”

This applies to **unsigned** builds only (CI tag releases, local `./scripts/build-dmg.sh`). **Signed releases** from GitHub should open normally.

For unsigned builds:

1. **Applications** → right-click **MarkCalm** → **Open** → **Open**, or
2. `xattr -cr /Applications/MarkCalm.app`

### Unsigned builds (Gatekeeper)

If you downloaded an unsigned CI build:

1. Open the `.dmg` and drag **MarkCalm** to **Applications**
2. **Right-click MarkCalm → Open** (first time only) → **Open**

Or: `xattr -cr /Applications/MarkCalm.app`

### “xcodebuild requires Xcode” / “active developer directory … CommandLineTools”

Install full Xcode from the App Store, then:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### Packages fail to resolve / Xcode Cloud “resolved file is required”

- `Package.resolved` is committed at `MarkCalm.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` — do not gitignore it.
- Check your network connection.
- In Xcode: **File → Packages → Reset Package Caches**, then **Resolve Package Versions**.
- From terminal: `xcodebuild -resolvePackageDependencies -scheme MarkCalm -destination 'platform=macOS'`

### Signing errors (“Signing for MarkCalm requires a development team”)

**MarkCalm** target → **Signing & Capabilities** → enable **Automatically manage signing** → select your Team. A free Apple ID works for running on your own Mac; Developer ID distribution requires a paid Apple Developer account.

### Build errors after pulling changes

1. **Product → Clean Build Folder** (⇧⌘K)
2. Resolve packages again
3. **⌘R**

If you added a new `.swift` file outside Xcode, it must also be added to `MarkCalm.xcodeproj/project.pbxproj`.

### Console noise when running (harmless)

Messages like `com.apple.linkd.autoShortcut` or `Unable to obtain a task name port right` are normal macOS/Xcode debugger output. Ignore them if the app works.

### Grey console messages vs real errors

Red errors in Xcode's **Issue navigator** matter. Grey lines in the debug console usually don't.

---

## Project structure

```
MarkCalm/              SwiftUI app source
MarkCalmTests/         Unit tests (MarkdownPipeline)
Fixtures/sample.md     Sample markdown for manual testing
MarkCalm.xcodeproj     Xcode project (+ committed Package.resolved)
scripts/build-dmg.sh          Unsigned .dmg (local testing / CI)
scripts/build-release-dmg.sh  Signed + notarized .dmg (public releases)
.github/workflows/     CI release workflow
docs/                  Design spec and plans
AGENTS.md              Guidance for AI agents and contributors
```

---

## Docs

- [AGENTS.md](AGENTS.md) — agent/contributor guide (build verification, conventions)
- [Documentation index](docs/spec.md)
- [Design spec](docs/superpowers/specs/2026-06-10-markcalm-design.md)
- [Implementation plan](docs/superpowers/plans/2026-06-10-markcalm.md)
