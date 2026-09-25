# LibBabble-Zone-2.2

Ace3v port of the Ace2 library **Babble-Zone-2.2** (r17779), API-compatible.

A translation table for **zone, instance and battleground names**. WoW's own API gives you the
localized name of the zone you are *standing in* (`GetRealZoneText()`), but nothing that lets an
addon talk about a zone it is not in. Babble-Zone closes that gap: you write English zone names in
your code and the library hands back whatever the player's client calls them, in either direction.

```lua
local Z = LibStub("LibBabble-Zone-2.2")

Z["Un'Goro Crater"]                      --> "Krater von Un'Goro" on a German client
Z:GetReverseTranslation("Kratern von Un'Goro")  --> "Un'Goro Crater"
```

It is the only hard dependency of `LibTourist-2.0`.

## Dependencies

All hard.

```
LibStub\LibStub.lua
AceLocale-3.0\AceLocale-3.0.xml
LibBabble-Zone-2.2\LibBabble-Zone-2.2.xml
```

| Dependency | Used for |
|---|---|
| LibStub | registration |
| AceLocale-3.0 | holds the eight translation tables and picks the client's |

Note that `AceLocale-3.0` itself needs nothing but `LibStub`, so this is the shortest dependency
chain of any library in `target/`.

## Usage

```lua
local Z = LibStub("LibBabble-Zone-2.2")
```

Not embeddable — there is no `:Embed()`, matching the Ace2 original. The library is pure data plus
lookups: nothing to initialize, no events, no frames.

**Index it with the English name.** That is the "base" key in every locale, so English is both the
source language and the fallback.

## Locales

Eight, as in the original: **enUS, deDE, esES, frFR, ruRU, zhCN** (the six this project targets)
plus zhTW and koKR. `AceLocale-3.0:NewLocale` returns `nil` for a locale the client is not running,
so the other blocks' tables are never built.

enUS has 106 keys; every other locale translates 96–100 of them and falls back to English for the
rest — the English-only labels (`Battlegrounds`, the four `Scarlet Monastery (…)` wings,
`The Sunken Temple`, which are addon conventions, not client strings), the continent names
`Eastern Kingdoms` / `Kalimdor` (the client gives those through `GetMapContinents()`), and names
that are the same word in that language.

**The zone names are checked against the 1.12 client.** The VMaNGOS world database carries the
localized `AreaTable.dbc` (`locales_area`, one row per area, joined to the English `area_template`
by id; it has a row for each of the 1081 areas, so it reads as an automated extraction of the
client files rather than hand transcription). Where it has a row for a name:

| locale | agrees with the original | corrected | added |
|---|---|---|---|
| deDE | 83 | **5** | 1 |
| frFR | 88 | 2 | 1 |
| zhCN | 88 | 2 | 2 |
| koKR | 74 | 10 | 2 |
| ruRU | 89 | — (1 differs, kept) | 2 |
| esES, zhTW | the database has no column for them | | |

The corrections: deDE `Grom'gol Basis Lager` → `Das Basislager von Grom'gol`, `Menethil Hafen` →
`Der Hafen von Menethil`, `Insel Theramore` → `Die Insel Theramore`, `Das grosse Meer` →
`Das große Meer`, `Das Scharlachrote Kloster` → `Das scharlachrote Kloster`; frFR `Les mortemines` →
`Les Mortemines`, `Le Temple d'Atal'Hakkar` → `Le temple d'Atal'Hakkar`; zhCN `Hyjal` 海加尔 → 海加尔山,
`The Stockade` 暴风城监狱 → 监狱; koKR ten spacing and wording fixes. The later LibBabble-Zone-3.0 has
the database's string exactly for 13 of those 19. The least certain are the three deDE names with
an article (`Der Hafen von Menethil`, `Das Basislager von Grom'gol`, `Die Insel Theramore`): 3.0 has
them without it, the original had a third form — only a German 1.12 client can settle those. Added: `The Black Morass` and `Dalaran` (both 1.12 areas) where
the original had no entry. ruRU is only filled in, never corrected — vanilla had no Russian client,
both sources are fan translations, and a Russian client presumably matches the original's.

**The frFR names with the English name in brackets are genuine**: `Terres ingrates (Badlands)`,
`Les Carmines (Redridge Mts)`, `Les Tarides (the Barrens)` and 20 more. The 1.12 French client's
AreaTable has them exactly so, abbreviations included, and that is what `GetRealZoneText()` returns
there. (The older Babble-Zone-2.0 and the later LibBabble-Zone-3.0 have them without brackets —
other client versions.)

**Every one of the 84 zone names `LibTourist-2.0` looks up is translated in all six target locales** —
the test suite asserts this per locale, so the English fallback never shows up through Tourist.

## API

Everything below is the AceLocale-2.2 instance API, reproduced.

### `Z[englishName]`

The localized name. Falls back to the English name if this locale does not translate it, and if the
key is unknown entirely, AceLocale-3.0 reports a non-breaking error and returns the key itself.

### `Z:GetTranslation(englishName)`

Same as indexing.

### `Z:GetStrictTranslation(englishName)`

The localized name, or a hard `error()` if this locale has no entry for it. Use this when a missing
translation is a bug you want to hear about.

### `Z:HasTranslation(englishName)`

`true` if the name is known, `nil` otherwise. Never errors, so it is the safe way to validate
user input.

### `Z:GetReverseTranslation(localizedName)` / `Z:HasReverseTranslation(localizedName)`

Localized name → English name. `GetReverseTranslation` errors if there is no such name;
`HasReverseTranslation` returns `true`/`nil`. The reverse map is built on first use, as in the
original.

### `Z:GetIterator()` / `Z:GetReverseIterator()`

`for english, localized in Z:GetIterator() do` and the same the other way round.

### `Z:GetLocale()`

The locale actually in use — the client's, or `"enUS"` if the client's locale is not one of the eight.

### `Z:HasLocale(locale)` / `Z:IterateAvailableLocales()`

Which locales this library carries.

### `Z:GetLibraryVersion()`

Returns `"LibBabble-Zone-2.2", <minor>`.

### `Z:SetStrictness()` / `Z:EnableDebugging()` / `Z:EnableDynamicLocales()` / `Z:Debug()`

No-ops, kept so callers of the Ace2 API do not break. See the differences below for why.

## Example

```lua
local Z = LibStub("LibBabble-Zone-2.2")

-- announce a destination in the player's own language
local function Announce(englishZone)
    if not Z:HasTranslation(englishZone) then return end
    SendChatMessage("Heading to " .. Z[englishZone], "PARTY")
end

-- turn what the client tells us back into a key our code can use
local here = Z:HasReverseTranslation(GetRealZoneText())
        and Z:GetReverseTranslation(GetRealZoneText())
        or GetRealZoneText()
```

## Differences from the Ace2 version

1. **Lookup name.** `AceLibrary("Babble-Zone-2.2")` → `LibStub("LibBabble-Zone-2.2")`.
2. **`MINOR_VERSION` is a plain integer** (starting at 1). The original derived it from an SVN
   `$Revision:$` string *and* multiplied it by AceLocale-2.2's own revision, which LibStub has no
   equivalent for.
3. **`RegisterTranslations` → `NewLocale`.** The eight
   `BabbleZone:RegisterTranslations("deDE", function() return { ... } end)` blocks became
   `L = AceLocale:NewLocale(MAJOR_VERSION, "deDE")` followed by `L["key"] = "value"` assignments. The
   data itself is copied verbatim; `= true` still means "same as the key", which AceLocale-3.0
   handles natively.
4. **Strictness is gone, and unknown keys are softer.** The original called `SetStrictness(true)`,
   which made a missing translation a hard error — including for a key the *current locale* lacked
   even when English had it. AceLocale-3.0 has no strictness setting: a locale gap falls back to the
   English base string, and a completely unknown key produces a non-breaking error (via
   `geterrorhandler()`) and returns the key. `SetStrictness` is kept as a no-op. This is a
   **loosening** — code that worked keeps working, and code that
   would have crashed now degrades to an English name instead. `GetStrictTranslation` is still there
   for callers that want the hard failure.
   Consequence for `HasTranslation`: it now answers `true` for a key only English defines (6 to 10
   keys, depending on locale: the English-only labels, the continents, and names that are the same
   word), where the original answered false. None is used by Tourist.
5. **No cache-clearing frame.** AceLocale-2.2 created a frame and hooked `ADDON_LOADED` /
   `PLAYER_ENTERING_WORLD` to clear a per-instance lookup cache. The port does not cache lookups —
   `__index` points straight at the AceLocale-3.0 table — so there is nothing to invalidate and no
   frame is created.
6. **`EnableDynamicLocales` and `Debug` are no-ops.** The original could switch locale at runtime and
   print a coverage report to the chat frame. AceLocale-3.0 registers only the client's locale and
   the default, so neither is possible; both are kept as no-ops rather than removed, so an Ace2-era
   caller does not blow up.
7. **The duplicate `["Battlegrounds"]` entry is dropped.** The original's enUS table listed it twice
   with the same value — legal in a table constructor, but it reads as a mistake.
8. **14 non-vanilla zones are removed** — TBC and beta names (`Tower of Karazhan`, `Upper Karazhan
   Halls`, `Lower Karazhan Halls`, `Karazhan Crypt`, `Caverns of Time: Black Morass`,
   `Black Morass`, `Moomoo Grove`, `Blood Ring`) and a private server's custom zones
   (`Hateforge Quarry`, `The Crescent Grove`, `Stormwind Vault`, `Gilneas City`, `Gilneas`,
   `Emerald Sanctum`). None is in a 1.12 AreaTable or Map row, none was translated, none is used by
   Tourist. `Dalaran` and `The Black Morass` stay — they are 1.12 areas.
9. **Locales corrected and completed from the 1.12 AreaTable.dbc**, see Locales. These change values
   the original returned; the point is that the originals were not what the 1.12 client prints.
10. **deDE `Ironforge` and `Stormwind City` no longer depend on the Lua version.** The original said
    `expansion and "Eisenschmiede" or "Ironforge"` (and `"Sturmwind"` / `"Stormwind"`), where
    `expansion` meant "running on Lua 5.1", i.e. TBC. Unreal Azeroth is a 1.12.1 client on Lua 5.1,
    so the original would have given it the TBC names. (The first version of this port dropped the
    `local expansion` line and so read a *global* `expansion` — nil in practice, but any addon
    defining one would have flipped it.) Both are now the plain vanilla names.
11. **Looking up an unknown zone no longer makes it known.** The first version of this port indexed
    AceLocale-3.0's table directly, whose miss handler stores the key: after `Z["Typo"]`,
    `HasTranslation("Typo")` said `true` and the reverse map, if built later, contained it. The
    lookup is raw now; an unknown zone still returns its name with one non-breaking error.
12. **`GetLocale` honours `GAME_LOCALE`**, as AceLocale-3.0 does, and a reverse lookup of a name two
    zones share would return the alphabetically first English name (no such name exists today).
