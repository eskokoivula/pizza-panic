# Pizza Panic — Handoff (v8 Phase 6 valmiit, Phase 6.5 GitHub push seuraavaksi)

You are continuing work on a small meme-based mobile web game. The user is non-technical, Finnish-speaking, has ADHD. **Read the rules below before doing anything.**

---

## HARD RULES (do not violate)

1. **All project files** live in `/Users/macesko/Desktop/Claude general/Projects/Pizza heist/`. Never write project files anywhere else.
2. **Documents and code in English. Game UI text in Finnish. Conversation matches the user's language** (usually Finnish).
3. **Show a plan and wait for explicit approval before any multi-step work or any code change.** ADHD: short paragraphs, one thing at a time, never dump everything in one message.
4. **Never delete or overwrite without explicit confirmation.** Warn first, then act.
5. **`spec.md` is source of truth for game logic. `visual-spec.md` for visuals. `leaderboard-design.md` for v8 leaderboard/auth design.** If docs and code disagree, ask before deciding which to change.
6. **Explain context for every file/component on first reference.** Name what each file is — e.g. `mockup.html` is a stand-alone preview, `index.html` is the live game.

---

## Project Documents

- `claude.md` — sprint structure and working-style rules
- `spec.md` — game logic source of truth (current state v7)
- `visual-spec.md` — visual identity source of truth (Sprint 3 mockup, unchanged in v7+)
- `leaderboard-design.md` — **v8 design** (leaderboard, Google login, Firestore data model, security rules, build phases)
- `plan.md` — version history of decisions (v1 → v8)
- `index.html` — live game implementation (v8 Phase 6 done: + hosting + tuned difficulty `BAKE_DECAY=0.85`, `BAKE_MIN_MS=300`. Web Audio API untouched.)
- `mockup.html` — Sprint 3 visual mockup, fully approved. Stand-alone preview, no game logic.
- `404.html` — Firebase default Page Not Found. Generic, not pizza-themed. Created by `firebase init hosting`.
- `assets/pizza-song.mp3` — meme song. Preloaded and decoded on page load, played via Web Audio. **NOT committed to git** (see `.gitignore`); user keeps it locally.
- `assets/README.md` — BYO mp3 instructions for anyone cloning the repo.
- **`firestore.rules`** — **deployed 2026-04-30** (anti-cheat: monotonic bestScore, ≤1000 cap, 5 s rate-limit, immutable createdAt, uid match, no deletes)
- **`firebase.json`** — Firebase CLI config: `firestore` block + `hosting` block (public=`.`, ignores docs/mockup/rules so only `index.html` + `404.html` + `assets/pizza-song.mp3` are deployed)
- **`.firebaserc`** — default project = `pizza-paniikki` (no need for `--project` flag)
- **`README.md`** — drafted 2026-05-01, English. Public-facing project description, BYO mp3, deploy commands, known limitations.
- **`.gitignore`** — Firebase init defaults + `assets/pizza-song.mp3` + `.DS_Store`

---

## Current Status

**v8 Phase 1–6 valmiit. Phase 6.5 (GitHub push) seuraavaksi.**

Live URL: https://pizza-paniikki.web.app — verified working on phone 2026-05-01.

### v8 Phase 4 — DONE 2026-04-29 (Leaderboard view)
All implemented in `index.html`:
- ✅ Firestore imports added: `collection, query, orderBy, limit, getDocs`
- ✅ `fetchLeaderboard()` module-level helper: top 10 query, top 100 fallback for own rank, returns `{ top, ownRow }`. `ownRow.rank` = string ("1"–"100" or "100+")
- ✅ `openLeaderboard()` flow: shows screen → "Ladataan…" → renders data / "Ei vielä pelaajia. Pelaa ensimmäinen erä!" / inline error
- ✅ `renderLeaderboard()` + `setLeaderboardStatus()` + `escapeHtml()` (nicknames not sanitized server-side, must escape on render)
- ✅ New `screen-leaderboard`: title (Lilita One, yellow shadow, sticker-tilt), `.leaderboard-list` container, `TAKAISIN` button → `game.show('start')`
- ✅ `LEADERBOARD` button on start screen (yellow `.btn-leaderboard`, no pulse, between ALOITA and auth UI). Visible signed-out too.
- ✅ Pink border on own row (`.leaderboard-row.own`, `4 px var(--pink)`). Removed `(sinä)` text labels because the border + `#`-rank prefix already convey it.
- ✅ Error messages rewritten — no longer "Ei yhteyttä" (misleading). Now: blocked → "Suojausasetuksesi esti yhteyden. Tarkista mainosesto / selaimen tietosuoja-asetukset ja päivitä sivu." Other → "Listan lataus epäonnistui. Päivitä sivu tai yritä uudestaan."
- ✅ Same wording propagated to `BLOCKED_MSG` (start-screen yellow banner) — "Brave Shields" mention removed for genericity.

### v8 Phase 4 — Verified (live, by user)
- ✅ Top 10 ordering descending by bestScore
- ✅ Own row pink border in top 10, no "(sinä)" text
- ✅ Rate-limit not yet hit (rules deployed in Phase 5)
- ⚠️ **Outside top 10 case (`#47 Esko 89` row)** not explicitly tested — only one user doc in DB during testing.
- ⚠️ Empty-state ("Ei vielä pelaajia") not exercised live (DB never empty).

### v8 Phase 5 — DONE 2026-04-30 (Firestore rules deployed)
- ✅ Firebase CLI installed via Homebrew (`brew install firebase-cli`, v15.15.0)
- ✅ Logged in as `esko.koivula1@gmail.com` (`firebase login`)
- ✅ Three new files at project root: `firestore.rules`, `firebase.json`, `.firebaserc`
- ✅ Rules deployed: `firebase deploy --only firestore:rules` → `✔ released rules firestore.rules to cloud.firestore`
- ✅ Light verification: user played a game, score saved, leaderboard rendered, no rule rejections.
- ⚠️ **Full verification (Rules Playground) NOT done.** Forbidden writes (other-user doc, score >1000, non-monotonic) not explicitly verified rejected. Worth doing in next session if convenient — Firebase Console → Firestore → Rules → Rules Playground.

### Rules differences from `leaderboard-design.md`
1. **Rate-limit reduced 30s → 5s.** User-approved. 30 s would block legitimate back-to-back KARVA-games (each ~7 s).
2. **`new.bestScore is int` → `is number`.** Firestore JS SDK stores all numbers as doubles; `is int` would reject all writes.
3. **Added `newDoc.lastPlayedAt == request.time` check on update.** Without it, attacker could keep `lastPlayedAt` frozen and bypass the rate-limit. Same check added to `isValidNewUser` for symmetry.
4. **Added `allow delete: if false`.** Belt-and-braces, design didn't mention deletes.

### ⚠️ DeepGuard / F-Secure / DNA Digiturva — environment gotcha
User has F-Secure DeepGuard active (via DNA Digiturva). It blocks Node.js from accessing protected folders (Desktop, ~/.config). **All previous "rename failed" / "An unexpected error has occurred" errors during Phase 5.1–5.2 were caused by this**, not by Firebase itself.

User added three allow rules in DeepGuard config (`~/.config/configstore/`, `~/Desktop/Claude general/Projects/Pizza heist/`, `~/firebase-debug.log`, all `rwcx`, all SHA256-bound to current Node binary).

**When this will bite again:**
- Brew updates Node → SHA256 changes → DeepGuard treats it as a new app → starts blocking again → spurious "An unexpected error" returns.
- Resolution: user re-clicks "Salli" on DeepGuard popups, or re-creates the rules in DeepGuard config.

### v8 Phase 6 — DONE 2026-05-01 (Hosting + difficulty tuning + README)
- ✅ `firebase init hosting` — public dir = `.`, no SPA, no GitHub auto-deploy, did not overwrite `index.html`. Created `404.html` (Firebase default), `.firebase/` cache, `.gitignore`. Added `"hosting"` block to `firebase.json` alongside existing `"firestore"` block.
- ✅ Authorized domains added in Firebase Console: `pizza-paniikki.web.app`, `pizza-paniikki.firebaseapp.com`.
- ✅ First deploy succeeded; flagged that 12 files shipped (internal docs publicly accessible). Tightened `firebase.json` `ignore` to add `**/*.md`, `mockup.html`, `firestore.rules`, `*.log`. Redeploy: 3 files (`index.html`, `assets/pizza-song.mp3`, `404.html`).
- ✅ Phone-tested live URL end-to-end: load, ALOITA, music, Google sign-in, score save, leaderboard, TAKAISIN. All green.
- ✅ **Difficulty tuned** based on phone test: `BAKE_DECAY` 0.80 → 0.85 (slower difficulty growth, longer "hard" phase), `BAKE_MIN_MS` 800 → 300 (lower floor — perfect window 69 ms at the floor, well below human reaction time). Floor reached at round 17 (~1:25 into audio), aligns with music cap at round 13. `spec.md` table updated. Audio file confirmed 192.6 s = 3:13.
- ✅ `README.md` drafted at project root. English. Covers what the project is (father-son vibe-coding learning project, Finnish meme tribute), how to play, tech stack, local dev (port 8080 server), deploy commands, project structure, BYO mp3 instructions, known limitations, credits. **Not yet git-committed** — user pushes in Phase 6.5.
- ✅ `.gitignore` extended to exclude `assets/pizza-song.mp3` (option B = public repo without copyrighted audio) and `.DS_Store`.

---

## Firebase Web App Config

These are NOT secrets in the traditional sense (Firebase designs config to be public in client code). Now the database is protected by deployed `firestore.rules` — safe to push to a public GitHub repo.

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyBCNeVxq84QC5H5HLwUjcSjdCAj95aAaWA",
  authDomain: "pizza-paniikki.firebaseapp.com",
  projectId: "pizza-paniikki",
  storageBucket: "pizza-paniikki.firebasestorage.app",
  messagingSenderId: "816172471465",
  appId: "1:816172471465:web:73b15d6ce1497274f245b8",
  measurementId: "G-6KHRXPNHFZ"
};
```

`measurementId` is for Analytics — not used by the game, can be ignored.

---

## v8 Build Phases (from `leaderboard-design.md`)

- ✅ **Phase 1** — Firebase project setup (user clicks)
- ✅ **Phase 2** — Login + user document + UX polish + back-to-menu navigation
- ✅ **Phase 3** — Score submission + "UUSI ENNÄTYS!" overlay banner + signed-out hint
- ✅ **Phase 4** — Leaderboard view (LEADERBOARD button + screen-leaderboard + fetchLeaderboard())
- ✅ **Phase 5** — Firestore rules + deploy (rate-limit 5 s, ≤1000 cap, monotonic, immutable createdAt). **Test mode replaced 2026-04-30, well before deadline.**
- ✅ **Phase 6** — Hosting + deploy + README (deployed 2026-05-01, README drafted, phone-verified)
- 🟡 **Phase 6.5** — Push to GitHub ← **next session starts here**

Estimated remaining work: ~30 min (Phase 6.5 only).

---

## Phase 6.5 — GitHub push (next session)

**Decisions already made (2026-05-01):**
- ✅ Repo will be **public** (portfolio + GitBook goal)
- ✅ Audio handling: **option B** — `.gitignore` excludes `assets/pizza-song.mp3`, README explains BYO instructions. Audio file stays on user's local Mac only.
- ✅ `.gitignore` already updated (mp3 + `.DS_Store` added on top of firebase init defaults)
- ✅ `README.md` already drafted at project root, English, ready to commit

**Remaining work:**

1. **Create GitHub repo** (recommend `gh` CLI; if not installed: `brew install gh` + `gh auth login`)
   ```
   gh repo create pizza-panic --public --description "Finnish meme pizza game — mobile web, Firebase, Web Audio API"
   ```
   - Repo name suggestion: `pizza-panic` (matches game name; project ID `pizza-paniikki` stays internal). User can change.
   - Or use the GitHub web UI if preferred.

2. **`git init` + first commit** in the project root
   ```
   cd "/Users/macesko/Desktop/Claude general/Projects/Pizza heist"
   git init
   git branch -m main
   git add .
   git status   # ⚠️ verify pizza-song.mp3 is NOT in the staged list
   git commit -m "Initial commit: Pizza Panic v8 (hosted, leaderboard, anti-cheat rules)"
   ```
   - Critical check: `git status` before commit. The mp3 must be ignored. If it shows up, the .gitignore line is wrong.

3. **Push**
   ```
   git remote add origin https://github.com/<username>/pizza-panic.git
   git push -u origin main
   ```
   (`gh repo create` with `--source` can do step 1+3 in one go — see `gh repo create --help`.)

4. **Verify on GitHub**
   - Repo loads, README renders correctly
   - `assets/pizza-song.mp3` does NOT appear in the file list
   - Live URL link in README works

5. **(Optional) Add live URL to repo description** via GitHub repo settings → Website field → `https://pizza-paniikki.web.app`

### Files that will be pushed

- `index.html` (the game)
- `404.html` (Firebase default, generic)
- `mockup.html` (early visual mockup, no game logic — kept as historical reference)
- `assets/README.md` (BYO mp3 instructions)
- `claude.md`, `spec.md`, `visual-spec.md`, `leaderboard-design.md`, `plan.md`, `handoff.md` (design docs)
- `firebase.json`, `.firebaserc`, `firestore.rules`, `.gitignore` (Firebase config + ignore rules)
- `README.md` (the new project README written 2026-05-01)

### Files that will NOT be pushed (gitignored)

- `assets/pizza-song.mp3` (copyright — see assets/README.md for BYO)
- `.firebase/` (hosting cache)
- `firebase-debug*.log`
- `.DS_Store`
5. Create GitHub repo (`gh repo create` or web UI)
6. `git push` + verify files visible on GitHub

Firebase web config in `index.html` is **safe to push** — it's public client-side config, protected by deployed `firestore.rules`.

---

### Optional but worth nudging the user about

- **Firebase Hosting free tier:** 10 GB storage, 360 MB/day bandwidth. Very generous for a meme game. Won't hit limits with <500 players.
- **Custom domain:** open question in `leaderboard-design.md`. Not required for Phase 6, but offer to set it up later if user wants `pizzapanic.fi` or similar.
- **Rules Playground full verification:** still skipped from Phase 5. Worth 5 min before/after Phase 6 to validate the anti-cheat rules. Steps in `leaderboard-design.md` "Anti-Cheat" section.
- **GitHub push:** rules are deployed → DB is now safe. Pushing to a public GitHub repo is fine if user wants to. Not required.

**Do NOT touch:** game scoring math, audio, Phase 1–5 logic. Don't introduce a build step or bundler — the project is intentionally one HTML file.

---

## Tunable Knobs (current v7 values, unchanged in v8)

```
TOPPING_MS           = 6000
BAKE_BASE_MS         = 4000
BAKE_DECAY           = 0.85
BAKE_MIN_MS          = 300
PERFECT_MIN          = 62
PERFECT_MAX          = 85
MUSIC_BASE_RATE      = 1.0
MUSIC_MAX_RATE       = 2.0
MUSIC_START_S        = 14
MUSIC_RAMP_ROUNDS    = 12
```

Music rate formula: `1.0 + 1.0 × t²`, where `t = min(1, (round − 1) / 12)`.

Anti-cheat (firestore.rules):
- Score cap: 1000 (realistic max ~55 in 120 s)
- Rate-limit: 5 s between writes per user
- Monotonic bestScore: cannot decrease

---

## Audio Implementation Notes (do not break in v6+)

- AudioContext is created at module load via `preloadAudio()`. iOS allows creation outside a user gesture; the context just stays `suspended` until the first ALOITA tap calls `audioCtx.resume()`.
- `startMusic()` is **synchronous from the user gesture's perspective** — no `await` before `src.start()`. If the buffer is not yet ready, the source is started asynchronously via the readiness promise.
- Each new game creates a fresh `AudioBufferSourceNode` (sources are one-shot in Web Audio).
- `playbackRate.setTargetAtTime(target, ctx.currentTime, 0.05)` gives an exponential 50 ms ramp — smooth.
- If editing audio code: do **not** introduce `await` in `startMusic` before `src.start()`. iOS Safari will silently refuse to play.

Adding Firebase imports/initialization is fine — does not interact with the audio path. Imports stay at module level so they don't block the start tap.

---

## Local Dev Server

⚠️ **Port 8080**, not 8000. Tähtipolku (user's other project) occupies port 8000.

```python
python3 -c "
import http.server, socketserver, os
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()
os.chdir('/Users/macesko/Desktop/Claude general/Projects/Pizza heist')
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(('', 8080), H) as httpd:
    httpd.serve_forever()
"
```

URLs:
- Mac browser: `http://localhost:8080/index.html`
- Mobile: `http://<mac-lan-ip>:8080/index.html` (get IP with `ipconfig getifaddr en0`)

⚠️ **Authorized domains** in Firebase Console: `localhost`, `pizza-paniikki.firebaseapp.com`, `pizza-paniikki.web.app` (added Phase 6). LAN-IP testing would require adding the IP — but with hosting live this is rarely needed.

---

## Sprint Sequence

- ✅ Sprint 1 — Playable Base (v5)
- ✅ Sprint 2 — Meme Audio Core
- ✅ Sprint 3 — Visual Fun (mockup approved 2026-04-27)
- ✅ Phase 4 — Implementation (v6)
- ✅ Sprint 4 — Final Polish (v7, 2026-04-28)
- 🟡 v8 — Leaderboard + Auth (Phase 1–6 done 2026-04-28..2026-05-01; Phase 6.5 GitHub push remaining)

---

## Suggested first message in the new session

After reading this handoff, greet briefly in Finnish, summarize where we are, and ask whether to start Phase 6.5 now. Example:

> "Luin handoffin. v8 Phase 1–6 valmiit — peli on livenä osoitteessa https://pizza-paniikki.web.app, vaikeustaso viritetty (floor R17 = mahdoton), README kirjoitettu. Jäljellä Phase 6.5: pushataan public-repona GitHubiin (`pizza-panic`), `pizza-song.mp3` jää ulos `.gitignore`:n takia. Aloitanko: 1) `gh repo create`, 2) `git init` + commit (varmistus että mp3 ei livahda), 3) push, 4) varmistus GitHub-sivulla?"

**Wait for user response before any git operations.**

### Heads-up: gotchas the next session may hit

1. **DeepGuard popups** — `git`/`gh` may trigger F-Secure DeepGuard prompts on first use. User clicks "Salli".
2. **`gh repo create` is interactive on first auth** — `gh auth login` requires browser flow; user runs in Terminal, agent guides.
3. **mp3 leak risk** — before `git commit`, run `git status` and confirm `assets/pizza-song.mp3` is NOT staged. If it appears, the `.gitignore` line is wrong (currently: `assets/pizza-song.mp3` — case-sensitive, exact path).
4. **Repo name vs project ID** — game/repo name = `pizza-panic` (English), Firebase project ID = `pizza-paniikki` (Finnish, immutable). README and live URL use the Finnish form. Don't try to rename the Firebase project — only the GitHub repo can carry the English name.
