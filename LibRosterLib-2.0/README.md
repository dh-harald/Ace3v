# LibRosterLib-2.0

Ace3v port of the Ace2 library **RosterLib-2.0** (r17213), API-compatible.

RosterLib keeps a **name-keyed model of your party or raid**. Vanilla's API only lets you ask about
units by id (`raid7`, `partypet2`), and those ids shift around as people join, leave and change
groups. RosterLib scans the group, tracks each member by *name*, and tells you when anything about
them changes — so an addon can say "where is Alice right now?" instead of re-deriving it.

```lua
local roster = LibStub("LibRosterLib-2.0")

local unit = roster:GetUnitIDFromName("Alice")   --> "raid7"

roster.RegisterCallback(MyAddon, "RosterLib_UnitChanged", "OnUnitChanged")
function MyAddon:OnUnitChanged(event, unitid, name, class, subgroup, rank)
    -- ...
end
```

It is purely local: **no addon-channel traffic at all**, so there is no interoperability concern
with players running the Ace2 original.

## Dependencies

All hard — the library embeds AceEvent and AceTimer into itself.

```
LibStub\LibStub.lua
CallbackHandler-1.0\CallbackHandler-1.0.xml
AceCore-3.0\AceCore-3.0.xml
AceEvent-3.0\AceEvent-3.0.xml
AceTimer-3.0\AceTimer-3.0.xml
LibRosterLib-2.0\LibRosterLib-2.0.xml
```

| Dependency | Used for |
|---|---|
| LibStub | registration |
| CallbackHandler-1.0 | the callback registry consumers subscribe to |
| AceCore-3.0 | table recycling (`new`/`del`), replacing Compost-2.0 |
| AceEvent-3.0 | `RAID_ROSTER_UPDATE`, `PARTY_MEMBERS_CHANGED`, `UNIT_PET`, `PLAYER_LOGIN` |
| AceTimer-3.0 | retrying units whose name has not arrived yet |

## Usage

```lua
local roster = LibStub("LibRosterLib-2.0")
```

Not embeddable — there is no `:Embed()`, matching the Ace2 original.

The library starts itself on `PLAYER_LOGIN` (or `PLAYER_ENTERING_WORLD`, whichever comes first),
fires `RosterLib_Enabled`, and then keeps the roster current on its own. Register your callbacks at
load time so you do not miss `RosterLib_Enabled`.

## Unit objects

Every roster entry is a table with these fields:

| Field | Type | Meaning |
|---|---|---|
| `name` | string | the unit's name; also the roster key |
| `unitid` | string | current unit id, e.g. `"raid7"`, `"partypet2"`, `"player"` |
| `class` | string | uppercase class token (`"PRIEST"`), or `"PET"` for pets |
| `subgroup` | number | raid subgroup, `1` when not in a raid |
| `rank` | number | raid rank, `0` when not in a raid |
| `online` | **boolean** | `true`/`false` — normalised, see the differences section |

Do not hold onto a unit object across updates: entries are recycled when a member leaves.

## API

### `roster:GetUnitIDFromName(name)`

Current unit id for that player, or `nil` if they are not in the group. The main reason this
library exists.

### `roster:GetUnitIDFromUnit(unit)`

Resolves any unit id to the roster's canonical one — `"party3"` becomes `"raid7"` when you are in a
raid. `nil` if unknown.

### `roster:GetUnitObjectFromName(name)` / `roster:GetUnitObjectFromUnit(unit)`

The whole unit object, or `nil`.

### `roster:IterateRoster([pets])`

Iterator over unit objects. Pets are **excluded** unless `pets` is truthy.

```lua
for u in roster:IterateRoster() do
    print(u.name, u.class, u.subgroup)
end
```

### `roster:GetPetFromOwner(unit)`

The pet unit id belonging to an owner — `"party1"` → `"partypet1"`, `"raid7"` → `"raidpet7"`,
`"player"` → `"pet"`. `nil` if the owner is not in the roster.

Note it returns `string.gsub`'s results, so a **second** value (the substitution count) follows the
id. Wrap the call in parentheses if that matters: `local pet = (roster:GetPetFromOwner("party1"))`.
The Ace2 original behaves the same way.

### `roster:Enable()` / `roster:Disable()`

No-ops, kept because addons may still call them.

### Internal methods, reachable but rarely needed

`ScanFullRoster()`, `ScanPet(owner)`, `ScanUnknownUnits()`, `ProcessRoster()`,
`CreateOrUpdateUnit(unitid)`, `RemoveUnit(name)`, `AceEvent_FullyInitialized()`.

### `roster:GetLibraryVersion()`

Returns `"LibRosterLib-2.0", <minor>`. Compatibility shim for code written against AceLibrary.

## Callbacks

Subscribe with a **dot call**, passing your own object first. The handler receives the **event name**
as its first argument.

```lua
roster.RegisterCallback(MyAddon, "RosterLib_UnitChanged", "OnUnitChanged")
roster.UnregisterCallback(MyAddon, "RosterLib_UnitChanged")
roster.UnregisterAllCallbacks(MyAddon)
```

### `RosterLib_Enabled`

Fired once when the library starts. No payload.

### `RosterLib_RosterChanged(event, updatedUnits)`

Fired once per update batch, before the per-unit events. `updatedUnits` maps name → a change record
with `name, unitid, class, subgroup, rank, online` and the previous `oldname, oldunitid, oldclass,
oldsubgroup, oldrank, oldonline`.

**The table is recycled immediately after the per-unit events fire — copy anything you need.**

### `RosterLib_UnitChanged(event, unitid, name, class, subgroup, rank, oldname, oldunitid, oldclass, oldsubgroup)`

Fired once per changed unit. The `old*` values are `nil` for a member who just joined; for a member
who left, the new values are `nil` and the `old*` values describe them.

`oldrank` is **not** among the arguments — see the differences section. Read it from
`RosterLib_RosterChanged`'s table if you need it.

## Example

```lua
local roster = LibStub("LibRosterLib-2.0")

MyAddon = {}
roster.RegisterCallback(MyAddon, "RosterLib_UnitChanged", "OnUnitChanged")

function MyAddon:OnUnitChanged(event, unitid, name, class, subgroup, rank, oldname)
    if not name then
        print(oldname .. " left the group")
    elseif not oldname then
        print(name .. " joined as " .. class .. " in group " .. subgroup)
    else
        print(name .. " is now " .. unitid .. " in group " .. subgroup)
    end
end

-- pull style: no callback needed
local function IsInMyGroup(playerName)
    return roster:GetUnitIDFromName(playerName) ~= nil
end
```

## Differences from the Ace2 version

1. **Lookup name.** `AceLibrary("RosterLib-2.0")` → `LibStub("LibRosterLib-2.0")`.
2. **`MINOR` is a plain integer** (starting at 1) instead of an SVN `$Revision:$` string.
3. **Callbacks instead of AceEvent-2.0.** Where you wrote
   `self:RegisterEvent("RosterLib_UnitChanged", "Handler")`, now write
   `roster.RegisterCallback(self, "RosterLib_UnitChanged", "Handler")`, and the handler gains a
   leading `event` parameter. The event names themselves are unchanged.
4. **`RosterLib_UnitChanged` carries 9 arguments, not 10 — `oldrank` is dropped.** This is a limit
   of the vanilla CallbackHandler: its dispatcher is generated with ten value slots, and the event
   name occupies one, so the tenth payload argument cannot be delivered. Upstream Ace3 has no such
   limit because it uses real varargs, which Lua 5.0 lacks. The port passes `argc = 9` explicitly
   rather than letting the argument be truncated silently. **`oldrank` is still available** from the
   `updatedUnits` table that `RosterLib_RosterChanged` fires immediately beforehand.
5. **`online` is a real boolean.** RosterLib-2.0 stored the raw `UnitIsConnected` return, which is
   `1`/`nil` on one 1.12.1 client and `true`/`false` on another. The port normalises it, so an
   offline member now reads `online == false` rather than `nil`. Truthiness tests are unaffected.
6. **Bug fix — pets are refreshed again.** RosterLib-2.0 guarded pet updates with
   `roster[name].class ~= "pet"` while setting the class to `"PET"`, so the comparison was always
   true and the function bailed out for *every* already-known pet. A pet's `unitid`, `subgroup` and
   `online` therefore went stale after it was first seen. Now compared against `"PET"`, matching the
   stated intent ("return if a pet attempts to replace a player name"). Pets can now generate
   `RosterLib_UnitChanged` events, which they previously could not.
7. **Bug fix — `UNKNOWNBEING`.** RosterLib-2.0 tested the misspelled global `UKNOWNBEING`, which is
   `nil`, so the guard reduced to `name ~= nil` and a unit literally named "Unknown Being" was added
   to the roster under that name. Now spelled correctly, so such units are treated as unknown and
   retried, as intended. (The same typo appears in Ace2 HealComm, where it is harmless for an
   unrelated reason — it compares a *unit id* against a *name* constant, so the guard is inert
   either way.)
8. **Compost-2.0 replaced by AceCore-3.0's `new`/`del`.** Same recycling behaviour, one less
   optional dependency. Recycled tables are still handed to callbacks, so the "copy what you need"
   rule from the original still applies.
9. **`AceEvent_FullyInitialized` is gone as an event.** AceEvent-2.0's synthetic
   "everything is loaded" event has no Ace3 equivalent. The library now starts on `PLAYER_LOGIN` /
   `PLAYER_ENTERING_WORLD`, with a 10-second fallback timer for the case where the library is loaded
   after login — the same fallback AceEvent-2.0 used internally. The method
   `roster:AceEvent_FullyInitialized()` is retained and simply triggers startup.
10. **`AceOO-2.0` dropped.** RosterLib-2.0 required it but never used it.
11. **A dead debug helper was removed** — an unused `local function print(text)` writing to
    `ChatFrame3`.
12. **`self:argCheck` / `:error` / `:assert` are gone**, since LibStub does not inject them. This
    library barely used them; error message wording may differ.
13. **Bug fix — a pet renamed on the same unit id is a rename, not a second member.** On Unreal
    Azeroth a freshly summoned pet appeared in the roster twice, both entries on `"pet"`: under its
    creature type and under its own name (`Voidwalker` and `Zag'nuz`; `Dire Mottled Boar` and
    `Bendo`; measured in game). The roster is keyed by name, so a pet whose name changed left its
    old entry behind. When a pet unit shows up under a name that is not in the roster yet, the entry
    already on that unit id is now moved to the new name, and one `RosterLib_UnitChanged` fires
    with `oldname` set. Two pets that trade unit ids are unaffected (both names already exist).
    Measured after the fix: a resummoned hunter pet joins as `Dire Mottled Boar`, then one
    `RosterLib_UnitChanged` renames it to `Bendo`.
