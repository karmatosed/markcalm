# MarkCalm — Design Spec

**Date:** 2026-06-10  
**Status:** Approved  
**Author:** Brainstorming session

## Summary

MarkCalm is a native macOS app for **read-only** markdown viewing. It opens `.md` files in a calm, minimal reading experience — one window per file — so markdown stops opening in IDEs by default.

## Goals

- Open and read markdown files beautifully on Mac
- Register as the default handler for `.md` files
- Stay invisible: the document is the experience (Calm Technology)
- Support system light/dark mode with optional override
- Be small, fast, and offline — no network calls

## Non-Goals (v1)

- Editing markdown
- Tabs or multi-file single-window UI
- Search, export, sync, plugins
- Custom fonts, font-size zoom, or custom CSS
- Onboarding wizards, notifications, or upsells

## Calm Technology Principles

1. **Inform without demanding attention** — optional reading progress bar, off by default
2. **Peripheral when appropriate** — progress indicator is 2–3px, muted, non-interactive
3. **Respect the environment** — follows system light/dark by default
4. **One job, done quietly** — open, read, close; no feature creep in chrome

## User Profile

- Developer who knows JavaScript/TypeScript; learning Swift as the app is built
- Wants to use the app personally first; share signed binary later via Apple Developer Program ($99/year)
- Unsigned distribution is unacceptable for sharing with non-technical users

---

## Architecture

```
┌─────────────────────────────────────────┐
│  macOS (.md double-click / Open With)   │
└──────────────────┬──────────────────────┘
                   ▼
┌─────────────────────────────────────────┐
│  MarkCalm.app (Swift + SwiftUI)         │
│  ┌─────────────┐  ┌──────────────────┐  │
│  │ Document    │  │ Settings         │  │
│  │ (one window │  │ (UserDefaults)   │  │
│  │  per file)  │  │                  │  │
│  └──────┬──────┘  └──────────────────┘  │
│         ▼                                 │
│  ┌─────────────────────────────────┐    │
│  │ Markdown pipeline               │    │
│  │ 1. Read file                    │    │
│  │ 2. Strip YAML frontmatter       │    │
│  │ 3. Parse GFM → render (SwiftUI) │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

### Technology Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| UI | SwiftUI | Native Mac app, system theme integration |
| App model | `DocumentGroup` (document-based app) | One window per file; built-in file handling |
| Markdown rendering | **MarkdownUI** (Swift package, cmark-gfm) | GFM support, SwiftUI-native rendering |
| Frontmatter | **Yams** | Parse and strip YAML before render |
| Code highlighting | **Highlightr** or **Splash** | Syntax colors in fenced code blocks |
| Settings | SwiftUI `Settings { }` scene | Standard macOS Settings window |
| Preferences storage | `@AppStorage` / `UserDefaults` | Simple, immediate apply |
| Minimum macOS | macOS 14 (Sonoma) | Modern SwiftUI APIs without legacy burden |

### Markdown Feature Support (v1)

Full GitHub-Flavored Markdown:

- Headings, paragraphs, emphasis, strikethrough
- Ordered/unordered lists, task lists
- Links (open in default browser), images (relative paths)
- Blockquotes, horizontal rules
- Fenced code blocks with syntax highlighting
- Tables
- Footnotes

**Frontmatter:** YAML block at file start (`---` … `---`) is parsed and **stripped** before rendering. Metadata is not displayed in v1.

---

## UI & Reading Experience

### Default View (no chrome)

- Full-window scrollable rendered markdown
- No toolbar, no sidebar
- Window title shows filename without `.md` extension
- Typography: system font (San Francisco), ~65ch max content width, centered column, generous padding
- Clickable links open in the user's default browser
- Local images resolve relative to the markdown file's directory

### Reading Progress Timeline (optional)

- **Default: off**
- When enabled: 2–3px bar in a muted system color
- Tracks scroll position (0% top → 100% bottom)
- Position configurable: top or bottom (Settings)
- Non-interactive; does not intercept clicks

### Menus

| Menu | Items |
|------|-------|
| File | Open (⌘O), Close Window (⌘W) |
| Edit | Copy (⌘C) — selected text only; no Paste |
| MarkCalm | Settings… (⌘,) |

No splash screen. No welcome dialog. App opens directly to the document.

---

## Settings

Standard macOS Settings window (`MarkCalm → Settings…` or ⌘,).

### Appearance

| Setting | Options | Default |
|---------|---------|---------|
| Theme | System / Light / Dark | System |

Applies immediately to all open windows.

### Reading

| Setting | Options | Default |
|---------|---------|---------|
| Show reading progress | On / Off | Off |
| Progress bar position | Top / Bottom | Top |

Progress bar position control is only relevant when progress is enabled; may be hidden or disabled when progress is Off.

Settings persist via `@AppStorage`. Changes apply immediately to open windows.

---

## File Handling

### Opening Files

- Double-click `.md` in Finder (when MarkCalm is default)
- Open With → MarkCalm
- Drag `.md` onto MarkCalm icon or dock icon
- File → Open (⌘O)
- Each file opens in its **own window** (Preview model)

### Default App Registration

- App declares `.md` document type in `Info.plist` (`UTType` / `CFBundleDocumentTypes`)
- **One-time calm prompt** — not on first launch; shown when user opens via Open With or from the app and MarkCalm is not yet the default:

  > "Make MarkCalm the default app for Markdown files?"  
  > [Open System Settings] [Not Now]

  Opens System Settings to the appropriate default-app picker. Dismissal is permanent (no re-nagging in v1).

---

## Error Handling

| Situation | Behavior |
|-----------|----------|
| File unreadable (permissions, missing) | Inline message: "Couldn't open this file." — no crash, no stack trace |
| Empty file | Blank reading view |
| Malformed markdown | Render what parses; do not block |
| Broken image path | Subtle broken-image placeholder |
| Invalid YAML frontmatter | Skip stripping; render file as-is |
| Very large file (> ~5 MB) | Open normally; rely on lazy scrolling; no warning in v1 |

No network calls in v1 — no connectivity handling required.

---

## Testing

### Unit Tests (Swift Testing or XCTest)

- Frontmatter stripping: valid YAML, invalid YAML, no frontmatter
- Markdown rendering: headings, lists, links, code blocks, tables, task lists, footnotes

### Manual Smoke Tests

- Open `.md` → renders correctly
- System light/dark and Settings theme override
- Progress bar on/off; top vs bottom placement
- Double-click `.md` in Finder opens MarkCalm
- Relative local images display
- Links open in default browser
- Set as default app flow (prompt + System Settings link)

No UI automation in v1.

---

## Distribution

### Phase 1 — Development (free)

- Build and run locally via Xcode
- Set MarkCalm as default `.md` handler on developer's Mac
- No Apple Developer Program required

### Phase 2 — Share with developers (free)

- Open-source repo with build-from-source instructions
- Requires Xcode and free Apple ID on recipient's Mac

### Phase 3 — Share binary with anyone ($99/year)

- Apple Developer Program enrollment
- Developer ID signing + notarization
- Ship signed `.dmg` via GitHub Releases or direct download
- Optional: Homebrew cask

Unsigned binaries are not an acceptable distribution path for non-technical users.

---

## Project Structure

```
markcalm/
├── MarkCalm/                   # Xcode app target
│   ├── MarkCalmApp.swift       # App entry, DocumentGroup, Settings scene
│   ├── MarkdownDocument.swift  # File document model (read-only)
│   ├── ContentView.swift       # Reading view, scroll, progress bar
│   ├── MarkdownPipeline.swift  # Frontmatter strip + parse prep
│   ├── SettingsView.swift      # Settings window UI
│   ├── DefaultAppPrompt.swift  # One-time default-app nudge
│   └── Assets.xcassets
├── MarkCalmTests/              # Unit tests
├── docs/superpowers/specs/     # This document
└── README.md                   # Build and run instructions
```

---

## Open Questions

None — design approved 2026-06-10.
