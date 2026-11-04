# DeskCat

A tiny macOS menu bar companion. **Pip**, your desk cat, keeps you company while you work — and meows once when you drift away from the keyboard.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![SwiftUI](https://img.shields.io/badge/SwiftUI-AppKit-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

https://github.com/user-attachments/assets/890d0487-eb55-4cb6-9b43-6f90cd01692c

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
2. Drag **DeskCat.app** into **Applications** (don’t launch from inside the DMG)
3. Open **DeskCat** from Applications (or Spotlight)

### First open on macOS (Gatekeeper)

The release is **ad-hoc signed** (not Developer ID / not notarized). Apple’s Gatekeeper warning is expected until the app is notarized with a paid [Apple Developer Program](https://developer.apple.com/programs/) membership ($99/yr).

**Do this once after copying to Applications:**

1. Try opening DeskCat from **Applications**.
2. If you see *“Apple could not verify DeskCat.app is free of malware…”*:
   - Open **System Settings → Privacy & Security**
   - Scroll down to the message about DeskCat
   - Click **Open Anyway**, then confirm **Open**
3. Or clear the quarantine flag in Terminal, then open normally:

```bash
xattr -cr /Applications/DeskCat.app
open /Applications/DeskCat.app
```

> On Sequoia / Sonoma, right-click → Open often no longer offers an **Open** button on the same dialog — **Open Anyway** in Privacy & Security is the reliable path.

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
