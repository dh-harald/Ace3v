# LibBabble-Spell-2.2

Ace3v port of the Ace2 library **Babble-Spell-2.2** (r25190), API-compatible.

A translation table for **spell names** — player spells, talents, professions, and a large set of
NPC and boss abilities — plus an icon for most of them. The client prints spell names in its own
language (buffs, the combat log, cast bars), so an addon that wants to recognise "Polymorph" has to
know what the client calls it. Babble-Spell gives you that in both directions: write English names
in your code, and the library hands back the client's name, or turns the client's name back into
English.

```lua
local BS = LibStub("LibBabble-Spell-2.2")

BS["Frostbolt"]                              --> "Frostblitz" on a German client
BS:GetReverseTranslation("Frostblitz")       --> "Frostbolt"
BS:GetSpellIcon("Frostbolt")                 --> "Interface\\Icons\\Spell_Frost_FrostBolt02"
```

Only vanilla (1.12) names are carried; see difference 5.

## Dependencies

All hard.

```
LibStub\LibStub.lua
AceLocale-3.0\AceLocale-3.0.xml
LibBabble-Spell-2.2\LibBabble-Spell-2.2.xml
```

| Dependency | Used for |
|---|---|
| LibStub | registration |
| AceLocale-3.0 | holds the eight translation tables and picks the client's |

`AceLocale-3.0` itself needs nothing but `LibStub`.

## Usage

```lua
local BS = LibStub("LibBabble-Spell-2.2")
```

Not embeddable — there is no `:Embed()`, matching the Ace2 original. The library is pure data plus
lookups: nothing to initialize, no events, no frames. It is one file of about 13 000 lines; the
tables of the locales the client is not running are parsed but never built.

**Index it with the English name.** That is the "base" key in every locale, so English is both the
source language and the fallback.

## Locales

Eight, as in the original: **enUS, deDE, esES, frFR, ruRU, zhCN** (the six this project targets)
plus zhTW and koKR.

The original's tables were community-maintained, half empty in places, and partly TBC-era. They
are completed and corrected here from the **localized 1.12 `Spell.dbc`** — the client's own spell
names, as carried by the VMaNGOS world database (`locales_spell`; `locales_item` /
`locales_creature` for the five names that are items or NPCs). Out of the 1408 English names:

| locale | own entries | from the original | added | filled in¹ | corrected² | still English |
|---|---|---|---|---|---|---|
| enUS | 1408 | 1408 | — | — | — | — |
| deDE | **1408** | 1201 | 46 | 92 | 69 | 0 |
| zhCN | **1408** | 1006 | 306 | 76 | 20 | 0 |
| zhTW | **1408** | 1025 | 305 | 72 | 6 | 0 |
| koKR | **1408** | 1055 | 304 | 40 | 9 | 0 |
| ruRU | 1406 | 1403 | — | 3 | — | 2 |
| frFR | 1401 | 1032 | 298 | 39 | 32 | 7 |
| esES | 1375 | 13 | **1362** | — | — | 33 |

¹ an empty `''` placeholder, or the English name left in as a placeholder ("Need to translated").
² the original had a different string; see below.

The rules, applied per locale and name:

- **The original's string stays whenever the client uses it** for some spell of that English name,
  and whenever the database has nothing for the name.
- Otherwise **the client's string wins**. If spells sharing one English name have different
  localized names, the one with the lowest spell id is taken — the original spell, usually the
  player's (zhCN `Adrenaline Rush`: the rogue's 冲动, not an NPC version's 激素刺激).
- A database name that is just the English one never replaces a real translation.
- Each spell id's name is taken from its newest 1.12 build — ids were reused across patches
  (22959 was `Curse of Agony` in one early build, `Fire Vulnerability` since).

What the corrections are, by example: typos (deDE `Schaden verstäken` → `Schaden verstärken`),
mojibake (deDE `Eisk?tefalle`, zhTW `Remorseless` = `å†·é…·` → `冷酷`), stray whitespace (zhCN
`" \t骑术：羊"`), copy-paste slips (zhTW `Concussion` held the name of Consecration, zhCN
`Two-Handed Swords` an item name), and **TBC-era renames** — deDE `Herbalism` is `Kräuterkunde` in
1.12, not the later `Kräutersammeln`; `Auto Shot` is `Automatischer Schuss`, not `Autom. Schuss`.
Of the corrections pfUI's vanilla tables (taken from the same localized clients, deDE/frFR/zhCN/koKR)
can judge, they side with the database 54 times against 1 (3 more have both strings); the one
exception is that same `Herbalism`, where pfUI lists the gathering cast `Kräutersammeln`, not the
skill.

**The client's strings are kept even where they look wrong**, because they are what the client
prints: the esES 1.12 client calls Hearthstone `Descorazonado` and Wands `Peste vagante`, and the
zhCN one names the Fire Vulnerability debuff `痛苦诅咒`, the name of Curse of Agony. pfUI's tables
show the same strings.

What is left in English: ruRU `Backhand` and `Unstable Concoction` (vanilla had no Russian client,
so the database has no ruRU spell names; ruRU is the original's community translation, completed
only for three items/NPCs); frFR seven names that are the same word in French (`Dynamite`,
`Guillotine`, `Poison`, …); esES 33, mostly the same in Spanish (`Garrote`, `Furor`, `Vigor`) or
early-patch talents (`Improved Searing Totem`, …) the Spanish client has no row for. No `''` placeholder
is left: all were filled, except frFR `Clone`, which the database knows only in English — that
entry was removed, so it falls back to English instead of returning `""`.

The 51 spell names the consumers in this repository index (LoseControl, FiveSecLib-1.0,
SpellStatus-AimedShot-1.0) are translated in all eight locales.

## API

The AceLocale-2.2 instance API, reproduced, plus the original's two icon functions and two new
icon helpers.

### `BS[englishName]`

The localized name. Falls back to the English name if this locale does not translate it. For a
name the library does not know at all, it reports a **non-breaking** error through
`geterrorhandler()` (once per name) and returns the name itself.

### `BS:GetTranslation(englishName)`

Same as indexing.

### `BS:GetStrictTranslation(englishName)`

The localized name, or a hard `error()` if the library has no entry for it. English-only names count
as present (they come back in English), see difference 4.

### `BS:HasTranslation(englishName)`

`true` if the name is known, `nil` otherwise. Never errors, so it is the safe way to validate
input. Looking up an unknown name with `BS[name]` does not make it known.

### `BS:GetReverseTranslation(localizedName)` / `BS:HasReverseTranslation(localizedName)`

Localized name → English name. `GetReverseTranslation` errors if there is no such name;
`HasReverseTranslation` returns `true`/`nil`. The reverse map is built on first use.

**Several spells can share one localized name** — deDE calls five different fire shields
`Feuerschild`, and `Chain Bolt`, `Chain Lightning` and `Chained Bolt` are all `Kettenblitzschlag`
(10–49 such names per locale, koKR the most). The reverse translation then returns the **alphabetically first**
English name (`Chain Bolt`), on every client. The original returned whichever its hash order put
last, so it was one of the same candidates but not a predictable one.

### `BS:GetIterator()` / `BS:GetReverseIterator()`

`for english, localized in BS:GetIterator() do` and the same the other way round.

### `BS:GetSpellIcon(spell)` → `string` or `nil`

The icon texture path, `"Interface\\Icons\\<name>"`, or `nil` if the library has no icon for it
(1386 of the 1408 names have one). `spell` may be the English name or the client's name; the latter
goes through the reverse translation, so for a shared localized name you get the icon of the
alphabetically first spell. Errors if `spell` is not a string.

### `BS:GetShortSpellIcon(spell)` → `string` or `nil`

Same, without the path: `"Spell_Frost_FrostBolt02"`.

### `BS:GetIconKey(texture)` → `string` or `nil` (new)

Reduces any texture path to a key that compares equal across clients: the last path segment, in
lower case, with any file extension and a trailing `_TEX` removed. `nil` for a non-string. Use it
whenever you compare a texture from the client with one from this library:

| where the path comes from | shape | key |
|---|---|---|
| 1.12.1 client, `GetSpellIcon` | `Interface\Icons\Spell_Nature_Sleep` | `spell_nature_sleep` |
| Unreal Azeroth `UnitBuff` / `UnitDebuff` | `/Game/Interface/Icons/Spell_Nature_Sleep_TEX` | `spell_nature_sleep` |
| Unreal Azeroth `GetActionTexture` | `Interface/Icons/Spell_Nature_Sleep` | `spell_nature_sleep` |

The Unreal Azeroth shapes are the ones measured in game for the ElvUI rewrite (one sample per API).
No icon name in the table ends in `_tex`, and no two different icons collapse into one key.

### `BS:IsSpellIcon(spell, texture)` → `boolean` (new)

`true` if `texture`, in any of the shapes above, is the icon of `spell` (English or localized name).
`false` for an unknown spell, a spell without an icon, or a non-string `texture`.

```lua
-- 1.12 UnitDebuff returns the texture first
if BS:IsSpellIcon("Polymorph", UnitDebuff("target", 1)) then ... end
```

### `BS:GetLocale()`

The locale actually in use — the client's (or `GAME_LOCALE`, which AceLocale-3.0 honours for
testing), or `"enUS"` if that is not one of the eight.

### `BS:HasLocale(locale)` / `BS:IterateAvailableLocales()`

Which locales this library carries.

### `BS:GetLibraryVersion()`

Returns `"LibBabble-Spell-2.2", <minor>`.

### `BS:SetStrictness()` / `BS:EnableDebugging()` / `BS:EnableDynamicLocales()` / `BS:Debug()`

No-ops, kept so callers of the Ace2 API do not break.

## Example

```lua
local BS = LibStub("LibBabble-Spell-2.2")

-- crowd control we want to show, keyed by the client's own spell names
local CC = {}
for _, spell in ipairs({ "Polymorph", "Sap", "Hibernate", "Freezing Trap" }) do
    CC[BS[spell]] = spell
end

-- 1.12 debuffs carry only a texture, so match on the icon, in either client's shape
local function IsCrowdControlled(unit)
    for i = 1, 16 do
        local texture = UnitDebuff(unit, i)
        if not texture then return false end
        for _, spell in pairs(CC) do
            if BS:IsSpellIcon(spell, texture) then return spell end
        end
    end
    return false
end
```

## Differences from the Ace2 version

1. **Lookup name.** `AceLibrary("Babble-Spell-2.2")` → `LibStub("LibBabble-Spell-2.2")`.
2. **`MINOR_VERSION` is a plain integer** (starting at 1). The original derived it from an SVN
   `$Revision:$` string multiplied with AceLocale-2.2's own revision.
3. **`RegisterTranslations` → `NewLocale`.** The eight
   `BabbleSpell:RegisterTranslations("deDE", function() return { ... } end)` blocks became
   `L = AceLocale:NewLocale(MAJOR_VERSION, "deDE", nil, true)` followed by `L["key"] = "value"`
   assignments. The data is copied verbatim, including the translators' trailing comments; `= true`
   still means "same as the key".
4. **Strictness is gone, and unknown keys are softer.** The original called `SetStrictness(true)`:
   a name the *current locale* did not translate was a hard error even when English had it — on an
   esES client that was nearly every spell. Now a locale gap falls back to the English name, and a
   completely unknown name produces one non-breaking error and returns the name. This is a
   **loosening**: code that worked keeps working. Consequence: `HasTranslation` and
   `GetStrictTranslation` now also accept English-only names (where the original said no), and
   `HasReverseTranslation("Frostbolt")` is `true` on a client that does not translate it.
5. **Non-vanilla names are removed.** 72 names of the original are not in the 1.12 client — TBC
   spells, and four private-server professions the copy had been extended with. A name was kept if
   the VMaNGOS 1.12 world database knows it as a spell (its `spell_template` is the client's
   `Spell.dbc`), an item or a creature; everything else was removed from every locale and from the
   icon table. `Arcane Blast`, `Lacerate` and `Force of Nature` stay: the player spells are TBC, but
   1.12 has NPC spells of those names. `Magic Dust`, `Lifegiving Gem`, `Consecrated Sharpening
   Stone`, `Enamored Water Spirit` (items) and `Sheep` (a creature) stay too. Removed:

   > Anesthetic Poison, Anguish, Arcane Surge, Aspect of the Viper, Avenger's Shield, Avenging Wrath,
   > Backlash, Barkskin Effect, Binding Heal, Blazing Speed, Circle of Healing, Cloak of Shadows,
   > Consume Magic, Create Spellstone (Master), Crusader Aura, Deadly Throw, Divine Illumination,
   > Dragon's Breath, Earth Elemental Totem, Earth Shield, Envenom, Erupting Shield, Fel Armor,
   > Fire Elemental Totem, Flight Form, Garderning, Gemology, Goldsmithing, Ice Lance, Intervene,
   > Jewelcrafting, Kill Command, Lifebloom, Maim, Mangle (Bear), Mangle (Cat), Mass Dispel,
   > Misdirection, Molten Armor, Mutilate, Pain Suppression, Prayer of Mending, Righteous Defense,
   > Ritual of Souls, Rogue Passive, Seal of Blood, Seal of Vengeance, Seed of Corruption,
   > Shadow Word: Death, Shadowfiend, Shadowfury, Shadowstep, Shamanistic Rage, Shiv, Snake Trap,
   > Soulshatter, Spellsteal, Spiritual Attunement, Stance Mastery, Steady Shot, Summon Felguard,
   > Survival, Tamed Pet Passive, The Beast Within, Totem of Wrath, Tree of Life,
   > Unstable Affliction, Vampiric Touch, Victory Rush, Water Shield, Waterbolt, Wrath of Air Totem

   Indexing one of them now gives the non-breaking unknown-name error and the English name back.
6. **zhCN loads.** The original's zhCN table had `["Force of Nature"] = true`, and AceLocale-2.2
   accepts `true` only in the base locale — so on a zhCN client the whole library **errored at load
   and did not exist**. The entry now holds the 1.12 client's name, `自然之力` (difference 13).
7. **Duplicate keys.** Several tables listed a key twice (`Lacerate`, `Quick Shots`, `Arcane Blast`,
   `Jewelcrafting`, and `Icicle` in the icon table). The original's table constructor kept the later
   value, and so does the port, which lists each key once. One exception: zhCN `Quick Shots` keeps
   the real translation `快速射击` rather than the later English "Need to translated" placeholder —
   the original never loaded on zhCN (difference 6), so there was no zhCN result to preserve. Where
   the later value was an English placeholder elsewhere (koKR and zhTW `Quick Shots`, `Lacerate`,
   `Arcane Blast`), the 1.12 Spell.dbc has since filled it in (difference 13).
8. **Reverse translation of a shared name is deterministic** — the alphabetically first English
   name, see `GetReverseTranslation`. The original's pick depended on hash order, and the two
   clients (Lua 5.0 and Lua 5.1) do not share one.
9. **`GetIconKey` and `IsSpellIcon` are new**, for comparing textures across the 1.12.1 client and
   Unreal Azeroth, which return icon paths in different shapes.
10. **`GetLocale`, `HasLocale` and `IterateAvailableLocales` work.** In the original they errored
    ("Cannot call ... without first calling `EnableDynamicLocales'"), since the library never
    enabled dynamic locales.
11. **No cache-clearing frame.** AceLocale-2.2 created a frame listening to `ADDON_LOADED` /
    `PLAYER_ENTERING_WORLD` to clear a lookup cache; the port does not cache, so no frame is created.
12. **`EnableDynamicLocales` and `Debug` are no-ops.** AceLocale-3.0 registers only the client's
    locale and the default, so runtime switching and the coverage report are not possible.

13. **The locales are completed and corrected from the localized 1.12 `Spell.dbc`** — see Locales.
    Every one of those changes a value the original returned (an English fallback, `""`, or a
    different string), which is the point: the original's values were not what a 1.12 client
    prints. The consequences for a consumer are all improvements, with one to know about: a few
    more names are now shared by two spells (deDE `Explosive Trap` and `Explosive Trap Effect` are
    both `Sprengfalle`, as in the client), so `GetReverseTranslation` resolves them to the
    alphabetically first English name.

Left as it was, on purpose: the icon `Spell_Fost_Glacier` for `Freeze Solid` — a typo for
`Spell_Frost_Glacier` in the original, so that path names a texture that does not exist.
