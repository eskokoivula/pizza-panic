# Pizza Panic — MVP Game Spec

## Overview

Pizza Panic is a fast-paced mobile web game. The player runs a pizza station: read each customer order, build the pizza, bake it for the right amount of time, and serve. Each round gets faster and the meme music speeds up with it. The game runs as long as the player makes correct moves — the **first wrong move ends the game**.

## Game Length

There is no fixed total timer. The game continues round by round until the player commits any wrong move (see Round End Conditions). Score never decreases, so the final score is always whatever the player accumulated up to that mistake.

## Game Flow

ALOITA PAISTO → read order → MÄTÄISE TAIKINA (add toppings within 6 s) → UUNIIN → PYSÄYTÄ → TARJOILE → next order. The game ends on the first wrong move.

## Round Counter

A round counter is visible in the HUD next to the score. It starts at 1 on ALOITA PAISTO and increments each time a new pizza begins (after every successful TARJOILE). It controls bake speed and music speed.

## HUD

The HUD has two cells:
- `Kierros: <n>`
- `Pisteet: <n>`

There is no global time counter.

## Order System

- One order is shown at the top of the bake screen at all times: `ASIAKAS HALUAA: <toppings>`.
- Each order is a random set of 1–3 toppings drawn from the normal toppings list. KARVA never appears in orders.
- A new order is generated immediately after each successful TARJOILE.

## Topping Timer

- The bake screen shows a countdown next to MÄTÄISE TAIKINA: `Aikaa: 6,0s` → `0,0s`.
- The budget is a constant **6 seconds** per pizza, regardless of round.
- If the countdown hits 0 before UUNIIN is pressed, the game ends → "Liian hidas!" screen (see Round End Conditions).
- Pressing UUNIIN before the countdown expires advances normally and clears the countdown.
- Resets on every new pizza. Cleared when leaving the bake screen for any reason.

## Toppings

Normal (orderable, safe):
- Juusto
- Pepperoni
- Oliivi
- Herkkusieni
- Ananas

Trap:
- KARVA — visible as a 6th button in the topping grid. Button label text: **"Karva"** with the curly-hair SVG icon. Clicking it ends the game instantly with "Hyi helvetti, KARVA!!". Position randomized every order.

## Bake Mechanic (Oven)

- After UUNIIN, an oven bar fills from 0% to 100%.
- The bar is divided into three zones (proportions constant across rounds):
  - 0–62%: ALIKYPSÄ (undercooked)
  - 62–85%: PERFECTO (perfect)
  - 85–100%: PALANUT (burnt)
- PYSÄYTÄ behavior:
  - In PERFECTO → proceed to TARJOILE step
  - **In ALIKYPSÄ → game ends instantly → "Alikypsä!" screen** (TARJOILE never reached)
  - **In PALANUT → game ends instantly → "Pizza paloi!" screen** (TARJOILE never reached)
- If the player does not press PYSÄYTÄ before the bar reaches 100% → game ends → "Pizza paloi!" screen.

### Bake Speed Ramp

The total fill time decays exponentially per round:

    bakeMs(round) = max(300, 4000 × 0.85^(round − 1))

| Round | Total fill | Perfect window (23 %) |
| --- | --- | --- |
| 1 | 4.00 s | 0.92 s |
| 5 | 2.09 s | 0.48 s |
| 8 | 1.51 s | 0.35 s |
| 10 | 0.94 s | 0.22 s |
| 13 | 0.58 s | 0.13 s |
| 15 | 0.44 s | 0.10 s |
| 17+ | 0.30 s (floor) | ~0.07 s |

By round 13 the perfect window collapses below typical reaction time. Floor is reached at round 17 — the perfect window is then ~70 ms, well below human reaction time, so stopping in PERFECTO becomes pure luck. This aligns with the music cap at round 13: by the time the audio peaks, the bake is already in luck-shot territory.

## Audio (Music Sync)

The meme song is the centerpiece of the game.

- File: `assets/pizza-song.mp3` (relative path; project must contain it).
- Audio is played via the **Web Audio API** (not `<audio>`). The mp3 is fetched once, decoded into an `AudioBuffer`, and played through an `AudioBufferSourceNode` connected to the context destination.
- The `AudioContext` is created lazily on the first ALOITA PAISTO tap (required by browsers for autoplay).
- The source loops with `loopStart = 14 s` and `loopEnd = buffer.duration`, skipping the silent intro on every loop.
- Web Audio's `playbackRate` naturally affects pitch — chipmunk effect emerges automatically as rounds advance.
- The rate is synced to the bake speed curve, **slow at start, fast at the end**:

      t = min(1, (round − 1) / 12)
      musicRate(round) = 1.0 + 1.0 × t²

| Round | playbackRate |
| --- | --- |
| 1 | 1.00× |
| 3 | 1.03× |
| 5 | 1.11× |
| 7 | 1.25× |
| 8 | 1.34× |
| 10 | 1.56× |
| 12 | 1.84× |
| 13+ | 2.00× (cap) |

- Rate transitions use `playbackRate.setTargetAtTime(target, ctx.currentTime, 0.05)` — exponential ramp with ~50 ms time constant, no audible step.
- Music stops on **any** game over (karva, slow, alikypsä, palanut, mismatch). The source is `stop()`ed and disconnected; a fresh source is created on each new game.
- If the audio file is missing or decoding fails, the game still runs silently. No crash, no error UI — only a console warning.

## Scoring

Score never goes negative. Only successful TARJOILE actions add points. Any wrong move ends the game.

| Pizza vs order | Bake quality | Outcome |
| --- | --- | --- |
| Match | PERFECTO | +3 score, continue to next round |
| Mismatch | PERFECTO | **Game over → "Väärä tilaus!" screen** |

Notes:
- ALIKYPSÄ and PALANUT pizzas never reach a TARJOILE evaluation — both end the game during the bake step.
- Match comparison is an exact set match — order of toppings does not matter, but the set must be identical to the order.

## Round End Conditions

There are **5 game-over paths**, each with its own visually distinct screen. All show: title, final score, PELAA UUDESTAAN. Music stops on every ending.

1. **Karva** — KARVA button is clicked at any point in the bake step.
   - Screen title: "Hyi helvetti, KARVA!!"
2. **Slow** — topping timer (6 s) hits 0 on the bake screen before UUNIIN is pressed.
   - Screen title: "Liian hidas!"
3. **Alikypsä** — PYSÄYTÄ pressed while the bake bar is in the yellow zone (0–62 %).
   - Screen title: "Alikypsä!"
4. **Palanut** — bake bar entered the red zone (PYSÄYTÄ in PALANUT, or auto-fill to 100%).
   - Screen title: "Pizza paloi!"
5. **Mismatch** — TARJOILE pressed with a pizza whose topping set does not match the active order.
   - Screen title: "Väärä tilaus!"

## UI Text (Finnish)

ALOITA PAISTO
ASIAKAS HALUAA
MÄTÄISE TAIKINA
Aikaa
UUNIIN
PYSÄYTÄ
PERFECTO
ALIKYPSÄ
PALANUT
TARJOILE
Karva
Kierros
Pisteet
Liian hidas!
Alikypsä!
Pizza paloi!
Väärä tilaus!
Hyi helvetti, KARVA!!
PELAA UUDESTAAN
