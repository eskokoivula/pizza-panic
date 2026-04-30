# Pizza Panic — Leaderboard & Auth Design

## Overview

Add user identity and a global leaderboard so players can save their best score and see how they rank against others. Backend: **Firebase** (Auth + Firestore + Hosting). No own server, all client-side calls.

Target audience: semi-public (~10–500 players). Anti-cheat is light by design — this is a meme game, not a competition.

## Goals

- A logged-in player's **best score persists across devices**
- A **global leaderboard** visible to anyone (logged in or not)
- Playing **anonymously still works** — login is optional, only required to save scores
- Total surface area: one new file (`firestore.rules`) plus additions to `index.html`. No build step.

## Non-Goals

- Score history per user (only best score is stored)
- Friends list / following / social features
- Time-windowed leaderboards (daily / weekly)
- Server-authoritative game logic
- Email/password or magic-link login

## Architecture

```
┌─────────────────────────────────────┐
│  index.html (browser, mobile)       │
│  ┌─────────────────────────────┐    │
│  │  Game logic (v7, unchanged) │    │
│  │  + Firebase JS SDK (CDN)    │    │
│  └─────────────────────────────┘    │
└──────────────┬──────────────────────┘
               │ HTTPS
               ▼
┌─────────────────────────────────────┐
│  Firebase                           │
│  • Auth      (Google provider)      │
│  • Firestore (users collection)     │
│  • Hosting   (https://*.web.app)    │
└─────────────────────────────────────┘
```

The game runs entirely in the browser. The Firebase SDK is loaded from Google's CDN as ES modules. No bundler, no build step.

## Authentication

- **Provider: Google only.** One tap if the browser is already signed in to a Google account.
- **Playing without login is allowed.** The login button is optional — an unauthenticated player sees the leaderboard and plays normally; their score is not persisted. (Note: this is not Firebase Anonymous Auth; the user is simply unauthenticated.)
- **First-time login flow:**
  1. Player taps "Kirjaudu Googlella"
  2. Google consent popup → returns Auth user
  3. App checks if `users/{uid}` exists in Firestore
  4. If no: prompt for nickname (default = Google `displayName`)
  5. Write `users/{uid}` with nickname + initial fields
  6. Return to start screen, now showing best score and nickname
- **Subsequent logins:** auto-redirect through, no nickname prompt.
- **Sign-out:** available from start screen (small "vaihda" link next to nickname).

## Data Model

Single Firestore collection: `users`.

```
users/{uid}
  ├── nickname:     string   // shown on leaderboard, max 20 chars
  ├── bestScore:    number   // highest end-of-game score
  ├── createdAt:    timestamp
  └── lastPlayedAt: timestamp
```

- Document ID is the Firebase Auth UID. There is no separate `userId` field.
- `bestScore` is denormalized so the leaderboard query is one read.
- A user document is created on first login. It is updated when:
  - The user submits a new personal best (writes `bestScore`, `lastPlayedAt`)
  - The user changes their nickname (writes `nickname`)

No score history collection. If wanted later, add `users/{uid}/games/{gameId}` as a subcollection — non-breaking.

## Game Flow Changes

The existing v7 game loop is unchanged. The additions are at the boundaries:

**On page load:**
- Initialize Firebase
- Check auth state — if signed in, fetch own `users/{uid}` document
- Render start screen with appropriate state (best score, login/nickname)

**On game over (any of the 5 endings):**
- If not signed in: show standard game over + small text *"Kirjaudu sisään tallentaaksesi pisteet"*
- If signed in **and** `finalScore > bestScore`:
  1. Write `users/{uid}` with new `bestScore` and `lastPlayedAt`
  2. Show "**Uusi ennätys!**" banner above the existing game over title
- If signed in but score ≤ bestScore: just update `lastPlayedAt`

**On leaderboard tap:**
- Fetch top 10 from `users` ordered by `bestScore desc`
- If signed in and not in top 10: fetch top 100 to find own rank
  - If own row is in top 100: show actual rank (e.g. `#47 Esko (sinä) 89`)
  - If not in top 100: show `#100+ Esko (sinä) 89`
- Render leaderboard view, back button returns to start

## UI / Screens

Three changes to the existing 9 screens, plus 2 new screens.

**Start screen (modified):**
```
┌──────────────────────┐
│   PIZZA PANIC 🍕     │
│                      │
│   Paras: 234         │  ← if signed in
│                      │
│   [ ALOITA PAISTO ]  │
│   [ LEADERBOARD ]    │  ← new
│                      │
│   Esko (vaihda)      │  ← if signed in
│   [ KIRJAUDU ]       │  ← if not signed in
└──────────────────────┘
```

**Game-over screens (modified):**
- Add optional "**Uusi ennätys!**" banner above title when applicable
- Add "Kirjaudu sisään tallentaaksesi pisteet" text when not signed in
- All other content unchanged

**Login screen (new):**
- Single button: "Kirjaudu Googlella"
- Triggers Google popup
- On first login: nickname input + "Tallenna" button

**Leaderboard screen (new):**
```
┌──────────────────────┐
│   🏆 LEADERBOARD     │
│                      │
│   1. Matti      512  │
│   2. Liisa      430  │
│   3. Pekka      388  │
│   …                  │
│   10. Anna      201  │
│   ─────────────      │
│   #47 Esko (sinä) 89 │  ← own rank if > 10
│                      │
│   [ TAKAISIN ]       │
└──────────────────────┘
```

Visual style follows `visual-spec.md` (sticker-pack: thick black outlines, drop shadow, Lilita One headings).

## Anti-Cheat (Firestore Security Rules)

Stored in `firestore.rules` and deployed via `firebase deploy --only firestore:rules`.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /users/{uid} {
      // Anyone can read the leaderboard
      allow read: if true;

      // Only the user can write their own document
      allow create: if request.auth != null
                    && request.auth.uid == uid
                    && validNewUser(request.resource.data);

      allow update: if request.auth != null
                    && request.auth.uid == uid
                    && validUpdate(request.resource.data, resource.data);
    }
  }
}

function validNewUser(d) {
  return d.nickname is string
      && d.nickname.size() > 0
      && d.nickname.size() <= 20
      && d.bestScore == 0
      && d.createdAt == request.time;
}

function validUpdate(new, old) {
  return new.nickname.size() <= 20
      && new.bestScore is int
      && new.bestScore >= old.bestScore       // monotonic
      && new.bestScore <= 1000                 // realistic cap
      && new.createdAt == old.createdAt        // immutable
      && request.time > old.lastPlayedAt + duration.value(30, 's');  // 30 s rate-limit
}
```

**What this prevents:**
- Casual DevTools score editing (rules reject scores > 1000 or non-monotonic updates)
- Spamming submissions (30 s rate-limit per user)
- Tampering with someone else's document
- Creating a doc with a non-zero starting score

**What this does not prevent:**
- A determined attacker who learns the Firestore SDK and submits 999 to their own document via direct API calls

For a meme game, this is an accepted trade-off.

## Build Phases

Six phases. Each ends with a verification step before continuing.

**Phase 1 — Firebase project setup** *(user clicks in console, ~10 min)*
- Create Firebase project "pizza-panic"
- Enable Authentication → add Google provider
- Create Firestore database in production mode (any region)
- Enable Hosting
- Copy 6 config values to share with Claude
- → verify: console shows all three services as enabled

**Phase 2 — Login & user document**
- Add Firebase SDK imports to `index.html`
- Implement `signInWithGoogle()`, `signOut()`, `ensureUserDoc()`
- Add login button + nickname prompt UI
- Update start screen to show signed-in state
- → verify: sign in, check Firestore console for new `users/{uid}` doc with nickname

**Phase 3 — Score submission**
- On game over, if signed in and `finalScore > bestScore`, write update
- Show "Uusi ennätys!" banner when applicable
- → verify: play, beat your own score, see banner, see new value in Firestore

**Phase 4 — Leaderboard view**
- Add "LEADERBOARD" button on start screen
- Implement `fetchLeaderboard()` (top 10 + own rank from top 100)
- New leaderboard screen matching `visual-spec.md` style
- → verify: with 2+ test accounts, see ordering and own rank correctly

**Phase 5 — Firestore rules**
- Write `firestore.rules` per spec above
- Deploy: `firebase deploy --only firestore:rules`
- → verify: in browser console, attempt forbidden writes (other user's doc, score > 1000, non-monotonic) → all rejected

**Phase 6 — Hosting & deploy**
- `firebase init hosting` → public dir = project root
- Run `firebase deploy`
- Test on mobile via the `*.web.app` URL
- Update `README.md` with deploy/local-dev instructions
- → verify: friends can sign in and play from the public URL

Estimated total: ~2 sessions.

## Open Questions

- **Domain name** — keep default `pizza-panic.web.app`, or buy a custom domain? (Decide before Phase 6.)
- **Profanity filter on nicknames** — none planned. Add only if it becomes a problem.
- **Leaderboard pagination** — top 10 only. If population grows past a few hundred, revisit (still cheap to fetch top 100).
