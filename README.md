# MarkCalm

A calm, native macOS app for reading markdown files — one window per file, no IDE chrome.

## Download MarkCalm (unsigned preview)

**Current release:** unsigned build while Apple Developer enrollment is pending. No Xcode needed to install.

Download **`MarkCalm.dmg`** from **[GitHub Releases](https://github.com/karmatosed/markcalm/releases)**.

### Install (required for unsigned builds)

macOS will block the app the first time because it isn't notarized yet. This is normal — one extra step:

1. Open the `.dmg` and drag **MarkCalm** to **Applications**
2. In Finder → **Applications**, **right-click MarkCalm → Open**  
   (Do **not** double-click the first time.)
3. Click **Open** in the dialog

**Or** run once in Terminal:

```bash
xattr -cr /Applications/MarkCalm.app
```

After that, open MarkCalm normally. Use **File → Open** (⌘O) to read a `.md` file.

### Why unsigned?

Apple Developer Program membership is **pending**. Once it becomes **Active**, future releases will be signed + notarized — drag to Applications and double-click, no right-click step.

---

## Apple Developer — signed releases (when membership is Active)

### 1. Configure Xcode (one time)

1. **Xcode → Settings → Accounts** → add your Apple ID → select your **paid team**
2. Open `MarkCalm.xcodeproj` → **MarkCalm** target → **Signing & Capabilities**
3. Enable **Automatically manage signing**
4. **Team:** your Developer Program team (not "Personal Team")
5. **Xcode → Settings → Accounts → [your team] → Manage Certificates**
6. Click **+** → **Developer ID Application** (creates the cert if missing)

### 2. Release from Xcode (easiest first time)

1. Scheme **MarkCalm**, destination **Any Mac (arm64, x86_64)**
2. **Product → Archive**
3. In Organizer → **Distribute App**
4. **Custom** → **Developer ID** → **Upload** (notarize) → export `.app` or `.dmg`
5. Upload to [GitHub Releases](https://github.com/karmatosed/markcalm/releases)

### 3. Release from the command line

```bash
export APPLE_TEAM_ID="K2967B5G85"
export APPLE_ID="you@example.com"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # appleid.apple.com → App-Specific Passwords

./scripts/build-release-dmg.sh
# → build/MarkCalm.dmg (signed + notarized)
```

### 4. Automated releases (GitHub Actions)

Add these [repository secrets](https://github.com/karmatosed/markcalm/settings/secrets/actions):

| Secret | Value |
|--------|-------|
| `APPLE_TEAM_ID` | 10-character Team ID |
| `APPLE_ID` | Apple ID email |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password |
| `APPLE_CERTIFICATE_BASE64` | `base64 -i DeveloperID.p12 \| pbcopy` |
| `APPLE_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` |

Export the certificate: **Keychain Access** → **Developer ID Application** → export as `.p12`.

Publish:

```bash
git tag v0.1.0 && git push origin v0.1.0
```

The **Release** workflow builds, signs, notarizes, and attaches `MarkCalm.dmg` to the release.

> **Note:** Tag pushes (`git push origin v*`) build **unsigned** DMGs by default. Signed releases require **Actions → Release → Run workflow** with **signed** checked, after Apple secrets are configured.

---

### Publish a release (quick reference)

```bash
# Current: unsigned (Apple Developer pending)
./scripts/build-dmg.sh
# → build/MarkCalm.dmg — upload to GitHub Releases

# After Apple Developer is Active: signed + notarized
./scripts/build-release-dmg.sh

# Tag → GitHub Actions (unsigned by default; signed via Actions → Release → signed ✓)
git tag v0.1.1 && git push origin v0.1.1
```

---

## Who this README is for

| Audience | What you need |
|----------|----------------|
| **Try the app** | [Download unsigned `.dmg`](#download-markcalm-unsigned-preview) from [Releases](https://github.com/karmatosed/markcalm/releases) — right-click → Open once |
| **Developers** (build from source) | macOS 14+, Xcode 15+ — [Quick start](#quick-start) |
| **Ship signed releases** | Apple Developer **Active** — [Signed releases](#apple-developer--signed-releases-when-membership-is-active) |

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

Wait for **File → Packages → Resolve Package Versions** to finish. Dependencies:

- [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui) (≥ 2.4.1)
- [Yams](https://github.com/jpsim/Yams) (≥ 5.0.0)

### 4. Configure signing

1. In the project navigator, select the **MarkCalm** project → **MarkCalm** target.
2. Open **Signing & Capabilities**.
3. Enable **Automatically manage signing**.
4. Choose your **Team** (personal Apple ID is fine for local development).

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

## Using the app

### Settings

**MarkCalm → Settings** (⌘,)

| Setting | Default | Notes |
|---------|---------|-------|
| Theme | System | System / Light / Dark |
| Show reading progress | **Off** | Turn on to see the scroll progress bar |
| Progress bar position | Top | Top or Bottom (when progress is enabled) |

The reading progress bar only moves when the document is **taller than the window** — shrink the window or use a long file to test it.

### Set as default for `.md` files

1. Right-click any `.md` file in Finder
2. **Get Info → Open with → MarkCalm**
3. Click **Change All…**

Or accept the in-app prompt the first time you open a markdown file.

---

## Troubleshooting

### “MarkCalm can't be opened” / “unidentified developer” (downloaded .dmg)

Expected for **unsigned** releases. Do **not** double-click the first time:

1. **Applications** → right-click **MarkCalm** → **Open** → **Open**, or
2. `xattr -cr /Applications/MarkCalm.app`

This is a one-time step per download. **Signed releases** (after Apple Developer is Active) won't need this.

### Apple Developer membership still "Pending"

You can't create Developer ID certificates or notarize until Apple activates your account (usually 24–48 hours for individuals). Until then, ship unsigned builds with `./scripts/build-dmg.sh` and the [install steps above](#install-required-for-unsigned-builds).

### “xcodebuild requires Xcode” / “active developer directory … CommandLineTools”

Install full Xcode from the App Store, then:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### Packages fail to resolve

- Check your network connection.
- In Xcode: **File → Packages → Reset Package Caches**, then **Resolve Package Versions**.
- From terminal: `xcodebuild -resolvePackageDependencies -scheme MarkCalm -destination 'platform=macOS'`

### Signing errors (“Signing for MarkCalm requires a development team”)

**MarkCalm** target → **Signing & Capabilities** → enable **Automatically manage signing** → select your Team. A free Apple ID works for running on your own Mac.

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
MarkCalm.xcodeproj     Xcode project
scripts/build-dmg.sh          Unsigned .dmg (testing)
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

---

## Sharing with others (maintainers)

### Now — unsigned `.dmg` (Apple Developer pending)

| Step | Action |
|------|--------|
| Build | `./scripts/build-dmg.sh` → `build/MarkCalm.dmg` |
| Publish | Upload to [GitHub Releases](https://github.com/karmatosed/markcalm/releases) or `gh release create v0.1.0 build/MarkCalm.dmg …` |
| User install | [Right-click → Open once](#install-required-for-unsigned-builds) |

Document in release notes that this is an **unsigned preview** and include the install steps.

### After Apple Developer is Active — signed + notarized

Users install normally — drag to Applications, double-click, done.

| Step | Action |
|------|--------|
| Setup | [Signed releases](#apple-developer--signed-releases-when-membership-is-active) |
| Build | `./scripts/build-release-dmg.sh` |
| CI | GitHub secrets → `git tag v* && git push origin v*` |
