# LibItemBonusLib-1.0

Ace3v port of the Ace2 library **ItemBonusLib-1.0** (r17465), API-compatible.

ItemBonusLib answers "how much *total* Stamina / Healing / Crit is my gear giving me right now?".
Vanilla's API cannot tell you: the numbers only exist as tooltip text. The library scans every
equipped item's tooltip, parses the stat lines against localized patterns, adds up **set bonuses**
for the pieces you actually have on, and keeps a running total that it refreshes whenever your
equipment changes.

```lua
local itemBonus = LibStub("LibItemBonusLib-1.0")

local healing = itemBonus:GetBonus("HEAL")     --> e.g. 186
local sta     = itemBonus:GetBonus("STA")      --> e.g. 620
```

It also offers the **BonusScanner-compatible** subset of that API, so code written against
BonusScanner mostly works unchanged.

## Dependencies

All hard. Locale files must load **before** the main file — the library calls
`AceLocale-3.0:GetLocale()` at load time, which errors if nothing is registered.

```
LibStub\LibStub.lua
CallbackHandler-1.0\CallbackHandler-1.0.xml
AceCore-3.0\AceCore-3.0.xml
AceEvent-3.0\AceEvent-3.0.xml
AceTimer-3.0\AceTimer-3.0.xml
AceBucket-3.0\AceBucket-3.0.xml
AceConsole-3.0\AceConsole-3.0.xml
AceLocale-3.0\AceLocale-3.0.xml
LibDeformat-2.0\LibDeformat-2.0.xml
LibGratuity-2.0\LibGratuity-2.0.xml
LibItemBonusLib-1.0\LibItemBonusLib-1.0.xml
```

`LibItemBonusLib-1.0.xml` already loads the six locale files in the right order (enUS first, as
the default), so including it is enough.

| Dependency | Used for |
|---|---|
| LibStub | registration |
| CallbackHandler-1.0 | the `ItemBonusLib_Update` callback |
| AceCore-3.0 | pulled in by AceEvent/AceTimer/AceBucket |
| AceEvent-3.0 | `PLAYER_ENTERING_WORLD`, `PLAYER_LEAVING_WORLD` |
| AceTimer-3.0 | the delayed first scan after entering the world |
| AceBucket-3.0 | throttling `UNIT_INVENTORY_CHANGED` to 0.5 s |
| AceConsole-3.0 | the `/abonus` chat command |
| AceLocale-3.0 | localized stat patterns and bonus names (enUS, deDE, esES, frFR, ruRU, zhCN) |
| LibGratuity-2.0 | reading item tooltips |
| LibDeformat-2.0 | pulling values out of `ITEM_SET_NAME` and friends |

## Usage

```lua
local itemBonus = LibStub("LibItemBonusLib-1.0")
```

Not embeddable — there is no `:Embed()`, matching the Ace2 original.

The library starts itself: it registers its events at load, and scans your equipment one second
after `PLAYER_ENTERING_WORLD`, then again (throttled to 0.5 s) whenever your inventory changes. Just
read the getters, or subscribe to `ItemBonusLib_Update`.

## Bonus keys

Bonuses are identified by uppercase string keys. The common ones:

```
STR AGI STA INT SPI            ARMOR BLOCK BLOCKVALUE DODGE PARRY
HEAL DMG SPELLCRIT CRIT        ATTACKPOWER RANGEDATTACKPOWER RANGEDCRIT
HOLYCRIT ARCANEDMG FIREDMG     FROSTDMG NATUREDMG SHADOWDMG HOLYDMG
MANAREG HEALTHREG RESILIENCE   FIRERES FROSTRES NATURERES SHADOWRES ARCANERES
```

The authoritative list is the `NAMES` table in `Locales-enUS.lua`. `GetBonusFriendlyName` turns a
key into its localized display name.

Slot names, used by the per-slot getters, are the inventory slot names without the `Slot` suffix:
`Head, Neck, Shoulder, Shirt, Chest, Waist, Legs, Feet, Wrist, Hands, Finger0, Finger1, Trinket0,
Trinket1, Back, MainHand, SecondaryHand, Ranged, Tabard`. Set bonuses are attributed to the
pseudo-slot `Set`.

## API

### `itemBonus:GetBonus(bonus)`

Total value of that bonus across all equipped items **and** active set bonuses. `0` if absent — it
never returns `nil`, so it is safe to use in arithmetic directly.

### `itemBonus:GetSlotBonuses(slotname)`

Table of `bonus -> value` for one slot.

### `itemBonus:GetSlotBonus(bonus, slotname)`

One bonus from one slot, `0` if absent.

### `itemBonus:GetBonusDetails(bonus)`

Table of `slotname -> value` showing where a bonus comes from. Empty table if absent.

```lua
for slot, value in pairs(itemBonus:GetBonusDetails("STA")) do
    print(slot, value)      --> Chest 40 / Back 22 / Set 20
end
```

### `itemBonus:GetBonusFriendlyName(bonus)`

Localized display name (`"STA"` → `"Stamina"` / `"Ausdauer"`). Returns the key unchanged if the
locale has no name for it.

### `itemBonus:ScanItemLink(link)`

Parses one item (by link or `item:` string) and returns its info table:
`{ bonuses = { KEY = value, ... }, set = <set name or nil>, set_line = <tooltip line or nil> }`.
Results are cached per link. This also populates the library's internal set database.

### `itemBonus:ScanEquipment()`

Rescans all equipped items and fires `ItemBonusLib_Update`. Called automatically; you rarely need
it.

### BonusScanner-compatible methods

- `itemBonus:ScanItem(itemlink, excludeSet)` — returns the item's bonus table. `excludeSet` **must**
  be truthy; passing false raises an error, as in the original.
- `itemBonus:IsActive()` — always `true`.
- `itemBonus:ScanTooltipFrame(frame, excludeSet)` — always raises an error; not available.

### Debugging

`itemBonus:SetDebugging(true)` turns on parse diagnostics (unmatched tooltip lines, failed tokens)
printed to chat; `itemBonus:IsDebugging()` reports the state. Off by default.

### `itemBonus:GetLibraryVersion()`

Returns `"LibItemBonusLib-1.0", <minor>`.

### Internal methods, reachable but rarely needed

`OnInitialize()`, `AddValue`, `CheckPassive`, `CheckToken`, `CheckGeneric`, `CheckOther`,
`AddBonusInfo`, `ChatCommand`.

## Callback

```lua
itemBonus.RegisterCallback(MyAddon, "ItemBonusLib_Update", "OnBonusesChanged")
function MyAddon:OnBonusesChanged(event)
    -- no payload; read the getters
end
```

Fired after every `ScanEquipment()`, i.e. on login and whenever equipment changes.

## Chat command

`/abonus` (from `CHAT_COMMANDS` in the locale), with the subcommands:

| Subcommand | Effect |
|---|---|
| *(none)* | prints the available subcommands |
| `show` | all current bonuses |
| `details` | all bonuses with their slot distribution |
| `item <itemlink>` | bonuses of a linked item, including its set bonuses |
| `slot <slotname>` | bonuses contributed by one slot |

## Example

```lua
local itemBonus = LibStub("LibItemBonusLib-1.0")

MyHealAddon = {}
itemBonus.RegisterCallback(MyHealAddon, "ItemBonusLib_Update", "UpdateGear")

function MyHealAddon:UpdateGear(event)
    self.healingPower = itemBonus:GetBonus("HEAL")
    self.spellCrit    = itemBonus:GetBonus("SPELLCRIT")
end

-- or just read it when you need it
local function EstimatedHeal(base)
    return base + itemBonus:GetBonus("HEAL")
end
```

## Differences from the Ace2 version

1. **Lookup name.** `AceLibrary("ItemBonusLib-1.0")` → `LibStub("LibItemBonusLib-1.0")`.
2. **`MINOR` is a plain integer** (starting at 1) instead of an SVN `$Revision:$` string.
3. **It is no longer an AceAddon.** The original was
   `AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceConsole-2.0", "AceDebug-2.0")`, so it had the
   AceAddon lifecycle and its module/enable machinery. This is a plain LibStub library that embeds
   AceEvent-3.0, AceTimer-3.0, AceBucket-3.0 and AceConsole-3.0. Practical effects:
   `OnInitialize()` is called at the end of the file instead of on `ADDON_LOADED` (it is idempotent),
   and there is no `NewModule` / `Enable` / `Disable` / `SetDefaultModuleState`. Nothing in the
   library's own API depended on them.
4. **`ItemBonusLib_Update` is a CallbackHandler callback.** Where you wrote
   `self:RegisterEvent("ItemBonusLib_Update", "Handler")`, now write
   `itemBonus.RegisterCallback(self, "ItemBonusLib_Update", "Handler")`, and the handler gains a
   leading `event` parameter. The event name is unchanged.
5. **AceDebug-2.0 replaced by a local helper.** `SetDebugging`, `IsDebugging` and `Debug` are kept
   with the same names and behaviour; `SetDebugLevel` / `LevelDebug` / `CustomDebug` are gone, as
   nothing used them.
6. **The chat command is hand-dispatched.** AceConsole-2.0 accepted an option table and derived the
   subcommands from its localized `name` fields; AceConsole-3.0 only registers a plain handler.
   The subcommands, their localized words and their output are the same, and `CHAT_COMMANDS` from
   the locale is still what registers the slash command. Building the option table on AceConfig-3.0
   instead would have pulled in AceGUI and the whole dialog stack for a debug command, so it was not
   worth it. Side effect: no GUI options pane — the original did not present one either.
7. **`Print` with a format string became `Printf`.** AceConsole-2.0's `Print` formatted when the
   first argument contained `%`; AceConsole-3.0 splits that into `Print` (concatenate) and `Printf`
   (format). Output is unchanged. One subtlety: the original passed every argument through
   `tostring()` first, so a `nil` printed as `"nil"`; `Printf` will error on a `nil` for `%s`. This
   only affects the diagnostic commands.
8. **An esES locale was added** (not present in the Ace2 original). Its Spanish strings come from
   upstream ItemBonusLib r54839 (WowAce, 2007-11-15, contributed by "bailon"), filtered to vanilla
   1.12.1: the TBC-only `PATTERNS_SKILL_RATING` table is dropped, every kept entry references only
   bonus keys the vanilla enUS locale defines, and patterns left untranslated upstream were removed
   rather than kept as fake coverage. Four patterns (CRIT, TOHIT, DODGE, BLOCK) were derived from
   live Classic Era item tooltips and verified by back-translation.

   Twenty-five further patterns were derived from live Classic Era tooltips — five from item
   tooltips, sixteen from item-**set** tooltips, and four from relic/idol/libram items resolved by
   name. Each was verified by matching the vanilla enUS line first, then translating the result back
   to English.

   **Coverage, stated in the file's own header.** Complete: `NAMES` (44/44) and the stat tokens in
   `PATTERNS_GENERIC_LOOKUP`, so ordinary `"+10 Aguante"` lines parse on every item.
   `PATTERNS_PASSIVE` covers every bonus key that is still reachable. The one without an esES pattern,
   `MANAREGNORMAL`, is deliberately left unset: its enUS pattern expects the old combined wording
   *"Increases your normal health and mana regeneration by N"*, which the 1.12.1 client no longer
   renders — it shows two separate lines instead, and the library already covers those as `MANAREG`
   and `HEALTHREG`. `PATTERNS_OTHER` is 4 of 13.

   Two honest caveats, both in the file header: Classic Era tooltips are not always worded exactly as
   vanilla 1.12 (the `CHEAPERDRUID` sentence gained a comma and a double space), and Blizzard's
   Spanish for the healing relics says *"Aumenta el daño causado por…"* — increases the **damage** —
   although the effect is healing. The pattern has to match what the client renders, so it is kept
   verbatim.

9. **A zhCN locale was added** (absent from the original, and from upstream, which had zhTW only).
   Everything in it is **derived and verified, never translated**: stat tokens by aligning the enUS
   and zhCN tooltips of the same item, passive patterns by locating the vanilla enUS sentence in an
   item or item-set tooltip and reading the same line in Chinese, consumable names by item-name
   lookup, and the enchant-only tokens through Wowhead's `ench` parameter.

   It covers **62 of the 64 effect keys** enUS covers, the two remaining ones being dead on 1.12.1. All six spell schools are covered through the
   `STAGE1`+`STAGE2` composition — the Chinese tokens are `火焰伤害`, `冰霜伤害`, `暗影伤害` and so on,
   verified from enchants 2614-2616. The two it lacks, `ATTACKPOWERFERAL` and `MANAREGNORMAL`, are dead keys on
   1.12.1. The interface strings and `CHAT_COMMANDS` fall back to enUS, as the original deDE
   and frFR locales do. The file header lists all of it.


10. **Bug fix — the `Equip:` prefix is now stripped correctly in every locale.** ItemBonusLib-1.0 did
    `strsub(line, l_equip + 2)`, which assumes exactly one space after the colon. zhCN's prefix is
    `装备：` with no trailing space, so that skipped one byte too many and produced a broken UTF-8
    fragment that no pattern could match — every Chinese passive bonus would have been missed. The
    port skips exactly the prefix and then drops leading whitespace, which is identical for enUS and
    correct for zhCN. This never surfaced in the original because it had no zhCN locale.

11. **AceLocale-2.2 → AceLocale-3.0.** The four original locale files now use
   `NewLocale("ItemBonusLib", <locale>[, true])` instead of `RegisterTranslations`. **All translation
   tables — every pattern, every bonus name — are byte-identical to the originals**; only the
   wrapper changed. The application name `"ItemBonusLib"` is unchanged.
12. **Bug fix — deDE and frFR now actually load.** Both locale files began with a UTF-8 BOM, which
   Lua 5.0 rejects outright (`unexpected symbol near '?'`) — verified with `luac 5.0.3` on the
   originals. The BOM has been stripped, so German and French clients get their translations instead
   of silently falling back to English patterns that cannot match their tooltips.
13. **`self:error` is gone**, since LibStub does not inject it. `ScanItem(link, false)` and
    `ScanTooltipFrame` still raise errors, with slightly different message text.
14. **`UnregisterBucketEvent(event)` became `UnregisterBucket(handle)`**, following AceBucket-3.0.
    The library stores the handle itself; this is only visible if you called the internal method.

## Locale coverage

All six locales were measured against the effect keys enUS covers:

| locale | effects covered | missing |
|---|---|---|
| enUS | 64/64 | — |
| frFR | **64/64** | — |
| ruRU | **64/64** | — |
| deDE | 63/64 | `MANAREGNORMAL` |
| esES | 63/64 | `MANAREGNORMAL` |
| zhCN | 62/64 | `MANAREGNORMAL`, `ATTACKPOWERFERAL` |

Both keys the table names are **dead on 1.12.1**: `MANAREGNORMAL`'s wording no longer exists (the
client splits it into two lines the library already handles as `MANAREG`/`HEALTHREG`), and vanilla has
no separate feral attack power.

One real gap remains and is **zhCN-only**: `DMGUNDEAD` in its sentence form. The other five locales
have the translated "Increases damage done to Undead by magical spells and effects by up to N"; the
Chinese locale does not. The file does carry the Classic-Era token wording (`法术伤害vs亡灵`, from
enchant 2685) but that is Classic's phrasing and will not match a 1.12.1 client — vanilla-era sources
(this library's enUS locale and BonusScanner) show 1.12 uses the sentence, and "when fighting Undead"
in token position. The Chinese 1.12 sentence is not obtainable from Wowhead, so the gap is left open
rather than guessed: on a Chinese client, spell damage against Undead is simply not counted.

The count includes the `STAGE1`+`STAGE2` composition: `CheckToken` concatenates a school effect with
a category effect, so a token like `火焰伤害` (Fire Damage) yields `FIREDMG` with no explicit entry.

`deDE` started at 44/63 — the German original was missing all seventeen healing set/talent bonuses
(`CASTING*`, `CHEAPER*`, `DURATION*`, `IMP*`, `REFUND*`, `JUMPHEALINGWAVE`, `NATURECRIT`) plus
`CASTINGREG`. Those were
filled from live Classic Era tooltips by the same pipeline built for esES. Nothing existing in
deDE/frFR/ruRU was replaced — those files are vanilla-era authentic data and the tooling only adds.

15. **The locale files are plain data, registered by the main file.** Each `Locales-<locale>.lua`
    stores its table in the global `LibItemBonusLib_Locales[<locale>]` and depends on nothing;
    `LibItemBonusLib-1.0.lua` registers all six with AceLocale-3.0 (enUS as the default) and then
    sets the global back to `nil`. They sit next to the library, with no subdirectory. Two client
    behaviours forced this:
    - the WoW 1.12.1 client silently skips a `<Script file="Locales\enUS.lua"/>` whose path has a
      subdirectory (only an `Error loading` line in `Logs\FrameXML.log`);
    - on Unreal Azeroth, with this library included from an addon's `Libraries\Load_Libraries.xml`,
      the six locale files ran **before every other script of that XML** — before AceLocale-3.0,
      AceTimer-3.0, AceBucket-3.0, LibDeformat-2.0 and LibGratuity-2.0, all included earlier —
      while the main file ran in its place. Measured with a trace line in each file; it happened
      with a nested `Locales\Locales.xml`, with flat `Locales-enUS.lua` names, and with names
      containing neither "Locale" nor a locale code, so it is not name-based. A locale file that
      called `LibStub("AceLocale-3.0"):NewLocale` failed with `Cannot find a library instance of
      "AceLocale-3.0"`.

16. **`tostring(ItemBonusLib)` is `"ItemBonusLib"`.** AceConsole-3.0 prefixes every `Print` /
    `Printf` line with `tostring(self)` in green. The Ace2 original was an AceAddon-2.0 object and
    printed its name there; a plain LibStub table printed `table: 0x...`. A `__tostring` metamethod
    restores the name, so `/abonus` output reads `ItemBonusLib: ...` again.

17. **Equipped items are scanned with `SetInventoryItem`, not `SetHyperlink`.** `ScanItemLink`
    takes an optional second argument, the inventory slot id; `ScanEquipment` passes it, and the
    tooltip is then loaded with `Gratuity:SetInventoryItem("player", slot)`. On Unreal Azeroth
    `SetHyperlink("item:6512:0:758:0")` drops the random-property field and shows the base
    *Disciple's Robe* without its "of the Owl" stats, while `SetInventoryItem` on the equipped
    item shows `+3 Intellect` / `+2 Spirit` (measured in game) — so random-suffix items counted
    nothing. Results are still cached by link. A link scanned without a slot (`/abonus item`,
    `ScanItem`) keeps using `SetHyperlink` and has the same limitation on Unreal Azeroth.
    Also, Unreal Azeroth's `GetInventoryItemLink` returns `item:0:0:0:0` (name `[]`) for an empty
    slot instead of `nil`; `ScanEquipment` skips item id 0.

18. **Bug fix — `/abonus details` after a bonus leaves the equipment.** `ScanEquipment` empties
    each `details[bonus]` table but keeps the key, and clears `bonuses[bonus]`; `ShowDetails` then
    formatted a `nil` total with `%d` and raised an error (the Ace2 original does the same). It
    now skips a bonus with no total.
