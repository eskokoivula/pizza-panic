# Pizza Panic

Is a Finnish meme pizza game I built with my son to teach him basics of vibe coding.
Mobile-first, browser-based, music-driven, and legally not responsible for what it does to your dopamine receptors, created under conditions that could loosely be described as “product development.

**Live:** https://pizza-paniikki.web.app

## What this is

On the surface, it is a simple mobile-first pizza game. Underneath, it is a serious cultural preservation project dedicated to an old Finnish pizza meme that has somehow outlived trends, platforms, attention spans, and majority of startups.
The idea was simple: take something deeply stupid, treat it with unnecessary respect, make it playable on mobile so he can share it on TikTok and take all the credits.

It is fast, chaotic, Finnish, and about pizza.
In other words, a perfectly reasonable use of modern technology.

## How to play

Tap **ALOITA**, read the order, add the right toppings, throw the pizza in the oven, and stop the bake bar in the green PERFECTO zone. One mistake ends the game. Each round speeds up — by round 17 the perfect window is below human reaction time, so finishing strong is half skill and half luck.

Avoid the **KARVA** (hair) topping. Instant game over.

## Tech

- One HTML file, no build step
- Web Audio API for the music — `playbackRate` ramps with the round, pitch goes chipmunk
- Firebase Auth (Google sign-in) + Firestore for the leaderboard
- Firebase Hosting for the public URL
- Anti-cheat in Firestore security rules: monotonic best score, ≤1000 cap, 5 s rate-limit, immutable createdAt
- Parental supervision, technically

## Local dev

The meme audio is not committed (see below). Drop your own `assets/pizza-song.mp3` first, then serve the project root on port 8080:

```bash
python3 -c "
import http.server, socketserver, os
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        super().end_headers()
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(('', 8080), H) as httpd:
    httpd.serve_forever()
"
```

Open `http://localhost:8080/index.html`.

## Deploy

Requires Firebase CLI (`brew install firebase-cli`) and `firebase login`.

```bash
firebase deploy --only hosting          # game
firebase deploy --only firestore:rules  # security rules
```

## Project structure

- `index.html` — the entire game
- `firestore.rules` — anti-cheat rules
- `firebase.json`, `.firebaserc` — Firebase CLI config
- `spec.md` — game logic source of truth
- `visual-spec.md` — visual identity
- `leaderboard-design.md` — auth + leaderboard design
- `plan.md`, `handoff.md` — project history and running notes
- `assets/` — drop `pizza-song.mp3` here (see [`assets/README.md`](assets/README.md))
- `mockup.html` — early visual mockup, no game logic

## About the meme audio

The song is copyrighted Finnish meme material. It's central to the experience but I'm not shipping it in a public repo. Find the original `pizza-song.mp3` yourself, drop it in `assets/`, and the game will pick it up. Without the file the game still runs — just silent.

## Known limitations

- 404 page is the Firebase default — generic, not pizza-themed
- Difficulty plateaus at the floor (round 17+) — challenging but doesn't get harder past that
- One HTML file means no code separation, no lint, no tests — fine for an MVP, would be the first thing to fix if extended
- No custom domain yet — lives on the default `*.web.app` host

## Credits

Built by Esko Koivula and his son. Logic and visuals iterated through repeated sessions with Claude Code.
