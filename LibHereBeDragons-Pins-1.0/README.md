# LibHereBeDragons-Pins-1.0

Shows pins/icons on the **minimap** and the **world map** in World of Warcraft 1.12.1 (stock and
Unreal Azeroth). It implements the `HereBeDragons-Pins-1.0` API on top of
[LibHereBeDragons-1.0](../LibHereBeDragons-1.0/README.md), and replaces Astrolabe's
`PlaceIconOnMinimap` / `PlaceIconOnWorldMap`.

You hand it an icon frame and a position; it decides every frame whether that icon belongs on the
current minimap view, where, and whether it should be clamped to the rim. The pin maths is upstream's,
unchanged. What differs is how the client is asked about itself — see *Indoor/outdoor* below.

## Dependencies

Load order, top to bottom:

```
LibStub\LibStub.lua
CallbackHandler-1.0\CallbackHandler-1.0.xml
LibHereBeDragons-1.0\LibHereBeDragons-1.0.xml
LibHereBeDragons-Pins-1.0\LibHereBeDragons-Pins-1.0.xml
```

`CallbackHandler-1.0` must be **MINOR 7 or later** (the one in this repository), which fires like
upstream Ace3: `Fire(event, ...)`. With the older vanilla backport (MINOR 6, `Fire(event, argc, ...)`)
every callback payload would arrive shifted by one.

All **hard**. `CallbackHandler-1.0` is needed by LibHereBeDragons-1.0 rather than directly.

## Loading and usage

```lua
local pins = LibStub("LibHereBeDragons-Pins-1.0")
```

Also registered as **`HereBeDragons-Pins-1.0`**, so an addon written against upstream finds it
unmodified. Not embeddable.

Every pin is tracked under a `ref` — your addon table, or any string — so you can remove your own
pins without knowing what anyone else registered. The `icon` is a frame you create and own: the
library only parents, positions, shows and hides it. Size, texture and scripts are yours.

Coordinates are either **world yards** (`...World` functions) or **0-1 zone coordinates**
(`...MF` functions). `mapFloor` is always `nil` on vanilla.

## API

### Minimap

| Signature | Returns |
|---|---|
| `pins:AddMinimapIconWorld(ref, icon, instanceID, x, y [, floatOnEdge])` | `true` |
| `pins:AddMinimapIconMF(ref, icon, mapID, mapFloor, x, y [, floatOnEdge])` | `true`, or `false` if the coordinates cannot be converted |
| `pins:IsMinimapIconOnEdge(icon)` | `true` when a floating pin is currently clamped to the rim, `false` when it is inside it, `nil` when the icon is unknown |
| `pins:RemoveMinimapIcon(ref, icon)` | — |
| `pins:RemoveAllMinimapIcons(ref)` | — |
| `pins:SetMinimapObject(minimapObject)` | retarget every pin at another Minimap-like frame; `nil` restores `Minimap` |

`floatOnEdge` decides what happens when a pin is out of range: with it, the pin slides along the
minimap rim so the player can still see the direction; without it, the pin is hidden.

`mapID` accepts a mapFile string too, as in LibHereBeDragons-1.0.

### World map

| Signature | Returns |
|---|---|
| `pins:AddWorldMapIconWorld(ref, icon, instanceID, x, y [, showFlag])` | `true` |
| `pins:AddWorldMapIconMF(ref, icon, mapID, mapFloor, x, y [, showFlag])` | `true`, or `false` if the coordinates cannot be converted |
| `pins:RemoveWorldMapIcon(ref, icon)` | — |
| `pins:RemoveAllWorldMapIcons(ref)` | — |
| `pins:SetWorldMapAnchor(frame)` | position pins against another frame; `nil` restores `WorldMapButton` |

A pin **always** shows on its own zone's map. `showFlag` says how much further it reaches:

| Constant | Value | Also shown on |
|---|---|---|
| *(omitted)* | `nil` | nothing else |
| `HBD_PINS_WORLDMAP_SHOW_PARENT` | 1 | the zone's continent map |
| `HBD_PINS_WORLDMAP_SHOW_CONTINENT` | 2 | the same — on vanilla a zone's parent *is* its continent |
| `HBD_PINS_WORLDMAP_SHOW_WORLD` | 3 | the continent map **and** the cosmic world map |

Battleground pins appear only on their own battleground map: a battleground is its own instance, so
it has no continent to be shown on.

### Both

| Signature | Returns |
|---|---|
| `pins:GetVectorToIcon(icon)` | `angle, distance` from the player to the pin — **radians**, `0` = north, clockwise; yards. `nil` if the pin is in another instance or the player has no position. Works for minimap and world map pins |
| `pins:GetLibraryVersion()` | `MAJOR, MINOR` |

### Indoor/outdoor and rotation

The minimap's radius in yards depends on the zoom level *and* on whether the player is indoors — and
the only way to tell on this client family is to compare the `minimapZoom` and `minimapInsideZoom`
CVars. **Unreal Azeroth registers neither**, and `GetCVar` returns the string `"0"` for an
unregistered name, which is indistinguishable from a genuine zero. So the library probes with
`GetCVarDefault`, which for a name that does not exist returns `nil` on Unreal Azeroth and **raises an
error** on stock 1.12.1 — the probe runs inside a `pcall` and treats both answers as "not registered":

- **CVars available** (stock 1.12.1): upstream's method exactly, including the one-step zoom nudge
  that disambiguates the two environments when both CVars happen to be equal. The zoom is restored
  immediately, and this runs only on events, never per frame.
- **CVars unavailable** (Unreal Azeroth): the **outdoor** radii are used, and `Minimap:SetZoom()` is
  never called, so the user's zoom is left alone.

  Some interiors on that client do rescale the minimap art, and nothing exposes which environment is
  active — but the client does not move addon pins when it rescales, and no addon compensates.
  Astrolabe and pfQuest both also conclude "outdoor" there, for the same reason: their
  `minimapZoom == minimapInsideZoom` test is always true when both read as `"0"`, and the follow-up
  comparison can then never match. So this library gives the same answer they do, and reaches it
  **without** writing to the user's minimap zoom the way both of those do. Use
  `pins:SetMinimapEnvironment("indoor")` if you want to force the other table.

The gate fails **safe**: if `GetCVarDefault` itself were missing, the CVars are assumed to work, so a
client that has them keeps upstream behaviour. An *error* from it is not treated that way — on stock
1.12.1 that is precisely how the client says "no such CVar", and a registered name never throws. If Unreal Azeroth ever implements them, the same code
path activates with no change needed.

| Signature | Returns |
|---|---|
| `pins:SetMinimapEnvironment(mode)` | force `"indoor"` / `"outdoor"`, or `nil` / `"auto"` to follow the client |
| `pins:GetMinimapEnvironment()` | `"indoor"\|"outdoor"`, whether the CVars are usable, whether rotation is on |

Rotating minimaps are supported where the client can report both `rotateMinimap` and the player's
facing. If `rotateMinimap` cannot be read, rotation is treated as **off** rather than hiding every
pin. If rotation is genuinely on but the facing is unavailable, pins are hidden — drawing them at the
wrong bearing is worse than not drawing them.

Square minimaps are honoured through the `GetMinimapShape()` convention, and additionally by
detecting `Squeenix` and `simpleMinimap_Skins` directly, so consumers no longer need their own copy of
that test.

## Example

```lua
local HBD  = LibStub("LibHereBeDragons-1.0")
local pins = LibStub("LibHereBeDragons-Pins-1.0")

-- A waypoint at 42.3, 61.7 in Elwynn Forest, on both maps.
local mapID = HBD:GetMapIDFromZoneName("Elwynn Forest")

local dot = CreateFrame("Frame", nil, Minimap)      -- unnamed: see the note below
dot:SetWidth(12); dot:SetHeight(12)
local tex = dot:CreateTexture(nil, "OVERLAY")
tex:SetAllPoints()
tex:SetTexture("Interface\\Minimap\\ObjectIcons")

pins:AddMinimapIconMF("MyAddon", dot, mapID, nil, 0.423, 0.617, true)

local mapDot = CreateFrame("Frame", nil, WorldMapButton)
mapDot:SetWidth(12); mapDot:SetHeight(12)
local mapTex = mapDot:CreateTexture(nil, "OVERLAY")
mapTex:SetAllPoints()
mapTex:SetTexture("Interface\\Minimap\\ObjectIcons")

pins:AddWorldMapIconMF("MyAddon", mapDot, mapID, nil, 0.423, 0.617,
                       HBD_PINS_WORLDMAP_SHOW_WORLD)

-- Later:
--   local angle, dist = pins:GetVectorToIcon(dot)
--   pins:RemoveAllMinimapIcons("MyAddon")
--   pins:RemoveAllWorldMapIcons("MyAddon")
```

**Do not give a created frame a name containing `-`.** On Unreal Azeroth `CreateFrame` rewrites every
`-` in a frame name, so `"MyAddon-Pin1"` silently becomes something else. Prefer unnamed frames.

## Differences from upstream HereBeDragons-Pins-1.0

**Pin delta direction.** Upstream computes `lastXY - data.x`, which is correct for retail's
coordinate axes. LibHereBeDragons-1.0 uses Astrolabe's additive axes, so the deltas here are
`data.x - lastXY`. Only relevant if you read the internals: getting it wrong mirrors every pin
through the minimap centre.

**Indoor/outdoor and rotation go through a capability gate** rather than reading the CVars directly,
and `Minimap:SetZoom()` is never written on a client that cannot answer. See above.
`SetMinimapEnvironment` / `GetMinimapEnvironment` are additions.

**World map pins are children of `WorldMapButton`** and positioned in its own coordinate space, so
they inherit the map's scale and no scale maths is needed. Upstream's retail versions use the map
canvas provider, which does not exist here. `SetWorldMapAnchor` is an addition for a client where
`WorldMapButton` does not cover the map art; the library warns once if it disagrees with
`WorldMapDetailFrame` in width.

**Show flags are an addition.** Upstream 1.0 has none — a pin shows only on its own map. The
constants and their values match upstream 2.0, so a 2.0-aware consumer's literals mean the right
thing. `HBD_PINS_WORLDMAP_SHOW_PARENT` and `..._SHOW_CONTINENT` behave identically on vanilla.

**The world map is also refreshed on a throttle while it is open**, not only on `WORLD_MAP_UPDATE`.
That event is not reliably fired on this client — TomTom carries its own redraw loop for exactly this
reason.

**`GetVectorToIcon` also accepts world map pins**, not only minimap pins.

**Dropped:** frame pooling and the `HereBeDragonsPinsTemplate` machinery (the caller owns its icons
here), the map canvas data provider, and `C_Minimap.GetViewRadius` (absent — the vanilla yard table is
used, which is what that branch existed to replace).

## Differences from Astrolabe-0.2

| Astrolabe | Here |
|---|---|
| `Astrolabe:PlaceIconOnMinimap(icon, c, z, x, y)` | `pins:AddMinimapIconMF(ref, icon, mapID, nil, x, y, floatOnEdge)` |
| `Astrolabe:PlaceIconOnWorldMap(frame, icon, c, z, x, y)` | `pins:AddWorldMapIconMF(ref, icon, mapID, nil, x, y, showFlag)` |
| `Astrolabe:RemoveIconFromMinimap(icon)` | `pins:RemoveMinimapIcon(ref, icon)` |
| `Astrolabe:GetDistanceToIcon(icon)` / `GetDirectionToIcon(icon)` — **degrees** | one call: `pins:GetVectorToIcon(icon)` → `angle` in **radians**, `distance` |
| `Astrolabe.MinimapIcons[icon]`, `Astrolabe.minimapOutside` | internal. Use `pins:IsMinimapIconOnEdge(icon)` and `pins:GetMinimapEnvironment()` |
| icon placement recalculated by the consumer | the library owns the update loop; add a pin once and it is maintained |

Astrolabe re-derives the indoor/outdoor state on every `ZONE_CHANGED_NEW_AREA` by nudging
`Minimap:SetZoom()`. On a client where the CVars do not exist that comparison is always true, so the
nudge fires every time and simply disturbs the user's zoom. This library does not do that.

## Licence

BSD 2-Clause -- see `LICENSE`, which also records exactly which parts derive from
Nevcairiel's HereBeDragons and which are this project's own.
