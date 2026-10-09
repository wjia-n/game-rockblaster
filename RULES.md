# Rock Blaster — Rules

This document is the authoritative source of truth for Rock Blaster gameplay.
If the implementation ever conflicts with this document, fix the implementation.

## 1. Objective

Pilot a rocket ship through an asteroid belt. Blast every rock into rubble,
dodge debris and enemy saucers, and survive as many waves as possible.
In Score Attack, score as many points as possible in 2 minutes.

## 2. Setup

- The ship spawns at the center of the playfield with 1.0s of invulnerability.
- Endless mode: 3 lives. Score Attack: unlimited lives, 120 seconds on the clock.
- Wave 1 spawns `min(3 + difficulty + wave, cap)` large rocks at the playfield
  edges, never within 170px of the ship (no unfair instant deaths).
- Difficulty caps: Cadet 7, Pilot 9, Ace 11 rocks per wave.

## 3. Turn order (game phases)

The engine owns a strict phase machine; phases always advance in this order:

1. `ready` (1.4s "GET READY" banner) → 2. `playing` → 3. `waveBreak`
   (2.0s bonus banner) → 2. `playing` → … → 6. `gameOver`.
4. `respawning` (1.0–1.3s) interrupts `playing` on death and returns to `playing`.
5. `paused` freezes `playing`/`ready`/`waveBreak`/`respawning` and restores
   the exact previous phase on resume.
6. Every timed phase carries a live deadline. A 1-second watchdog re-checks
   all invariants: any phase found without a live deadline, or a `playing`
   phase with zero rocks and no pending transition, is forced forward.
   Stuck states are impossible by construction.

## 4. Legal moves

- Hold ◀ / ▶ to rotate the ship (3.6 rad/s).
- Hold ▲ to thrust (340 px/s², drag 0.55/s, max speed 440 px/s).
- Tap or hold 🔥 to fire (0.17s cooldown; bullets live 0.9s at 580 px/s).
- Tap 🌀 to hyperspace-jump to a random point (1.0s invulnerability after).
- The playfield wraps: ship, rocks and particles exiting one edge re-enter
  the opposite edge.

## 5. Illegal moves

- Firing during `ready`, `waveBreak`, `respawning`, `paused` or `gameOver`
  does nothing (no shot is consumed, no error is shown — the cannon is cold).
- Hyperspace during any non-`playing` phase does nothing.
- Rotation/thrust inputs are ignored unless the phase is `playing`.

## 6. Captures (destructions)

- Player bullets destroy rocks and the enemy saucer on contact.
- Enemy saucer bullets and rocks destroy the ship on contact (unless
  invulnerable — see §7).
- A destroyed large rock (radius > 40) splits into 2 medium rocks;
  a destroyed medium rock (radius > 20) splits into 2 small rocks;
  small rocks are destroyed outright.
- Rocks are never destroyed by other rocks, and bullets never collide
  with each other.

## 7. Special rules

- **Invulnerability:** 1.0s after spawn, 2.5s after respawn, 1.0s after a
  hyperspace jump. The ship blinks while invulnerable and cannot die.
- **Hyperspace risk:** 15% chance the jump itself destroys the ship
  (the void sometimes bites back). Never usable while invulnerable
  protection from a fresh respawn would be wasted — the jump resets it.
- **Enemy saucer:** spawns every ~26s (Cadet), ~18s (Pilot), ~12s (Ace);
  drifts across the screen on a sine wobble and fires aimed shots with
  angular error 0.38 / 0.20 / 0.09 rad. Worth 200 points.
- **Score Attack:** the clock runs only during `playing`. At 0:00 the run
  ends immediately, even mid-wave.
- **Wave-clear bonus:** awarded the moment the last rock is destroyed:
  `wave × 100` points plus a "+N WAVE BONUS" popup.

## 8. Scoring

| Event | Points |
|---|---|
| Large rock destroyed | 20 |
| Medium rock destroyed | 50 |
| Small rock destroyed | 100 |
| Enemy saucer destroyed | 200 |
| Wave-clear bonus | wave × 100 |

Scores are announced with floating "+N" popups at the destruction point —
never silently.

## 9. Winning conditions

- Endless mode has no final win: the run ends when all 3 lives are lost.
  Every cleared wave is a victory; the best score is the trophy.
- Score Attack ends at 0:00; the highest score wins.

## 10. Draw conditions

Not applicable — single-player arcade scoring has no draws.

## 11. AI strategy (enemy saucer)

- Enters from a random side at a random height (20–80% of playfield).
- Moves horizontally at 115 px/s with a ±34 px/s vertical sine wobble.
- Fires every 1.5s at the ship's current position plus a difficulty-scaled
  angular error (it leads less and misses more on Cadet).
- Exits the far side and despawns; the spawn timer then restarts.

## 12. Edge cases

- Bullet fired the same frame the last rock is destroyed: the rock still
  splits and scores; the wave break begins on the next update.
- Ship dies the same frame the last rock is destroyed: the wave-clear bonus
  is awarded first, then the death is processed.
- Death during hyperspace invulnerability: impossible (invuln > 0 blocks it).
- App backgrounded mid-run: engine pauses, music pauses; both resume
  exactly where they left off.
- Rapid pause/resume or music toggles: the audio generation counter makes
  the latest request win; music can never be left half-started or
  silently dead.

## 13. Test cases

Covered in `test/rock_engine_test.dart` and `test/settings_names_test.dart`:

1. `start()` → `ready` → (deadline) → `playing` with rocks spawned.
2. Empty rock field during `playing` → `waveBreak` → next wave spawns.
3. Watchdog never throws and never deadlocks; timed phases always advance.
4. Two deaths → `respawning` → `playing`; third death → `gameOver`.
5. Score Attack: death respawns without consuming lives; clock expiry →
   `gameOver`.
6. Rock smash scores points, splits large/medium rocks, increments the
   smash counter.
7. Pause freezes the world; resume restores the exact phase.
8. Profile JSON: round-trips, trims, migrates the legacy key, and falls
   back to the default on corrupt data.
