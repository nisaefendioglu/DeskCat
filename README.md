# DeskCat

A tiny macOS menu bar companion. **Pip**, your desk cat, keeps you company while you work — and meows once when you drift away from the keyboard.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![SwiftUI](https://img.shields.io/badge/SwiftUI-AppKit-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

<video src="docs/video/DeskCat.mp4" controls width="720" title="DeskCat demo"></video>

[**▶ Watch the demo**](docs/video/DeskCat.mp4) (≈12s) — Pip on the mini desk, idle moods, and the away meow.

## What it does

DeskCat lives in the menu bar. It watches idle time and the frontmost app (no “Start Focus” button) and updates Pip’s mood on a mini desk scene.

| Pip mood | When |
| --- | --- |
| Focusing | You’re active at the keyboard |
| Drifting / drowsy | You’ve been idle for a bit |
| Asleep | Idle past your sleep threshold |

After your chosen away time (default ~1 minute), Pip **meows once** for that away stretch. Coming back to the keyboard arms the next meow. Optional notification banner. Snooze (“Remind later”) silences meows for a while.

## Features

- Menu bar Pip (awake / drowsy / sleep icons)
- Mini desk scene — lamp, notebook, coffee steam, writing pen
- Automatic idle + frontmost-app tracking
- Focus / distraction breakdown by app (today)
- Customizable sleep threshold and meow delay
- Appearance: System / Light / Dark
- Language: System / English / Turkish
- Menu bar–only app (`LSUIElement`) — no Dock icon while idle

## Download

Grab the latest **`.dmg`** from [Releases](https://github.com/nisaefendioglu/DeskCat/releases):

1. Open `DeskCat-x.y.z.dmg`
2. Drag **DeskCat** into **Applications**
3. Launch from Applications (or Spotlight)

### Open on macOS (Gatekeeper)

The release DMG is **not** Developer ID–signed or notarized (that needs a paid Apple Developer account). Gatekeeper may show *“Apple could not verify DeskCat.app…”* — that is expected, not a bug in the app.

**Workaround (once):**
1. In Finder, **right-click** `DeskCat.app` → **Open** → **Open** again in the dialog  
2. Or: **System Settings → Privacy & Security** → **Open Anyway**  
3. Or after installing: `xattr -cr /Applications/DeskCat.app` then open normally

## Requirements

- macOS 14 Sonoma or later
- Xcode 16+ (only if building from source)

## Run from source

```bash
git clone https://github.com/nisaefendioglu/DeskCat.git
cd DeskCat
open FocusDesk.xcodeproj
```

Press **Run** (⌘R). Look for Pip in the menu bar. Click Pip to open the desk popover; use the gear for Settings.

### Build a DMG locally

```bash
./scripts/make-dmg.sh
# → build/DeskCat-1.0.0.dmg
```

Optional: `VERSION=1.0.1 ./scripts/make-dmg.sh`

> The Xcode project folder is still named `FocusDesk` for historical reasons; the product and display name are **DeskCat**.

## Privacy

- Idle time uses `CGEventSource` (no Accessibility permission required)
- Frontmost app uses `NSWorkspace`
- No accounts, no analytics, no network calls for tracking
- Notifications are optional and only used for the away banner

## License

[MIT](LICENSE)
