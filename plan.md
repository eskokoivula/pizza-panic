# Pizza Panic — Pelimekaniikka v2

## Konteksti

Sprint 1:n nykyinen toteutus toimii teknisesti, mutta pelissä ei ole haastetta — mikään ei voi mennä pieleen, taito ei ratkaise. Lisätään pelimekaniikka spec.md:n pohjalle.

Brainstorming-päätökset:
- Haaste tulee **tilauksista + paistoajasta**
- **Yksi tilaus kerrallaan** näkyvissä
- **Karva-ansa**: kuudes nappi joka päättää pelin heti
- Uunissa **tähtäysvyöhyke-palkki**
- Pisteet: **+3 / +1 / −1** (rangaistus virheistä) → *muutettu v5:ssä*

## Pelimekaniikka

### 1. Tilausjärjestelmä
- Yläosassa näkyy aktiivinen tilaus: *"Asiakas haluaa: Juusto + Pepperoni"*
- Tilaus = satunnainen 1–3 toppingin setti viidestä normaalista (Juusto, Pepperoni, Oliivi, Herkkusieni, Ananas)
- Uusi tilaus joka tarjoilun jälkeen
- Karvaa ei koskaan tilauksissa

### 2. Paisto-vaihe (MÄTÄISE TAIKINA)
- Topping-ruudukossa **6 nappia**: 5 normaalia + **KARVA**
- Karvan sijainti **satunnainen joka kierroksella** (Fisher–Yates) — pelaaja ei voi opetella välttelemään
- Karva-napissa selvä visuaalinen erottuvuus (musta tausta + 🦱 + teksti "KARVA")
- Normaalia toppingia klikataan päälle/pois

### 3. KARVA-ansa (instant game over)
- KARVA-napin klikkaus → kierros päättyy välittömästi
- Erillinen game over -ruutu: "Hyi helvetti, KARVA!!" + pisteet + PELAA UUDESTAAN

### 4. Uuni-vaihe
- Edistymispalkki täyttyy vasemmalta oikealle (n. 5 s)
- Vihreä vyöhyke (65–85%) = täydellinen, ennen vihreää = alikypsä, jälkeen = palanut
- PYSÄYTÄ tallentaa palkin asennon → tarjoiluun
- Jos palkki täyttyy 100%:iin → palanut

### 5. Tarjoilu + pisteytys (alkuperäinen v2-malli)
- Vertaa tarjoiltua pizzaa tilaukseen exact match (joukko sama, järjestys ei väliä)
- Oikea pizza + täydellinen → **+3**
- Oikea pizza + ok → **+1**
- Väärä pizza tai palanut → **−1** (*muutettu v5:ssä: nämä päättävät pelin*)

### 6. Kierroksen kulku
- Kokonaiskesto **120 s** (*poistettu v5:ssä*)
- Aikalaskuri näkyvissä koko ajan (*poistettu v5:ssä*)
- Aika loppuu → "Aika loppui!" -ruutu (*poistettu v5:ssä*)

---

# v3 — Speed ramp + audio sync

## Konteksti

Käyttäjän testissä paistoaika oli liian hidas — ei reaktio-haastetta. Halutaan että peli nopeutuu kierros kierrokselta niin että kierros 12 on jo tuuria, ja meemimusiikki synkronoituu (chipmunk-efekti). Audio nostettiin Sprint 2:sta tähän vaiheeseen koska se on pelin keskiössä.

Päätökset:
- Paistoaika: eksponentiaalinen lasku, lattia 800 ms (~kierros 14)
- Musiikki: aggressiivinen ramppi (+0.10 / kierros), katto 2.5×
- Chipmunk: `preservesPitch=false`, sävel nousee kun nopeutuu

## Kaavat

```
bakeMs(round)    = max(800, 5000 × 0.86^(round−1))
musicRate(round) = min(2.5, 1.0 + (round−1) × 0.10)
```

## Ulkoiset riippuvuudet

- `assets/pizza-song.mp3` — käyttäjän pudotettava itse, peli toimii ilmankin (vain konsolivaroitus)

---

# v4 — Topping timer (peli loppuu jos aika loppuu)

## Konteksti

Bake-vaiheessa ei ollut paineolla mitään: pelaaja saattoi pohtia toppingeja loputtomiin. Lisätään vakiolaskuri ja aika loppumalla peli päättyy (ei automaattista uuniin siirtymistä). Tämä tekee toppingien valinnasta rytmiriskin — hidastelu = häviö.

Päätökset:
- Kiinteä **3,5 s** budjetti per pizza (*nostettu 5,0 s:iin v5:ssä*)
- Aika loppuu → uusi "Liian hidas!" -loppuruutu
- UUNIIN ennen aikaloppua siirtyy uuniin normaalisti ja sammuttaa laskurin
- Laskuri näkyy bake-näytöllä: "Aikaa: 5,0s" → "0,0s"

---

# v5 — Endurance-malli: 4 loppumistapaa, ei negatiivisia pisteitä

✅ **Toteutettu** — `index.html` ja `spec.md` heijastavat v5-tilaa.

## Konteksti

Käyttäjän testissä 120 s kokonaisaikalaskuri tuntui turhalta nyt kun topping-laskuri ja paistopalkki tuottavat painetta itsessään. Pisteytyksen rangaistus (−1) tuntui väärältä — yksinkertaisempi malli: pisteet kasvavat kun teet oikein, ja ensimmäinen virhe lopettaa pelin. Topping-aika nostetaan 5 sekuntiin koska sen loppuminen on nyt suora game over.

## Päätökset

- **Poista 120 s kokonaisaikalaskuri** kokonaan
- **Topping-aika 3,5 s → 5,0 s**
- **Pisteet eivät voi mennä negatiivisiksi** — vain +3 ja +1 (ja "ei pisteitä, peli loppuu")
- **4 loppumistapaa**, jokaisella oma loppuruutunsa:
  1. KARVA-klikkaus → "Hyi helvetti, KARVA!!" (säilyy v2:sta)
  2. Topping-aika loppuu → "Liian hidas!" (säilyy v4:stä)
  3. Paistoaika ylittyy / palanut → **"Pizza paloi!"** (uusi)
  4. TARJOILE väärällä toppingsetillä → **"Väärä tilaus!"** (uusi)
- Palanut-tila ei enää mene serve-näytölle — se päättää pelin heti uunissa
- Mismatch ei enää anna −1 pistettä — se päättää pelin heti

## Verifiointi

Testilista löytyy handoff.md:n "Walk-through testing" -osiosta.

---

# v6 — Sprint 3 visuaalinen ilme + Phase 4 implementaatio

✅ **Toteutettu 2026-04-27** — `index.html`, `spec.md`, `visual-spec.md` heijastavat v6-tilaa.

## Konteksti

Sprint 3:ssa tehtiin täysi visuaalinen suunnittelu mockup-tasolla (8 näkymää, hyväksytty). Phase 4 nosti mockupin tuotantoon: kirjoitti `index.html`:n UI-kerroksen uudelleen mockupin pohjalta, säilytti pelilogiikan, korjasi audio-bugin ja teki spec-muutoksia jotka olivat kertyneet Sprint 3 -keskusteluissa.

## Päätökset

- **Sticker-pack -tyyli**: paksut mustat outlinet, drop shadow, tilttejä, Lilita One + Plus Jakarta Sans -fontit
- **Bake-vyöhykkeet 65/20/15 → 62/23/15**: 3 %-yksikköä siirretty ALIKYPSÄ:stä PERFECTO:lle
- **PERFECTO korvaa TÄYDELLINEN** UI-tekstinä (sisäiset state-nimet pysyvät)
- **Topping-aika 5,0 s → 6,0 s** käyttäjän pyynnöstä
- **ALIKYPSÄ päättää pelin** — ei enää +1-pistettä-jatka. Uusi 5. game over -näkymä "Alikypsä!" (kalpea taikinapizza, keltainen text-shadow)
- **Audio-fix**: `canplay`-event odotetaan ennen `currentTime = 14` (vanha bugi: setting before metadata silently failed mobile)
- **Asiakaskasvot vaihtuvat kierroksen mukaan**: rento (1–3) → hermostunut (4–7) → raivokas (8+)
- **Täytteet 5 kiinteässä slotissa pizzalla** + jitter — ei overlapia
- **KARVA-napin teksti "Karva"** (aiemmin "🦱 KARVA")

## Lopputulokset

- 9 näkymää: start, bake, oven, serve, karva, hidas, **alikypsa (uusi)**, palanut, vaara
- Vain 4 → **5 game over -polkua**
- `mockup.html` säilyy itsenäisenä review-tiedostona, ei viedä tuotantoon
- `visual-spec.md` kirjoitettu uudelleen synkkaan mockupin kanssa

## Vaikeustason huomio

ALIKYPSÄ-game-over poisti "turvaverkon" jossa pelaaja sai +1 pisteen suboptimaalisella paistolla. Nyt vain PERFECTO antaa pisteitä → pelistä tuli huomattavasti vaikeampi. `BAKE_DECAY = 0.86` saattaa olla liian aggressiivinen; Sprint 4:n testissä voi olla syytä nostaa esim. 0.90:een.

---

# v7 — Sprint 4 vaikeustasaus + Web Audio API

✅ **Toteutettu 2026-04-28** — `index.html` ja `spec.md` heijastavat v7-tilaa.

## Konteksti

Sprint 4:n alkutestissä peli tuntui aluksi liian helpolta (round 1–5 eivät vaikeutuneet riittävästi) ja iOS-mobiilissa musiikki katkesi kierrosten välillä. Kahdessa iteraatiossa säädettiin vaikeuskäyrää, ja kolmannessa korvattiin koko audio-systeemi Web Audio API:lla iOS-stutterin poistamiseksi. Lopuksi musiikkikaava sidottiin baken kanssa synkkaan ja maltillisemmaksi.

## Päätökset

**Vaikeustaso:**
- `BAKE_BASE_MS` 5000 → **4000** (round 1 alkaa nopeammin)
- `BAKE_DECAY` 0.86 → **0.80** (kierrokset vaikeutuvat jyrkemmin)
- Bake-lattia 800 ms osuu round 8:lla (oli round 14)

**Audio:**
- Korvattiin `<audio>`-elementti **Web Audio API:lla** — `AudioContext` + `AudioBufferSourceNode`, natiivit `setTargetAtTime`-rampit
- Mp3 esiladataan ja dekoodataan sivun avautuessa → ALOITA-kosketuksessa source luodaan ja `start()`atan synkronisesti samassa gestureissä (iOS-vaatimus)
- Loop seamless: `loopStart = 14 s`, `loopEnd = buffer.duration`
- Pitch nousee luonnollisesti `playbackRate`:n mukana (Web Audio default) → chipmunk-efekti ilman erillistä `preservesPitch`-flagia

**Musiikkikaava:**
- Vanha lineaarinen `1.0 + (r-1) × 0.10` → uusi kvadraattinen `1.0 + 1.0 × t²` missä `t = min(1, (r-1)/12)`
- `MUSIC_MAX_RATE` 2.5 → **2.0** (chipmunk-katto matalampi)
- `MUSIC_RAMP_ROUNDS` = **12** (rampi venytetty)
- Hidas alku (round 1–5: 1.00 → 1.11×), maltillinen huippu (round 13+: 2.0×)

**Devauspuoli:**
- Paikallinen serveri ajetaan no-cache headereilla testin aikana — mobiili-Safarin aggressiivinen cache hämärsi aikaisempia tuloksia

## Kaavat

```
bakeMs(round)    = max(800, 4000 × 0.80^(round−1))
musicRate(round) = 1.0 + 1.0 × min(1, (round−1)/12)²
```

## Lopputulokset

- iOS-mobiilissa musiikki soi koko pelin ajan ilman katkoja
- Vaikeuskäyrä tuntuu kireämmältä alusta lähtien
- Musiikki ja bake liikkuvat saman muotoisella käyrällä mutta musa hitaammin → toistensa pari, ei kilpaile
- Esiladattu puskuri vaatii ~1 s lataus-ikkunan ennen ALOITAa (puhelimella nopealla yhteydellä huomaamaton)

---

# v8 — Leaderboard + Google-kirjautuminen + Firebase

🟡 **Suunniteltu 2026-04-28** — design-dokumentti `leaderboard-design.md`, ei vielä toteutettu.

## Konteksti

Pelistä halutaan jaettava puoli-julkinen versio: pelaaja voi kirjautua, paras tulos säilyy laitteiden välillä, ja kaikki näkevät globaalin leaderboardin. Skaala kymmeniä–satoja pelaajia, ei tarvetta raskaalle anti-cheatille. Käyttäjä on ei-tekninen — backend pitää olla minimaalisen ylläpidon palvelu.

Brainstorming-päätökset (1-on-1 dialogi):
- Yleisö: **puoli-julkinen** (B-vaihtoehto)
- Auth: **Google-kirjautuminen + nimimerkki** (ei salasanaa, ei magic linkkiä)
- Leaderboard: **top 10 + oma sija** (B-taso)
- Backend: **Firebase** (Auth + Firestore + Hosting samasta paikasta, Google-login natiivi)

## Päätökset

**Arkkitehtuuri:**
- Ei omaa palvelinta. Selain puhuu Firebaseen suoraan ES-moduuli-SDK:n kautta CDN:ltä.
- Yksi `users`-kokoelma Firestoressa, dokumentin id = Firebase Auth UID
- Hosting Firebasella (`https://pizza-panic.web.app`)

**Tietomalli:**
```
users/{uid}
  ├── nickname:     string  (max 20 merkkiä)
  ├── bestScore:    number
  ├── createdAt:    timestamp
  └── lastPlayedAt: timestamp
```
Ei score historya — vain paras tulos. Voidaan lisätä myöhemmin alikokoelmana ilman rikkovaa muutosta.

**Pelin kulku:**
- Ilman kirjautumista: peli toimii kuten ennen, pisteet eivät tallennu
- Kirjautuneena: pelin lopussa jos `finalScore > bestScore` → kirjoitetaan Firestoreen + näytetään "Uusi ennätys!" -banneri
- Pelilogiikkaan v7-tilaan **ei muutoksia**

**UI-lisäykset:**
- Aloitusnäkymään: "Paras: N", `LEADERBOARD`-nappi, `KIRJAUDU`/nimimerkki-rivi
- Uusi login-näkymä (Google-nappi + nimimerkin kysely ekan kerran)
- Uusi leaderboard-näkymä (top 10 + oma sija jos ei top 10:ssä)
- Game over -näkymiin: ehdollinen "Uusi ennätys!" -banneri, "Kirjaudu sisään tallentaaksesi pisteet" -teksti jos ei loginia
- Visuaalinen tyyli noudattaa `visual-spec.md`:ta

**Anti-cheat (kevyt):**
- Firestore-säännöt: vain käyttäjä saa kirjoittaa omaan dokkariinsa, `bestScore` ≤ 1000 ja monotoninen, 30 s rate-limit, immutable `createdAt`
- Estää satunnaisen DevTools-huijauksen, ei päättäväistä Firestore-API-spoofiaa
- Hyväksytty trade-off memepelissä

**Toteutusvaiheet (6 kpl):**
1. Firebase-projektin setup (käyttäjä klikkaa konsolissa)
2. Login + user document
3. Pisteen tallennus + "Uusi ennätys!" -banneri
4. Leaderboard-näkymä
5. `firestore.rules` + deploy
6. Hosting + deploy + README

## Open Questions

- Custom-domain vs default `*.web.app` — päätetään Phase 6:ssa
- Nimimerkkien kirosanasuodatin — ei nyt, vain jos siitä tulee ongelma
- Leaderboard-pagination — top 10 nyt riittää; jos populaatio kasvaa yli sadan, harkitaan
