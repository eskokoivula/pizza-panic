# Pizza Panic — Visual Spec

Visual identity for Pizza Panic. Complements `spec.md` (game logic, source of truth) and does not change any timing, scoring, or round-end logic. Numeric values for timers, zones, and rounds live in `spec.md`.

This document reflects the Sprint 3 mockup approved 2026-04-27 and the implementation in `index.html`.

## Style

Sticker-pack bold cartoon.

- Thick black outlines (3–6 px) on every shape
- Slight tilt on stickers (–4°…+2°) for hand-placed feel
- Drop-shadow filter: `drop-shadow(0 3px 0 charcoal) drop-shadow(0 8px 12px rgba(0,0,0,0.15))`
- Buttons: 4 px charcoal border, 4 px charcoal "depth" shadow, press-down animation
- Saturated colors with high contrast
- Snappy micro-animations (drop-in, bounce, pulse)

## Color Palette

| Role | Hex | Usage |
| --- | --- | --- |
| Cream (background) | `#FFF6E5` | App background, button text on dark buttons |
| Pizza red | `#E63946` | Pepperoni, oliivi pimento, palanut zone, score number |
| Basil green | `#2A9D5F` | Oliivi body, perfecto zone, TARJOILE button, ✓ |
| Warm yellow | `#FFB627` | Cheese highlight, alikypsä zone, UUNIIN button, ALIKYPSÄ shadow |
| Shock pink | `#FF3D9A` | ALOITA PAISTO + PELAA UUDESTAAN buttons, title shadow |
| Charcoal | `#1A1A1A` | All outlines, primary text |
| Tomato sauce | `#B22A2A` | Sauce ring under cheese (deeper than pepperoni for contrast) |
| Brown crust | `#D4965A` | Pizza crust ring |
| Cheese | `#FFD063` | Default cheese fill (overridable via `--cheese-fill` CSS var) |

Background pattern: cream base with five faint pepperoni-spot radial gradients tiling at 280×280 px (8 % opacity red dots).

## Typography

- **Display:** `Lilita One` — titles, buttons, scores, HUD values, quality stamp, zone label
- **Body:** `Plus Jakarta Sans` (weights 500, 700, 800) — speech-bubble label, HUD label, score caption
- Loaded via Google Fonts `<link>` in `<head>`
- HUD numbers in display font, ~26 px, no animation by default; flash green briefly on score increment

## SVG Library

All visual assets are inline SVG `<symbol>`s defined once in `<defs>` and reused via `<use>` across screens. No external image files except the audio asset.

### `pizza-base` (200×200)
- Brown crust ring `#D4965A` (r = 92), charcoal outline 5 px, four small dark spots for texture
- Tomato sauce circle `#B22A2A` (r = 80) — deeper red than pepperoni so it shows as a ring inside crust
- Cheese circle (r = 70), fill from `--cheese-fill` CSS var (default `#FFD063`)
- Two white ellipse highlights on cheese (35 % and 30 % opacity)

### Toppings (80×80 viewBox)
- `t-pepperoni` — `#E63946` circle with darker `#9B1F2A` spots
- `t-juusto` — `#FFD93D` melted-cheese drip shape with darker holes
- `t-oliivi` — basil green `#2A9D5F` ellipse with red `#E63946` pimento centre
- `t-herkkusieni` — brown cap `#A8754B` on cream stem `#F4E0C2`
- `t-ananas` — yellow rotated square with cross-hatch in `#E8A82E`
- `t-karva` — single thin curly hair (3 px charcoal stroke), tilted –22°, transparent background, **no skin oval**

### Customer faces (100×100 viewBox)
- `cust-rento` — neutral cream face `#E8B698`, smile arc
- `cust-hermostunut` — same skin, downward eyebrows, oval mouth, blue sweat drop
- `cust-raivokas` — red face `#E84A4A`, angled angry brows, small downward-arc mouth (no white anger marks, no yelling box)

## Screens

The app has nine screens. Only one is active at a time. Mounted inside `#app` (max-width 430 px, centered).

### Start (`#screen-start`)
- Two-row title: "PIZZA" charcoal with pink shadow, no tilt; "PANIC" red with charcoal shadow, tilted +2°
- Credit line under title: "by lieksazz" with small inline TikTok icon (uppercase, 70 % opacity, no tilt)
- Hero pizza centered with bobbing animation
- Pink **ALOITA PAISTO** button, pulses
- No music hint UI — music auto-starts on click

### Bake (`#screen-bake`)
- HUD top: Kierros + Pisteet in two white sticker cells
- Customer face (left, animated bob) + speech bubble (right) showing "ASIAKAS HALUAA: …"
- Customer expression escalates with round count: rento (early) → hermostunut → raivokas (late)
- Pizza centered with `placed-toppings` overlay (toppings drop-in with bounce, max 5 distinct slots, no overlap)
- 3×2 grid of white sticker topping buttons: Juusto, Pepperoni, Oliivi, Herkkusieni, Ananas, Karva. Position randomized per round (per `spec.md`). Selected toppings get green basil background.
- Countdown row: "Aikaa" label + time text + horizontal bar that drains and shifts color (green → yellow → red)
- Yellow **UUNIIN** button

### Oven (`#screen-oven`)
- HUD same as bake
- "PYSÄYTÄ VIHREÄLLÄ!" instruction — straight, no rotation, yellow text-shadow
- Pizza (with the toppings just placed) centered with tilt animation
- 4 sticker flames below pizza (yellow outer + red inner, charcoal outlines), flickering animation
- Bake bar: 62 % ALIKYPSÄ (yellow) + 23 % PERFECTO (basil green, label inside) + 15 % PALANUT (red)
- Indicator: vertical charcoal bar with arrow caps top + bottom, sweeps left → right
- Red **PYSÄYTÄ** button — straight, no shake

### Serve (`#screen-serve`)
- HUD same
- Tilted quality stamp: green "PERFECTO!" with charcoal shadow (pop-in animation). ALIKYPSÄ no longer reaches this screen — only PERFECTO bakes do.
- Pizza centered (180 px) with same toppings as bake
- Two `match-row` cells: "Tilaus" + topping SVG icons; "Sinun" + topping SVG icons. Green ✓ shown on Sinun row only when sets match.
- Green **TARJOILE** button

### Game-over screens (`.game-over-screen` shared layout)

Each screen: visual (180 px) → tilted title → score box (red number + "pistettä") → pink pulsing **PELAA UUDESTAAN** button. Drop-in animation cascade: visual 0.1 s, title 0.25 s, score 0.4 s, button 0.55 s.

| Screen | Visual | Title shadow |
|--------|--------|--------------|
| `#screen-karva` | Big tilted curly hair (8 px stroke) | pizza red |
| `#screen-hidas` | Yellow clock with red minute hand at 12, charcoal hour hand at ~6 | yellow |
| `#screen-alikypsa` | Pale dough pizza: light crust `#E8C99A`, pale sauce `#D45A5A`, unmelted cheese `#FFE9A8`, no toppings | yellow |
| `#screen-palanut` | Charred black pizza, glowing red/yellow embers, three grey smoke wisps | charcoal (title is red) |
| `#screen-vaara` | Raivokas customer face | pizza red |

## Animations

- `drop-in` (0.6 s, cubic-bezier overshoot) — used on titles, hero, game-over visuals/scores
- `pizza-bob` — start screen hero, ±5° tilt + 8 px translate, 3.6 s loop
- `pizza-tilt` — oven pizza, ±3° loop, 0.55 s
- `cust-bob` — bake screen customer, subtle bob, 2.6 s loop
- `flame-flicker` — oven flames, 0.32 s steps(2)
- `topping-drop` — placed toppings, 0.32 s overshoot, staggered by index
- `stamp-pop` — quality stamp on serve, 0.5 s overshoot
- `btn-pulse` — primary buttons (start, replay), 1.6–1.8 s gentle pulse
- HUD score: brief green flash on score increment

## What does NOT change

- Game logic, timing, scoring, round-end conditions, all tunable knobs — `spec.md` is source of truth
- Audio mechanics — `spec.md` Audio (Music Sync) section
- Finnish UI text — `spec.md` UI Text section

## Sensitive note: KARVA

KARVA is the meme trap element. The current implementation is a single thin curly hair on transparent background — no skin oval. This was changed from an earlier draft mid-Sprint 3 because the brown-skin background risked reading as racial. Keep it as just a hair: it reads as "stray hair from somewhere", comedic and unambiguous. Do not reintroduce a skin background.
