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

Eight, unchanged from the original: **enUS, deDE, esES, frFR, ruRU, zhCN** (the six this project
targets) plus zhTW and koKR, kept because the data was already there and costs nothing — 
`AceLocale-3.0:NewLocale` returns `nil` for a locale the client is not running, so that block's table
is never even built.

enUS defines 120 keys; the other locales define 94–98 and fall back to English for the rest. Those
gaps are **not** vanilla zones — they are TBC and beta names (`Dalaran`, `The Black Morass`, the four
Karazhan variants), private-server custom zones this particular copy was extended with
(`Hateforge Quarry`, `The Crescent Grove`, `Stormwind Vault`, `Emerald Sanctum`, `Gilneas`), the
Scarlet Monastery wing labels, and the `Battlegrounds` category label.

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
   `geterrorhandler()`) and returns the key. `SetStrictness` is kept as a no-op. This is the one
   behavioural difference, and it is a **loosening** — code that worked keeps working, and code that
   would have crashed now degrades to an English name instead. `GetStrictTranslation` is still there
   for callers that want the hard failure.
   Consequence for `HasTranslation`: it now answers `true` for a key only English defines (22 to 26
   keys, depending on locale), where the original answered false. All of them are TBC, beta or
   custom-server names; none is used by Tourist.
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
