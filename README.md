# Qiwi Browser

A Kiwi-like Chromium for Android phones: degoogled, with extensions, DevTools and the classic stack tab switcher.
Based on Chromium `153.0.8010.37`. Package `com.qiwi.browser`, so it installs next to other Chromium builds.

Download the arm64 APK from [Releases](https://github.com/n0n3m4/Qiwi-Browser/releases).

## What's different from Chromium

- **Extensions on phones**, both Manifest V2 and V3. Load unpacked from `chrome://extensions`, or open a `.crx`
  link (GitHub release `.crx` files work too). Each extension gets a row in the app menu; there are no toolbar buttons.
- **No Google.** A subset of [cromite](https://github.com/uazo/cromite)'s patches removes telemetry, GMS, variations,
  updates and the Safe Browsing backend. No sync, sign-in, push, translation or passkeys.
- **DevTools** from the app menu, and "Inspect" in the long-press menu.
- **Classic stack tab switcher**, ported from Chromium 90.
- **Small UI trims:** no "make default browser" prompts, the address bar stays in the toolbar on the New Tab Page,
  and Google-only settings are removed. Screenshots in Incognito can be allowed in Settings (off by default).

## Building

Needs Linux x86_64, ~16 GB RAM plus swap, and ~120 GB of disk.

```bash
export WORK=/mnt/scratch
scripts/checkout.sh          # Chromium at the tag in CHROMIUM_VERSION
scripts/apply_patches.sh     # patches/*/series, in order
scripts/build.sh arm64       # dev build; build_release.sh makes the signed official build
```

Each file in `patches/NN-*/` is one commit, and its message explains the change.
