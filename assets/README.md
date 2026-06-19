# assets/

Brand media for **Honter Boden**. These files are **not committed to git** (see `.gitignore`)
— they are kept locally and shipped by Firebase Hosting (which deploys from disk, not git).
If a file is missing, the game still runs — it just skips that media (no crash).

## Files the game expects

    assets/honter-song.m4a   — in-game background music (loops, ramps playbackRate per round)
    assets/honter-intro.mp4  — start-screen intro video (muted, 4s, swap the "real" one in later)

## Re-create the music from the source video (no ffmpeg needed)

The music is the audio track of the Kiffness "Ievan Polkka (Club Remix)" video. Extract it with
the macOS built-in `afconvert`:

    afconvert -f m4af -d aac \
      "/path/to/The Kiffness - Ievan Polkka ... (Club Remix) ... .mp4" \
      assets/honter-song.m4a

The audio engine in `index.html` fetches `assets/honter-song.m4a`, decodes it via Web Audio,
loops it, and ramps `playbackRate` 1.0 → 2.0 over ~12 rounds (chipmunk effect). To change the
loop start point, edit `MUSIC_START_S` in `index.html`.

## Intro video

`assets/honter-intro.mp4` autoplays muted on the start screen. To swap in the final intro later,
just replace this file (keep the same name) — no code change needed.
