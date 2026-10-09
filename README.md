# Rock Blaster 🚀

An arcade asteroid shooter by WAJIHA. Blast the belt, dodge the debris,
outlive the waves — or chase a high score in 2-minute Score Attack runs.

## Features

- **Engine-owned state machine + watchdog** — phases (`ready → playing ⇄
  waveBreak → gameOver`, plus `respawning`/`paused`) always carry live
  deadlines; a 1s watchdog forces any stuck phase forward. No freezes, ever.
- **Juicy feedback** — screen shake, explosion particles, floating score
  popups, wave banners, muzzle flash, thruster flames, invulnerability blink.
- **Synthesized audio** — cached WAV clips, SFX pool for overlapping lasers,
  looping thruster rumble, menu + gameplay music, busy-guard serialization,
  lifecycle pause/resume, splash prewarm. Toggles + volume in Settings.
- **Modes** — Endless (3 lives) and Score Attack (2 minutes, unlimited
  respawns).
- **Difficulties** — Cadet, Pilot, and Ace (Pro) with clear speed/density/
  UFO-accuracy progression.
- **Customization** — 12 space themes + custom color creator (Pro),
  9 toy-like ship styles, 8 rock styles. Renameable pilot profile persisted
  as a single order-safe JSON string.
- **Pro + tip jar** — real Play Billing: `rockblasterpro` (one-time),
  `rockblastercoffee` / `rockblasterchocolate` (consumable tips). Free-vs-Pro
  table, restore purchases, graceful "after store setup" state.
- **Share + review** — share your score via the Play Store link; review
  prompt appears at sensible moments (new best / every 4th run).

## Rules

See [RULES.md](RULES.md) — the authoritative gameplay specification.

## Build

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

Package: `com.gameswajiha.rockblaster`
