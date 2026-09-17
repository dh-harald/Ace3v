# LibHereBeDragons-1.0

A map data API for **World of Warcraft 1.12.1** (stock and Unreal Azeroth). It implements the
`HereBeDragons-1.0` API — zone/world coordinate translation, distances, bearings and the player's
position — on top of a **static, generated zone table**, and it replaces `Astrolabe-0.2`.

The reason it exists is a bug, not tidiness. Astrolabe builds its zone geometry at load by walking
the whole world map: `GetMapZones(C)` once per continent, then `SetMapZoom(C, Z)` once per zone.
On Unreal Azeroth **`GetMapZones` ignores its argument** and answers for the *currently selected*
continent, so the sweep mismatches a whole continent. Depending on which continent the character is
standing on when it runs, Astrolabe either throws `table index is nil` during load, or loads with a
continent's worth of zone dimensions silently replaced by zeros. This library never sweeps the map,
so neither can happen.

Zone geometry is derived from the vanilla `WorldMapArea.dbc` and cross-validated against Astrolabe's
own table: all 46 zones agree on width, height and both offsets to within 0.01 yards. Coverage is
**vanilla only** — 46 zones, 2 continent maps, the cosmic world map, and the 3 battlegrounds (which
Astrolabe had no data for at all).

## Dependencies

Load order, top to bottom:

```
LibStub\LibStub.lua
CallbackHandler-1.0\CallbackHandler-1.0.xml
LibHereBeDragons-1.0\LibHereBeDragons-1.0.xml
```

Both are **hard** dependencies.

`LibBabble-Zone-2.2` is **optional**, and only bridges localized zone names:

```
LibBabble-Zone-2.2\LibBabble-Zone-2.2.xml        (optional, before this library)
```

Without it, coordinates, distances and every `mapFile`-based lookup are unaffected. What degrades is
*name*-based lookup on a non-enUS client: `GetMapIDFromZoneName` and `GetLocalizedMap` then only know
the zones the player has actually visited, because the library learns those from `GetRealZoneText()`
as it goes. That also limits `LearnZoneIndices`, which matches the **localized** names
`GetMapZones()` returns. On an enUS client nothing is lost at all.

The library ships its own zone geometry and needs nothing else.

## Loading and usage

Add the lines above to your `.toc`, then:

```lua
local HBD = LibStub("LibHereBeDragons-1.0")
```

The library also registers itself as **`HereBeDragons-1.0`**, so an addon written against upstream
finds it with `LibStub("HereBeDragons-1.0")` unmodified. It is not embeddable — there is no `:Embed`.

Everywhere a `zone` is taken, you may pass either a numeric **mapID** or a **mapFile** string.
Every `level` / `floor` parameter exists for call compatibility and is meaningful only on the cosmic
map (see below); on any real zone it is always `nil`.

### Identifiers

| Identifier | What it is |
|---|---|
| **mapID** | the vanilla `WorldMapArea.dbc` id — the same numbers every other HereBeDragons-era addon calls a mapID (`Durotar` = 4, `Elwynn` = 30) |
| **mapFile** | what `GetMapInfo()` returns. Vanilla's own spellings, including Blizzard's typos: `Hilsbrad`, `Ogrimmar`, `Darnassis`, `Stormwind`, `Stranglethorn`, `Alterac` |
| **instanceID** | the yard space a coordinate lives in: `0` Eastern Kingdoms, `1` Kalimdor, the battleground's own map id for a battleground, `-1` for the cosmic map. Two positions are comparable only if these match |
| **C, Z** | `GetCurrentMapContinent()` / `GetCurrentMapZone()` indices. `C` is stable; **`Z` is client state**, learned by observation, never stored |

World coordinates are yards. Zone coordinates are `0-1`, with `(0,0)` at the map's top-left,
x growing right and y growing **down**.

## API

### Zone information

| Signature | Returns |
|---|---|
| `HBD:GetLocalizedMap(zone)` | the zone's name — localized when knowable, English otherwise, `nil` if unknown |
| `HBD:GetMapIDFromFile(mapFile)` | mapID, or `nil` |
| `HBD:GetMapFileFromID(mapID)` | mapFile, or `nil` |
| `HBD:GetMapIDFromCZ(C, Z)` | mapID, or `nil` if that index has not been observed yet |
| `HBD:GetCZFromMapID(mapID)` | `C, Z` — `Z` is `nil` until observed |
| `HBD:GetMapIDFromZoneName(name)` | mapID for a zone name — English or localized, exact or normalised (case, spaces and punctuation ignored) |
| `HBD:GetZoneSize(zone [, level])` | `width, height` in yards, or `0, 0` |
| `HBD:GetNumFloors(zone)` | always `0` — vanilla has no multi-level maps |
| `HBD:GetAllMapIDs()` | array of every known mapID |

### Coordinates

| Signature | Returns |
|---|---|
| `HBD:GetWorldCoordinatesFromZone(x, y, zone [, level])` | `x, y, instanceID` in yards, or `nil` |
| `HBD:GetZoneCoordinatesFromWorld(x, y, zone [, level [, allowOutOfBounds]])` | `x, y` in 0-1, or `nil`. Without `allowOutOfBounds`, a result outside 0-1 is returned as `nil` |
| `HBD:TranslateZoneCoordinates(x, y, oZone, oLevel, dZone, dLevel [, allowOutOfBounds])` | `x, y` on the destination map, or `nil` if the two are in different instances |

### Distance and bearing

| Signature | Returns |
|---|---|
| `HBD:GetWorldDistance(instanceID, oX, oY, dX, dY)` | `distance, deltaX, deltaY` in yards |
| `HBD:GetZoneDistance(oZone, oLevel, oX, oY, dZone, dLevel, dX, dY)` | `distance, deltaX, deltaY`, or `nil` across instances |
| `HBD:GetWorldVector(instanceID, oX, oY, dX, dY)` | `angle, distance` |
| `HBD:GetZoneVector(oZone, oLevel, oX, oY, dZone, dLevel, dX, dY)` | `angle, distance`, or `nil` across instances |

**Angles are radians**, normalised to `[0, 2*pi)`, `0` = north, growing clockwise. So east is
`pi/2`, south `pi`, west `3*pi/2`.

### The player

| Signature | Returns |
|---|---|
| `HBD:GetPlayerZone()` | `mapID, level, mapFile` — `level` is always `nil` |
| `HBD:GetPlayerZonePosition()` | `x, y, mapID, level, mapFile` — 0-1 position, or all `nil` |
| `HBD:GetPlayerWorldPosition()` | `x, y, instanceID` in yards, or `nil` |
| `HBD:GetUnitWorldPosition(unitId)` | as above for another unit, when it projects onto the current map |
| `HBD:GetCurrentPlayerPosition()` | `C, Z, x, y` — an Astrolabe-shaped convenience shim |
| `HBD:GetCurrentMapID()` | `mapID, mapFile` of the map currently **displayed**, which is not necessarily the player's zone |
| `HBD:GetPlayerFacing()` | facing in radians, or `nil` if this client cannot report it |
| `HBD:RefreshPlayerPosition()` | force a re-read now |

### Housekeeping

| Signature | Returns |
|---|---|
| `HBD:LearnZoneIndices([C])` | number of `(C, Z)` indices learned for a continent — see *Zone indices* |
| `HBD:GetLibraryVersion()` | `MAJOR, MINOR` |

`GetPlayerZonePosition` returns `nil` inside instances and dungeons: they have no world coordinates
in vanilla and are not in the table.

**While the world map is open the position is not refreshed.** Reading the player's position
requires the map to be showing the player's own zone, and moving a map the user is looking at is
worse than a slightly stale position, so the last known values are served instead.

### Zone indices

`Z` is the client's index into a continent's zone list — locale-dependent, and on Unreal Azeroth not
reliably queryable. It is therefore **learned by observation**: whenever the library reads the map it
records the `(C, Z) -> mapID` pairing it just saw, which cannot be wrong because all three values
describe the same map.

```lua
local learned = HBD:LearnZoneIndices([C])
```

fills in a whole continent at once: one `SetMapZoom(C)`, one `GetMapZones(C)` for the continent that
is now actually selected, then name matching — **never** `SetMapZoom(C, Z)` per zone. It restores the
user's map view afterwards, refuses to run while the world map is open, and returns how many indices
it learned. It is never called automatically; call it from an explicit user action.

### The cosmic (world) map

The cosmic map is mapID `0`. It has **one floor per continent, and the floor index is the
instanceID**, so crossing continents means naming the floor explicitly:

```lua
-- Elwynn Forest (instance 0) onto the cosmic map
local x, y = HBD:TranslateZoneCoordinates(0.5, 0.5, 30, nil, 0, 0, true)
-- Durotar (instance 1)
local x, y = HBD:TranslateZoneCoordinates(0.5, 0.5, 4, nil, 0, 1, true)
```

Without a floor the cosmic map declines, because its own instance is `-1` and matches nothing.
Asking for a floor the map does not have returns `nil` rather than silently using another one.

**Accuracy note:** the cosmic map's size and the two continent offsets onto it are the only five
numbers not derived from the DBC — they come from Astrolabe/Questie, and the Eastern Kingdoms pair is
a guess there. They affect **cross-continent translation only**; everything within a zone or a
continent is exact.

### Events

One callback, through CallbackHandler-1.0:

```lua
HBD.RegisterCallback(self, "PlayerZoneChanged", function(event, mapID, level, mapFile)
    -- level is always nil
end)
HBD.UnregisterCallback(self, "PlayerZoneChanged")
```

Note the `.` on `RegisterCallback`, and that a handler receives the event name first. There is no
`UnregisterAllCallbacks`.

## Example

```lua
local HBD = LibStub("LibHereBeDragons-1.0")

-- Where am I, and how far to the Stormwind gates?
local function report()
    local x, y, mapID = HBD:GetPlayerZonePosition()
    if not x then
        DEFAULT_CHAT_FRAME:AddMessage("No position (in an instance?)")
        return
    end

    local target = HBD:GetMapIDFromZoneName("Elwynn Forest")
    local angle, dist = HBD:GetZoneVector(mapID, nil, x, y, target, nil, 0.335, 0.51)
    if not angle then
        DEFAULT_CHAT_FRAME:AddMessage("Another continent.")
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "%s (%.1f, %.1f) -- %d yards, bearing %.0f degrees",
        HBD:GetLocalizedMap(mapID), x * 100, y * 100, dist, angle * 180 / math.pi))
end

HBD.RegisterCallback("MyAddon", "PlayerZoneChanged", report)
```

## Differences from upstream HereBeDragons-1.0

**Coordinate axes.** Upstream computes `x = left - width * u`, i.e. retail's axes, which run against
increasing map coordinates. This library uses Astrolabe's additive convention instead:
`x = left + width * u`, so `left`/`top` are the zone's **minimum** x/y and both axes run *with* the
0-1 coordinates. Nothing observable changes for code that only converts, measures and places, but
anything reading `HBD.mapData` directly must know it.

**No `UnitPosition`, so world coordinates are derived.** This client cannot report world-space unit
positions at all; the only measurable quantity is `GetPlayerMapPosition`, which is 0-1 on the
currently viewed map. `GetPlayerWorldPosition` and `GetUnitWorldPosition` therefore compute yards
from the 0-1 position and the zone table, and are only as accurate as that table.

**Dropped as meaningless on vanilla:** micro-dungeons (`GetNumFloors` always returns `0`, and
`GetPlayerZone`'s fourth return is always `nil`), map transforms and phasing, instance-ID overrides,
and the entire `C_Map` data-gathering layer — the last replaced by generated data, which is the point
of the library.

**Localized names come from two sources, and the client wins.** The name the client itself reports
for the zone the player is standing in (`GetRealZoneText()`) is recorded as authoritative; every other
zone is translated through `LibBabble-Zone-2.2` when it is present. Upstream gets localized names
straight from the map API, which cannot be queried per-zone here without driving the UI.

**Added:** `GetMapIDFromZoneName`, `GetZoneVector`, `GetCurrentMapID`, `GetPlayerFacing`,
`GetCurrentPlayerPosition` (an Astrolabe-shaped shim), `LearnZoneIndices`, `RefreshPlayerPosition`.

**`GetMapIDFromCZ` / `GetCZFromMapID` can return `nil`** for a zone whose index has not been seen
yet. Upstream always knows every index because it can query the map API directly; here the index is
observed, deliberately.

**One upstream bug fixed.** `GetWorldCoordinatesFromZone` and `GetZoneCoordinatesFromWorld` guard
with `data[0] == 0 or data[1] == 0`; index `0` is always `nil`, so the zero-size check only ever
tested the width. Corrected to `data[1] == 0 or data[2] == 0`, which matters here because rejecting
zero-size zones is how this library avoids ever reproducing Astrolabe's failure mode.

## Differences from Astrolabe-0.2

For addons migrating off Astrolabe:

| Astrolabe | Here |
|---|---|
| `Astrolabe:GetCurrentPlayerPosition()` | `HBD:GetCurrentPlayerPosition()`, or `GetPlayerZonePosition()` |
| `Astrolabe:ComputeDistance(c1,z1,x1,y1,c2,z2,x2,y2)` | `HBD:GetZoneDistance(id1, nil, x1, y1, id2, nil, x2, y2)` on mapIDs |
| `Astrolabe:TranslateWorldMapPosition(...)` | `HBD:TranslateZoneCoordinates(...)` |
| `Astrolabe:GetDirectionToIcon()` — **degrees** | `HBD:GetZoneVector()` / `GetWorldVector()` — **radians** |
| the globals `WorldMapSize`, `MinimapSize` | gone. Use `GetZoneSize` and `GetAllMapIDs` |
| `Astrolabe.ContinentList` | `GetAllMapIDs` plus `GetLocalizedMap` / `GetMapFileFromID` |

**Cross-continent distance now returns `nil`** where Astrolabe returned a number. Astrolabe computes
it through the cosmic map, i.e. from the five numbers that are *not* DBC-derived and two of which are
guesses, so the figure it produced was never trustworthy. Returning `nil` follows the HereBeDragons
contract and lets a caller say "another continent" instead of showing a fabricated distance.

## Licence

BSD 2-Clause -- see `LICENSE`, which also records exactly which parts derive from
Nevcairiel's HereBeDragons and which are this project's own.
