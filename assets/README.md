# assets/

Drop the meme audio file here as `pizza-song.mp3`.

The game expects exactly:

    assets/pizza-song.mp3

The audio element in `index.html` loads this path, plays on ALOITA PAISTO, loops, and ramps up `playbackRate` per round (chipmunk effect).

If the file is missing, the game still runs silently — no crash, just no music.
