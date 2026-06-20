#!/usr/bin/env bash
#
# Rebuilds assets/honter-intro.mp4 from the raw 9x16 intro by re-styling the
# baked-in "The Game" subtitle and re-timing the powder beat.
#
# The raw clip (boden_intro_9x16.mp4) has "The Game" drawn into the video in a
# plain bold sans. This script:
#   1. Covers that baked text with a flat #928C8C patch (the clip's bg gray),
#      feathered so the edges blend seamlessly.
#   2. Draws "THE GAME" in Bangers (pure black, matching the HONTER BODEN
#      title) that DROPS in from the top and settles (~1.0-1.6s).
#   3. Inserts a 0.5s freeze at t=1.4s — BEFORE the powder starts forming
#      (~1.5s) — so the nose stays clean during the wait and the powder then
#      spews naturally 0.5s later. Freezing AFTER the powder starts looked
#      janky ("blob appears, pause, drops"), hence 1.4s specifically.
#
# Requires: ffmpeg (libx264), python3 + Pillow, curl. drawtext is NOT used
# (this ffmpeg lacks libfreetype) — the text is rendered with Pillow to a PNG
# and composited with overlay.
#
# The output is gitignored (large/derived); this script is the source of truth.

set -euo pipefail

SRC="${1:-/Users/macesko/Desktop/Claude general/Projects/Honter Bodem/boden_intro_9x16.mp4}"
OUT="${2:-$(cd "$(dirname "$0")/.." && pwd)/assets/honter-intro.mp4}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# 1. Fetch the Bangers font
FONT_URL="$(curl -s 'https://fonts.googleapis.com/css2?family=Bangers' -H 'User-Agent: Mozilla/5.0' | grep -oE 'https://[^)]+\.ttf' | head -1)"
curl -sL -o "$WORK/Bangers.ttf" "$FONT_URL"

# 2. Render the cover patch and the "THE GAME" text PNG
python3 - "$WORK" <<'PY'
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter
work = sys.argv[1]
# Cover: 960x280 flat bg-gray, feathered edges -> seamless over the flat bg
W, H = 960, 280
cov = Image.new('RGBA', (W, H), (146, 140, 140, 255))
mask = Image.new('L', (W, H), 0)
ImageDraw.Draw(mask).rectangle([30, 30, W - 30, H - 30], fill=255)
cov.putalpha(mask.filter(ImageFilter.GaussianBlur(14)))
cov.save(f'{work}/cover.png')
# Text: "THE GAME" in Bangers, pure black, sized to ~690px wide
Wt, Ht = 820, 180
txt = Image.new('RGBA', (Wt, Ht), (0, 0, 0, 0))
d = ImageDraw.Draw(txt)
fs = 150
f = ImageFont.truetype(f'{work}/Bangers.ttf', fs)
bb = d.textbbox((0, 0), 'THE GAME', font=f)
fs = int(fs * 690 / (bb[2] - bb[0]))
f = ImageFont.truetype(f'{work}/Bangers.ttf', fs)
bb = d.textbbox((0, 0), 'THE GAME', font=f)
tw, th = bb[2] - bb[0], bb[3] - bb[1]
d.text(((Wt - tw) // 2 - bb[0], (Ht - th) // 2 - bb[1]), 'THE GAME', font=f, fill=(0, 0, 0, 255))
txt.save(f'{work}/tgtext.png')
PY

# 3. Drop animation: ease-out-back from y=-200 (above screen) to y=564, over
#    t=1.0..1.6 — fast in, small settle bounce.
DROP="if(lt(t\,1.0)\,-200\,if(gt(t\,1.6)\,564\,-200+764*(1+2.70158*pow((t-1.0)/0.6-1\,3)+1.70158*pow((t-1.0)/0.6-1\,2))))"

# 4. Composite: freeze 0.5s @1.4s (12 frames @24fps), cover the old text,
#    overlay the dropping "THE GAME".
ffmpeg -y -i "$SRC" -i "$WORK/cover.png" -i "$WORK/tgtext.png" -filter_complex "\
[0:v]trim=0:1.4,setpts=PTS-STARTPTS[v1];\
[0:v]trim=1.4:1.45,setpts=PTS-STARTPTS,loop=loop=11:size=1:start=0,setpts=N/(24*TB)[vf];\
[0:v]trim=1.4,setpts=PTS-STARTPTS[v2];\
[v1][vf][v2]concat=n=3:v=1[cat];\
[cat][1:v]overlay=58:517[base];\
[base][2:v]overlay=x=128:y=${DROP}:eval=frame[out]" \
  -map "[out]" -an -r 24 -c:v libx264 -pix_fmt yuv420p -crf 20 -preset veryfast "$OUT"

echo "Built $OUT"
