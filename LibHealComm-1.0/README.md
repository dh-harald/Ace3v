# LibHealComm-1.0

Ace3v port of the Ace2 library **HealComm-1.0** (r11732), API-compatible.

Source provenance: HealComm-1.0 is **no longer available from WowAce**, so the port was made from a
preserved copy — the [aviana](https://github.com/Aviana) mirror at r11732, which is one of only two
known surviving sources (the other is roughly 200 revisions older). Community mirrors are the only
remaining source for this library, which is worth remembering if the port ever needs to be checked
against the original again: `source/Addons-for-Vanilla-1.12.1/!Libs/HealComm-1.0/` in this repository
is that copy.

HealComm answers **"is someone already healing this player, and for how much?"** — the question
every healing addon needs so two healers do not both dump a Greater Heal into the same target.
Vanilla's API tells you nothing about other players' casts, so HealComm broadcasts your own heals
over the addon channel and listens for everyone else's, keeping a live picture of incoming heals,
heal-over-time effects and pending resurrections.

```lua
local HealComm = LibStub("LibHealComm-1.0")

local incoming = HealComm:getHeal("Bob")     --> total heal landing on Bob
local count    = HealComm:getNumHeals("Bob") --> how many healers are on him
```

**It interoperates with the Ace2 original.** The addon-channel protocol is byte-identical, so a raid
can mix players running Ace2 HealComm-1.0 and players running this port — they see each other's
heals. That constraint drove the whole port and is verified by the test suite.

## Dependencies

All hard.

```
LibStub\LibStub.lua
CallbackHandler-1.0\CallbackHandler-1.0.xml
AceCore-3.0\AceCore-3.0.xml
AceEvent-3.0\AceEvent-3.0.xml
AceTimer-3.0\AceTimer-3.0.xml
AceLocale-3.0\AceLocale-3.0.xml
LibDeformat-2.0\LibDeformat-2.0.xml
LibGratuity-2.0\LibGratuity-2.0.xml
LibItemBonusLib-1.0\LibItemBonusLib-1.0.xml
LibRosterLib-2.0\LibRosterLib-2.0.xml
LibHealComm-1.0\LibHealComm-1.0.xml
```

| Dependency | Used for |
|---|---|
| LibStub | registration |
| CallbackHandler-1.0 | the three callbacks |
| AceCore-3.0 | `_G` access |
| AceEvent-3.0 | the nine game events it listens to |
| AceTimer-3.0 | cast-completion and resurrection-expiry timers |
| AceLocale-3.0 | spell, item and zone names in 7 locales |
| LibRosterLib-2.0 | one call: `GetUnitIDFromName` |
| LibItemBonusLib-1.0 | one call: `GetBonus("HEAL")` — pulls in LibGratuity and LibDeformat |
| LibDeformat-2.0 | reading HoT ticks from the combat log with the client's format strings |

## Usage

```lua
local HealComm = LibStub("LibHealComm-1.0")
```

Not embeddable — there is no `:Embed()`, matching the Ace2 original.

The library starts itself: it registers its events at load and installs its hooks on
`PLAYER_LOGIN`. Just read the getters, or subscribe to the callbacks.

## A trap worth knowing: name vs unit

The getters are **not consistent** about what they take, and this is inherited from the original:

| Getter | Argument |
|---|---|
| `getHeal`, `getNumHeals` | a **player name** (`"Bob"`) — `Heals` is keyed by name |
| `getRegrTime`, `getRejuTime`, `getRenewTime` | a **unit id** (`"raid7"`) — they call `UnitName` on it |
| `UnitisResurrecting` | a **player name** |

Use `LibRosterLib-2.0`'s `GetUnitIDFromName` / `UnitName()` to convert as needed.

## API

### `HealComm:getHeal(name)`

Total incoming direct heal on that player, `0` if none. Includes group heals (Prayer of Healing)
that list the player as a target.

### `HealComm:getNumHeals(name)`

How many separate heals are landing on that player, `0` if none.

### `HealComm:getRenewTime(unit)` / `getRejuTime(unit)` / `getRegrTime(unit)`

`start, duration` of the HoT on that unit, or nothing if it is not active. `getRegrTime` covers
Regrowth, `getRejuTime` Rejuvenation, `getRenewTime` Renew.

```lua
local start, dur = HealComm:getRenewTime("raid7")
if start then
    local remaining = start + dur - GetTime()
end
```

### `HealComm:UnitisResurrecting(name)`

The earliest expiry time of a pending resurrection on that player, or `nil`. Expired entries are
pruned as a side effect of the call.

### `HealComm:GetBuffSpellPower()`

`spellPower, healModifier` from the player's own buffs (Power Infusion, Divine Favor, healing
trinkets…).

### `HealComm:GetUnitSpellPower(unit, spellName)`

`targetPower, targetModifier` contributed by buffs and debuffs **on the target** — Blessing of
Light, Healing Way, Mortal Strike, Wound Poison and the rest of the healing-reduction debuffs.

### `HealComm:SendAddonMessage(msg)`

Broadcasts on the `"HealComm"` prefix, to `"BATTLEGROUND"` in the three battlegrounds and `"RAID"`
elsewhere. You should not need to call it.

### `HealComm:Enable()` / `HealComm:Disable()`

No-ops, kept because addons may still call them.

### `HealComm:GetLibraryVersion()`

Returns `"LibHealComm-1.0", <minor>`.

### Data tables

`HealComm.Spells` (heal amount functions per spell and rank), `HealComm.Buffs`,
`HealComm.Debuffs`, `HealComm.Heals`, `HealComm.GrpHeals`, `HealComm.Hots`,
`HealComm.pendingResurrections`. Read-only as far as consumers are concerned.

### Internal methods, reachable but rarely needed

`startHeal`, `stopHeal`, `delayHeal`, `startGrpHeal`, `stopGrpHeal`, `delayGrpHeal`,
`startResurrection`, `cancelResurrection`, `RessExpire`, `ProcessSpellCast`, and the seven hook
handlers `CastSpell`, `CastSpellByName`, `UseAction`, `SpellTargetUnit`, `SpellStopTargeting`,
`TargetUnit`, `CameraOrSelectOrMoveStart`, plus `OnMouseDown` (the world-click logic, called by
`CameraOrSelectOrMoveStart`). The original globals are in `HealComm.hooks[name]`.

## Callbacks

```lua
HealComm.RegisterCallback(MyAddon, "HealComm_Healupdate", "OnHealUpdate")
HealComm.UnregisterCallback(MyAddon, "HealComm_Healupdate")
```

| Callback | Payload |
|---|---|
| `HealComm_Enabled` | none — fired once at load |
| `HealComm_Healupdate` | `unit` — the affected target changed |
| `HealComm_Ressupdate` | `name` — a pending resurrection changed |
| `HealComm_Hotupdate` | `unit, hotName` — `"Renew"`, `"Rejuvenation"` or `"Regrowth"` |

The handler receives the event name first: `function MyAddon:OnHealUpdate(event, unit)`.

## Example

```lua
local HealComm = LibStub("LibHealComm-1.0")
local roster   = LibStub("LibRosterLib-2.0")

MyHealAddon = {}
HealComm.RegisterCallback(MyHealAddon, "HealComm_Healupdate", "OnHealUpdate")

function MyHealAddon:OnHealUpdate(event, unit)
    local name = UnitName(unit) or unit
    local incoming = HealComm:getHeal(name)
    if incoming > 0 then
        -- someone is already healing them for `incoming`
    end
end

-- is this target overhealed already?
local function IsCovered(unit)
    local name = UnitName(unit)
    local missing = UnitHealthMax(unit) - UnitHealth(unit)
    return HealComm:getHeal(name) >= missing
end
```

## The wire protocol — do not change it

Prefix `"HealComm"`, plain text, slash-delimited. Every message except the two bare stop commands
ends with a trailing slash.

```
Heal/<targetName>/<amount>/<castTimeMs>/    GrpHeal/<amount>/<castTimeMs>/<name>/<name>/...
Healstop                                    GrpHealstop
Healdelay/<delayMs>/                        GrpHealdelay/<delayMs>/
Resurrection/<targetName>/start/            Resurrection/stop/
Regr/<targetName>/<seconds>/                Renew/<targetName>/<seconds>/
Reju/<targetName>/<seconds>/
```

The trailing slashes are **load-bearing**: the library's private `strsplit` has a broken last-field
branch, and a trailing delimiter keeps it from ever running. The two bare commands contain no
delimiter at all, which is why the receiver compares the raw message for those and the split fields
for everything else. This port keeps `strsplit` and the format exactly as they are.

## Differences from the Ace2 version

1. **Lookup name.** `AceLibrary("HealComm-1.0")` → `LibStub("LibHealComm-1.0")`.
2. **`MINOR` is a plain integer** (starting at 1) instead of an SVN `$Revision:$` string.
3. **Callbacks instead of AceEvent-2.0.** `self:RegisterEvent("HealComm_Healupdate", "Handler")`
   becomes `HealComm.RegisterCallback(self, "HealComm_Healupdate", "Handler")`, and the handler gains
   a leading `event` parameter. The event names are unchanged.
4. **Named scheduled events are emulated.** AceEvent-2.0 let you schedule under a name
   (`"Healcomm_"..caster`) and cancel or query by that name; AceTimer-3.0 hands out ids instead. The
   port keeps a name → id map and reproduces `ScheduleEvent` / `CancelScheduledEvent` /
   `IsEventScheduled` behaviour. Timer granularity is now ~0.1 s, which is well below the cast times
   involved.
5. **Hooks are plain global replacements, not AceHook.** Ace2's `:Hook` replaced the original and
   expected the handler to call it back through `self.hooks[name]`. The port does exactly that
   itself: `PLAYER_LOGIN` replaces each global with a pass-through wrapper and keeps the original in
   `HealComm.hooks[name]`, so the handlers are unchanged and AceHook-3.0 is no longer a dependency.
   The reason is Unreal Azeroth: `RawHookScript(WorldFrame, "OnMouseDown")` raises an error there
   (`WorldFrame:HasScript("OnMouseDown")` is false; a handler set with `SetScript` is stored but never
   runs), and since it came first in `PLAYER_LOGIN`, none of the other hooks were installed. Replacing
   the `UseAction` and `CastSpellByName` globals is measured to work on Unreal Azeroth, in combat too.
   **World clicks go through `CameraOrSelectOrMoveStart`** — the left-button binding's function — in
   place of `WorldFrame`'s `OnMouseDown`: a pass-through replacement of it fires on clicks on the
   ground and on NPCs and not on unit-frame clicks, and camera and selection keep working (measured
   on Unreal Azeroth). The handler runs `OnMouseDown`'s logic (a pending spell's target is the
   `mouseover` unit) before calling the original. **That finds nothing on Unreal Azeroth**: under a
   spell cursor it reports no `mouseover` for any unit and shows no tooltip (measured on a friendly
   NPC and on the own character). So the click is remembered (`HealComm.worldClickSpell`) and
   resolved at `SPELLCAST_START` (`HealComm:ResolveWorldClick`): by then the spell cursor is gone and
   `UPDATE_MOUSEOVER_UNIT` has already restored the unit under the cursor (measured order), so
   `mouseover` is the target. The own character never gives a `mouseover` on Unreal Azeroth (no
   tooltip either), and a click on empty ground starts no cast, so a cast that follows a world click
   with no `mouseover` is recorded on the player. A world click only records a **player** (both
   here and in `OnMouseDown`), like every other cast path; HealComm-1.0 recorded any unit on a world
   click, so a heal on an NPC was predicted and broadcast under the NPC's name. A new cast, `SpellStopTargeting`, `SPELLCAST_FAILED`
   or a cast of another spell drops the remembered click; a target already recorded another way is
   kept. The one case this gets wrong: the mouse leaves the unit between the click and the cast
   start. **On the 1.12.1 client world clicks go through
   `WorldFrame`'s `OnMouseDown` instead**, as in the Ace2 original: 1.12.1 protects
   `CameraOrSelectOrMoveStart` (like every movement and camera function), and once an addon has
   replaced it every left click in the world is blocked ("blocked from an action only available to
   the Blizzard UI", measured). The choice is made at `PLAYER_LOGIN` from Unreal Azeroth's own markers (`GetUECvar`
   exists, or interface number 5875), not from `WorldFrame:HasScript("OnMouseDown")`: a choice made
   on that at login lost Unreal Azeroth's world clicks (measured), although it reads `false` there
   later; the previous script is kept in
   `HealComm.hooks.WorldFrameOnMouseDown` and called after the handler.
6. **`activate`/`external` replaced by a startup block.** State that Ace2 copied out of `oldLib`
   (`Heals`, `GrpHeals`, `Lookup`, `pendingResurrections`, `Hots`, `SpellCastInfo`) now uses the
   LibStub `or`-idiom, and the events are registered unconditionally at the bottom of the file.
   `PLAYER_LOGIN` is guarded so the hooks are installed once, and a mid-session library upgrade
   re-installs them itself since `PLAYER_LOGIN` will not fire again.
7. **Bug fix — ruRU `Flash of Light`.** The Russian locale held `"Улучшенная вспышка света"`, which
   is *Improved* Flash of Light — a **talent** name. This key is used as a cast spell name
   (`HealComm.Spells` is indexed with the name from `SPELLCAST_START`), so it could never match, and
   Russian players got no heal prediction for the Paladin's main fast heal. Corrected to
   `"Вспышка Света"`, which both the community `Babble-Spell-2.2` ruRU data and Blizzard's own
   Russian give for the spell. The rest of the Russian locale is the community translation and is
   left untouched — it agrees with `Babble-Spell-2.2` on 17 of the 18 heal spells.
8. **Bug fix — the `UKNOWNBEING` typo.** Five getters tested a misspelled global, which is `nil`. In
   `getHeal` and `getNumHeals` the argument is a player **name**, so the guard was meant to work and
   the typo defeated it; in the three HoT getters the argument is a unit id, so that guard was dead
   code either way. Spelled `UNKNOWNBEING` in all five.
9. **An esES locale was added** (absent from the original). Spell and item names were resolved from
   Wowhead Classic Era with an id only accepted when its enUS name matches exactly; the three
   battleground names come from this repository's own `Babble-Zone-2.2` esES data. Deliberately
   **not** filled in, falling back to enUS rather than being invented: the two
   `"Set: Increases the duration of …"` strings (item tooltips do not expose set-bonus lines, so the
   Spanish form is unverifiable — consequence: on a Spanish client `getSetBonus()` returns nil and
   Renew/Rejuvenation use 15/12 s instead of 18/15 s), the `"^Corpse of (.+)$"` pattern
   (resurrect-on-corpse targeting stays English-only), and seven trinket buff names.
   The locale block documents each gap.
10. **`getglobal` → `_G[...]`**, `getn` → `table.getn`, and the two Lua-4 style `for k,v in t do`
    loops became `pairs(t)`. Behaviour-neutral.
11. **`strmatch` is still defined as a global**, as in the original, in case another addon picked up
    the accidental export.
12. **The scan tooltip is owned by `UIParent` and re-owned before every scan.** HealComm-1.0 owned
    `healcommTip` by `WorldFrame` once, at load. A tooltip loses its owner when it hides, and an
    unowned tooltip is not filled by its `Set*` methods, so every scan now calls
    `SetOwner(UIParent, "ANCHOR_NONE")` first — unconditionally, since `IsOwned`'s return shape
    differs between clients. `UIParent` is the owner LibGratuity-2.0 uses, measured on both clients.
13. **The base heal grows with the caster's level.** HealComm-1.0 used one fixed base amount per
    rank, but in 1.12 a heal's range grows by `(min(level, MaxLevel) - SpellLevel) *
    EffectRealPointsPerLevel` (Spell.dbc). Healing Wave rank 2 is 64-78 at level 6 and 69-83 from
    level 11; the fixed table said 72, and a level-11+ shaman's cast was predicted at 72 and
    landed for 80 (measured on Unreal Azeroth, tooltip "69 to 83"). `HealComm.SpellLevels` holds,
    per spell and rank, `{ min, max, spellLevel, maxLevel, pointsPerLevel }` from the 1.12.1
    client's Spell.dbc (the 12 heals in `HealComm.Spells`; generator: `tmp/gen-heal-levels.py`,
    not shipped). `HealComm:GetSpellAmount(name, rank, spellPower)` evaluates the rank's formula,
    then replaces its base (the formula with no spell power and every talent at rank 0) with the
    level-scaled DBC average, scaled by the talent multiplier the formula applies. Spell power and
    talents are unchanged. A rank without level data keeps the table amount. The wire protocol is
    unaffected — it only carries the resulting number. Measured after the fix on Unreal Azeroth:
    the same rank-2 cast is predicted at 76.
14. **HoT amounts: `HealComm:getHotHeal(name [, caster])`** — the healing still to come from the HoTs (only `caster`'s, if given)
    (Renew, Rejuvenation, Regrowth) on that player, which HealComm-1.0 only timed. A tick has no
    random range (Spell.dbc die sides 1 for every rank) and does not grow with level;
    `HealComm.HotLevels` holds `{ tick, spellLevel, duration, interval }` per rank from the 1.12.1
    client's Spell.dbc. What the result is built from:
    - **the player's own HoT:** `GetHotTick(hotName, rank, spellPower, mod)` at cast time — the base
      tick times the talent multiplier (Priest Spiritual Healing (2,15) +2% and Improved Renew
      (2,2) +5% per rank; Druid Gift of Nature (3,12) +2% and Improved Rejuvenation (3,10) +5% per
      rank), plus the spell power share (a whole HoT gets duration/15 of it — Renew 1.0,
      Rejuvenation 0.8, Regrowth's HoT 0.7 — with the below-level-20 penalty) split over the ticks,
      times the buff and target-debuff multipliers.
    - **another player's HoT** (addon channel: target and duration only, no amount — the protocol
      is unchanged): estimated as the tick of the highest rank the caster's level allows, without
      spell power or talents.
    - **either, once a tick lands:** the real tick is read from the combat log with the client's own
      format strings (`PERIODICAURAHEAL*`, through LibDeformat, so every locale works) and replaces
      the formula or estimate for the rest of that HoT; its start is re-aligned on the tick, and
      `HealComm_Hotupdate` fires. A tick on a unit at full health sends no message.
    Remaining ticks are counted from the HoT's start and duration. `LibDeformat-2.0` is now a direct
    dependency (it already came in through LibItemBonusLib). The talent indexes (2,2), (2,15) and
    (3,10) are not measured in game; (3,12) is.
    Measured on Unreal Azeroth (druid, level 10, Rejuvenation rank 2 on self): `getHotHeal` 56 at
    the cast (4 x 14), then 42 after the first tick, and the combat log ticked 14 each.

15. **Bug fix — `HealComm_Hotupdate` only for a HoT that was recorded.** HealComm-1.0's
    `UNIT_AURA` fired the callback for every one of Renew, Rejuvenation and Regrowth that was not on
    the unit, on every aura change, even when none had been recorded (seen in game: a Rejuvenation
    cast also fired `Regrowth` and `Renew`). Now only a recorded HoT that is gone fires it.
